[Voltar ao índice](../README.md)

# 03. Componentes

Este documento descreve cada componente presente no esquemático: o que é, por que foi escolhido,
como funciona e qual o papel dele no pinball. As referências de designador (U1, D1, CF01 e assim
por diante) são as mesmas usadas no esquemático do Proteus.

## 3.1 Lista de materiais

| Designador | Componente | Qtd. | Função no pinball |
|---|---|---|---|
| RB01 | Raspberry Pi 4 | 1 | Unidade central de processamento |
| U1, U2, U3 | PCF8574 | 3 | Expansor de I/O digital via I²C |
| U4, U5, U6 | L293D | 3 | Driver de potência para as cargas |
| SI01 a SI03 | LJ12A3-4-Z/BX | 3 | Sensor indutivo de presença da bola |
| CF01 a CF10 | KW11-3Z-3 | 10 | Chave de fim de curso, alvos e botões |
| SL01 a SL10 | Solenoide | 10 | Atuador dos flippers, bumpers e injetor |
| D1 a D12 | LED vermelho 5 mm | 12 | Iluminação cênica |
| R1 a R12 | Resistor 180 Ω | 12 | Limitação de corrente dos LEDs |
| RN1, RN2 | Rede resistiva 8x10 kΩ | 2 | Pull-up nas entradas dos drivers |
| RN3 | Rede resistiva 8x10 kΩ | 1 | Pull-up nas entradas de sensor |
| BAT1, BAT2 | Fonte 5 V | 2 | Alimentação de lógica e de potência |
| BAT3 | Fonte 3,3 V | 1 | Referência dos pull-ups de entrada |

## 3.2 Raspberry Pi 4 (RB01)

### O que é

Um computador de placa única com SoC Broadcom BCM2711, quatro núcleos Cortex-A72, rodando Linux
completo. No esquemático aparece como o modelo `RPI4` do Proteus, que expõe o conector de 40 pinos.

### Por que foi escolhida

O relatório da etapa anterior justifica a escolha por três razões. A primeira é rodar Python
diretamente, sem toolchain de compilação cruzada, o que acelera o desenvolvimento. A segunda é ter
I²C e SPI nativos no cabeçalho de pinos. A terceira é abrir caminho para recursos de alto nível
mais adiante, como um placar em tela, áudio e registro de recordes em banco de dados.

### Como é usada no projeto

A Pi tem dois papéis distintos no esquemático.

Como leitora de sensores, ela dedica 16 GPIOs configurados como entrada com pull-up interno.
Treze deles estão ocupados pelos sensores e três ficam de reserva. É o caminho de menor latência
disponível, e é por isso que os sensores não passam pelos expansores.

Como mestre do barramento I²C, ela usa GPIO2 e GPIO3 (pinos físicos 3 e 5) para comandar os três
PCF8574, que por sua vez acionam solenoides e luzes.

A pinagem completa está em [05. Pinagem e mapa de I/O](05-pinout.md).

### Limitações relevantes

Os GPIOs trabalham em 3,3 V e não toleram 5 V. Aplicar 5 V numa entrada danifica o SoC de forma
permanente. Isso é crítico aqui porque os PCF8574 do esquemático estão alimentados em 5 V.

A corrente por GPIO é limitada a cerca de 16 mA, com um total de aproximadamente 50 mA somando
todos os pinos. Não há folga para acionar carga alguma diretamente, o que reforça a necessidade dos
drivers.

O Linux não é um sistema de tempo real. O escalonador pode atrasar a execução de um trecho de código
por dezenas de milissegundos sob carga. Para o placar isso é irrelevante, mas para o flipper é o
problema central que motivou a proposta de migrar o tempo real para um microcontrolador dedicado.

## 3.3 PCF8574 (U1, U2, U3)

### O que é

Um expansor de I/O de 8 bits com interface I²C, em encapsulamento DIP ou SO de 16 pinos. Converte
duas linhas do barramento serial em oito pinos digitais quase bidirecionais.

