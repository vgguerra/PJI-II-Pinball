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
| Furo do parafuso | 2,38 mm (3/32") | 3,30 mm, com rosca M4 |
| Assento para o macho | não tem | 7,00 × 0,60 mm |

## Medidas do nosso arquivo

| Item | Medida |
|---|---:|
| Diâmetro da haste | 5,70 mm |
| Folga diametral | 0,30 mm |
| Encaixe da haste | 6,00 mm × 34,00 mm |
| Chanfro de entrada | 14,00 mm, 4,00 mm de profundidade |
| Furo do parafuso | 3,30 mm, até dentro do encaixe |
| Assento plano no topo | 7,00 × 0,60 mm |
| Centro do furo do parafuso | 6,35 mm da face de entrada |
| Rosca disponível | 8,61 mm (~12 fios em M4) |
| Do assento até a haste | 8,76 mm |
| Parafuso | M4 sem cabeça, 10 mm ou mais |
| Volume | 25,0 cm³ |

O furo antigo de 13,21 mm é tapado e o encaixe novo de 6,00 mm é aberto no lugar, com 34 mm de
profundidade. O chanfro de entrada de 14 mm guia a haste e, de quebra, tira da face frontal a borda
do furo original, que era o que sujava a malha na boca do encaixe.

## Como a haste fica presa

O furo do parafuso desce do topo da base e **entra no encaixe da haste**: a ponta do parafuso aperta
a haste contra o fundo do furo, e é esse aperto que prende as duas peças. Na referência o furinho de
3/32" já fazia esse caminho; aqui ele foi aberto para 3,30 mm, que é a medida de furo para abrir
rosca M4 com macho.

Sobram 8,61 mm de material para a rosca, o que dá cerca de 12 fios com o passo de 0,7 mm do M4 —
folgado para segurar. Do fundo do assento até a superfície da haste são 8,76 mm, então o parafuso
precisa ser **mais longo que isso**: um M4 sem cabeça de 10 mm entra 1,2 mm no encaixe e encosta na
haste com sobra. Um de 8 mm não chega a tocar.

O assento plano de 7 mm no topo existe só para o macho (ou a broca) entrar esquadrejado: a base é
cilíndrica e a ferramenta escorregaria na curvatura.

**Recomendação:** lime um plano na haste no ponto onde o parafuso encosta. Parafuso de pressão
apertando contra superfície cilíndrica e lisa escorrega com o uso, e o plunger leva tranco axial
repetido. Com o plano, o parafuso assenta e o conjunto não gira nem desliza.

Se preferir rosca de metal, troque `screw_diameter` para 6,0 mm e use insert térmico M4 — cabe nos
8,6 mm de parede. Para parafuso soberbo, que rosca sozinho no plástico, use 3,6 mm.

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
