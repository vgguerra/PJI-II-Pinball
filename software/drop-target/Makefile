# Versão em C do acionamento do servo. Sem biblioteca externa: fala direto
# com o PWM de hardware por /sys/class/pwm, então basta a libc.
CFLAGS = -O2 -Wall -Wextra -Wpedantic -std=c11

servo_sobe: servo_sobe.c

clean:
	rm -f servo_sobe

.PHONY: clean