O tratamento detalhado do CI, com pinagem, protocolo e tabela de endereços, está em
[04. Circuitos integrados](04-circuitos-integrados.md). Aqui fica o papel dele no pinball.

### Por que foi escolhido

A conta de I/O do projeto não fecha com os pinos da Raspberry Pi. São necessários mais de 20 pontos
de saída, além dos 13 de entrada já ocupados. Cada PCF8574 acrescenta 8 pinos consumindo apenas as
duas linhas do I²C que já existiam, e é possível colocar até oito unidades no mesmo barramento. O CI
é barato, amplamente disponível e a biblioteca `smbus2` do Python fala com ele em uma linha de
código.

### Como é usado no projeto

A intenção do projeto, conforme o esquemático, distribui as saídas assim:

| CI | Pinos | Destino |
|---|---|---|
| U1 | P0 a P7 | Solenoides SL01 a SL08 |
| U2 | P0 e P1 | Solenoides SL09 e SL10 |
| U2 | P2 a P7 | Entradas de comando dos L293D |
| U3 | P0 a P7 | Entradas de comando dos L293D |

O acionamento é por nível baixo. A classe `Pcf8574` do projeto mantém uma cópia do byte de estado em
memória, começando em `0b11111111`, e para acionar uma saída ela zera o bit correspondente e
reescreve o byte inteiro. Isso é necessário porque o PCF8574 não permite escrever um pino
isoladamente: toda escrita afeta os oito de uma vez.

### Limitações relevantes

A corrente que o PCF8574 pode fornecer em nível alto é de apenas 100 microampères, vinda de uma
fonte de corrente interna. Em nível baixo ele drena até 25 mA por pino. A consequência prática é que
qualquer carga deve ser ligada entre a alimentação e o pino, para que o CI a acione drenando
corrente, e não fornecendo. Isso explica a lógica invertida adotada no código.

O barramento I²C na Raspberry Pi opera tipicamente a 100 kHz. Cada escrita de byte consome cerca de
0,3 ms entre endereçamento e confirmação. Acionar um flipper por essa via, portanto, custa uma
fração de milissegundo apenas na transmissão, sem contar o atraso do agendador do Linux.

O CI oferece um pino INT que sinaliza mudança nas entradas, dispensando leitura por varredura. No
esquemático o pino 13 (INT) dos três CIs aparece com uma conexão que não é levada até a Raspberry
Pi, ou seja, o recurso está disponível mas não foi aproveitado.

## 3.4 L293D (U4, U5, U6)

### O que é

Um driver de quatro meias-pontes em um encapsulamento de 16 pinos, capaz de fornecer 600 mA
contínuos por canal, com pico de 1,2 A. A letra D no final indica que o CI já traz diodos de
proteção internos contra a tensão reversa gerada por cargas indutivas.

O tratamento detalhado está em [04. Circuitos integrados](04-circuitos-integrados.md).

### Por que foi escolhido

É o CI de acionamento mais comum em laboratórios de ensino, provavelmente já disponível no
almoxarifado do campus. Ele resolve o problema de o PCF8574 não ter corrente para carga alguma,
aceita nível lógico direto nas entradas e, por ter os diodos internos, dispensa componentes
adicionais quando a carga é indutiva.

### Como é usado no projeto

No esquemático os três L293D acionam exclusivamente os LEDs. Cada CI tem quatro canais, e são doze
LEDs no total.

| CI | Saídas | LEDs |
|---|---|---|
| U4 | OUT1 a OUT4 | D1 a D4 |
| U5 | OUT1 a OUT4 | D5 a D8 |
| U6 | OUT1 a OUT4 | D9 a D12 |

O comando de cada canal vem de um pino de PCF8574 ligado à entrada IN correspondente. Quando a
entrada vai a nível alto, a saída conduz e o LED acende.

### Como o relatório pretendia usá-lo

