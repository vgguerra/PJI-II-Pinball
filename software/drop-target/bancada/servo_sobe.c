/* Teste de bancada do servo do drop target, sem a chave de fim de curso.
 *
 * Faz o ciclo do braço: repouso, levanta o alvo, espera ele travar no engate
 * da gaiola, e volta ao repouso. A volta é obrigatória — braço levantado fica
 * no caminho e a bola não derruba o alvo de novo.
 *
 * Para o ciclo automático, disparado pela chave, use o drop_target.
 *
 * MONTAGEM
 *     Sinal do servo (laranja)  ->  furo físico 12   (BCM 18)
 *     GND            (marrom)   ->  furo físico 6
 *     +5 V           (vermelho) ->  furo físico 2
 *
 * Precisa do overlay de PWM no config.txt e de sudo — ver o README.
 */

#define _POSIX_C_SOURCE 200809L

#include "pwm.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* MEDIDOS NA BANCADA, com a gaiola e o alvo montados. Não são estimativa:
 * saíram do --calibra, olhando o braço.
 *
 * Os dois são independentes de propósito. Amarrar o levanta ao repouso mais
 * um curso fixo prende os dois valores a um curso que talvez não seja o seu,
 * e impede o caso em que levantar significa DIMINUIR o ângulo, que acontece
 * conforme o lado para onde a corneta ficou apontando. */
#define ANGULO_REPOUSO 51.0
#define ANGULO_LEVANTA 102.0

/* Conferência de sanidade: se alguém mexer nos dois ângulos e o curso fugir
 * muito disto, é sinal de corneta encaixada no dente errado do eixo. */
#define CURSO_ESPERADO 43.0

#define TEMPO_DE_GIRO_MS 600
#define TEMPO_NO_TOPO_MS 500

static void dorme_ms(long ms)
{
    struct timespec t = { ms / 1000, (ms % 1000) * 1000000L };
    nanosleep(&t, NULL);
}

static int vai_para(const Pwm *p, double graus, const char *rotulo)
{
    printf("%12s: %5.1f graus  ->  pulso %ld us\n",
           rotulo, graus, pwm_pulso_de(graus) / 1000);
    if (pwm_angulo(p, graus) != 0) {
        perror("duty_cycle");
        return -1;
    }
    dorme_ms(TEMPO_DE_GIRO_MS);
    return 0;
}

/* Modo calibração: move a cada número digitado, sem sair e sem recompilar.
 * Mantém o pulso ligado entre um movimento e outro, senão o braço amolece e
 * você não consegue ver onde ele de fato parou. */
static int calibra(const Pwm *p, double repouso, double levanta)
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

        char *s = linha;
        while (*s == ' ' || *s == '\t') s++;

        if (*s == 'q' || *s == 'Q') return 0;
        if (*s == 'r' || *s == 'R') { vai_para(p, repouso, "repouso"); continue; }
        if (*s == 'l' || *s == 'L') { vai_para(p, levanta, "levanta"); continue; }
        if (*s == '\0') continue;

        char *fim;
        double g = strtod(s, &fim);
        if (fim == s) {
            fprintf(stderr, "  nao entendi \"%s\"\n", s);
            continue;
        }
        if (g < 0.0 || g > 180.0) {
            fprintf(stderr, "  fora da faixa do SG90: %.1f nao esta entre 0 e 180\n", g);
            continue;
        }
        vai_para(p, g, "angulo");
    }
}

static void ajuda(const char *prog)
{
    printf("uso: sudo %s [--angulo G] [--repouso G] [--levanta G] [--segura]\n"
           "                      [--calibra] [--chip N] [--canal N]\n\n"
           "  --calibra    move a cada angulo digitado, para achar os seus dois\n"
           "  --angulo G   vai direto para este angulo e para por ai\n"
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
    int segura = 0, canal = 0, chip = -1, modo_calibra = 0;

    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        int tem_valor = (i + 1 < argc);

        if (!strcmp(a, "-h") || !strcmp(a, "--help")) { ajuda(argv[0]); return 0; }
        else if (!strcmp(a, "--segura"))  segura = 1;
        else if (!strcmp(a, "--calibra")) modo_calibra = 1;
        else if (!strcmp(a, "--angulo")  && tem_valor) angulo  = atof(argv[++i]);
        else if (!strcmp(a, "--repouso") && tem_valor) repouso = atof(argv[++i]);
        else if (!strcmp(a, "--levanta") && tem_valor) levanta = atof(argv[++i]);
        else if (!strcmp(a, "--chip")    && tem_valor) chip    = atoi(argv[++i]);
        else if (!strcmp(a, "--canal")   && tem_valor) canal   = atoi(argv[++i]);
        else { fprintf(stderr, "argumento desconhecido: %s\n\n", a); ajuda(argv[0]); return 2; }
    }

    const double faixa[] = { repouso, levanta, angulo < 0 ? 0.0 : angulo };
    for (size_t i = 0; i < sizeof faixa / sizeof *faixa; i++)
        if (faixa[i] < 0.0 || faixa[i] > 180.0) {
            fprintf(stderr, "angulo fora da faixa do SG90: %.1f nao esta entre 0 e 180\n",
                    faixa[i]);
            return 2;
        }

    double curso = levanta - repouso;
    printf("curso configurado: %.1f graus (medido na bancada: %.0f)\n",
           curso, CURSO_ESPERADO);
    if (fabs(fabs(curso) - CURSO_ESPERADO) > 15.0)
        fprintf(stderr,
            "aviso: esse curso esta longe dos %.0f graus medidos na bancada.\n"
            "       se o alvo nao levanta direito, veja se a corneta nao\n"
            "       entrou no dente errado do eixo.\n", CURSO_ESPERADO);

    Pwm pwm;
    if (pwm_abre(&pwm, chip, canal, angulo < 0 ? repouso : angulo) != 0)
        return 1;

    int erro = 0;
    if (modo_calibra) {
        erro = calibra(&pwm, repouso, levanta);
    } else if (angulo >= 0.0) {
        erro = vai_para(&pwm, angulo, "angulo");
    } else {
        erro = vai_para(&pwm, repouso, "repouso");
        if (!erro) {
            dorme_ms(1000);
            erro = vai_para(&pwm, levanta, "levanta");
        }
        if (!erro) {
            dorme_ms(TEMPO_NO_TOPO_MS);
            erro = vai_para(&pwm, repouso, "volta");
        }
    }

    if (segura && !erro) {
        printf("segurando o pulso; Ctrl+C para sair\n");
        for (;;) dorme_ms(1000);
    }

    pwm_solta(&pwm);
    printf("servo solto\n");
    return erro ? 1 : 0;
}
