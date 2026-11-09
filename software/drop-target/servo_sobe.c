/* Primeiro acionamento do servo do drop target, em C.
 *
 * Faz o ciclo inteiro do braço: repouso, levanta o alvo, espera ele travar no
 * engate da gaiola, e volta para o repouso. A volta é obrigatória — braço
 * levantado fica no caminho e a bola não derruba o alvo de novo.
 *
 * Em vez de pedir o pulso a uma biblioteca, este programa fala direto com o
 * PWM de hardware do SoC, pela interface que o kernel expõe em
 * /sys/class/pwm. Não depende de biblioteca nenhuma — só da libc.
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
#include <math.h>
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

/* ÂNGULOS — é aqui que você mexe depois de calibrar.
 *
 * Os dois são independentes de propósito. Uma versão anterior calculava
 * ANGULO_LEVANTA como ANGULO_REPOUSO + 75, o que parecia esperto e era um
 * estorvo: amarrava os dois valores a um curso que talvez não seja o seu, e
 * impedia o caso em que levantar significa DIMINUIR o ângulo, que acontece
 * dependendo de para que lado a corneta ficou apontando.
 *
 * Para achar os seus números, rode com --calibra.
 *
 * O curso da simulação mecânica (drop-target-simulation.scad: arm_rest_angle
 * = -35, arm_lift_angle = -110) é de 75 graus. Isso NÃO diz onde os dois
 * caem na escala do servo, porque depende de como a corneta entrou no eixo
 * estriado. Serve de conferência: se a diferença entre os seus dois valores
 * der muito longe de 75, provavelmente a corneta está no dente errado, e é
 * melhor remontar do que compensar no software. */
/* MEDIDOS NA BANCADA, com a gaiola e o alvo montados. Não são estimativa:
 * saíram do --calibra, olhando o braço. */
#define ANGULO_REPOUSO 54.0
#define ANGULO_LEVANTA 97.0

/* O curso que saiu é de 43 graus. A simulação mecânica previa 75
 * (drop-target-simulation.scad: arm_rest_angle = -35, arm_lift_angle = -110).
 *
 * Quem manda é a peça real: o alvo levanta com 43. A diferença provavelmente
 * está na referência — os ângulos da simulação são do braço no sistema dela,
 * e o zero do servo depende de onde a corneta entrou no eixo. Mas 32 graus é
 * muita diferença para só referência, e vale conferir a geometria do braço na
 * simulação antes de repetir o conjunto três vezes.
 *
 * O valor abaixo é a conferência de sanidade: se alguém mexer nos dois
 * ângulos e o curso fugir muito disto, é sinal de corneta em dente errado. */
#define CURSO_ESPERADO 43.0

#define TEMPO_DE_GIRO_MS 600

/* Quanto o braço fica lá em cima antes de recolher.
 *
 * Recolher não é enfeite: com o braço levantado ele fica no caminho do alvo e
 * a bola não consegue derrubá-lo de novo. O ciclo só fecha quando o braço
 * volta para baixo do alvo, pronto para a próxima.
 *
 * A pausa existe para o alvo assentar no engate da gaiola antes de perder o
 * apoio do braço. Se ele cair sozinho logo depois de levantar, aumente. */
#define TEMPO_NO_TOPO_MS 500

/* Os caminhos são montados por concatenação: chip -> pwm -> arquivo. Cada
 * buffer tem de ser comprovadamente maior que o anterior, senão o gcc avisa
 * de truncamento — e com razão, porque ele não tem como saber que na prática
 * "/sys/class/pwm/pwmchip0" tem 24 caracteres. */
/* Raiz do sysfs. É substituível na compilação só para dar para exercitar o
 * programa inteiro contra uma árvore de arquivos falsa, sem placa:
 *     gcc -DRAIZ_PWM='"/tmp/fake"' ... */
#ifndef RAIZ_PWM
#define RAIZ_PWM "/sys/class/pwm"
#endif