O relatório da etapa anterior afirma que os L293D serviriam de driver tanto para os LEDs quanto para
as solenoides dos bumpers e flippers. O esquemático, porém, só implementa o caminho dos LEDs: as
solenoides SL01 a SL10 estão ligadas direto nos pinos dos PCF8574, sem estágio de potência algum.

Essa é uma divergência importante entre a intenção documentada e o circuito desenhado, e ela precisa
ser resolvida antes de qualquer montagem. Vale registrar também que o L293D não é adequado para
solenoides de pinball: 600 mA por canal fica muito abaixo dos vários ampères que uma solenoide de
flipper exige, e a tensão máxima de 36 V limita as opções de fonte. Ver
[P2](09-pendencias-e-roadmap.md).

### Limitações relevantes

O L293D é um driver bipolar, e por isso tem queda de tensão considerável: cerca de 1,4 V no
transistor superior e 1,2 V no inferior, somando aproximadamente 2,6 V perdidos internamente. Com
alimentação de 5 V, sobram cerca de 2,4 V para a carga, o que é suficiente para um LED vermelho mas
inviabiliza cargas mais exigentes.

Essa queda também gera calor. Com quatro canais ativos, o encapsulamento precisa de dissipação, o
que na prática significa deixar as abas de terra soldadas a uma área de cobre generosa.

## 3.5 Sensor indutivo LJ12A3-4-Z/BX (SI01 a SI03)

### O que é

Um sensor de proximidade indutivo cilíndrico de rosca M12, que detecta a presença de metal a uma
distância nominal de 4 mm sem contato físico. A designação decompõe-se assim: `LJ12` indica o
diâmetro de 12 mm, `A3` é a série, `4` é a distância de detecção em milímetros, `Z/BX` indica saída
NPN normalmente aberta.

O princípio de funcionamento é uma bobina que gera um campo magnético alternado na face do sensor.
Quando um objeto metálico entra nesse campo, correntes parasitas induzidas no metal amortecem a
oscilação, e o circuito interno detecta essa queda de amplitude e comuta a saída.

### Por que foi escolhido

A bola de pinball é de metal, o que dispensa qualquer refletor ou marcação. Como não há contato
mecânico, não existe peça para desgastar nem contato para oxidar, e o sensor é imune a poeira e
iluminação ambiente, ao contrário de uma solução óptica. Também é um dos sensores industriais mais
baratos e comuns no mercado brasileiro.

### Como é usado no projeto

Os três sensores detectam a passagem da bola em pontos específicos da mesa. Os usos típicos são
confirmar que a bola foi injetada e está em jogo, detectar passagem por rampas ou túneis para
pontuar, e detectar que a bola caiu no dreno para encerrar a bola atual.

Eletricamente eles são ligados como contato para o terra. A saída NPN conduz para o terra quando
detecta metal, e a rede de pull-up RN3, referenciada em 3,3 V, mantém a linha em nível alto quando
não há detecção. O GPIO da Raspberry Pi lê nível baixo como bola detectada.

### Cuidado importante de tensão

Este é o ponto de atenção mais relevante deste componente. O LJ12A3-4-Z/BX é especificado para
alimentação entre 6 V e 36 V, tipicamente 12 V ou 24 V. A saída em coletor aberto de um sensor
alimentado em 24 V, se conectada diretamente a um GPIO da Raspberry Pi, aplicaria 24 V no pino e
destruiria o SoC.

O esquemático evita isso ao usar RN3 puxando para 3,3 V, o que é a topologia correta: o transistor
de saída do sensor só puxa para baixo, e quem define o nível alto é o pull-up em 3,3 V. Para que
isso realmente funcione na montagem física, a saída do sensor precisa ser genuinamente coletor
aberto, sem nenhum caminho interno para a alimentação de 24 V. Vale medir com o multímetro antes de
ligar na Pi. Ver [P4](09-pendencias-e-roadmap.md).

## 3.6 Chave de fim de curso KW11-3Z-3 (CF01 a CF10)

### O que é

