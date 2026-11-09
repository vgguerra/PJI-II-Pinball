#!/usr/bin/env python3
"""Primeiro acionamento do servo do drop target: levantar o alvo.

Este é o teste de bancada mais simples possível do mecanismo. Ele não lê o
micro switch nem fecha o ciclo — só manda o braço do servo para a posição de
repouso, espera, e depois para a posição que levanta o alvo, para você ver o
movimento e conferir se os ângulos batem com a mecânica.

    python3 servo_sobe.py                  # usa os ângulos padrão
    python3 servo_sobe.py --angulo 90      # vai direto para um ângulo, e fica
    python3 servo_sobe.py --repouso 25 --levanta 100

MONTAGEM
    Sinal do servo (fio laranja ou amarelo)  ->  BCM 18 = furo físico 12
    Terra  (fio marrom ou preto)             ->  qualquer GND, ex. pino 6
    +5 V   (fio vermelho)                    ->  ver o aviso de alimentação

GPIO18 foi escolhido porque é um dos pinos de PWM por hardware da Pi 4 e
porque ele já aparece no esquemático do projeto sem função atribuída: não está
no banco de 16 entradas de sensores (docs/05-pinout.md, seção 5.1).

ALIMENTAÇÃO — leia antes de ligar
    O SG90 puxa cerca de 250 mA girando e passa de 700 mA se travar. Esse pico
    derruba a tensão do trilho de 5 V, e a Pi reinicia no meio do jogo. Para o
    pinball montado, alimente o servo pelos 5 V externos (BAT2, o mesmo trilho
    dos L293D) e ligue os terras em comum — sem o terra comum o servo não
    entende o sinal. Para um teste rápido de um servo só, na bancada, o pino 5 V
    da própria Pi costuma aguentar.

PWM — qualidade do pulso
    O servo lê a largura do pulso, então tremor no pulso vira tremor no braço.
    O script funciona com qualquer backend do gpiozero e diz na saída qual
    está em uso, em ordem de preferência:

      pigpio   pulso gerado por DMA, imune à carga da Pi. É o melhor, mas o
               pacote nem sempre existe no repositório da sua versão do
               Raspberry Pi OS, e ele não suporta a Pi 5. Se estiver
               disponível: sudo apt install pigpio python3-pigpio
               e depois sudo systemctl enable --now pigpiod
      lgpio    padrão do Raspberry Pi OS atual. Pulso gerado em espaço de
               usuário: treme um pouco com a Pi carregada, mas serve bem para
               este mecanismo, que só move o braço de vez em quando.

    Se o braço ficar zumbindo parado, o problema some sozinho: o script solta
    o servo no fim, o que corta o trem de pulsos.
"""

from __future__ import annotations

import argparse
import sys
import time

from gpiozero import AngularServo

# NUMERAÇÃO — leia antes de mexer nestes dois números.
#
# O gpiozero fala BCM, que é a numeração do chip, NÃO o número do furo no
# conector de 40 vias. Os dois existem e são diferentes:
#
#     BCM 18  ==  furo físico 12   <- é aqui que o fio laranja entra
#     BCM 12  ==  furo físico 32   <- outro lugar da placa
#
# Trocar o 18 abaixo pelo 12 do furo é o erro clássico: o fio continua certo,
# o programa passa a acionar outro pino, e o servo não mexe sem dar erro
# nenhum. Se precisar mudar de pino, mude os DOIS números juntos.
PINO_SERVO = 18          # BCM
PINO_FISICO = 12         # furo no conector, só para a mensagem na tela

# Curso tirado da simulação mecânica, em
# mecanica/modelos-3d/drop-target/simulation/drop-target-simulation.scad:
# arm_rest_angle = -35 e arm_lift_angle = -110, ou seja 75 graus entre as duas
# posições. O que a simulação NÃO decide é onde esses 75 graus caem na escala
# do servo: isso depende de como a corneta entrou no eixo na hora de montar.
# Por isso os valores abaixo são um ponto de partida no meio do curso do SG90,
# para calibrar com --angulo e depois fixar aqui.
CURSO_DA_SIMULACAO = 75
ANGULO_REPOUSO = 30
ANGULO_LEVANTA = ANGULO_REPOUSO + CURSO_DA_SIMULACAO

