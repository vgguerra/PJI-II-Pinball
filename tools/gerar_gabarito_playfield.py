#!/usr/bin/env python3
"""
Gera um gabarito do playfield em escala 1:1, no formato SVG.

O arquivo abre no Inkscape com as dimensões físicas corretas, então dá para
imprimir em tamanho real (em folhas A4 lado a lado) e conferir sobre a mesa
antes de furar qualquer coisa.

O desenho vem em camadas separadas, para que a camada de proposta possa ser
desenhada por cima sem mexer nas referências:

    grade        quadriculado de 10 mm, e linhas de 50 mm mais fortes
    zonas        divisão em terços, superior, média e inferior
    geometria    flippers em repouso, vão, dreno e lane do injetor
    cotas        medidas escritas
    proposta     camada vazia, para vocês desenharem

Uso:

    python3 gerar_gabarito_playfield.py
    python3 gerar_gabarito_playfield.py --largura 410 --comprimento 860

As medidas padrão são as da caixa, 450 x 900 mm. Se a área interna útil do
playfield for menor, por causa das paredes do gabinete, passe as medidas
internas nos argumentos.
"""

import argparse
import math

# Geometria dos flippers, calculada para uma mesa de 900 x 450 mm.
# Ver seção 13.10 da documentação para a origem de cada número.
FLIPPER_MM = 65          # comprimento, escalado dos 76 mm comerciais
ANGULO_REPOUSO = 30      # graus abaixo da horizontal
VAO_MM = 40              # entre as pontas, cerca de 1,5 diâmetro de bola
EIXO_AO_FUNDO = 90       # do eixo do flipper à borda inferior
LANE_MM = 30             # largura da lane do injetor
BOLA_MM = 27


