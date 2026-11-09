/* Primeiro acionamento do servo do drop target, em C.
 *
 * Mesmo mecanismo do servo_sobe.py, por outro caminho: em vez de pedir o
 * pulso a uma biblioteca, este programa fala direto com o PWM de hardware do
 * SoC, pela interface que o kernel expõe em /sys/class/pwm. Não depende de
 * biblioteca nenhuma — só da libc.
 *
 * Por que isso é melhor que o caminho do Python: lá o pulso é montado em
 * espaço de usuário pelo lgpio, então ele treme quando a Pi está ocupada.
 * Aqui quem conta o tempo é o silício. O pulso sai igual com a Pi parada ou
 * compilando o kernel. O ganho vem do PWM de hardware, não de ser C — dava
 * para fazer isto do Python também, escrevendo nos mesmos arquivos.
 *
 * ANTES DE RODAR, uma vez só:
 *
 *     sudo nano /boot/firmware/config.txt
 *         dtoverlay=pwm,pin=18,func=2
 *     sudo reboot
 *
 * O "pin=18" é BCM 18, que é o furo físico 12 — o mesmo fio laranja, sem
 * mexer na ligação. O "func=2" é a função alternativa ALT5 do pino, que é a
 * que liga o GPIO18 ao bloco PWM0.
 *
 * COMPILAR E RODAR
 *
 *     gcc -O2 -Wall -Wextra -o servo_sobe servo_sobe.c
 *     sudo ./servo_sobe
 *     sudo ./servo_sobe --angulo 90 --segura
 *
 * Precisa de sudo porque os arquivos de /sys/class/pwm pertencem ao root.
 * Para rodar sem sudo, uma regra de udev resolve — ver o README.
 */

#define _POSIX_C_SOURCE 200809L

#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* Mesmas cotas do servo_sobe.py, para os dois programas se comportarem
 * igual. O SG90 responde de 500 a 2400 us; fico 100 us dentro das pontas
 * para o braço não forçar contra o batente interno. */
#define PULSO_MIN_NS   600000L     /*  600 us  ->  0 graus   */
#define PULSO_MAX_NS  2300000L     /* 2300 us  -> 180 graus  */
#define PERIODO_NS   20000000L     /*   20 ms  ->  50 Hz     */

/* Curso tirado da simulação mecânica (drop-target-simulation.scad):
 * arm_rest_angle = -35 e arm_lift_angle = -110, ou seja 75 graus. Onde esses
 * 75 caem na escala do servo depende de como a corneta entrou no eixo. */
#define CURSO_DA_SIMULACAO 75.0
#define ANGULO_REPOUSO     30.0
#define ANGULO_LEVANTA     (ANGULO_REPOUSO + CURSO_DA_SIMULACAO)

#define TEMPO_DE_GIRO_MS 600

/* Os caminhos são montados por concatenação: chip -> pwm -> arquivo. Cada
 * buffer tem de ser comprovadamente maior que o anterior, senão o gcc avisa
 * de truncamento — e com razão, porque ele não tem como saber que na prática
 * "/sys/class/pwm/pwmchip0" tem 24 caracteres. */
#define TAM_CHIP  96
#define TAM_PWM  (TAM_CHIP + 32)
#define TAM_PATH (TAM_PWM + 32)

static int escreve(const char *caminho, const char *valor)
{
    FILE *f = fopen(caminho, "w");
    if (!f)
        return -1;
    int ok = fputs(valor, f) >= 0;
    if (fclose(f) != 0)
        ok = 0;
    return ok ? 0 : -1;
}

static int escreve_long(const char *caminho, long valor)
{
    char buf[32];
    snprintf(buf, sizeof buf, "%ld", valor);
    return escreve(caminho, buf);
}

static void dorme_ms(long ms)
{
    struct timespec t = { ms / 1000, (ms % 1000) * 1000000L };
    nanosleep(&t, NULL);
}

/* Acha o pwmchip. O número varia com o kernel e com o modelo da Pi, então
 * procurar é mais confiável que cravar "pwmchip0". */
static int acha_chip(char destino[TAM_CHIP])
{
    DIR *d = opendir("/sys/class/pwm");
    if (!d)
        return -1;

    int melhor = -1;
    struct dirent *e;
    while ((e = readdir(d))) {
        int num;
        if (sscanf(e->d_name, "pwmchip%d", &num) == 1)
            if (melhor < 0 || num < melhor)
                melhor = num;
    }
    closedir(d);

    if (melhor < 0)
        return -1;
    snprintf(destino, TAM_CHIP, "/sys/class/pwm/pwmchip%d", melhor);
    return 0;
}

/* Exportar cria o diretório pwmN, mas quem o cria de fato é o udev, e isso
 * não é instantâneo. Esperar é mais barato que falhar por corrida. */
static int exporta(const char chip[TAM_CHIP], int canal, char destino[TAM_PWM])
{
    char caminho[TAM_PATH];
    snprintf(destino, TAM_PWM, "%s/pwm%d", chip, canal);

    if (access(destino, F_OK) != 0) {
        snprintf(caminho, sizeof caminho, "%s/export", chip);
        if (escreve_long(caminho, canal) != 0 && errno != EBUSY)
            return -1;
    }

    for (int i = 0; i < 100; i++) {
        snprintf(caminho, sizeof caminho, "%s/period", destino);
        if (access(caminho, W_OK) == 0)
            return 0;
        dorme_ms(10);
    }
    return -1;
}

