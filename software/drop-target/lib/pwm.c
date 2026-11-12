#define _POSIX_C_SOURCE 200809L

#include "pwm.h"

#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <unistd.h>

/* Raiz do sysfs. Substituível na compilação só para dar para exercitar o
 * programa contra uma árvore de arquivos falsa, sem placa:
 *     gcc -DRAIZ_PWM='"/tmp/fake"' ... */
#ifndef RAIZ_PWM
#define RAIZ_PWM "/sys/class/pwm"
#endif

#define TAM_CHIP 256
#define TAM_PATH 352

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

/* O número do pwmchip varia com o kernel e com o modelo da Pi, então procurar
 * é mais confiável que cravar "pwmchip0". */
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

/* Exportar cria o diretório pwmN, mas quem o cria é o udev, e isso não é
 * instantâneo. Esperar é mais barato que falhar por corrida. */
static int exporta(const char *chip, int canal, char destino[320])
{
    char caminho[TAM_PATH];
    snprintf(destino, 320, "%s/pwm%d", chip, canal);

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

long pwm_pulso_de(double graus)
{
    return PULSO_MIN_NS
         + (long)((graus / 180.0) * (double)(PULSO_MAX_NS - PULSO_MIN_NS));
}

int pwm_angulo(const Pwm *p, double graus)
{
    char caminho[TAM_PATH];
    snprintf(caminho, sizeof caminho, "%s/duty_cycle", p->caminho);
    return escreve_long(caminho, pwm_pulso_de(graus));
}

void pwm_solta(const Pwm *p)
{
    char caminho[TAM_PATH];
    snprintf(caminho, sizeof caminho, "%s/enable", p->caminho);
    escreve(caminho, "0");
}

int pwm_abre(Pwm *p, int chip_forcado, int canal, double graus_iniciais)
{
    char chip[TAM_CHIP], caminho[TAM_PATH];

    if (chip_forcado >= 0)
        snprintf(chip, sizeof chip, RAIZ_PWM "/pwmchip%d", chip_forcado);
    else if (acha_chip(chip) != 0) {
        fprintf(stderr,
            "nao achei nenhum pwmchip em " RAIZ_PWM ".\n"
            "falta o overlay: ponha 'dtoverlay=pwm,pin=18,func=2' sob [all]\n"
            "em /boot/firmware/config.txt e reinicie.\n");
        return -1;
    }
    printf("PWM de hardware: %s canal %d\n", chip, canal);

    if (exporta(chip, canal, p->caminho) != 0) {
        fprintf(stderr, "nao consegui exportar o canal %d de %s: %s\nrodou com sudo?\n",
                canal, chip, strerror(errno));
        return -1;
    }

    /* Zerar o duty ANTES de mexer no período. O kernel recusa período menor
     * que o duty corrente, e o duty corrente é o que sobrou da última vez que
     * alguém usou este canal — pode ter sido outro programa, ou um teste à
     * mão com período de 1 segundo. Sem isto, a escrita do período falha com
     * EINVAL e o programa morre sem ter feito nada. */
    snprintf(caminho, sizeof caminho, "%s/duty_cycle", p->caminho);
    escreve_long(caminho, 0);

    snprintf(caminho, sizeof caminho, "%s/period", p->caminho);
    if (escreve_long(caminho, PERIODO_NS) != 0) {
        fprintf(stderr, "nao consegui ajustar o periodo em %s: %s\n",
                caminho, strerror(errno));
        if (errno == EINVAL)
            fprintf(stderr,
                "EINVAL aqui quase sempre e duty_cycle maior que o periodo novo.\n"
                "limpe o canal a mao:\n"
                "  sudo sh -c 'echo 0 > %s/enable; echo 0 > %s/duty_cycle'\n",
                p->caminho, p->caminho);
        return -1;
    }

    if (pwm_angulo(p, graus_iniciais) != 0) {
        perror("duty_cycle inicial");
        return -1;
    }

    snprintf(caminho, sizeof caminho, "%s/enable", p->caminho);
    if (escreve(caminho, "1") != 0) {
        perror("enable");
        return -1;
    }
    return 0;
}
