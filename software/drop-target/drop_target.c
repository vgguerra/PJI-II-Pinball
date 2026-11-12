/* Drop target automático: a chave acusa o alvo caído, e o servo o levanta.
 *
 * Ao iniciar ele arma o mecanismo: se o alvo estiver caído, levanta antes de
 * passar a escutar. Isso importa porque o gatilho é a borda — alvo parado em
 * baixo não gera borda nenhuma, e sem isso o jogo começaria com um alvo
 * morto, que nunca mais subiria.
 *
 * Depois, o ciclo se repete para sempre:
 *
 *   1. espera a bola derrubar o alvo, que solta a chave de fim de curso;
 *   2. espera 2 s, para a bola sair da frente antes do braço subir;
 *   3. o braço levanta o alvo até ele travar no engate da gaiola;
 *   4. o braço volta ao repouso, para não ficar no caminho da próxima bolada.
 *
 * LIGAÇÃO DA CHAVE (KW11-3Z-3)
 *
 *     Um terminal   ->  GND,   furo físico 14
 *     Outro terminal ->  BCM23, furo físico 16
 *
 * Chave é contato puro, não tem polaridade: tanto faz qual terminal vai em
 * qual furo. O furo 14 e o 16 são vizinhos, na mesma fileira dos pares.
 *
 * Não precisa de resistor: o programa liga o pull-up interno da própria
 * Raspberry.
 *
 * Na nossa gaiola, o alvo EM PÉ mantém a chave pressionada, e a queda a
 * solta. Então a linha fica baixa com o alvo em pé e SOBE quando ele cai: é
 * essa subida o evento. Para o arranjo oposto, --chave-solta-em-pe.
 *
 * O gatilho é a BORDA, não o nível, porque enquanto o alvo estiver caído a
 * linha fica parada no novo nível — isso é o estado normal de um alvo
 * derrubado, não um evento novo.
 *
 * COMPILAR E RODAR
 *
 *     make
 *     sudo ./drop_target
 *
 * Precisa do mesmo overlay de PWM do servo_sobe. Ver o README.
 */

#define _POSIX_C_SOURCE 200809L

#include "pwm.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/gpio.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

/* Ângulos medidos na bancada. Os mesmos do servo_sobe.c. */
#define ANGULO_REPOUSO 51.0
#define ANGULO_LEVANTA 102.0

#define TEMPO_DE_GIRO_MS   600
#define TEMPO_NO_TOPO_MS   500
#define ESPERA_ANTES_MS   2000   /* da queda do alvo até o braço começar */

/* Linha da chave, em numeração BCM — a mesma que o kernel usa. BCM 23 é o
 * furo físico 16. Está no banco de 16 entradas de sensores do projeto
 * (docs/05-pinout.md, seção 5.1), então não conflita com nada. */
#define LINHA_CHAVE 23

/* A KW11-3Z-3 é de ação rápida: os contatos batem e repicam por alguns
 * milissegundos antes de assentar. Sem filtro, uma única queda do alvo vira
 * três ou quatro eventos. O kernel sabe filtrar isso sozinho; quando o driver
 * não aceitar, o filtro em software abaixo cobre. */
#define DEBOUNCE_US 20000

static volatile sig_atomic_t parar = 0;

static void pede_parada(int sinal) { (void)sinal; parar = 1; }

static void dorme_ms(long ms)
{
    struct timespec t = { ms / 1000, (ms % 1000) * 1000000L };
    nanosleep(&t, NULL);
}

static long agora_ms(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000L + t.tv_nsec / 1000000L;
}

/* O gpiochip do conector muda de número conforme o modelo e o kernel, então
 * procuro pelo rótulo em vez de cravar /dev/gpiochip0. */
static int abre_gpiochip(const char *forcado)
{
    if (forcado) {
        int fd = open(forcado, O_RDWR | O_CLOEXEC);
        if (fd < 0)
            fprintf(stderr, "nao abri %s: %s\n", forcado, strerror(errno));
        return fd;
    }

    for (int i = 0; i < 16; i++) {
        char caminho[32];
        snprintf(caminho, sizeof caminho, "/dev/gpiochip%d", i);

        int fd = open(caminho, O_RDWR | O_CLOEXEC);
        if (fd < 0)
            continue;

        struct gpiochip_info info;
        memset(&info, 0, sizeof info);
        if (ioctl(fd, GPIO_GET_CHIPINFO_IOCTL, &info) == 0
            && info.lines > LINHA_CHAVE
            && (strstr(info.label, "pinctrl") || strstr(info.label, "bcm"))) {
            printf("GPIO: %s (%s, %u linhas)\n", caminho, info.label, info.lines);
            return fd;
        }
        close(fd);
    }

    fprintf(stderr, "nao achei o gpiochip do conector. tente --gpiochip /dev/gpiochipN\n");
    return -1;
}