# O SG90 responde a pulsos de 500 a 2400 us. O padrão do gpiozero é 1000 a
# 2000, que num SG90 entrega só a metade do curso — é o tropeço clássico de
# quem acha que o servo "não gira tudo". Fico 100 us dentro das pontas para o
# braço não bater no batente interno e ficar forçando.
PULSO_MINIMO = 0.0006   # 600 us
PULSO_MAXIMO = 0.0023   # 2300 us
PERIODO = 0.020         # 50 Hz

TEMPO_DE_GIRO = 0.6     # o SG90 faz ~60 graus em 0,1 s sem carga; sobra folga


def abre_servo() -> AngularServo:
    """Monta o servo no melhor backend disponível e diz qual ficou em uso."""
    fabrica = None
    try:
        from gpiozero.pins.pigpio import PiGPIOFactory

        fabrica = PiGPIOFactory()
        print("PWM: pigpio (pulso por DMA, firme)")
    except Exception:
        # Sem pigpio o gpiozero escolhe sozinho — hoje o padrão é o lgpio.
        # Não é motivo de alarme: serve bem para mover o braço de vez em
        # quando. Só não é o ideal se você for deixar o servo segurando carga.
        #
        # Descobrir o nome do backend é só informação. Se isso falhar, não é
        # motivo para derrubar o programa: quem de fato abre o pino é o
        # AngularServo logo abaixo, e o erro dele é que interessa.
        try:
            from gpiozero import Device

            Device.ensure_pin_factory()
            nome = Device.pin_factory.__class__.__name__
        except Exception:
            nome = "padrao"
        print(f"PWM: {nome} (padrao do gpiozero; pode tremer sob carga da Pi)")

    return AngularServo(
        PINO_SERVO,
        min_angle=0,
        max_angle=180,
        min_pulse_width=PULSO_MINIMO,
        max_pulse_width=PULSO_MAXIMO,
        frame_width=PERIODO,
        pin_factory=fabrica,
    )


def vai_para(servo: AngularServo, angulo: float, rotulo: str) -> None:
    print(f"{rotulo:>12}: {angulo:5.1f} graus")
    servo.angle = angulo
    time.sleep(TEMPO_DE_GIRO)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--angulo", type=float,
                   help="vai direto para este angulo e para por ai, "
                        "para achar o repouso e o levanta na mao")
    p.add_argument("--repouso", type=float, default=ANGULO_REPOUSO,
                   help=f"angulo de repouso (padrao {ANGULO_REPOUSO})")
    p.add_argument("--levanta", type=float, default=ANGULO_LEVANTA,
                   help=f"angulo que levanta o alvo (padrao {ANGULO_LEVANTA})")
    p.add_argument("--segura", action="store_true",
                   help="mantem o pulso no fim, em vez de soltar o servo")
    args = p.parse_args()

    for nome, valor in (("repouso", args.repouso), ("levanta", args.levanta),
                        ("angulo", args.angulo)):
        if valor is not None and not 0 <= valor <= 180:
            p.error(f"--{nome} fora da faixa do SG90: {valor} nao esta entre 0 e 180")

    servo = abre_servo()
    print(f"servo em BCM{PINO_SERVO} = furo fisico {PINO_FISICO}")

    try:
        if args.angulo is not None:
            vai_para(servo, args.angulo, "angulo")
        else:
            vai_para(servo, args.repouso, "repouso")
            time.sleep(1.0)
            vai_para(servo, args.levanta, "levanta")

        if args.segura:
            print("segurando o pulso; Ctrl+C para sair")
            while True:
                time.sleep(1.0)

        # Soltar o servo corta o trem de pulsos. Sem isso ele fica corrigindo a
        # posição o tempo todo, zumbindo e esquentando à toa. O braço do drop
        # target não precisa de torque parado: quem segura o alvo levantado é a
        # própria mecânica.
        servo.detach()
        print("servo solto")
    except KeyboardInterrupt:
        print("\ninterrompido")
    finally:
        servo.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
