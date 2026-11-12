# Sem biblioteca externa: os programas falam direto com o kernel, pelo sysfs
# do PWM e pela uAPI de GPIO do /dev/gpiochip. Basta a libc.
#
#   drop_target        o que roda no jogo
#   bancada/servo_sobe teste manual do servo, sem a chave
CFLAGS  = -O2 -Wall -Wextra -Wpedantic -std=c11 -Ilib
LDLIBS  = -lm

all: drop_target bancada/servo_sobe

drop_target: drop_target.o lib/pwm.o
	$(CC) $^ $(LDLIBS) -o $@

bancada/servo_sobe: bancada/servo_sobe.o lib/pwm.o
	$(CC) $^ $(LDLIBS) -o $@

drop_target.o bancada/servo_sobe.o lib/pwm.o: lib/pwm.h

clean:
	rm -f drop_target bancada/servo_sobe *.o lib/*.o bancada/*.o

.PHONY: all clean
