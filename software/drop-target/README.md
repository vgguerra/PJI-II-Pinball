# Drop target — software

Código de acionamento do drop target na Raspberry Pi 4.

| Arquivo | O que faz |
|---|---|
| [`servo_sobe.c`](servo_sobe.c) | Teste de bancada: leva o braço do servo para repouso e depois para a posição que levanta o alvo |

Houve uma versão em Python, com `gpiozero`. Foi removida quando o acionamento passou para o PWM
de hardware. O que decidiu não foi a linguagem: no Python o pulso era montado pelo `lgpio`, em
espaço de usuário, e tremia quando a Pi estava ocupada. Aqui quem conta o tempo é o bloco PWM do
SoC, então o pulso sai igual com a Pi parada ou carregada. Daria para escrever nos mesmos arquivos
de `/sys/class/pwm` a partir do Python — o ganho veio do hardware, não de ser C.

Custo da troca: um `dtoverlay`, um reboot e `sudo`.

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

## Preparar a Pi

Uma vez só. **Não é opcional**: o programa fala com o bloco PWM do SoC, e sem o overlay esse bloco
não aparece em `/sys/class/pwm`.

Em `/boot/firmware/config.txt`:

```
[all]
dtoverlay=pwm,pin=18,func=2
```

`pin=18` é BCM 18, o mesmo furo físico 12 — **não mexa no fio**. `func=2` é a função alternativa
que liga o GPIO18 ao bloco PWM0. O `[all]` garante que a linha vale para qualquer modelo de placa:
o `config.txt` é dividido em seções condicionais, e uma linha solta no fim do arquivo pode cair
numa seção de outro modelo e simplesmente não se aplicar.

Reinicie e confirme:

```bash
ls /sys/class/pwm/        # tem que aparecer pelo menos um pwmchip0
```

Fora isso, não precisa instalar nada: o programa só depende da libc.

**O áudio analógico usa o mesmo bloco PWM.** A saída do conector de 3,5 mm é gerada por PWM0/PWM1.
Se o pinball for ter som pelo P2, esse overlay briga com ele; por HDMI ou placa USB, não há
conflito.

### Se pedirem para instalar o `pigpio`, ignore

Tutoriais antigos mandam `sudo apt install pigpio`. O `apt` vai responder `Package 'pigpio' has no
installation candidate`, e **não tem conserto**: o pacote saiu do Raspberry Pi OS a partir do
Trixie, porque o Debian o removeu em 2025 — projeto abandonado pelo autor e incompatível com a
Pi 5. Este programa não usa biblioteca nenhuma de GPIO, então nada disso faz falta.

## Compilar e rodar

Com o overlay já no lugar (seção anterior):

```bash
make
sudo ./servo_sobe
```

Precisa de `sudo` porque `/sys/class/pwm` pertence ao root. Para dispensar, uma regra de udev:

```bash
sudo tee /etc/udev/rules.d/99-pwm.rules <<'EOF'
SUBSYSTEM=="pwm", ACTION=="add", RUN+="/bin/chgrp -R gpio /sys%p", RUN+="/bin/chmod -R g=u /sys%p"
EOF
sudo udevadm control --reload
```

## Uso

```bash
sudo ./servo_sobe                            # ciclo completo
sudo ./servo_sobe --calibra                  # move a cada angulo digitado
sudo ./servo_sobe --repouso 50 --levanta 95  # testa um par sem recompilar
sudo ./servo_sobe --angulo 70                # vai a um angulo so, sem voltar
```

O ciclo completo é **repouso → levanta → volta ao repouso**. A volta não é enfeite: com o braço
levantado ele fica no caminho do alvo, e a bola não consegue derrubá-lo de novo. O ciclo só fecha
quando o braço está de volta embaixo do alvo, pronto para a próxima.

Entre levantar e recolher há uma pausa de 500 ms (`TEMPO_NO_TOPO_MS`), para o alvo assentar no
engate da gaiola antes de perder o apoio do braço. **Se o alvo cair sozinho logo depois de
levantar, é esse número que precisa aumentar** — não o ângulo.

## Ângulos

Medidos na bancada, com a gaiola e o alvo montados:

| | graus |
|---|---:|
| Repouso | **54** |
| Levanta | **97** |
| Curso | 43 |

A simulação mecânica previa **75** graus de curso
([`drop-target-simulation.scad`](../../mecanica/modelos-3d/drop-target/simulation/drop-target-simulation.scad):
`arm_rest_angle = -35`, `arm_lift_angle = -110`). Quem manda é a peça real: o alvo levanta com 43.
Parte da diferença é de referência — os ângulos da simulação são do braço no sistema dela, e o zero
do servo depende de onde a corneta entrou no eixo. Mas 32 graus é muita diferença, e vale conferir a
geometria do braço na simulação **antes de repetir o conjunto três vezes**.

## Calibrar os ângulos

Os valores da seção **Ângulos** já saíram desse procedimento. Refaça se trocar a corneta de
posição, se montar outro conjunto, ou se o alvo não levantar por completo.

```bash
sudo ./servo_sobe --calibra
```

Digite um ângulo e Enter: o braço vai e **fica**, segurando a posição, para você ver onde ele
parou. `r` volta ao repouso, `l` vai ao levanta, `q` sai.

Com o alvo montado na gaiola:

1. Comece em `90` e veja para que lado o braço aponta.
2. Vá digitando números até ele ficar **logo abaixo do alvo caído**, sem encostar. É o **repouso**.
3. Suba até o **alvo levantar por completo**. É o **levanta**.
4. Teste o par: `sudo ./servo_sobe --repouso X --levanta Y`.
5. Fixe em `ANGULO_REPOUSO` e `ANGULO_LEVANTA` no [`servo_sobe.c`](servo_sobe.c) e rode `make`.

Os dois são independentes: o levanta pode ser **menor** que o repouso, se a corneta ficou apontando
para o outro lado.

O programa imprime o curso resultante e avisa se ele fugir muito dos 43° medidos. Não impede nada —
é para pegar corneta encaixada no dente errado do eixo estriado, que é estriado e só aceita poucas
posições. Nesse caso remontar um dente é melhor que compensar no software, porque o curso errado
custa torque justamente no fim, onde o alvo é mais pesado de levantar.

**Não force o servo contra o alvo travado.** Ele não tem proteção de corrente e queima.

## Próximo passo

Ler o micro switch `KW11-3Z-3` para detectar a queda do alvo e disparar a subida sozinho. A chave é
de ação rápida e repica — vai precisar de `bouncetime`, como já está anotado em
[`docs/09-pendencias-e-roadmap.md`](../../docs/09-pendencias-e-roadmap.md).