/* Pede a linha como entrada, com pull-up interno e aviso de borda de descida.
 * Tenta primeiro com o debounce do kernel; se o driver não suportar, repete
 * sem ele e o filtro em software assume. */
static int pede_linha(int chip_fd, int em_pe_pressionada, int *tem_debounce_do_kernel)
{
    for (int com_debounce = 1; com_debounce >= 0; com_debounce--) {
        struct gpio_v2_line_request req;
        memset(&req, 0, sizeof req);

        req.offsets[0] = LINHA_CHAVE;
        req.num_lines = 1;
        snprintf(req.consumer, sizeof req.consumer, "drop-target");
        /* Qual borda é a queda do alvo depende de como a chave foi montada
         * na gaiola, e os dois arranjos existem:
         *
         *   alvo em pé PRESSIONA a chave  (o nosso)
         *       em pé  -> contato fechado -> linha baixa
         *       caiu   -> contato solto   -> linha sobe     <- evento
         *
         *   alvo em pé deixa a chave SOLTA
         *       em pé  -> contato aberto  -> linha alta
         *       caiu   -> contato fechado -> linha desce    <- evento
         */
        req.config.flags = GPIO_V2_LINE_FLAG_INPUT
                         | GPIO_V2_LINE_FLAG_BIAS_PULL_UP
                         | (em_pe_pressionada ? GPIO_V2_LINE_FLAG_EDGE_RISING
                                              : GPIO_V2_LINE_FLAG_EDGE_FALLING);

        if (com_debounce) {
            req.config.num_attrs = 1;
            req.config.attrs[0].mask = 1ULL;
            req.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_DEBOUNCE;
            req.config.attrs[0].attr.debounce_period_us = DEBOUNCE_US;
        }

        if (ioctl(chip_fd, GPIO_V2_GET_LINE_IOCTL, &req) == 0) {
            *tem_debounce_do_kernel = com_debounce;
            return req.fd;
        }
        if (!com_debounce)
            fprintf(stderr, "nao consegui pedir a linha BCM%d: %s\n",
                    LINHA_CHAVE, strerror(errno));
    }
    return -1;
}

/* Lê o nível atual da linha. Serve de conferência na partida: o nível com o
 * alvo em pé tem de casar com o arranjo configurado, senão o programa vai
 * esperar a borda errada e nunca disparar. */
static int le_nivel(int linha_fd)
{
    struct gpio_v2_line_values v;
    memset(&v, 0, sizeof v);
    v.mask = 1ULL;
    if (ioctl(linha_fd, GPIO_V2_LINE_GET_VALUES_IOCTL, &v) != 0)
        return -1;
    return (int)(v.bits & 1ULL);
}

/* Descarta os eventos que ficaram na fila. O alvo subindo mexe na chave e o
 * braço voltando sacode a gaiola: isso gera borda que é ruído do próprio
 * ciclo, não uma bolada nova. */
static void descarta_eventos(int linha_fd)
{
    struct gpio_v2_line_event ev;
    int antes = fcntl(linha_fd, F_GETFL);
    fcntl(linha_fd, F_SETFL, antes | O_NONBLOCK);
    while (read(linha_fd, &ev, sizeof ev) > 0) { }
    fcntl(linha_fd, F_SETFL, antes);
}

static int ciclo_do_servo(const Pwm *pwm)
{
    printf("  levanta %5.1f graus\n", ANGULO_LEVANTA);
    if (pwm_angulo(pwm, ANGULO_LEVANTA) != 0) return -1;
    dorme_ms(TEMPO_DE_GIRO_MS);

    dorme_ms(TEMPO_NO_TOPO_MS);

    printf("  volta   %5.1f graus\n", ANGULO_REPOUSO);
    if (pwm_angulo(pwm, ANGULO_REPOUSO) != 0) return -1;
    dorme_ms(TEMPO_DE_GIRO_MS);
    return 0;
}

