[Voltar ao índice](../README.md)

# 04. Circuitos integrados

O projeto usa dois circuitos integrados, em três unidades cada. Este documento trata dos dois em
detalhe: pinagem, funcionamento, protocolo e limites elétricos. O papel de cada um no pinball está
em [03. Componentes](03-componentes.md).

## 4.1 PCF8574, expansor de I/O I²C

### Identificação

Fabricado por NXP e Texas Instruments, entre outros. Encapsulamento DIP-16 ou SO-16. O nome completo
é "Remote 8-bit I/O expander for I2C-bus". Existe uma variante PCF8574**A** que difere apenas na
faixa de endereços, o que importa quando se precisa de mais de oito expansores no mesmo barramento.

### Pinagem

| Pino | Nome | Direção | Descrição |
|---|---|---|---|
| 1 | A0 | Entrada | Bit 0 do endereço I²C |
| 2 | A1 | Entrada | Bit 1 do endereço I²C |
| 3 | A2 | Entrada | Bit 2 do endereço I²C |
| 4 | P0 | Bidirecional | I/O de dados, bit 0 |
| 5 | P1 | Bidirecional | I/O de dados, bit 1 |
| 6 | P2 | Bidirecional | I/O de dados, bit 2 |
| 7 | P3 | Bidirecional | I/O de dados, bit 3 |
| 8 | VSS | Alimentação | Terra |
| 9 | P4 | Bidirecional | I/O de dados, bit 4 |
| 10 | P5 | Bidirecional | I/O de dados, bit 5 |
| 11 | P6 | Bidirecional | I/O de dados, bit 6 |
| 12 | P7 | Bidirecional | I/O de dados, bit 7 |
| 13 | INT | Saída | Interrupção, ativa em nível baixo, dreno aberto |
| 14 | SCL | Entrada | Clock do barramento I²C |
| 15 | SDA | Bidirecional | Dados do barramento I²C |
| 16 | VDD | Alimentação | Positivo, de 2,5 V a 6 V |

### Características elétricas relevantes

| Parâmetro | Valor | Consequência para o projeto |
|---|---|---|
| Tensão de alimentação | 2,5 V a 6 V | Aceita tanto 3,3 V quanto 5 V |
| Corrente drenada por pino, nível baixo | até 25 mA | Limite de carga por saída |
| Corrente fornecida por pino, nível alto | cerca de 100 µA | Não serve para alimentar carga alguma |
| Corrente total do CI | até 100 mA | Limita o número de saídas simultâneas |
| Velocidade do barramento | até 100 kHz (modo padrão) | Cada byte custa cerca de 0,3 ms |

O detalhe mais importante da tabela é a assimetria entre nível baixo e nível alto. Isso decorre da
estrutura de saída chamada quase bidirecional.

### O que significa "quase bidirecional"

Cada pino Pn tem, internamente, um transistor forte que puxa para o terra e uma fonte de corrente
fraca de 100 microampères que puxa para a alimentação. Quando o pino está em nível alto, ele está
apenas fracamente sustentado, e qualquer coisa externa consegue forçá-lo para baixo. É essa
característica que permite ao mesmo pino servir de entrada e de saída sem configuração de direção.

Para usar um pino como **entrada**, escreve-se 1 nele e depois faz-se a leitura. A fonte fraca
sustenta o nível alto, e um contato externo para o terra vence facilmente a fonte e leva o pino a
nível baixo.

Para usar um pino como **saída**, escreve-se 0 para acionar. A carga deve ser ligada entre a
alimentação e o pino, e o CI a aciona drenando corrente. Esta é a configuração usada no projeto, e é
a origem da lógica invertida no código.

### Endereçamento

O endereço de 7 bits do PCF8574 tem a forma `0100` seguida dos três bits definidos pelos pinos A2,
A1 e A0. Isso dá oito combinações possíveis:

| A2 | A1 | A0 | Endereço |
|---|---|---|---|
| 0 | 0 | 0 | `0x20` |
| 0 | 0 | 1 | `0x21` |
| 0 | 1 | 0 | `0x22` |
| 0 | 1 | 1 | `0x23` |
| 1 | 0 | 0 | `0x24` |
| 1 | 0 | 1 | `0x25` |
| 1 | 1 | 0 | `0x26` |
| 1 | 1 | 1 | `0x27` |

A variante PCF8574A usa o prefixo `0111`, ocupando a faixa de `0x38` a `0x3F`. Combinando os dois
modelos é possível ter dezesseis expansores no mesmo barramento.

