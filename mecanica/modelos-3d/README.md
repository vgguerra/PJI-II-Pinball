# Modelos 3D

Modelos em [OpenSCAD](https://openscad.org/) para os mecanismos do pinball. Todas as medidas estão
em milímetros e ficam no início de cada arquivo, ou num `parameters.scad` próprio, para serem
ajustadas antes de imprimir.

| Mecanismo | Pasta | Situação |
|---|---|---|
| Flipper | [`flipper`](flipper/) | versão 5, com os dois lados exportados |
| Drop target | [`drop-target`](drop-target/README.md) | peças convertidas dos STL de referência, com simulação do ciclo |
| Plunger handle | [`pinball-plunger`](pinball-plunger/README.md) | impresso e em ajuste de encaixe |

## Flipper

[`flipper/flipper-v5.scad`](flipper/flipper-v5.scad) é a versão atual e reúne o mecanismo completo de
90 mm: pá com canal para borracha, eixo sextavado de 8 mm, base com mancal e batentes, alavanca
inferior, guia frontal, haste de acionamento e botão.

O mesmo arquivo atende os dois lados da mesa. Em `lado_flipper`, `"esquerdo"` ou `"direito"` já
ajusta junto a distância lateral, o curso da haste e a posição da guia, que mudam entre os lados:

| | esquerdo | direito |
|---|---:|---:|
| Distância lateral | 95,0 mm | 127,0 mm |
| Curso da haste | 110,0 mm | 142,0 mm |

O arquivo abre na montagem. Para inspecionar ou exportar uma peça, altere `modo_visualizacao` para
`"base"`, `"alavanca"`, `"haste"`, `"guia_frontal"` ou `"botao"`. O modo `"mesa_impressao"` põe todas
as peças deitadas, na posição de impressão.

Os STL já exportados estão separados por lado em
[`flipper/export/lado_esquerdo`](flipper/export/lado_esquerdo/) e
[`flipper/export/lado_direito`](flipper/export/lado_direito/): `alavanca`, `base`, `botao`, `eixo`,
`flipper`, `guia_frontal` e `haste` em cada um.

A versão anterior continua em [`flipper/flipper-v4-esquerdo.scad`](flipper/flipper-v4-esquerdo.scad),
só do lado esquerdo.

## Drop target

O diretório [`drop-target`](drop-target/README.md) tem as três peças imprimíveis convertidas para
OpenSCAD a partir dos STL de referência, com a caixa envolvente idêntica à do original:

| Peça | Envelope |
|---|---:|
| Gaiola | 40 × 85 × 47,5 mm |
| Alvo | 38,4 × 80 × 12,5 mm |
| Braço do servo | 12 × 64,8 × 4 mm |

Os STL prontos para fatiar ficam em [`drop-target/print`](drop-target/print/README.md) e os originais
que serviram de referência em `drop-target/references`, junto com a foto do conjunto montado.

[`drop-target/simulation`](drop-target/simulation/README.md) monta um módulo completo, com servo
SG90, micro-switch e cordão, para conferir o ciclo antes de repetir o conjunto três vezes: a bola
derruba o alvo, o micro-switch abre, o servo recolhe o braço e o cordão levanta o alvo de volta.
O movimento roda em **View > Animate**.

## Plunger handle

O diretório [`pinball-plunger`](pinball-plunger/README.md) tem o pegador do lançador. O corpo externo
vem do STL de referência sem alteração; o interior foi refeito para a haste real de 6,1 mm e para um
parafuso M4 × 10 que trava a haste.

O furo do parafuso é cônico, de 4,20 mm na entrada a 3,80 mm no fundo: o parafuso começa a descer
solto e vai apertando conforme avança. Essa peça já foi impressa uma vez e as medidas atuais vieram
desse teste.

## Como usar

1. Abra o `.scad` do mecanismo no OpenSCAD.
2. `F5` para visualizar, `F6` para renderizar de verdade.
3. Onde houver animação, ative **View > Animate**; ela usa a variável `$t`.
4. Para exportar, selecione a peça no modo de visualização, renderize com `F6` e use
   **File > Export > Export as STL**.

Pela linha de comando, o que evita abrir a interface:

```bash
openscad --export-format binstl -o saida.stl arquivo.scad
```

## Antes de imprimir

Confira as folgas na sua impressora antes de mandar o conjunto todo. Furo em FDM sai menor que o
nominal, e foi exatamente isso que inutilizou a primeira impressão do plunger: o encaixe desenhado
com 6,00 mm não aceitou uma haste de 6,10 mm. Meça uma peça de teste, compare com o nominal e ajuste
o parâmetro de folga antes de gastar filamento na peça inteira.

As medidas de eixo, espessura do playfield e curso dos mecanismos ainda precisam ser validadas no
protótipo físico.
