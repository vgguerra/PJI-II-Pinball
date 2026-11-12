/* Acionamento de servo pelo PWM de hardware do SoC, via /sys/class/pwm.
 *
 * Sem biblioteca externa: o kernel expõe o bloco PWM como arquivos, e isso
 * aqui só escreve neles. Precisa do overlay no config.txt e de root — ver o
 * README desta pasta.
 */
#ifndef PWM_H
#define PWM_H

/* O SG90 responde a pulsos de 500 a 2400 us. Fico 100 us dentro das pontas
 * para o braço não forçar contra o batente interno. */
#define PULSO_MIN_NS   600000L     /*  600 us  ->  0 graus  */
#define PULSO_MAX_NS  2300000L     /* 2300 us  -> 180 graus */
#define PERIODO_NS   20000000L     /*   20 ms  ->  50 Hz    */

typedef struct {
    char caminho[320];   /* .../pwmchipN/pwmM */
} Pwm;

/* Abre o canal e deixa o pulso ligado no ângulo pedido. chip < 0 procura. */
int  pwm_abre(Pwm *p, int chip, int canal, double graus_iniciais);

/* Muda o ângulo. Não espera o servo chegar lá. */
int  pwm_angulo(const Pwm *p, double graus);

/* Corta o trem de pulsos: o servo amolece e para de zumbir. */
void pwm_solta(const Pwm *p);

long pwm_pulso_de(double graus);

#endif
