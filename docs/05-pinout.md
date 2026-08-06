[Voltar ao índice](../README.md)

# 05. Pinagem e mapa de I/O

Este documento reúne todas as ligações do projeto em forma de tabela. Onde uma informação não pode
ser determinada com certeza a partir do esquemático, isso está indicado de forma explícita em vez de
ser preenchido por suposição.

## 5.1 Raspberry Pi, entradas digitais

O código configura 16 GPIOs como entrada com pull-up interno, na lista definida em
`src/components/Raspberry.py`:

```python
self.entradas = [
    4, 17, 27, 22, 5, 6, 13, 19,
    26, 23, 24, 25, 12, 16, 20, 21
]
```

Esses 16 GPIOs correspondem exatamente aos que aparecem ligados no esquemático, o que confirma que
código e hardware estão de acordo neste ponto. A tabela abaixo cruza numeração BCM, pino físico do
conector de 40 vias e a posição no esquemático.

| GPIO (BCM) | Pino físico | Bloco no esquemático | Observação |
|---|---|---|---|
| GPIO4 | 7 | Superior (sensores) | |
| GPIO5 | 29 | Esquerdo (fim de curso) | |
| GPIO6 | 31 | Esquerdo (fim de curso) | |
| GPIO12 | 32 | Esquerdo (fim de curso) | |
| GPIO13 | 33 | Esquerdo (fim de curso) | |
| GPIO16 | 36 | Esquerdo (fim de curso) | |
| GPIO17 | 11 | Superior (sensores) | |
| GPIO19 | 35 | Esquerdo (fim de curso) | |
| GPIO20 | 38 | Esquerdo (fim de curso) | |
| GPIO21 | 40 | Esquerdo (fim de curso) | |
| GPIO22 | 15 | Superior (sensores) | |
| GPIO23 | 16 | Superior (sensores) | |
| GPIO24 | 18 | Superior (sensores) | |
| GPIO25 | 22 | Superior (sensores) | |
| GPIO26 | 37 | Esquerdo (fim de curso) | |
| GPIO27 | 13 | Superior (sensores) | |

São 16 entradas para 13 sensores, o que deixa 3 GPIOs de reserva.

O esquemático mostra também um GPIO18 desenhado no símbolo da Raspberry Pi, mas ele não aparece na
lista do código e não está ligado a sensor algum. Não faz parte do banco de entradas.

## 5.2 Mapeamento sensor para GPIO

Este é o ponto em que a documentação da etapa anterior não permite conclusão. O esquemático liga os
sensores aos GPIOs por fios que se cruzam ao longo do desenho, sem rótulos de rede (net labels), e a
imagem exportada não permite rastrear com segurança qual fio chega a qual pino.

O que se sabe com certeza:

- Os 13 sensores estão distribuídos entre os 16 GPIOs da tabela anterior.
- CF01 a CF08 estão no bloco esquerdo, cujos fios vão para GPIO5, GPIO6, GPIO12, GPIO13, GPIO16,
  GPIO19, GPIO20, GPIO21 e GPIO26.
- SI01 a SI03, CF09 e CF10 estão no bloco superior, cujos fios vão para GPIO4, GPIO17, GPIO22,
  GPIO23, GPIO24, GPIO25 e GPIO27.

O que precisa ser confirmado abrindo o projeto no Proteus e inspecionando cada nó, ou medindo com
multímetro na montagem física:

| Sensor | Tipo | GPIO | Função no jogo |
|---|---|---|---|
| SI01 | Indutivo | a confirmar | a definir |
| SI02 | Indutivo | a confirmar | a definir |
| SI03 | Indutivo | a confirmar | a definir |
| CF01 | Fim de curso | a confirmar | a definir |
| CF02 | Fim de curso | a confirmar | a definir |
| CF03 | Fim de curso | a confirmar | a definir |
| CF04 | Fim de curso | a confirmar | a definir |
| CF05 | Fim de curso | a confirmar | a definir |
| CF06 | Fim de curso | a confirmar | a definir |
| CF07 | Fim de curso | a confirmar | a definir |
| CF08 | Fim de curso | a confirmar | a definir |
| CF09 | Fim de curso | a confirmar | a definir |
| CF10 | Fim de curso | a confirmar | a definir |

Preencher esta tabela é uma das primeiras tarefas de quem continuar o projeto, e o procedimento
está descrito em [09. Pendências, item P7](09-pendencias-e-roadmap.md).

## 5.3 Raspberry Pi, barramento I²C

| Sinal | GPIO (BCM) | Pino físico | Destino |
|---|---|---|---|
| SDA | GPIO2 | 3 | Pino 15 de U1, U2 e U3 |
| SCL | GPIO3 | 5 | Pino 14 de U1, U2 e U3 |

O barramento usado é o `I2C1`, que precisa estar habilitado no sistema. Ver
[06. Software](06-software.md) para o procedimento.

## 5.4 Raspberry Pi, pinos desenhados mas não usados