def gerar(largura, comprimento):
    proj = FLIPPER_MM * math.cos(math.radians(ANGULO_REPOUSO))
    alt = FLIPPER_MM * math.sin(math.radians(ANGULO_REPOUSO))
    entre_eixos = VAO_MM + 2 * proj
    cx = largura / 2
    y_eixo = comprimento - EIXO_AO_FUNDO
    xe, xd = cx - entre_eixos / 2, cx + entre_eixos / 2

    p = []
    a = p.append

    a(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"')
    a(f'     width="{largura}mm" height="{comprimento}mm" viewBox="0 0 {largura} {comprimento}">')
    a(f'  <title>Gabarito do playfield {largura} x {comprimento} mm</title>')
    a('  <defs><style>')
    a('    .fina{stroke:#d8d8d8;stroke-width:.2;fill:none}')
    a('    .media{stroke:#b0b0b0;stroke-width:.4;fill:none}')
    a('    .borda{stroke:#000;stroke-width:1.2;fill:none}')
    a('    .zona{stroke:#8fbcd4;stroke-width:.6;stroke-dasharray:6 4;fill:none}')
    a('    .elem{stroke:#c0392b;stroke-width:1;fill:none}')
    # a pá do flipper tem cerca de 12 mm de largura, desenhada com traço grosso
    a('    .flipper{stroke:#c0392b;stroke-width:12;stroke-linecap:round;stroke-opacity:.35;fill:none}')
    a('    .cota{stroke:#2c7a3f;stroke-width:.5;fill:none}')
    a('    text{font-family:sans-serif;fill:#333}')
    a('    .t{font-size:7px} .ts{font-size:5px} .tz{font-size:9px;fill:#5b8ba6}')
    a('  </style></defs>')

    # grade
    a('  <g inkscape:groupmode="layer" inkscape:label="grade">')
    for x in range(0, int(largura) + 1, 10):
        a(f'    <line class="{"media" if x%50==0 else "fina"}" x1="{x}" y1="0" x2="{x}" y2="{comprimento}"/>')
    for y in range(0, int(comprimento) + 1, 10):
        a(f'    <line class="{"media" if y%50==0 else "fina"}" x1="0" y1="{y}" x2="{largura}" y2="{y}"/>')
    a('  </g>')

    # zonas
    a('  <g inkscape:groupmode="layer" inkscape:label="zonas">')
    t1, t2 = comprimento / 3, 2 * comprimento / 3
    a(f'    <line class="zona" x1="0" y1="{t1:.0f}" x2="{largura}" y2="{t1:.0f}"/>')
    a(f'    <line class="zona" x1="0" y1="{t2:.0f}" x2="{largura}" y2="{t2:.0f}"/>')
    a(f'    <text class="tz" x="6" y="{t1/2:.0f}">zona superior, bumpers e alvos altos</text>')
    a(f'    <text class="tz" x="6" y="{(t1+t2)/2:.0f}">zona média, alvos e caminhos</text>')
    a(f'    <text class="tz" x="6" y="{(t2+comprimento)/2:.0f}">zona inferior, flippers e dreno</text>')
    a('  </g>')

    # geometria
    a('  <g inkscape:groupmode="layer" inkscape:label="geometria">')
    a(f'    <rect class="borda" x="0" y="0" width="{largura}" height="{comprimento}"/>')
    # lane do injetor, à direita
    a(f'    <line class="elem" x1="{largura-LANE_MM}" y1="0" x2="{largura-LANE_MM}" y2="{comprimento}"/>')
    a(f'    <text class="ts" x="{largura-LANE_MM+3}" y="{comprimento-20}" transform="rotate(-90 {largura-LANE_MM+3} {comprimento-20})">lane do injetor, {LANE_MM} mm</text>')
    # flippers em repouso, apontando para baixo e para dentro
    a(f'    <line class="flipper" x1="{xe:.1f}" y1="{y_eixo:.1f}" x2="{xe+proj:.1f}" y2="{y_eixo+alt:.1f}"/>')
    a(f'    <line class="flipper" x1="{xd:.1f}" y1="{y_eixo:.1f}" x2="{xd-proj:.1f}" y2="{y_eixo+alt:.1f}"/>')
    for x in (xe, xd):
        a(f'    <circle class="elem" cx="{x:.1f}" cy="{y_eixo:.1f}" r="3"/>')
    # vão entre as pontas
    a(f'    <line class="cota" x1="{xe+proj:.1f}" y1="{y_eixo+alt:.1f}" x2="{xd-proj:.1f}" y2="{y_eixo+alt:.1f}"/>')
    a(f'    <text class="ts" x="{cx:.0f}" y="{y_eixo+alt-4:.0f}" text-anchor="middle">vão {VAO_MM} mm</text>')
    # bola em escala, para referência visual
    a(f'    <circle class="elem" cx="{cx:.0f}" cy="{y_eixo+alt+22:.0f}" r="{BOLA_MM/2}"/>')
    a(f'    <text class="ts" x="{cx+BOLA_MM:.0f}" y="{y_eixo+alt+24:.0f}">bola {BOLA_MM} mm</text>')
    # dreno
    a(f'    <rect class="elem" x="{cx-20:.0f}" y="{comprimento-18}" width="40" height="18"/>')
    a(f'    <text class="ts" x="{cx:.0f}" y="{comprimento-6}" text-anchor="middle">dreno</text>')
    a('  </g>')

    # cotas
    a('  <g inkscape:groupmode="layer" inkscape:label="cotas">')
    a(f'    <text class="t" x="4" y="12">{largura} x {comprimento} mm, escala 1:1, grade de 10 mm</text>')
    a(f'    <text class="ts" x="4" y="22">flipper {FLIPPER_MM} mm a {ANGULO_REPOUSO} graus, eixos a {entre_eixos:.0f} mm</text>')
    a(f'    <text class="ts" x="4" y="30">eixo do flipper a {EIXO_AO_FUNDO} mm do fundo</text>')
    a('  </g>')

    a('  <g inkscape:groupmode="layer" inkscape:label="proposta"></g>')
    a('</svg>')
    return "\n".join(p)


def main():
    ap = argparse.ArgumentParser(description="Gera gabarito do playfield em escala 1:1")
    ap.add_argument("--largura", type=float, default=450, help="largura em mm (padrão 450)")
    ap.add_argument("--comprimento", type=float, default=900, help="comprimento em mm (padrão 900)")
    ap.add_argument("--saida", default="gabarito-playfield.svg")
    args = ap.parse_args()

    svg = gerar(args.largura, args.comprimento)
    with open(args.saida, "w", encoding="utf-8") as f:
        f.write(svg)

    print(f"Gerado {args.saida}, {args.largura:.0f} x {args.comprimento:.0f} mm.")
    print("Abra no Inkscape. A camada 'proposta' está vazia, é onde desenhar.")
    print("Para imprimir em tamanho real: Arquivo, Imprimir, sem ajuste de escala.")


if __name__ == "__main__":
    main()
