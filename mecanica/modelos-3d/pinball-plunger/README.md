# Plunger handle

Handle do lançador de bolinhas do pinball. O corpo externo vem de
[`ref/Pinball_Plunger_Handle_v5.stl`](ref/Pinball_Plunger_Handle_v5.stl) sem nenhuma alteração; o que
mudou foi o interior, refeito para a haste e o parafuso que vamos usar.

## Arquivos

- [`pinball-plunger-handle.scad`](pinball-plunger-handle.scad): importa a referência e refaz o encaixe interno;
- [`print/pinball-plunger-handle.stl`](print/pinball-plunger-handle.stl): gerado a partir do `.scad`, pronto para fatiar;
- [`ref/Pinball_Plunger_Handle_v5.stl`](ref/Pinball_Plunger_Handle_v5.stl): referência original, não mexer.

## O que a referência tem por dentro

A referência é um desenho em polegadas e não serve para a nossa haste:

| Item | Referência | Nosso arquivo |
|---|---:|---:|
| Envelope | 31,75 × 53,97 × 31,75 mm | igual |
| Diâmetro externo da base | 25,40 mm (1") | igual |
| Furo axial | 13,21 mm (0,52") × 12,75 mm | 6,00 mm × 34,00 mm |
| Furo do parafuso | 2,38 mm (3/32") | 4,50 mm |
| Rebaixo da cabeça | não tem | 8,00 × 2,20 mm |

## Medidas do nosso arquivo

| Item | Medida |
|---|---:|
| Diâmetro da haste | 5,70 mm |
| Folga diametral | 0,30 mm |
| Encaixe da haste | 6,00 mm × 34,00 mm |
| Chanfro de entrada | 14,00 mm, 4,00 mm de profundidade |
| Furo do parafuso | 4,50 mm, passante até o encaixe |
| Rebaixo da cabeça | 8,00 × 2,20 mm |
| Centro do furo do parafuso | 6,35 mm da face de entrada |
| Parede entre o rebaixo e o encaixe | 6,85 mm |
| Volume | 24,9 cm³ |

O furo antigo de 13,21 mm é tapado e o encaixe novo de 6,00 mm é aberto no lugar, com 34 mm de
profundidade. O chanfro de entrada de 14 mm guia a haste e, de quebra, tira da face frontal a borda
do furo original, que era o que sujava a malha na boca do encaixe.

O furo do parafuso desce do topo da base e **entra no encaixe da haste** — é isso que faz o parafuso
encostar nela. Na referência o furinho de 3/32" já fazia isso; aqui ele foi aberto para 4,5 mm e
ganhou o rebaixo de 8 × 2,2 mm, que é a medida de uma cabeça abaulada M4. Como a base é cilíndrica,
o fundo do rebaixo é calculado a partir do ponto mais baixo dentro dele, senão a cabeça ficaria para
fora nas bordas.

**Ponto a confirmar antes de imprimir:** 4,5 mm é furo de passagem para M4, não de rosca. Do jeito
que está, o parafuso precisa roscar na haste, que teria de receber um furo com rosca M4. Se a ideia
for o parafuso travar direto no plástico, mude `screw_diameter` para 3,3 mm e passe macho M4, ou
para 3,6 mm se for parafuso soberbo.

## Impressão

Imprimir com a boca do encaixe voltada para cima, para não precisar de suporte dentro do furo.
0,20 mm de camada, 4 paredes e pelo menos 30% de preenchimento. A folga de 0,3 mm é um ponto de
partida para FDM; se a haste entrar apertada, aumente `rod_clearance` para 0,5 mm.

Para regerar o STL depois de mexer em alguma medida:

```bash
openscad --export-format binstl -o print/pinball-plunger-handle.stl pinball-plunger-handle.scad
```

O `.scad` importa a referência por caminho relativo, então rode o comando de dentro desta pasta.
A renderização leva uns 15 s porque a malha importada tem 22.922 triângulos.
