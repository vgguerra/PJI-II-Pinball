# Drop target — software

Código de acionamento do drop target na Raspberry Pi 4.

| Arquivo | O que faz |
|---|---|
| [`servo_sobe.py`](servo_sobe.py) | Teste de bancada: leva o braço do servo para repouso e depois para a posição que levanta o alvo |
| [`servo_sobe.c`](servo_sobe.c) | O mesmo, em C, pelo PWM de hardware do SoC |

As duas versões fazem a mesma coisa e aceitam os mesmos argumentos. A diferença não é a
linguagem — é **quem gera o pulso**:

| | Quem conta o tempo | Precisa de | Tremor |
|---|---|---|---|
| `servo_sobe.py` | `lgpio`, em espaço de usuário | nada, já vem no sistema | treme um pouco com a Pi ocupada |
| `servo_sobe.c` | o bloco PWM do SoC | um `dtoverlay` e `sudo` | nenhum |

Comece pela versão em Python: ela roda sem preparar nada. A versão em C vale quando o tremor
atrapalhar — e o ganho vem do PWM de hardware, não de ser C. Daria para escrever nos mesmos
arquivos de `/sys/class/pwm` a partir do Python.

### Compilar e rodar a versão em C

Uma vez só, em `/boot/firmware/config.txt`:

```
dtoverlay=pwm,pin=18,func=2
```

`pin=18` é BCM 18, o mesmo furo físico 12 — **não mexa na ligação**. `func=2` é a função
alternativa que liga o GPIO18 ao bloco PWM0. Reinicie depois de salvar.

```bash
make
sudo ./servo_sobe
sudo ./servo_sobe --angulo 90 --segura
```

Precisa de `sudo` porque `/sys/class/pwm` pertence ao root. Para dispensar, uma regra de udev:

```bash
sudo tee /etc/udev/rules.d/99-pwm.rules <<'EOF'
SUBSYSTEM=="pwm", ACTION=="add", RUN+="/bin/chgrp -R gpio /sys%p", RUN+="/bin/chmod -R g=u /sys%p"
EOF
sudo udevadm control --reload
```

## Ligação

Com a Pi **desligada**. Pino 1 fica no canto mais perto do slot do micro-SD; ímpares numa fileira,
pares na outra.

| Fio do SG90 | Vai para | Pino físico |
|---|---|---|
| Laranja / amarelo (sinal) | GPIO18 | **12** |
| Marrom / preto (GND) | GND | **14** |
| Vermelho (+5 V) | 5 V — **ver abaixo** | **2** |

```
 ímpar                      par
 ─────────────────          ─────────────────
  1  3V3                     2  5V       <-- VERMELHO
  3  GPIO2  (SDA, I2C)       4  5V
  5  GPIO3  (SCL, I2C)       6  GND
  7  GPIO4  (sensor)         8  GPIO14
  9  GND                    10  GPIO15
 11  GPIO17 (sensor)        12  GPIO18   <-- LARANJA (sinal)
 13  GPIO27 (sensor)        14  GND      <-- MARROM
```

O terra vai no 14, e não no 6, de propósito: achado o 12, o 14 é o buraco vizinho na mesma fileira.
O 6 funciona igual, mas obriga a contar de novo e é onde se erra.

GPIO18 foi escolhido por dois motivos: é PWM por hardware na Pi 4, e já aparece no esquemático do
projeto sem função atribuída — não está no banco de 16 entradas de sensores
([`docs/05-pinout.md`](../../docs/05-pinout.md), seção 5.1).

**Confira a ordem dos fios antes de energizar.** No SG90 original é marrom / vermelho / laranja, com
o vermelho no meio. Em clone pode vir preto / vermelho / amarelo. Se o vermelho não estiver no meio,
pare: 5 V no pino de sinal queima o servo. E o vermelho vai no pino 2, não no 1 — o pino 1 é 3,3 V, e
aí o servo gira torto e você culpa o código.

