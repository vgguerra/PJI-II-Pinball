#!/usr/bin/env python3
"""
Levantamento do mapeamento sensor para GPIO.

Resolve a pendência P7: o esquemático não permite determinar qual sensor está
ligado a qual GPIO, porque os fios se cruzam sem rótulo de rede. Este programa
descobre isso na bancada.

São dois modos.

    python3 levantar_entradas.py monitor
        Fica imprimindo toda mudança de estado. Útil para conferir a fiação e
        para achar sensor com mau contato.

    python3 levantar_entradas.py identificar
        Pede para acionar um sensor por vez, na ordem da lista, e registra qual
        GPIO respondeu. No fim grava mapeamento.csv, pronto para preencher a
        tabela da seção 5.2 da documentação.

Depende de RPi.GPIO e roda na Raspberry Pi. Sem a biblioteca instalada:

    pip3 install RPi.GPIO
"""

import csv
import sys
import time

try:
    import RPi.GPIO as GPIO
except ImportError:
    print("RPi.GPIO não encontrado. Este programa roda na Raspberry Pi.")
    print("Instale com: pip3 install RPi.GPIO")
    sys.exit(1)


# Os 16 GPIOs configurados como entrada, iguais aos de src/components/Raspberry.py.
# A ordem aqui é numérica para facilitar a leitura da saída.
ENTRADAS = [4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27]

# Número do pino físico no conector de 40 vias, para conferir com o multímetro.
PINO_FISICO = {
    4: 7, 5: 29, 6: 31, 12: 32, 13: 33, 16: 36, 17: 11, 19: 35,
    20: 38, 21: 40, 22: 15, 23: 16, 24: 18, 25: 22, 26: 37, 27: 13,
}

# Os 13 sensores do esquemático. A ordem é a da identificação.
SENSORES = [
    ("SI01", "Sensor indutivo"),
    ("SI02", "Sensor indutivo"),
    ("SI03", "Sensor indutivo"),
    ("CF01", "Fim de curso"),
    ("CF02", "Fim de curso"),
    ("CF03", "Fim de curso"),
    ("CF04", "Fim de curso"),
    ("CF05", "Fim de curso"),
    ("CF06", "Fim de curso"),
    ("CF07", "Fim de curso"),
    ("CF08", "Fim de curso"),
    ("CF09", "Fim de curso"),
    ("CF10", "Fim de curso"),
]

INTERVALO = 0.005  # 5 ms entre varreduras


def configurar():
    """Configura os pinos uma única vez, no início.

    Reconfigurar a cada leitura, como o scan() atual faz, solta o pull-up
    interno por um instante e pode gerar leitura falsa.
    """
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    for pino in ENTRADAS:
        GPIO.setup(pino, GPIO.IN, pull_up_down=GPIO.PUD_UP)


def ler():
    return {pino: GPIO.input(pino) for pino in ENTRADAS}


def descrever(pino, valor):
    estado = "ACIONADO" if valor == 0 else "liberado"
    return f"GPIO{pino:<2d} (pino físico {PINO_FISICO[pino]:>2d}): {estado}"


def monitor():
    """Imprime toda mudança de estado, indefinidamente."""
    print("Monitorando as 16 entradas. Ctrl+C para sair.\n")
    anterior = ler()

    em_repouso = [p for p, v in anterior.items() if v == 1]
    acionados = [p for p, v in anterior.items() if v == 0]
    print(f"Em repouso ({len(em_repouso)}): {em_repouso}")
    if acionados:
        print(f"Já acionados ({len(acionados)}): {acionados}")
        print("Entrada em nível baixo no repouso indica sensor preso, fio em")
        print("curto com o terra, ou pull-up ausente.")
    print()

    while True:
        atual = ler()
        for pino, valor in atual.items():
            if valor != anterior[pino]:
                print(descrever(pino, valor))
        anterior = atual
        time.sleep(INTERVALO)