Uma microchave de ação rápida, do tipo comumente chamado de microswitch, com haste ou alavanca
acionadora. O modelo KW11-3Z-3 é a versão com alavanca longa, três terminais (comum, normalmente
aberto e normalmente fechado) e mecanismo de mola que produz comutação rápida e com histerese.

### Por que foi escolhida

É o componente clássico de pinball, usado nas máquinas comerciais desde sempre, tanto nos alvos
quanto nos botões dos flippers. É extremamente barata, aceita milhões de ciclos, e o clique
mecânico dá retorno tátil ao jogador. A ação rápida também produz uma borda de sinal limpa, o que
ajuda na detecção por software.

### Como é usada no projeto

São dez unidades no esquemático, distribuídas em dois grupos. As oito primeiras, CF01 a CF08,
ficam no bloco à esquerda e vão diretamente para GPIOs, sem pull-up externo, dependendo do pull-up
interno da Pi. As duas últimas, CF09 e CF10, ficam no bloco superior junto dos sensores indutivos e
compartilham a rede de pull-up RN3 em 3,3 V.

Os papéis previstos no jogo são os alvos que pontuam quando a bola os atinge, os botões dos flippers
acionados pelo jogador, o botão de início de partida, e o monitoramento de posição de mecanismos,
por exemplo confirmar que o injetor voltou ao repouso.

O esquemático não identifica qual chave cumpre qual papel. Isso é uma lacuna a resolver na montagem
e está registrado em [P7](09-pendencias-e-roadmap.md).

### O problema do repique

Todo contato mecânico apresenta repique, ou bounce: nos primeiros milissegundos após o fechamento,
o contato abre e fecha várias vezes antes de estabilizar. Sem tratamento, o software conta um único
toque do jogador como cinco ou dez acionamentos, e a pontuação fica errada.

O tratamento pode ser feito em hardware, com um filtro RC seguido de um Schmitt trigger, ou em
software, ignorando novas transições dentro de uma janela de tempo. A biblioteca `RPi.GPIO` já
oferece o parâmetro `bouncetime` no método `add_event_detect`, que resolve o problema de forma
direta. O código atual não trata repique, porque ainda não implementa detecção de eventos. Está
registrado em [P9](09-pendencias-e-roadmap.md).

## 3.7 Solenoides (SL01 a SL10)

### O que são

Atuadores eletromagnéticos lineares. Uma bobina envolve um núcleo de ferro móvel, e ao ser
energizada gera um campo que puxa o núcleo para dentro com força considerável. Quando desenergizada,
uma mola devolve o núcleo à posição de repouso.

### Por que são usadas

A solenoide é o atuador padrão do pinball porque entrega um golpe forte e rápido em movimento
linear, exatamente o que se precisa para arremessar a bola. Um motor exigiria mecanismo de conversão
de movimento e responderia mais lentamente.

### Como seriam usadas no projeto

São dez solenoides previstas, distribuídas entre três funções. Duas acionam os flippers, respondendo
aos botões do jogador com o menor atraso possível. Algumas acionam os bumpers, disparando quando um
sensor detecta que a bola encostou no obstáculo. E uma aciona o injetor, que coloca a bola em jogo
no início de cada rodada.

### Estado atual no esquemático

As dez solenoides aparecem no esquemático como símbolos genéricos sem modelo atribuído, ligadas
diretamente aos pinos dos PCF8574. Isso significa que o estágio de acionamento não foi projetado, e
o circuito como está não pode ser montado: um pino de PCF8574 drena no máximo 25 mA, enquanto uma
solenoide de flipper puxa vários ampères.

### O que precisa ser projetado

O acionamento de uma solenoide de pinball envolve três coisas que faltam no circuito atual.

A primeira é o estágio de potência. Um MOSFET de canal N com resistência de condução baixa, ou um
módulo de driver de alta corrente, comandado pelo pino do PCF8574. O MOSFET deve ser dimensionado
para a corrente de pico da solenoide, com folga.

