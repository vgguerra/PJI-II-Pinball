# Drop target — software

Acionamento do drop target na Raspberry Pi. A bola derruba o alvo, a chave de fim de curso acusa a
queda, e o servo levanta o alvo de volta.

```
drop_target.c     o que roda no jogo: escuta a chave e faz o ciclo
Makefile
lib/pwm.c .h      acionamento do servo pelo PWM de hardware do SoC
bancada/
  servo_sobe.c    teste manual do servo, sem a chave. Serve para calibrar
```

Na raiz fica só o que roda de verdade. Nenhum dos dois depende de biblioteca externa: eles falam
direto com o kernel, pelo sysfs do PWM e pela uAPI de GPIO do `/dev/gpiochip`. Basta a libc.

Houve uma versão em Python, com `gpiozero`. Foi removida quando o acionamento passou para o PWM de
hardware. O que decidiu não foi a linguagem: no Python o pulso era montado pelo `lgpio`, em espaço
de usuário, e tremia quando a Pi estava ocupada. Aqui quem conta o tempo é o bloco PWM do SoC.

## Ligação do servo

Com a Pi **desligada**. Pino 1 fica no canto mais perto do slot do micro-SD; ímpares numa fileira,
pares na outra.

**Os três ficam na mesma fileira, a dos pares**, nos furos mais fáceis de contar.

| Fio do SG90 | Vai para | Pino físico |
|---|---|---|
| Vermelho (+5 V) | 5 V — **ver abaixo** | **2** |
| Marrom / preto (GND) | GND | **6** |
| Laranja / amarelo (sinal) | GPIO18 (BCM) | **12** |

```
 ímpar                      par
 ─────────────────          ─────────────────
  1  3V3                     2  5V       <-- VERMELHO   (1o furo)
  3  GPIO2  (SDA, I2C)       4  5V
  5  GPIO3  (SCL, I2C)       6  GND      <-- MARROM     (3o furo)
  7  GPIO4  (sensor)         8  GPIO14
  9  GND                    10  GPIO15
 11  GPIO17 (sensor)        12  GPIO18   <-- LARANJA    (6o furo, sinal)
 13  GPIO27 (sensor)        14  GND
```

Contando da ponta da fileira par, são o **1º, o 3º e o 6º** furo.

- **Sinal no 12.** É obrigatório. Os pinos de PWM por hardware são BCM 12, 13, 18 e 19 — furos 32,
  33, 12 e 35 — e o 12 é o único perto dos 5 V.
- **5 V no 2 e terra no 6.** Aqui a escolha é livre: todos os pinos de 5 V do header são o mesmo
  trilho, e todos os de terra são o mesmo plano. O 2 e o 6 foram escolhidos por serem fáceis de
  contar, não por diferença elétrica. O 4 serve de 5 V igual, e o 14 de terra igual.

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

## Ligação da chave

| Terminal da chave | Vai para | Pino físico |
|---|---|---|
| Um deles | GND | **14** |
| O outro | BCM23 | **16** |

**Tanto faz qual vai em qual** — chave é contato puro, não tem polaridade. Os dois furos são
vizinhos, na mesma fileira dos pares, e não colidem com os três do servo (2, 6 e 12).

**Não precisa de resistor.** O programa liga o *pull-up interno* da Raspberry.

### Qual borda é a queda

Depende de como a chave foi montada na gaiola, e os dois arranjos existem:

| Arranjo | Alvo em pé | Alvo caído | Evento |
|---|---|---|---|
| **O nosso** (padrão) | chave pressionada, linha **baixa** | chave solta, linha **alta** | **subida** |
| O oposto (`--chave-solta-em-pe`) | chave solta, linha alta | chave pressionada, linha baixa | descida |

Na nossa gaiola o alvo em pé segura a alavanca, e **a queda solta a chave**. Por isso o padrão é
disparar na subida.

O gatilho é a **borda**, não o nível: enquanto o alvo estiver caído a linha fica parada no novo
nível, e isso é o estado normal de um alvo derrubado, não um evento novo.

Ao iniciar, o programa lê a linha e diz em que nível ela está. Se não casar com o arranjo
configurado, ele avisa e diz qual opção usar — então não é preciso adivinhar.

BCM23 está no banco de 16 entradas de sensores do projeto
([`docs/05-pinout.md`](../../docs/05-pinout.md), seção 5.1), então é um pino já previsto para isso.

### Repique

A `KW11-3Z-3` é de ação rápida: os contatos batem e repicam por alguns milissegundos antes de
assentar. Sem filtro, uma única queda do alvo vira três ou quatro eventos, e o servo dispara várias
vezes seguidas.

