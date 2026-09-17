# Drop target

Conversão para OpenSCAD das três peças do drop target de
[Chris Mitchell](https://www.thingiverse.com/thing:2772610), cujos STL estão em
[`references/`](references/). A foto [`references/image.jpg`](references/image.jpg) mostra o
conjunto montado: **três impressões de cada arquivo**.

Cada peça foi remodelada a partir da malha original, e não apenas importada, para permitir edição
no OpenSCAD. Os STL de referência continuam intactos e podem ser impressos como estão.

| Peça | Arquivo | Envelope | Volume × STL |
|---|---|---|---:|
| Gaiola | [`cage.scad`](cage.scad) | 40 × 85 × 47,5 mm | +0,01 % |
| Alvo | [`target.scad`](target.scad) | 38,4 × 80 × 12,5 mm | +0,00 % |
| Braço do servo | [`servo_stick.scad`](servo_stick.scad) | 12 × 64,8 × 4 mm | −0,04 % |

A caixa envolvente de cada peça convertida é idêntica à do STL correspondente; a diferença de
volume vem apenas da quantidade de facetas nos furos redondos.

## Como ajustar o tamanho peça a peça

Tudo fica em [`parameters.scad`](parameters.scad). Para mudar só uma peça, use a escala dela:

```scad
target_scale = [1, 1.2, 1];   // alvo 20 % mais comprido, gaiola e braço intactos
cage_scale = [1, 1, 1];
servo_stick_scale = [1, 1, 1];
```

Para mudanças que não são de escala, edite as medidas nomeadas: espessura das laterais
(`cage_wall`), vão da gaiola (`cage_slot_width`), largura e comprimento do alvo (`target_width`,
`target_length`), espessura da cabeça (`target_head_thickness`), diâmetro dos furos
(`cage_screw_diameter`, `cage_pin_diameter`, `target_knot_hole_diameter`) e assim por diante. Os
contornos das peças são listas de pontos com nome, então dá para mover um vértice específico sem
mexer no resto.

A quantidade de cada peça também é parâmetro: `cage_count`, `target_count` e `servo_stick_count`,
todos em 3 para reproduzir a foto.

## Como o mecanismo funciona

O alvo corre encostado na face traseira da gaiola. As orelhas de 4,2 mm passam atrás das duas
laterais e é isso que prende o alvo contra a estrutura; a metade dianteira da cabeça entra no vão de
31 mm e faz a guia. O curso é de 30 mm, exatamente a altura da cabeça: em baixo, a base do alvo
encosta na base da gaiola e o topo da cabeça fica rente ao topo da estrutura, ou seja, o alvo some
sob o playfield; em cima, a cabeça aparece inteira. Essa posição foi achada testando peça contra
peça, e é a única em que não há interferência em nenhum ponto do curso.

O microservo é representado na montagem nas coordenadas da gaiola ainda deitada. O eixo fica na
lateral direita, normal à parede, e o corpo do SG90 fica apoiado nessa lateral. O horn e o braço
impresso entram no vão e giram no plano vertical imediatamente abaixo do alvo. Os dois braços
compartilham o mesmo eixo e giram juntos.

O fio é amarrado na ponta longa do braço, a aproximadamente 42 mm do eixo, e sobe até o furo do bloco
do alvo. É essa ponta que sobe junto com o alvo: o braço gira e puxa o fio, levantando o alvo; no
sentido contrário, o alvo desce. Com o fio esticado, a simulação resolve o triângulo a cada quadro
para manter os dois pontos conectados durante os 30 mm de curso.

O dente inferior do alvo encosta na alavanca do microswitch quando o alvo está levantado. Quando a
bola derruba o alvo, o dente desce e o contato abre. A animação segue essa lógica: os três alvos
caem em momentos diferentes e, depois que o terceiro cai, os três servos rearmam o banco junto.

## Vistas

[`drop-target.scad`](drop-target.scad) é o arquivo de abertura. Em `view_mode`:

- `"unidade"`: uma unidade completa em pé, recomendada para conferir o encaixe;
- `"banco"`: três gaiolas encostadas, uma a cada 40 mm, com alvo, servo, chave, fio e braço;
- `"mesa"`: o banco instalado sob o playfield de 450 × 900 mm, com as aberturas dos alvos;
- `"impressao"`: as peças deitadas na quantidade pedida, como saem da impressora;
- `"gaiola"`, `"alvo"`, `"braco_servo"`, `"servo"`: uma peça isolada.

`target_state` aceita `"levantado"`, `"baixado"` e `"animado"`. Para ver o ciclo completo, deixe
`"animado"` e ative **View > Animate** no OpenSCAD. O ritmo fica em `target_drop_times`,
`target_drop_duration`, `reset_start` e `reset_duration`.

O microservo, o microswitch e o playfield são envelopes de referência para conferir encaixe e curso,
não peças para imprimir. As três peças impressas continuam sendo gaiola, alvo e braço.

## O que ficou como estimativa

O conjunto de STL não traz suporte de servo nem nada que fixe a posição relativa das peças. A
posição do alvo (`target_depth_offset`, `target_drop_offset`, `target_travel`) veio de teste de
interferência e não tem folga sobrando. Já a posição do servo (`servo_shaft`), o comprimento do fio
(`string_length`) e o ponto de amarração (`servo_stick_tie`) foram escolhidos para dar o curso
inteiro sem o braço bater no alvo nem na gaiola, o que foi conferido em todo o curso, mas precisam
ser confirmados com o servo real na mão. O mesmo vale para a chave: os dois furos de 2 mm da lateral
direita são os que já existem na peça, mas o alcance da alavanca depende do modelo de microswitch.

A altura em que o banco fica sob a mesa também é escolha de montagem: o topo da estrutura encosta na
face inferior do playfield, e com 10 mm de espessura sobram 20 mm de alvo acima da superfície.

As abas de fixação do servo têm 32,2 mm e o vão entre as laterais tem 31 mm, então elas encostam nas
duas paredes. Pela geometria é o que segura o servo no lugar, mas na montagem real pode ser preciso
lixar as abas ou abrir um rebaixo.