#define TAM_CHIP  256
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
    DIR *d = opendir(RAIZ_PWM);
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
    snprintf(destino, TAM_CHIP, RAIZ_PWM "/pwmchip%d", melhor);
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

/* Modo calibração: move a cada número digitado, sem sair e sem recompilar.
 * Mantém o pulso ligado entre um movimento e outro, senão o braço amolece e
 * você não consegue ver onde ele de fato parou. */
static int calibra(const char pwm[TAM_PWM], double repouso, double levanta)
{
    char linha[64];

    printf("\nmodo calibracao\n"
           "  digite um angulo de 0 a 180 e Enter\n"
           "  r = ir para o repouso (%.1f)    l = ir para o levanta (%.1f)\n"
           "  q = sair\n\n", repouso, levanta);

    for (;;) {
        printf("angulo> ");
        fflush(stdout);

        if (!fgets(linha, sizeof linha, stdin)) {
            printf("\n");
            return 0;
        }

        linha[strcspn(linha, "\r\n")] = '\0';

        char *p = linha;
        while (*p == ' ' || *p == '\t') p++;

        if (*p == 'q' || *p == 'Q') return 0;
        if (*p == 'r' || *p == 'R') { vai_para(pwm, repouso, "repouso"); continue; }
        if (*p == 'l' || *p == 'L') { vai_para(pwm, levanta, "levanta"); continue; }
        if (*p == '\n' || *p == '\0') continue;

        char *fim;
        double g = strtod(p, &fim);
        if (fim == p) {
            fprintf(stderr, "  nao entendi \"%s\"\n", p);
            continue;
        }
        if (g < 0.0 || g > 180.0) {
            fprintf(stderr, "  fora da faixa do SG90: %.1f nao esta entre 0 e 180\n", g);
            continue;
        }
        vai_para(pwm, g, "angulo");
    }
}

static void ajuda(const char *prog)
{
    printf("uso: sudo %s [--angulo G] [--repouso G] [--levanta G] [--segura]\n"
           "                      [--calibra] [--chip N] [--canal N]\n\n"
           "  --calibra    move a cada angulo digitado, para achar os seus dois\n"
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
    int segura = 0, canal = 0, chip_forcado = -1, modo_calibra = 0;

    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        int tem_valor = (i + 1 < argc);

        if (!strcmp(a, "-h") || !strcmp(a, "--help")) { ajuda(argv[0]); return 0; }
        else if (!strcmp(a, "--segura"))  segura = 1;
        else if (!strcmp(a, "--calibra")) modo_calibra = 1;
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
        snprintf(chip, sizeof chip, RAIZ_PWM "/pwmchip%d", chip_forcado);
    else if (acha_chip(chip) != 0) {
        fprintf(stderr,
            "nao achei nenhum pwmchip em " RAIZ_PWM ".\n"
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

    /* Conferência contra a mecânica. Não impede nada: só avisa, porque quem
     * sabe se a corneta está no dente certo é você, olhando o braço. */
    double curso = levanta - repouso;
    printf("curso configurado: %.1f graus (medido na bancada: %.0f)\n",
           curso, CURSO_ESPERADO);
    if (fabs(fabs(curso) - CURSO_ESPERADO) > 15.0)
        fprintf(stderr,
            "aviso: esse curso esta longe dos %.0f graus medidos na bancada.\n"
            "       se o alvo nao levanta direito, veja se a corneta nao\n"
            "       entrou no dente errado do eixo.\n", CURSO_ESPERADO);

    int erro = 0;
    if (modo_calibra) {
        erro = calibra(pwm, repouso, levanta);
    } else if (angulo >= 0.0) {
        erro = vai_para(pwm, angulo, "angulo");
    } else {
        erro = vai_para(pwm, repouso, "repouso");
        if (!erro) {
            dorme_ms(1000);
            erro = vai_para(pwm, levanta, "levanta");
        }
        if (!erro) {
            dorme_ms(TEMPO_NO_TOPO_MS);
            erro = vai_para(pwm, repouso, "volta");
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