Nível baixo em A0, A1 ou A2 significa ligar o pino ao terra. Nível alto significa ligar à
alimentação. Esses pinos não devem ficar flutuando.

> **Este é o ponto do bug do projeto.** No esquemático, A0, A1 e A2 dos três CIs estão no mesmo nó,
> aterrado, o que coloca U1, U2 e U3 todos em `0x20`. Ver
> [09. Pendências, item P1](09-pendencias-e-roadmap.md).

### Protocolo de comunicação

O PCF8574 é o mais simples possível: não tem registradores nem comandos. A transação é apenas o
endereço seguido de um byte de dados.

Para **escrever** nas oito saídas de uma vez:

```
[START] [endereço + bit W=0] [ACK] [byte de dados] [ACK] [STOP]
```

Em Python, com a biblioteca `smbus2`:

```python
from smbus2 import SMBus

bus = SMBus(1)              # I2C1 da Raspberry Pi
bus.write_byte(0x20, 0xFE)  # zera apenas o bit 0, aciona P0
```

Para **ler** as oito entradas de uma vez:

```
[START] [endereço + bit R=1] [ACK] [byte lido] [NACK] [STOP]
```

```python
valor = bus.read_byte(0x20)
```

A consequência prática mais importante é que não existe acesso individual a pino. Toda escrita
sobrescreve os oito bits simultaneamente. Por isso o software precisa manter uma cópia do estado
atual em memória, modificar apenas o bit desejado e reescrever o byte completo. É exatamente o que a
classe `Pcf8574` do projeto faz com o atributo `self.estado`.

### O pino de interrupção

O pino 13, INT, vai a nível baixo sempre que alguma entrada muda de estado, e volta ao normal quando
o mestre faz uma leitura. Ligando esse pino a um GPIO da Raspberry Pi, o software é avisado da
mudança em vez de precisar consultar o expansor repetidamente.

Como é uma saída em dreno aberto, vários CIs podem compartilhar a mesma linha de interrupção, desde
que haja um pull-up. O software então lê os expansores para descobrir qual deles mudou.

No esquemático o INT dos três CIs não chega até a Raspberry Pi, ou seja, o recurso está disponível
mas não foi aproveitado. Como o projeto usa os expansores apenas como saída, isso não é um problema
hoje, mas seria útil caso alguma entrada venha a ser migrada para eles.

## 4.2 L293D, driver de quatro meias-pontes

### Identificação

Fabricado pela STMicroelectronics e por outros, em encapsulamento DIP-16 com abas de dissipação. O
nome de catálogo é "Quadruple Half-H Driver". A versão sem o D, L293, é eletricamente equivalente
mas não inclui os diodos de proteção.

### Pinagem

| Pino | Nome | Direção | Descrição |
|---|---|---|---|
| 1 | EN1 (1,2EN) | Entrada | Habilita os canais 1 e 2 |
| 2 | IN1 (1A) | Entrada | Comando lógico do canal 1 |
| 3 | OUT1 (1Y) | Saída | Saída de potência do canal 1 |
| 4 | GND | Alimentação | Terra e dissipação térmica |
| 5 | GND | Alimentação | Terra e dissipação térmica |
| 6 | OUT2 (2Y) | Saída | Saída de potência do canal 2 |
| 7 | IN2 (2A) | Entrada | Comando lógico do canal 2 |
| 8 | VS (VCC2) | Alimentação | Alimentação de potência, até 36 V |
| 9 | EN2 (3,4EN) | Entrada | Habilita os canais 3 e 4 |
| 10 | IN3 (3A) | Entrada | Comando lógico do canal 3 |
| 11 | OUT3 (3Y) | Saída | Saída de potência do canal 3 |
| 12 | GND | Alimentação | Terra e dissipação térmica |
| 13 | GND | Alimentação | Terra e dissipação térmica |
| 14 | OUT4 (4Y) | Saída | Saída de potência do canal 4 |
| 15 | IN4 (4A) | Entrada | Comando lógico do canal 4 |
| 16 | VSS (VCC1) | Alimentação | Alimentação lógica, de 4,5 V a 7 V |

Os quatro pinos de terra, 4, 5, 12 e 13, são internamente ligados ao dissipador do encapsulamento.
Soldá-los a uma área ampla de cobre é o que permite ao CI trabalhar próximo do limite de corrente.

### Tabela de funcionamento

Cada canal se comporta assim:

| ENn | INn | OUTn |
|---|---|---|
| 0 | qualquer | Alta impedância, desligada |
| 1 | 0 | Nível baixo, conduz para o terra |
| 1 | 1 | Nível alto, conduz da alimentação VS |