static long pulso_de(double angulo)
{
    return PULSO_MIN_NS
         + (long)((angulo / 180.0) * (double)(PULSO_MAX_NS - PULSO_MIN_NS));
}

static int vai_para(const char pwm[TAM_PWM], double angulo, const char *rotulo)
{
    char caminho[TAM_PATH];
    long ns = pulso_de(angulo);

    printf("%12s: %5.1f graus  ->  pulso %ld us\n", rotulo, angulo, ns / 1000);

    snprintf(caminho, sizeof caminho, "%s/duty_cycle", pwm);
    if (escreve_long(caminho, ns) != 0) {
        perror("duty_cycle");
        return -1;
    }
    dorme_ms(TEMPO_DE_GIRO_MS);
    return 0;
}

static void ajuda(const char *prog)
{
    printf("uso: sudo %s [--angulo G] [--repouso G] [--levanta G] [--segura]\n"
           "                      [--chip N] [--canal N]\n\n"
           "  --angulo G   vai direto para este angulo, para calibrar\n"
           "  --repouso G  angulo de repouso            (padrao %.0f)\n"
           "  --levanta G  angulo que levanta o alvo    (padrao %.0f)\n"
           "  --segura     mantem o pulso no fim, em vez de soltar o servo\n"
           "  --chip N     forca o pwmchip, se a busca errar\n"
           "  --canal N    canal do chip                (padrao 0)\n",
           prog, ANGULO_REPOUSO, ANGULO_LEVANTA);
}

int main(int argc, char **argv)
{
    double repouso = ANGULO_REPOUSO, levanta = ANGULO_LEVANTA, angulo = -1.0;
    int segura = 0, canal = 0, chip_forcado = -1;

    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        int tem_valor = (i + 1 < argc);

        if (!strcmp(a, "-h") || !strcmp(a, "--help")) { ajuda(argv[0]); return 0; }
        else if (!strcmp(a, "--segura"))  segura = 1;
        else if (!strcmp(a, "--angulo")  && tem_valor) angulo  = atof(argv[++i]);
        else if (!strcmp(a, "--repouso") && tem_valor) repouso = atof(argv[++i]);
        else if (!strcmp(a, "--levanta") && tem_valor) levanta = atof(argv[++i]);
        else if (!strcmp(a, "--chip")    && tem_valor) chip_forcado = atoi(argv[++i]);
        else if (!strcmp(a, "--canal")   && tem_valor) canal   = atoi(argv[++i]);
        else { fprintf(stderr, "argumento desconhecido: %s\n\n", a); ajuda(argv[0]); return 2; }
    }

    const double faixa[] = { repouso, levanta, angulo < 0 ? 0.0 : angulo };
    for (size_t i = 0; i < sizeof faixa / sizeof *faixa; i++)
        if (faixa[i] < 0.0 || faixa[i] > 180.0) {
            fprintf(stderr, "angulo fora da faixa do SG90: %.1f nao esta entre 0 e 180\n", faixa[i]);
            return 2;
        }

    char chip[TAM_CHIP], pwm[TAM_PWM], caminho[TAM_PATH];

    if (chip_forcado >= 0)
        snprintf(chip, sizeof chip, "/sys/class/pwm/pwmchip%d", chip_forcado);
    else if (acha_chip(chip) != 0) {
        fprintf(stderr,
            "nao achei nenhum pwmchip em /sys/class/pwm.\n"
            "falta o overlay: ponha 'dtoverlay=pwm,pin=18,func=2' em\n"
            "/boot/firmware/config.txt e reinicie.\n");
        return 1;
    }
    printf("PWM de hardware: %s canal %d\n", chip, canal);

    if (exporta(chip, canal, pwm) != 0) {
        fprintf(stderr, "nao consegui exportar o canal %d de %s: %s\n",
                canal, chip, strerror(errno));
        fprintf(stderr, "rodou com sudo?\n");
        return 1;
    }

    /* O período vem antes do duty: o kernel recusa duty maior que o período,
     * e o período que vier de fábrica pode ser 0. */
    snprintf(caminho, sizeof caminho, "%s/period", pwm);
    if (escreve_long(caminho, PERIODO_NS) != 0) { perror("period"); return 1; }

    snprintf(caminho, sizeof caminho, "%s/duty_cycle", pwm);
    if (escreve_long(caminho, pulso_de(angulo < 0 ? repouso : angulo)) != 0) {
        perror("duty_cycle inicial");
        return 1;
    }

    snprintf(caminho, sizeof caminho, "%s/enable", pwm);
    if (escreve(caminho, "1") != 0) { perror("enable"); return 1; }

    int erro = 0;
    if (angulo >= 0.0) {
        erro = vai_para(pwm, angulo, "angulo");
    } else {
        erro = vai_para(pwm, repouso, "repouso");
        if (!erro) {
            dorme_ms(1000);
            erro = vai_para(pwm, levanta, "levanta");
        }
    }

    if (segura && !erro) {
        printf("segurando o pulso; Ctrl+C para sair\n");
        for (;;)
            dorme_ms(1000);
    }

    /* Desligar corta o trem de pulsos. Sem isso o servo fica corrigindo a
     * posição o tempo todo, zumbindo e esquentando à toa. O braço do drop
     * target não precisa de torque parado: quem segura o alvo levantado é a
     * própria mecânica. */
    snprintf(caminho, sizeof caminho, "%s/enable", pwm);
    escreve(caminho, "0");
    printf("servo solto\n");

    return erro ? 1 : 0;
}
