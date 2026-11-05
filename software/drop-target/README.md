# Drop target — software

Código de acionamento do drop target na Raspberry Pi 4.

| Arquivo | O que faz |
|---|---|
| [`servo_sobe.py`](servo_sobe.py) | Teste de bancada: leva o braço do servo para repouso e depois para a posição que levanta o alvo |

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

**Não é preciso instalar `pigpio` para rodar.** O script usa o backend que existir e informa qual
ficou em uso na primeira linha da saída.

| Backend | Quando usar |
|---|---|
| `pigpio` | O melhor: pulso gerado por DMA, imune à carga da Pi. Mas o pacote não existe em toda versão do Raspberry Pi OS e **não suporta a Pi 5**. Se existir: `sudo apt install -y pigpio python3-pigpio` e `sudo systemctl enable --now pigpiod` |
| `lgpio` | Padrão do Raspberry Pi OS atual. Pulso gerado em espaço de usuário, treme um pouco com a Pi carregada. Serve bem aqui, porque o braço só se move de vez em quando |

Se `apt` responder `pigpio has no installation candidate`, ignore e siga: é só o pacote não existir
na sua versão. O script roda igual.

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