O pino de habilitação atua sobre um par de canais: EN1 controla os canais 1 e 2, e EN2 controla os
canais 3 e 4. Com a habilitação em nível baixo, as duas saídas do par ficam desconectadas.

Isso tem uma implicação de projeto que precisa estar clara: não é possível desligar um canal
individualmente pela habilitação, apenas o par. Para apagar um único LED, deve-se levar a entrada IN
correspondente a nível baixo, mantendo a habilitação ativa.

### Características elétricas relevantes

| Parâmetro | Valor | Consequência para o projeto |
|---|---|---|
| Alimentação lógica VSS | 4,5 V a 7 V | Os 5 V usados estão corretos |
| Alimentação de potência VS | até 36 V | Permite carga em tensão maior que a lógica |
| Corrente contínua por canal | 600 mA | Suficiente para LEDs, insuficiente para solenoides |
| Corrente de pico por canal | 1,2 A | Ainda muito abaixo de uma solenoide de flipper |
| Queda no transistor superior | cerca de 1,4 V | Reduz a tensão que chega à carga |
| Queda no transistor inferior | cerca de 1,2 V | Idem |
| Diodos de proteção | internos | Dispensa diodos externos em carga indutiva |

### Sobre a queda de tensão

O L293D é construído com transistores bipolares, que sempre apresentam uma queda de tensão ao
conduzir. Somando os dois transistores de uma meia-ponte, perde-se cerca de 2,6 V internamente.

Com alimentação de 5 V, isso significa que a carga recebe aproximadamente 2,4 V. É um desperdício
considerável, e é a razão pela qual os LEDs do projeto vão acender mais fracos do que o cálculo do
resistor previa, conforme detalhado em
[03. Componentes, seção 3.8](03-componentes.md#38-leds-e-resistores-d1-a-d12-r1-a-r12).

Além de reduzir a tensão útil, essa queda dissipa calor. Um canal conduzindo 600 mA com 1,4 V de
queda dissipa cerca de 0,84 W, e com quatro canais ativos o CI precisa de dissipação adequada. Para
os cerca de 9 mA dos LEDs deste projeto isso é irrelevante, mas vale saber para eventuais mudanças
de carga.

Drivers modernos baseados em MOSFET, como o DRV8871 ou mesmo o TB6612FNG, têm queda muito menor e
seriam a escolha atual para um projeto novo. O L293D permanece útil por disponibilidade e
familiaridade.

### Os diodos internos

Ao interromper a corrente numa carga indutiva, o campo magnético colapsa e a bobina gera um pico de
tensão de polaridade invertida. Sem um caminho para essa corrente, o pico pode chegar a centenas de
volts e destruir o transistor de comando.

Os diodos internos do L293D oferecem esse caminho, chamado de caminho de recirculação. É a razão de
existir a versão com o D no nome, e é o que a torna preferível sempre que a carga é um motor,
solenoide ou relé.

Vale notar que, se as solenoides do projeto vierem a ser acionadas por MOSFETs externos em vez do
L293D, esses diodos de proteção precisarão ser adicionados manualmente ao circuito. É um item que
não pode ser esquecido.

## 4.3 Comparação entre os dois CIs

Os dois integrados são complementares, e entender a divisão de trabalho entre eles é entender a
arquitetura do projeto.

| Aspecto | PCF8574 | L293D |
|---|---|---|
| Função | Multiplicar pinos de I/O | Fornecer potência à carga |
| Interface | Serial I²C, dois fios | Paralela, um pino por canal |
| Consumo de pinos da Pi | 2 para até 8 CIs | 1 por canal |
| Corrente por canal | 25 mA drenando | 600 mA contínuos |
| Latência | Cerca de 0,3 ms por byte | Imediata |
| Papel na cadeia | Decide o que ligar | Executa o acionamento |

A cadeia completa de acionamento fica assim:

```mermaid
flowchart LR
    A["Raspberry Pi<br/>2 pinos de I2C"] -->|"protocolo serial"| B["PCF8574<br/>8 pinos lógicos<br/>25 mA cada"]
    B -->|"nível lógico"| C["L293D<br/>4 canais<br/>600 mA cada"]
    C -->|"potência"| D["Carga<br/>LED ou solenoide"]
```

O PCF8574 resolve a escassez de pinos mas não tem força. O L293D tem força mas consome um pino por
canal. Em cascata, dois pinos da Raspberry Pi comandam dezenas de cargas de potência, que é
exatamente o que uma mesa de pinball exige.

---

Anterior: [03. Componentes](03-componentes.md) ·
Próximo: [05. Pinagem e mapa de I/O](05-pinout.md)