**Não encoste nos pinos 3 e 5** (I²C dos PCF8574, por onde os solenoides são comandados) nem nos
**7, 11 e 13** (banco de entradas de sensores). Nenhum deles é deste mecanismo.

### Alimentação

O SG90 puxa ~250 mA girando e passa de 700 mA se travar. Esse pico derruba o trilho de 5 V e a
Raspberry reinicia. **No pinball montado, alimente o servo pelos 5 V externos** (BAT2, o mesmo
trilho dos L293D) e ligue os terras em comum — sem terra comum o servo não enxerga o sinal.

Para um teste de bancada com um servo só, o pino 5 V da própria Pi costuma aguentar.

## Instalação

O `gpiozero` já vem no Raspberry Pi OS. Se faltar:

```bash
sudo apt install -y python3-gpiozero python3-lgpio
```

### Não tente instalar o `pigpio`

Se `apt` responder `Package 'pigpio' has no installation candidate`, **não é erro seu e não tem
conserto por `apt`**. O pacote foi removido do Raspberry Pi OS a partir do Trixie: o Debian o tirou
em 2025 porque o projeto foi abandonado pelo autor e não funciona na Pi 5. Compilar do fonte é
possível, mas há relatos de *segfault* no Trixie.

O script não precisa dele. Ele usa o backend que existir — hoje o `lgpio` — e informa qual ficou em
uso na primeira linha da saída. O pulso do `lgpio` é gerado em espaço de usuário e treme um pouco
quando a Pi está carregada, mas serve bem aqui: o braço só se move de vez em quando, e o script
solta o servo no fim, o que corta o trem de pulsos.

### Se o tremor incomodar

O caminho atual **não** é o `pigpio`, é o PWM de hardware do próprio SoC, que o kernel expõe em
`/sys/class/pwm`. Em `/boot/firmware/config.txt`:

```
dtoverlay=pwm,pin=18,func=2
```

Reinicie e o pulso passa a ser gerado pelo hardware, imune à carga da Pi. Só vale mexer nisso se a
calibração mostrar que o braço não para quieto — para levantar um alvo, o `lgpio` dá conta.

## Uso

```bash
python3 servo_sobe.py                        # repouso, pausa, levanta
python3 servo_sobe.py --angulo 90 --segura   # trava num ângulo, para calibrar
python3 servo_sobe.py --repouso 25 --levanta 100
```

## Calibrar os ângulos

A simulação mecânica define o **curso**, não a posição absoluta: `arm_rest_angle = -35` e
`arm_lift_angle = -110` em
[`drop-target-simulation.scad`](../../mecanica/modelos-3d/drop-target/simulation/drop-target-simulation.scad),
ou seja **75° entre repouso e levantado**. Onde esses 75° caem na escala de 0 a 180 do SG90 depende
de como a corneta entrou no eixo na montagem, e o eixo do SG90 é estriado — só dá para encaixar de
poucas em poucas posições.

Procedimento, com o alvo montado na gaiola:

1. `--angulo 90 --segura` e encaixe a corneta o mais perto possível do meio do curso que você quer.
2. Vá baixando com `--angulo` até achar onde o braço fica logo abaixo do alvo caído. É o repouso.
3. Suba com `--angulo` até o alvo levantar por completo. É o levanta.
4. Confira se a diferença deu perto de 75°. Se deu muito diferente, a corneta está na posição errada
   no eixo: volte ao passo 1 e gire um dente.
5. Fixe os dois valores em `ANGULO_REPOUSO` e `ANGULO_LEVANTA` no script.

Não force o servo contra o alvo travado. Ele não tem proteção de corrente e queima o motor.

## Próximo passo

Ler o micro switch `KW11-3Z-3` para detectar a queda do alvo e disparar a subida sozinho. A chave é
de ação rápida e repica — vai precisar de `bouncetime`, como já está anotado em
[`docs/09-pendencias-e-roadmap.md`](../../docs/09-pendencias-e-roadmap.md).
