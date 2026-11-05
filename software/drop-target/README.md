# Drop target — software

Código de acionamento do drop target na Raspberry Pi 4.

| Arquivo | O que faz |
|---|---|
| [`servo_sobe.py`](servo_sobe.py) | Teste de bancada: leva o braço do servo para repouso e depois para a posição que levanta o alvo |

## Ligação

| Fio do SG90 | Vai para | Pino físico |
|---|---|---|
| Laranja / amarelo (sinal) | GPIO18 | 12 |
| Marrom / preto (GND) | GND | 6 |
| Vermelho (+5 V) | 5 V — **ver abaixo** | 2 ou 4 |

GPIO18 foi escolhido por dois motivos: é PWM por hardware na Pi 4, e já aparece no esquemático do
projeto sem função atribuída — não está no banco de 16 entradas de sensores
([`docs/05-pinout.md`](../../docs/05-pinout.md), seção 5.1).

### Alimentação

O SG90 puxa ~250 mA girando e passa de 700 mA se travar. Esse pico derruba o trilho de 5 V e a
Raspberry reinicia. **No pinball montado, alimente o servo pelos 5 V externos** (BAT2, o mesmo
trilho dos L293D) e ligue os terras em comum — sem terra comum o servo não enxerga o sinal.

Para um teste de bancada com um servo só, o pino 5 V da própria Pi costuma aguentar.

## Instalação

```bash
sudo apt install pigpio python3-pigpio python3-gpiozero
sudo systemctl enable --now pigpiod
```

O `pigpio` não é obrigatório: sem ele o script roda no PWM por software da própria biblioteca e
avisa. Mas o PWM por software é gerado pelo sistema operacional e treme quando a Pi está ocupada —
no servo isso vira zumbido e tremor. O `pigpio` gera o pulso por DMA e sai estável.

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
