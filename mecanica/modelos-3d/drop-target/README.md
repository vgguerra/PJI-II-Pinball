# Drop target paramétrico

Primeira versão de um mecanismo de drop target com **três alvos independentes** em cada banco
de **120 × 60 mm**. A montagem principal mostra dois bancos nas posições previstas na mesa.
Todas as medidas estão em milímetros e podem ser alteradas em [`parameters.scad`](parameters.scad).

O arquivo principal é [`drop-target.scad`](drop-target.scad). Ele reúne:

- [`target.scad`](target.scad): face, haste, ressalto de retenção e sapata de rearme;
- [`cage.scad`](cage.scad): flange e guias instaladas sob o playfield;
- [`servo_stick.scad`](servo_stick.scad): braço de rearme acionado pelo servo;
- [`base.scad`](base.scad): base inferior, colunas e suporte do microservo.

## Envelope inicial

| Medida | Valor aproximado |
|---|---:|
| Banco completo | 120 × 60 mm |
| Face de cada alvo | aproximadamente 37,3 × 60 × 6 mm |
| Espaço entre alvos | 4 mm |
| Curso vertical | 64 mm |
| Abertura por alvo no playfield | aproximadamente 38,3 × 9 mm |
| Espaçamento entre os centros dos bancos | 210 mm |
| Inclinação de cada conjunto | ±15° |
| Largura visível dos dois bancos | aproximadamente 330 mm |
| Envelope mecânico do par | 396 × 98 mm |
| Altura visível acima do playfield | 63 mm |
| Profundidade abaixo do playfield | 135 mm |
| Altura total com os alvos elevados | 198 mm |
| Espessura considerada para o playfield | 10 mm |

Em `drop-target.scad`, use `view_mode` para alternar entre a montagem, as peças isoladas e a vista
explodida. `target_state` aceita `"elevado"`, `"baixado"` ou `"animado"`; para o último, ative
**View > Animate** no OpenSCAD.

O servo e o microswitch exibidos na montagem são apenas envelopes de referência e não são peças para
impressão. Antes da fabricação, é necessário conferir o servo real, a espessura final da mesa, o
curso necessário e o mecanismo de retenção. Para visualizar os alvos em estados diferentes, defina
`target_state = "individual"` no arquivo principal e altere o vetor `target_states` em
`parameters.scad`. Os STL em `references/` pertencem ao projeto de
[Chris Mitchell](https://www.thingiverse.com/thing:2772610) e foram mantidos somente como referência.

As três aberturas menores preservam duas pontes de material entre os alvos, mas a região ainda precisará
de reforço inferior. O torque do microservo deve ser testado com as peças impressas. Este desenho serve
para medição e prototipagem, ainda não como peça final validada para fabricação.
