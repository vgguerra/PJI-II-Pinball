# Plunger handle

Handle do lançador de bolinhas do pinball, remodelado a partir de
[`ref/Pinball_Plunger_Handle_v5.stl`](ref/Pinball_Plunger_Handle_v5.stl).
A geometria segue a referência visual: base larga, pescoço estreito e esfera arredondada na ponta
para facilitar a puxada.

## Arquivos

- [`pinball-plunger-handle.scad`](pinball-plunger-handle.scad): cópia da referência com alterações internas;
- [`print/pinball-plunger-handle.stl`](print/pinball-plunger-handle.stl): arquivo pronto para fatiar;
- [`ref/Pinball_Plunger_Handle_v5.stl`](ref/Pinball_Plunger_Handle_v5.stl): referência original.

## Medidas principais

| Item | Medida |
|---|---:|
| Envelope aproximado | 31,75 × 54,0 × 31,75 mm |
| Diâmetro da haste | 5,7 mm |
| Diâmetro da entrada da haste | 12,7 mm |
| Diâmetro interno após a entrada | 6,0 mm |
| Folga diametral nominal | 0,3 mm |
| Profundidade do encaixe | 34,0 mm |
| Furo transversal na base para parafuso | 4,5 mm |
| Parafuso recomendado | M4 |
| Rebaixo da cabeça | 8,0 × 2,2 mm |

O corpo externo é importado diretamente do STL original. A única alteração estrutural é o furo
axial, ajustado para 6,0 mm de diâmetro e 34 mm de profundidade, para a haste de 5,7 mm. O furo
do parafuso fica na posição original da referência, com 4,5 mm de diâmetro e 7 mm de profundidade.
A folga de 0,3 mm é uma medida inicial para impressão FDM;
se o encaixe ficar apertado, aumentar `rod_clearance_diameter` para 6,2 mm.

O furo do parafuso atravessa a base perpendicularmente ao eixo da haste, como na referência. O
parafuso entra pelo lado com rebaixo. A posição do centro fica a 6,5 mm da face de entrada.

## Impressão

Imprimir com a abertura da haste voltada para cima, para evitar suporte dentro do furo. Recomenda-se
0,20 mm de camada, 4 paredes e pelo menos 30% de preenchimento. O STL foi gerado com malha de
0,30 mm e está em escala 1:1.

Para gerar o STL, abrir o `.scad` no OpenSCAD e usar **F6 → Exportar STL**. O arquivo importa a
referência diretamente, preservando a geometria externa original.