O símbolo do Proteus expõe outros pinos que aparecem no desenho sem função atribuída no projeto:

| Sinal | GPIO | Pino físico | Situação |
|---|---|---|---|
| TXD | GPIO14 | 8 | Desenhado, sem uso |
| RXD | GPIO15 | 10 | Desenhado, sem uso |
| MOSI | GPIO10 | 19 | Desenhado, sem uso |
| MISO | GPIO9 | 21 | Desenhado, sem uso |
| CLK | GPIO11 | 23 | Desenhado, sem uso |
| CS | GPIO8 | 24 | Desenhado, sem uso |
| SPI_CE1 | GPIO7 | 26 | Desenhado, sem uso |

Esses pinos ficam disponíveis para expansões. A UART (TXD e RXD) é justamente o caminho natural para
a comunicação com o ESP32 prevista no roadmap, e o SPI ficaria livre para um display de placar.

## 5.5 PCF8574, endereços

### Situação no esquemático

| CI | A2 | A1 | A0 | Endereço resultante |
|---|---|---|---|---|
| U1 | GND | GND | GND | `0x20` |
| U2 | GND | GND | GND | `0x20` |
| U3 | GND | GND | GND | `0x20` |

Os três pinos de seleção dos três CIs estão ligados no mesmo nó, e esse nó vai ao terra. O resultado
é que os três respondem no mesmo endereço, o que impossibilita endereçá-los individualmente.

### Situação no código

O arquivo `src/main.py` instancia um único módulo:

```python
pcf = rasp.adiciona_modulo(0x27)   # endereço 0x27
```

O endereço `0x27` corresponde a A0, A1 e A2 todos em nível alto, o oposto do que o esquemático
desenha. Já o código de teste do relatório e o firmware da simulação usam `0x20`.

Ou seja, há três fontes divergindo entre si. A correção proposta está em
[09. Pendências, item P1](09-pendencias-e-roadmap.md), e a atribuição recomendada é:

| CI | A2 | A1 | A0 | Endereço | Função |
|---|---|---|---|---|---|
| U1 | GND | GND | GND | `0x20` | Solenoides SL01 a SL08 |
| U2 | GND | GND | VDD | `0x21` | Solenoides SL09 e SL10, e comando de driver |
| U3 | GND | VDD | GND | `0x22` | Comando de driver |

## 5.6 PCF8574, mapa de saídas

### U1, solenoides

| Pino do CI | Bit | Saída | Destino |
|---|---|---|---|
| 4 | P0 | SL01 | Solenoide |
| 5 | P1 | SL02 | Solenoide |
| 6 | P2 | SL03 | Solenoide |
| 7 | P3 | SL04 | Solenoide |
| 9 | P4 | SL05 | Solenoide |
| 10 | P5 | SL06 | Solenoide |
| 11 | P6 | SL07 | Solenoide |
| 12 | P7 | SL08 | Solenoide |

### U2, solenoides e comando de driver

| Pino do CI | Bit | Destino |
|---|---|---|
| 4 | P0 | SL09, solenoide |
| 5 | P1 | SL10, solenoide |
| 6 | P2 | Entrada de L293D, via RN1 ou RN2 |
| 7 | P3 | Entrada de L293D, via RN1 ou RN2 |
| 9 | P4 | Entrada de L293D, via RN1 ou RN2 |
| 10 | P5 | Entrada de L293D, via RN1 ou RN2 |
| 11 | P6 | Entrada de L293D, via RN1 ou RN2 |
| 12 | P7 | Entrada de L293D, via RN1 ou RN2 |

### U3, comando de driver

| Pino do CI | Bit | Destino |
|---|---|---|
| 4 | P0 | Entrada de L293D, via RN1 ou RN2 |
| 5 | P1 | Entrada de L293D, via RN1 ou RN2 |
| 6 | P2 | Entrada de L293D, via RN1 ou RN2 |
| 7 | P3 | Entrada de L293D, via RN1 ou RN2 |
| 9 | P4 | Entrada de L293D, via RN1 ou RN2 |
| 10 | P5 | Entrada de L293D, via RN1 ou RN2 |
| 11 | P6 | Entrada de L293D, via RN1 ou RN2 |
| 12 | P7 | Entrada de L293D, via RN1 ou RN2 |

Somando P2 a P7 de U2 com P0 a P7 de U3, há 14 linhas de comando disponíveis para as 12 entradas dos
três L293D. Assim como no caso dos sensores, o esquemático não permite determinar qual linha chega a
qual entrada, porque os fios se cruzam sem rótulo de rede. Essa correspondência precisa ser levantada
no Proteus.

## 5.7 L293D, mapa de ligações

Todos os três CIs seguem o mesmo padrão de alimentação:

| Pino | Nome | Ligação |
|---|---|---|
| 16 | VSS | 5 V, de BAT2 |
| 8 | VS | 5 V, de BAT2 |
| 4, 5, 12, 13 | GND | Terra |

E o mesmo padrão de entradas e saídas:

| Pino | Nome | Origem ou destino |
|---|---|---|
| 1 | EN1 | Atuador de simulação no esquemático, sem origem definida no hardware |
| 9 | EN2 | Atuador de simulação no esquemático, sem origem definida no hardware |
| 2 | IN1 | Saída de PCF8574 |
| 7 | IN2 | Saída de PCF8574 |
| 10 | IN3 | Saída de PCF8574 |
| 15 | IN4 | Saída de PCF8574 |
| 3 | OUT1 | Resistor e LED |
| 6 | OUT2 | Resistor e LED |
| 11 | OUT3 | Resistor e LED |
| 14 | OUT4 | Resistor e LED |

### Correspondência entre saídas e LEDs

| CI | OUT1 | OUT2 | OUT3 | OUT4 |
|---|---|---|---|---|
| U4 | R1 e D1 | R2 e D2 | R3 e D3 | R4 e D4 |
| U5 | R5 e D5 | R6 e D6 | R7 e D7 | R8 e D8 |
| U6 | R9 e D9 | R10 e D10 | R11 e D11 | R12 e D12 |

Todos os resistores R1 a R12 são de 180 ohms, e todos os LEDs D1 a D12 são vermelhos de 5 mm.

Sobre os pinos de habilitação: no esquemático eles estão ligados a atuadores de estado lógico do
Proteus, que servem para alternar o sinal manualmente durante a simulação. No hardware real esses
pinos precisam de uma origem definida. Ver [P3](09-pendencias-e-roadmap.md).

## 5.8 Alimentação

| Fonte | Tensão | Cargas |
|---|---|---|
| BAT1 | 5 V | VDD dos três PCF8574 |
| BAT2 | 5 V | VSS e VS dos três L293D |
| BAT3 | 3,3 V | Comum da rede RN3 |

Todas as referências de terra são comuns, conforme o barramento de terra do esquemático.

Não há fonte prevista para as solenoides, que é uma lacuna do projeto. Ver
[P2](09-pendencias-e-roadmap.md).

## 5.9 Redes resistivas

| Rede | Valor | Elementos | Comum ligado a | Função |
|---|---|---|---|---|
| RN1 | 10 kΩ | 8 | Barramento de saída dos PCF | Pull-up nas linhas de comando dos drivers |
| RN2 | 10 kΩ | 8 | Barramento de saída dos PCF | Pull-up nas linhas de comando dos drivers |
| RN3 | 10 kΩ | 8 | BAT3, 3,3 V | Pull-up nas entradas de sensor |

## 5.10 Referência rápida do conector da Raspberry Pi

Para consulta durante a montagem, com os pinos usados neste projeto destacados na coluna de função.

| Pino | Sinal | Função no projeto | | Pino | Sinal | Função no projeto |
|---|---|---|---|---|---|---|
| 1 | 3V3 | | | 2 | 5V | |
| 3 | GPIO2 | **SDA, I²C** | | 4 | 5V | |
| 5 | GPIO3 | **SCL, I²C** | | 6 | GND | Terra |
| 7 | GPIO4 | **Entrada de sensor** | | 8 | GPIO14 | Livre (UART TX) |
| 9 | GND | Terra | | 10 | GPIO15 | Livre (UART RX) |
| 11 | GPIO17 | **Entrada de sensor** | | 12 | GPIO18 | Livre |
| 13 | GPIO27 | **Entrada de sensor** | | 14 | GND | Terra |
| 15 | GPIO22 | **Entrada de sensor** | | 16 | GPIO23 | **Entrada de sensor** |
| 17 | 3V3 | | | 18 | GPIO24 | **Entrada de sensor** |
| 19 | GPIO10 | Livre (SPI MOSI) | | 20 | GND | Terra |
| 21 | GPIO9 | Livre (SPI MISO) | | 22 | GPIO25 | **Entrada de sensor** |
| 23 | GPIO11 | Livre (SPI CLK) | | 24 | GPIO8 | Livre (SPI CE0) |
| 25 | GND | Terra | | 26 | GPIO7 | Livre (SPI CE1) |
| 27 | GPIO0 | Reservado (EEPROM) | | 28 | GPIO1 | Reservado (EEPROM) |
| 29 | GPIO5 | **Entrada de sensor** | | 30 | GND | Terra |
| 31 | GPIO6 | **Entrada de sensor** | | 32 | GPIO12 | **Entrada de sensor** |
| 33 | GPIO13 | **Entrada de sensor** | | 34 | GND | Terra |
| 35 | GPIO19 | **Entrada de sensor** | | 36 | GPIO16 | **Entrada de sensor** |
| 37 | GPIO26 | **Entrada de sensor** | | 38 | GPIO20 | **Entrada de sensor** |
| 39 | GND | Terra | | 40 | GPIO21 | **Entrada de sensor** |

---

Anterior: [04. Circuitos integrados](04-circuitos-integrados.md) ·
Próximo: [06. Software](06-software.md)