def esperar_acionamento(referencia, tipo, base):
    """Espera um GPIO cair para nível baixo e devolve qual foi.

    Devolve None se o operador pular o sensor com Enter.
    """
    print(f"\n{referencia} ({tipo})")
    print("  Acione o sensor. Enter pula, Ctrl+C encerra.")

    while True:
        atual = ler()
        for pino in ENTRADAS:
            if atual[pino] == 0 and base[pino] == 1:
                print(f"  Respondeu: GPIO{pino}, pino físico {PINO_FISICO[pino]}")
                print("  Solte o sensor.")
                while ler()[pino] == 0:
                    time.sleep(INTERVALO)
                return pino

        # Enter pula o sensor atual, sem travar a varredura.
        import select
        if select.select([sys.stdin], [], [], 0)[0]:
            sys.stdin.readline()
            print("  Pulado.")
            return None

        time.sleep(INTERVALO)


def identificar():
    """Percorre a lista de sensores e registra qual GPIO responde a cada um."""
    print("Identificação de sensores.\n")
    print("Acione um sensor por vez, quando for pedido. No caso dos sensores")
    print("indutivos, aproxime a bola ou outra peça de metal da face.\n")

    base = ler()
    presos = [p for p, v in base.items() if v == 0]
    if presos:
        print(f"Atenção: já estão em nível baixo: {presos}")
        print("Esses pinos não serão detectados. Verifique antes de continuar.\n")

    mapeamento = {}
    usados = set()

    for referencia, tipo in SENSORES:
        pino = esperar_acionamento(referencia, tipo, base)
        if pino is None:
            mapeamento[referencia] = (None, tipo)
            continue
        if pino in usados:
            anterior = [r for r, (p, _) in mapeamento.items() if p == pino][0]
            print(f"  Atenção: GPIO{pino} já foi atribuído a {anterior}.")
            print("  Dois sensores no mesmo pino indica erro de fiação.")
        usados.add(pino)
        mapeamento[referencia] = (pino, tipo)

    resumo(mapeamento)
    gravar(mapeamento)


def resumo(mapeamento):
    print("\n" + "=" * 52)
    print("Resultado")
    print("=" * 52)
    print(f"{'Sensor':<8} {'Tipo':<17} {'GPIO':<7} {'Pino físico'}")
    print("-" * 52)
    for referencia, (pino, tipo) in mapeamento.items():
        if pino is None:
            print(f"{referencia:<8} {tipo:<17} {'-':<7} {'-'}")
        else:
            print(f"{referencia:<8} {tipo:<17} {'GPIO' + str(pino):<7} {PINO_FISICO[pino]}")

    atribuidos = {p for p, _ in mapeamento.values() if p is not None}
    livres = sorted(set(ENTRADAS) - atribuidos)
    print("-" * 52)
    print(f"Identificados: {len(atribuidos)} de {len(SENSORES)} sensores")
    print(f"GPIOs sem sensor: {livres}")
    if len(livres) != len(ENTRADAS) - len(SENSORES):
        print("O esperado eram 3 GPIOs de reserva. Divergência indica sensor")
        print("não identificado ou fiação diferente do esquemático.")


def gravar(mapeamento, caminho="mapeamento.csv"):
    with open(caminho, "w", newline="", encoding="utf-8") as f:
        escritor = csv.writer(f)
        escritor.writerow(["Sensor", "Tipo", "GPIO", "Pino fisico", "Funcao no jogo"])
        for referencia, (pino, tipo) in mapeamento.items():
            escritor.writerow([
                referencia,
                tipo,
                f"GPIO{pino}" if pino is not None else "",
                PINO_FISICO[pino] if pino is not None else "",
                "",  # preencher na montagem
            ])
    print(f"\nGravado em {caminho}.")
    print("Falta preencher a coluna de função no jogo, que só se define olhando")
    print("a mesa: qual é alvo, qual é botão de flipper, qual é o dreno.")


def main():
    modo = sys.argv[1] if len(sys.argv) > 1 else "monitor"
    if modo not in ("monitor", "identificar"):
        print(__doc__)
        sys.exit(1)

    configurar()
    try:
        monitor() if modo == "monitor" else identificar()
    except KeyboardInterrupt:
        print("\nEncerrado.")
    finally:
        GPIO.cleanup()


if __name__ == "__main__":
    main()
