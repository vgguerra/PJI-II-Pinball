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
| Furo axial | 13,21 mm (0,52") × 12,75 mm | 7,00 mm × 34,00 mm |
| Furo do parafuso | 2,38 mm (3/32") | cônico, 4,20 → 3,80 mm |
| Assento plano | não tem | 9,00 × 0,60 mm |

## Medidas do nosso arquivo

| Item | Medida |
|---|---:|
| Diâmetro da haste | 6,10 mm (medido na peça) |
| Folga diametral | 0,90 mm |
| Encaixe da haste | 7,00 mm × 34,00 mm |
| Chanfro de entrada | 14,00 mm, 4,00 mm de profundidade |
| Furo do parafuso, entrada | 4,20 mm |
| Furo do parafuso, fundo | 3,80 mm |
| Profundidade do furo | 7,78 mm |
| Assento plano no topo | 9,00 × 0,60 mm |
| Centro do furo do parafuso | 6,35 mm da face de entrada |
| Do assento até a haste | 8,68 mm |
| Parafuso | M4 × 10 mm |
| Volume | 24,7 cm³ |

O furo antigo de 13,21 mm é tapado e o encaixe novo de 7,00 mm é aberto no lugar, com 34 mm de
profundidade. O chanfro de entrada de 14 mm guia a haste e, de quebra, tira da face frontal a borda
do furo original, que era o que sujava a malha na boca do encaixe.

## Como a haste fica presa

O furo do parafuso desce do topo da base e **entra no encaixe da haste**: a ponta do parafuso aperta
a haste contra o fundo do furo, e é esse aperto que prende as duas peças. Na referência o furinho de
3/32" já fazia esse caminho.

**O furo é cônico.** Entra com 4,20 mm no assento e fecha até 3,80 mm lá embaixo, junto ao encaixe
da haste, ao longo de 7,78 mm. São 0,4 mm de fechamento, pouco menos de 3° de ângulo incluso.

Na prática, descendo o parafuso:

| Profundidade | Diâmetro | O que acontece |
|---|---:|---|
| 0 a 3,9 mm | 4,20 a 4,00 mm | desce solto, sem esforço |
| 3,9 mm | 4,00 mm | encosta nas paredes |
| 3,9 a 7,8 mm | 4,00 a 3,80 mm | vai mordendo, aperto crescente |
| 7,8 mm | 3,80 mm | 0,10 mm de interferência no raio |

A partida é fácil e o esforço só aparece no fim, quando já falta pouco: é o oposto do furo estreito
de ponta a ponta, que exigia força máxima logo no primeiro giro e espanava a cabeça. E, diferente do
furo reto de 4,0 mm, aqui existe aperto de verdade nas últimas voltas.

O aperto final é leve — 0,10 mm no raio é cerca de um quarto da profundidade do filete de um M4.
Segura o parafuso no lugar e gera alguma pressão, mas não é o mesmo que uma rosca cheia. Se quiser
mais mordida, baixe `screw_end_diameter` para 3,6 ou 3,5; a entrada continua fácil do mesmo jeito,
porque quem manda na partida é `screw_entry_diameter`.

**Recomendação que continua valendo:** faça uma marca de punção ou um rebaixo raso na haste, no ponto
onde a ponta do parafuso encosta. Com o cone o parafuso já fica firme, mas o que garante que a haste
não escorrega no tranco do plunger é a ponta assentada numa depressão, e não o atrito. Para achar o
ponto: monte a haste até o fundo, desça o parafuso e gire até riscar. Fica a 6,35 mm da face de
entrada.

Do fundo do assento até a haste são 8,68 mm, então o parafuso precisa ser **mais longo que isso**:
um M4 de 10 mm encosta com 1,3 mm de sobra; um de 8 mm não chega a tocar. Essa conta já considera o
pior caso, com a haste empurrada para o fundo do encaixe pelo próprio parafuso.

O assento plano de 9 mm no topo tem duas funções: a ponta do parafuso não escorrega na curvatura da
base ao começar a entrar, e a cabeça de 8 mm de um M4 cabeça panela apoia reta nele. Com parafuso
sem cabeça, o assento serve só de guia.

### Parafuso para comprar

Serve qualquer **M4 × 10 mm**, de preferência com cabeça, que é bem mais fácil de rosquear no
plástico do que um sem cabeça:

- cabeça panela Phillips, avulso, na [Casa do Resistor](https://www.casadoresistor.com.br/parafuso-m4x10-cabeca-panela-philips) — cerca de R$ 0,42 a unidade;
- o mesmo parafuso em pacote de 50 ou 100 peças na [Leroy Merlin](https://www.leroymerlin.com.br/50-pc-parafuso-maquina-cabeca-panela-phillips-m4-4mm-x-10mm_1570865961) e no [Mercado Livre](https://produto.mercadolivre.com.br/MLB-1543465019-parafuso-maquina-cabeca-panela-phillips-m4-x-10mm-100-pecas-_JM);
- se preferir que nada fique para fora, [Allen sem cabeça M4 × 10 de ponta cônica](https://www.mercadolivre.com.br/parafuso-allen-sem-cabeca-m4-x-10--100-pecas--aco-129/up/MLBU747480122): a ponta crava na haste e segura melhor, mas exige chave allen de 2 mm e mais força para entrar.

## Histórico das decisões

O furo do parafuso passou por várias versões antes de chegar no cone, e vale registrar o porquê de
cada uma ter sido descartada:

| Versão | Por que não ficou |
|---|---|
| 3,30 mm reto | medida de furo para macho M4; sem a ferramenta o parafuso não entra |
| Rosca M4 modelada no arquivo | passo de 0,70 mm é fino demais para FDM reproduzir, ainda mais com o furo deitado |
| 3,50 mm reto | força máxima logo no primeiro giro, risco de espanar a cabeça |
| 4,30 → 3,50 mm em dois degraus | resolvia o esforço, mas o degrau não era desejado |
| 4,00 mm reto | entra fácil, mas não gera aperto nenhum |
| **4,20 → 3,80 mm cônico** | partida livre e aperto progressivo — é o que está no arquivo |

Se um dia o aperto do cone não bastar, o caminho mais firme é insert térmico M4: troque
`screw_entry_diameter` e `screw_end_diameter` por um furo reto de 5,6 mm, que cabe nos 7,78 mm de
parede e dá rosca de metal.

## Impressão

Imprimir com a boca do encaixe voltada para cima, para não precisar de suporte dentro do furo.
0,20 mm de camada, 4 paredes e pelo menos 30% de preenchimento.

O encaixe da haste está em 7,00 mm para uma haste de 6,10 mm. A folga é grande de propósito: furo em
FDM sai menor que o nominal, e a primeira impressão, feita com 6,00 mm, não aceitou a haste. A conta
do comprimento do parafuso já leva em conta essa folga. Se quiser apertar o encaixe depois de medir
a peça impressa, mexa em `rod_clearance`.

Para regerar o STL depois de mexer em alguma medida:

```bash
openscad --export-format binstl -o print/pinball-plunger-handle.stl pinball-plunger-handle.scad
```

O `.scad` importa a referência por caminho relativo, então rode o comando de dentro desta pasta.
A renderização leva uns 15 s porque a malha importada tem 22.922 triângulos.

O furo do parafuso é impresso deitado nessa orientação e sai com a leve deformação típica de furo
horizontal em FDM. Medindo a primeira impressão, a máquina fechou só 0,04 mm em relação ao nominal,
então o cone deve sair em torno de 4,16 na entrada e 3,76 no fundo — a partida continua folgada e o
aperto final fica um pouco maior que o desenhado.
