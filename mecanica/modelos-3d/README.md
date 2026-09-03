# Modelos 3D

Modelos paramétricos em [OpenSCAD](https://openscad.org/) para os mecanismos do pinball. As medidas
estão em milímetros e podem ser ajustadas no início de cada arquivo antes da fabricação.

## Flipper

O arquivo [`flipper.scad`](flipper.scad) reúne o mecanismo completo do flipper:

- pá com canal para borracha;
- eixo sextavado;
- base com mancal e batentes;
- alavanca inferior;
- haste de acionamento.

Por padrão, o arquivo exibe a montagem completa. Para inspecionar ou exportar uma peça isolada,
altere `modo_visualizacao` para `"flipper"`, `"eixo"`, `"base"`, `"alavanca"` ou `"haste"`.

## Como usar

1. Abra `flipper.scad` no OpenSCAD.
2. Pressione `F5` para visualizar ou `F6` para renderizar.
3. Para observar o movimento, ative **View > Animate**; a animação usa a variável `$t`.
4. Para impressão 3D, selecione uma peça em `modo_visualizacao`, renderize com `F6` e use
   **File > Export > Export as STL**.

Antes de imprimir o conjunto definitivo, confira as dimensões do eixo, a espessura do playfield e
as folgas na sua impressora. Os parâmetros atuais ainda precisam ser validados no protótipo físico.

## Drop target

O diretório [`drop-target`](drop-target/README.md) contém dois bancos paramétricos de 120 × 60 mm,
cada um com três alvos independentes, além das guias, braços de servo, bases inferiores e da
montagem completa para medição.