A segunda é a proteção contra tensão reversa. Ao desligar uma bobina, o colapso do campo magnético
gera um pico de tensão que pode chegar a centenas de volts e destrói o transistor de comando. Um
diodo de recuperação rápida em antiparalelo com a bobina resolve, e é obrigatório.

A terceira é a limitação de tempo de acionamento. Uma solenoide de pinball é projetada para pulsos
curtos, tipicamente entre 30 ms e 50 ms. Se ficar energizada continuamente, a bobina superaquece e
queima em segundos. O software precisa garantir o desligamento, e é boa prática ter também uma
proteção em hardware que corte o acionamento independentemente do software. Este ponto é o mais
crítico da lista, porque uma falha de software aqui significa dano físico.

Tudo isso está detalhado em [P2](09-pendencias-e-roadmap.md).

## 3.8 LEDs e resistores (D1 a D12, R1 a R12)

### O que são

Doze LEDs vermelhos de 5 mm, cada um em série com um resistor de 180 ohms, acionados pelas saídas
dos três L293D.

### Como são usados

A função é a iluminação cênica da mesa: piscar no modo atração para chamar a atenção, dar retorno
visual quando um alvo é atingido, e indicar estados do jogo como bola em jogo ou fim de partida.

### Sobre o valor do resistor

O cálculo do resistor parte da tensão disponível, da queda no LED e da corrente desejada. Um LED
vermelho de 5 mm tem queda de cerca de 2 V e opera bem em 20 mA.

Se a saída do L293D entregasse os 5 V da alimentação, a conta seria a seguinte:

```
R = (5 V - 2 V) / 20 mA = 150 Ω
```

O valor de 180 ohms escolhido é o valor comercial imediatamente acima, uma escolha conservadora e
correta em princípio. Na prática, porém, o L293D perde cerca de 1,4 V internamente no transistor
superior, então a tensão que chega ao resistor é de aproximadamente 3,6 V:

```
I = (3,6 V - 2 V) / 180 Ω ≈ 8,9 mA
```

Ou seja, os LEDs vão acender com menos da metade da corrente pretendida. Ainda ficam visíveis, mas
bem mais fracos do que o projeto previa. Se o brilho for insuficiente na montagem, basta reduzir o
resistor para algo em torno de 82 ohms para voltar aos 20 mA. Registrado em
[P10](09-pendencias-e-roadmap.md).

Vale observar que usar um L293D para acender LEDs é um desperdício considerável de recurso: um CI de
16 pinos e quatro meias-pontes com diodos de proteção para acionar quatro LEDs. Um ULN2803, que tem
oito canais Darlington no mesmo tamanho, faria o serviço com metade dos CIs. Fica como sugestão de
otimização, não como erro.

## 3.9 Redes resistivas (RN1, RN2, RN3)

### O que são

Encapsulamentos SIP que agrupam oito resistores de mesmo valor com um terminal comum, referência
`RES8SIPB` no Proteus. Todas as três são de 10 kΩ.

### Como são usadas

RN3 é o pull-up das entradas de sensor. Ela puxa para 3,3 V as linhas dos sensores indutivos SI01 a
SI03 e das chaves CF09 e CF10, garantindo nível alto definido quando o sensor está em repouso e
protegendo o GPIO da Pi de tensões maiores.

RN1 e RN2 ficam entre as saídas dos PCF8574 e as entradas dos L293D. A razão é a característica
quase bidirecional da saída do PCF8574, que puxa firme para baixo mas conta apenas com 100
microampères para o nível alto. O pull-up externo firma esse nível e acelera a transição de subida.

### Por que rede em vez de resistores discretos

Onde há oito linhas precisando do mesmo resistor, uma rede SIP resolve com um componente e uma
solda, em vez de oito. Reduz espaço na placa, tempo de montagem e chance de erro.

---

Anterior: [02. Arquitetura de hardware](02-arquitetura-hardware.md) ·
Próximo: [04. Circuitos integrados](04-circuitos-integrados.md)