O programa pede ao kernel um *debounce* de 20 ms na própria linha. Se o driver não suportar, ele
repete o pedido sem isso e usa um filtro em software equivalente — e diz qual dos dois ficou em uso.
O filtro em software roda sempre de qualquer forma, porque a mesa treme e o alvo pode bater duas
vezes no engate.

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
```

Gera os dois: `drop_target` na raiz e `bancada/servo_sobe`.

Precisa de `sudo` porque `/sys/class/pwm` pertence ao root. Para dispensar, uma regra de udev:

```bash
sudo tee /etc/udev/rules.d/99-pwm.rules <<'EOF'
SUBSYSTEM=="pwm", ACTION=="add", RUN+="/bin/chgrp -R gpio /sys%p", RUN+="/bin/chmod -R g=u /sys%p"
EOF
sudo udevadm control --reload
```

## Uso

No jogo:

```bash
sudo ./drop_target
```

**Ao iniciar ele arma o mecanismo.** Lê a chave e, se o alvo estiver caído, levanta antes de passar
a escutar:

```
arranjo : alvo em pe deixa a chave PRESSIONADA, entao a queda e a SUBIDA da linha
linha agora: ALTO (chave aberta)
alvo esta caido. levantando antes de comecar.
  levanta 102.0 graus
  volta    51.0 graus
alvo em pe
```

Isso não é cosmético: o gatilho é a **borda**, e um alvo parado em baixo não gera borda nenhuma. Sem
armar, um jogo que terminou com o alvo derrubado começaria o próximo com um alvo morto, que nunca
mais subiria.

Com o alvo já em pé, ele só confirma:

```
linha agora: BAIXO (chave fechada)
alvo ja esta em pe
```

Se o braço subir e a chave **não** mudar de estado, ele avisa e lista as três causas possíveis: o
alvo não travou no engate, a chave não está sendo acionada por ele, ou o arranjo está trocado. Quando o alvo cai: espera 2 s para a bola sair da frente, levanta
o alvo até travar no engate, e recolhe o braço. Depois volta a escutar. `Ctrl+C` para sair.

Na bancada, para calibrar ou testar o servo sozinho:

```bash
sudo ./bancada/servo_sobe              # ciclo completo
sudo ./bancada/servo_sobe --calibra    # move a cada angulo digitado
sudo ./bancada/servo_sobe --angulo 70  # vai a um angulo so, sem voltar
sudo ./bancada/servo_sobe --help
```

O ciclo é **repouso → levanta → volta ao repouso**. A volta não é enfeite: com o braço levantado ele
fica no caminho do alvo, e a bola não consegue derrubá-lo de novo.

Entre levantar e recolher há uma pausa de 500 ms (`TEMPO_NO_TOPO_MS`), para o alvo assentar no
engate antes de perder o apoio do braço. **Se o alvo cair sozinho logo depois de levantar, é esse
número que precisa aumentar** — não o ângulo.

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
sudo ./bancada/servo_sobe --calibra
```

Digite um ângulo e Enter: o braço vai e **fica**, segurando a posição, para você ver onde ele
parou. `r` volta ao repouso, `l` vai ao levanta, `q` sai.

Com o alvo montado na gaiola:

1. Comece em `90` e veja para que lado o braço aponta.
2. Vá digitando números até ele ficar **logo abaixo do alvo caído**, sem encostar. É o **repouso**.
3. Suba até o **alvo levantar por completo**. É o **levanta**.
4. Teste o par: `sudo ./bancada/servo_sobe --repouso X --levanta Y`.
5. Fixe em `ANGULO_REPOUSO` e `ANGULO_LEVANTA` nos **dois** arquivos —
   [`drop_target.c`](drop_target.c) e [`bancada/servo_sobe.c`](bancada/servo_sobe.c) — e rode
   `make`.

Os dois são independentes: o levanta pode ser **menor** que o repouso, se a corneta ficou apontando
para o outro lado.

O programa imprime o curso resultante e avisa se ele fugir muito dos 43° medidos. Não impede nada —
é para pegar corneta encaixada no dente errado do eixo estriado, que é estriado e só aceita poucas
posições. Nesse caso remontar um dente é melhor que compensar no software, porque o curso errado
custa torque justamente no fim, onde o alvo é mais pesado de levantar.

**Não force o servo contra o alvo travado.** Ele não tem proteção de corrente e queima.

## Próximo passo

**Só existem dois canais de PWM por hardware na Raspberry**, e o pinball vai ter **três** drop
targets. Os três servos não cabem nesse caminho. As saídas são:

- um **PCA9685** no barramento I²C: 16 canais de servo, gerados fora da Pi, e o projeto já tem I²C
  para os PCF8574;
- ou voltar os outros dois para PWM por software, aceitando o tremor.

O PCA9685 é o caminho normal em pinball caseiro, e vale decidir isso antes de imprimir os outros
dois conjuntos.

Além disso: a simulação mecânica previa 75° de curso e a peça real pediu 43. Vale conferir a
geometria do braço no `.scad` antes de repetir o conjunto três vezes.
