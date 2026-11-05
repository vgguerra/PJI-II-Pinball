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
    Sinal do servo (fio laranja ou amarelo)  ->  GPIO18, pino físico 12
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

PWM — por que pigpio
    O PWM por software da RPi.GPIO é gerado pelo sistema operacional e treme
    quando a Pi está ocupada. Num servo isso vira zumbido, tremor e consumo à
    toa. O pigpio gera o pulso por DMA, então ele sai estável mesmo com a Pi
    carregada. O script usa pigpio quando o daemon está no ar e avisa quando
    cai no PWM por software.

        sudo apt install pigpio python3-pigpio python3-gpiozero
        sudo systemctl enable --now pigpiod
"""

from __future__ import annotations

import argparse
import sys
import time

from gpiozero import AngularServo

PINO_SERVO = 18

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
    """Monta o servo, preferindo o pigpio e avisando se cair no PWM software."""
    fabrica = None
    try:
        from gpiozero.pins.pigpio import PiGPIOFactory

        fabrica = PiGPIOFactory()
    except Exception as erro:
        print(
            f"aviso: pigpio indisponivel ({erro.__class__.__name__}), "
            "usando PWM por software — o servo pode tremer e zumbir.\n"
            "       sudo systemctl enable --now pigpiod",
            file=sys.stderr,
        )

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
    print(f"servo no GPIO{PINO_SERVO}")

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