int main(int argc, char **argv)
{
    const char *gpiochip = NULL;
    int pwmchip = -1, canal = 0, em_pe_pressionada = 1;

    for (int i = 1; i < argc; i++) {
        int tem_valor = (i + 1 < argc);
        if (!strcmp(argv[i], "--chave-solta-em-pe")) em_pe_pressionada = 0;
        else if (!strcmp(argv[i], "--gpiochip") && tem_valor) gpiochip = argv[++i];
        else if (!strcmp(argv[i], "--chip")  && tem_valor) pwmchip = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--canal") && tem_valor) canal   = atoi(argv[++i]);
        else {
            printf("uso: sudo %s [--chave-solta-em-pe] [--gpiochip /dev/gpiochipN]\n"
                   "                    [--chip N] [--canal N]\n\n"
                   "  Por padrao o alvo EM PE mantem a chave PRESSIONADA, que e\n"
                   "  como a nossa gaiola esta montada: a queda SOLTA a chave.\n\n"
                   "  --chave-solta-em-pe   para o arranjo oposto, em que o alvo\n"
                   "                        caido e que pressiona a chave.\n", argv[0]);
            return strcmp(argv[i], "--help") && strcmp(argv[i], "-h") ? 2 : 0;
        }
    }

    signal(SIGINT, pede_parada);
    signal(SIGTERM, pede_parada);

    int chip_fd = abre_gpiochip(gpiochip);
    if (chip_fd < 0)
        return 1;

    int debounce_do_kernel = 0;
    int linha_fd = pede_linha(chip_fd, em_pe_pressionada, &debounce_do_kernel);
    if (linha_fd < 0)
        return 1;

    printf("chave na linha BCM%d (furo fisico 16), pull-up interno ligado\n",
           LINHA_CHAVE);
    printf("debounce: %s\n",
           debounce_do_kernel ? "pelo kernel, 20 ms" : "em software, 20 ms");
    printf("arranjo : alvo em pe deixa a chave %s, entao a queda e a %s da linha\n",
           em_pe_pressionada ? "PRESSIONADA" : "SOLTA",
           em_pe_pressionada ? "SUBIDA" : "descida");

    Pwm pwm;
    if (pwm_abre(&pwm, pwmchip, canal, ANGULO_REPOUSO) != 0)
        return 1;
    dorme_ms(TEMPO_DE_GIRO_MS);

    /* Armar o mecanismo antes de começar a escutar. Se o jogo anterior
     * terminou com o alvo derrubado, ele está derrubado agora, e começar
     * assim é começar com um alvo a menos: ninguém vai levantá-lo, porque o
     * gatilho é a BORDA, e alvo parado em baixo não gera borda nenhuma. */
    const int nivel_em_pe = em_pe_pressionada ? 0 : 1;
    int nivel = le_nivel(linha_fd);

    printf("linha agora: %s\n", nivel < 0 ? "nao consegui ler"
           : nivel ? "ALTO (chave aberta)" : "BAIXO (chave fechada)");

    if (nivel < 0) {
        fprintf(stderr, "nao consegui ler a chave; sigo sem armar\n");
    } else if (nivel == nivel_em_pe) {
        printf("alvo ja esta em pe\n");
    } else {
        printf("alvo esta caido. levantando antes de comecar.\n");
        if (ciclo_do_servo(&pwm) != 0)
            return 1;
        descarta_eventos(linha_fd);

        nivel = le_nivel(linha_fd);
        if (nivel == nivel_em_pe) {
            printf("alvo em pe\n");
        } else {
            /* O braço fez o movimento e a chave não mudou. Ou o alvo não
             * travou no engate e caiu de volta, ou a chave não está sendo
             * acionada por ele, ou o arranjo configurado é o oposto. */
            fprintf(stderr,
                "aviso: o braco subiu mas a chave nao mudou de estado.\n"
                "  - o alvo pode nao estar travando no engate: aumente\n"
                "    TEMPO_NO_TOPO_MS, ou confira o angulo de levanta;\n"
                "  - ou a chave nao esta sendo acionada pelo alvo;\n"
                "  - ou o arranjo esta trocado: tente %s.\n",
                em_pe_pressionada ? "--chave-solta-em-pe"
                                  : "tirar o --chave-solta-em-pe");
        }
    }

    descarta_eventos(linha_fd);
    printf("\npronto. derrube o alvo. Ctrl+C para sair.\n");

    long ultima = 0;
    while (!parar) {
        struct gpio_v2_line_event ev;
        ssize_t n = read(linha_fd, &ev, sizeof ev);

        if (n < 0) {
            if (errno == EINTR) continue;   /* Ctrl+C */
            perror("read");
            break;
        }
        unsigned borda = em_pe_pressionada ? GPIO_V2_LINE_EVENT_RISING_EDGE
                                           : GPIO_V2_LINE_EVENT_FALLING_EDGE;
        if (n != (ssize_t)sizeof ev || ev.id != borda)
            continue;

        /* Guarda em software: vale mesmo com o debounce do kernel, porque a
         * mesa treme e o alvo pode bater duas vezes no engate. */
        long t = agora_ms();
        if (t - ultima < DEBOUNCE_US / 1000) continue;
        ultima = t;

        printf("\nalvo caiu. esperando %d ms\n", ESPERA_ANTES_MS);
        dorme_ms(ESPERA_ANTES_MS);
        if (parar) break;

        if (ciclo_do_servo(&pwm) != 0)
            break;

        descarta_eventos(linha_fd);
        ultima = agora_ms();
        printf("  pronto para a proxima\n");
    }

    printf("\nsaindo\n");
    pwm_solta(&pwm);
    close(linha_fd);
    close(chip_fd);
    return 0;
}
