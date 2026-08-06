[Voltar ao índice](../README.md)

# 02. Arquitetura de hardware

## 2.1 Esquemático completo

O esquemático original está no projeto Proteus `hardware/diagrama-pinball.pdsprj` do repositório
anterior (acessível por [`upstream/pinball`](../upstream/pinball)). A figura abaixo é a exportação
que acompanha aquele repositório.

![Esquemático completo do pinball](assets/diagrama-completo.png)

O esquemático se lê da esquerda para a direita em quatro blocos: as entradas (chaves de fim de curso
CF01 a CF08), o controlador (RB01, a Raspberry Pi 4) com os sensores do topo, os expansores de I/O
(U1, U2 e U3) e, à direita, o estágio de potência (U4, U5 e U6) com a carga de LEDs.

## 2.2 Topologia do sistema

```mermaid
flowchart TB
    subgraph POT["Alimentação"]
        B3["BAT3, 3V3<br/>referência dos pull-ups<br/>de entrada"]
        B1["BAT1, 5V<br/>lógica dos PCF8574"]
        B2["BAT2, 5V<br/>potência dos L293D"]
    end

    subgraph ENTRADAS["Entradas digitais, 13 sensores"]
        CF1["CF01 a CF08<br/>fim de curso<br/>alvos e botões"]
        SI["SI01 a SI03<br/>sensor indutivo<br/>presença da bola"]
        CF2["CF09 e CF10<br/>fim de curso"]
        RN3["RN3, rede 10k<br/>pull-up"]
    end

    RPI["<b>RB01, Raspberry Pi 4</b><br/>16 GPIOs configurados como entrada<br/>I2C1 em GPIO2 (SDA) e GPIO3 (SCL)"]

    subgraph I2C["Barramento I2C1"]
        U1["<b>U1, PCF8574</b><br/>P0 a P7<br/>8 solenoides"]
        U2["<b>U2, PCF8574</b><br/>P0 e P1: 2 solenoides<br/>P2 a P7: comando dos drivers"]
        U3["<b>U3, PCF8574</b><br/>P0 a P7<br/>comando dos drivers"]
    end

    subgraph SAIDAS["Saídas"]
        SL["SL01 a SL10<br/>10 solenoides"]
        RN12["RN1 e RN2<br/>redes 10k"]
        U456["U4, U5, U6<br/>3x L293D<br/>12 canais de potência"]
        LEDS["D1 a D12 com R1 a R12 (180R)<br/>12 LEDs vermelhos"]
    end

    B3 --> RN3
    RN3 --> SI
    RN3 --> CF2
    CF1 --> RPI
    SI --> RPI
    CF2 --> RPI
    RPI <--> U1
    RPI <--> U2
    RPI <--> U3
    B1 --> U1
    B1 --> U2
    B1 --> U3
    U1 --> SL
    U2 --> SL
    U2 --> RN12
    U3 --> RN12
    RN12 --> U456
    B2 --> U456
    U456 --> LEDS
```

## 2.3 Contagem de I/O

Este é o balanço que justifica a existência dos expansores.

| Função | Quantidade | Onde está ligado |
|---|---|---|
| Sensores de fim de curso | 10 (CF01 a CF10) | GPIO direto da Raspberry Pi |
| Sensores indutivos | 3 (SI01 a SI03) | GPIO direto da Raspberry Pi |
| Solenoides | 10 (SL01 a SL10) | U1 completo, mais P0 e P1 de U2 |
| Canais de LED | 12 (D1 a D12) | U4, U5 e U6, comandados por U2 e U3 |

Somando: 13 entradas nos GPIOs e 22 pontos de saída atendidos por 24 pinos de expansor. A Raspberry
Pi sozinha não daria conta das duas coisas, o que valida a decisão de expandir.

## 2.4 Barramento I²C

A comunicação usa o `I2C1` da Raspberry Pi, disponível nos pinos físicos 3 e 5:

| Sinal | GPIO (BCM) | Pino físico | Destino |
|---|---|---|---|
| SDA | GPIO2 | 3 | Pino 15 (SDA) de U1, U2 e U3 |
| SCL | GPIO3 | 5 | Pino 14 (SCL) de U1, U2 e U3 |

Os três PCF8574 compartilham o mesmo par de fios. O que deveria diferenciá-los é o endereço,
configurado nos pinos de seleção A0, A1 e A2 de cada CI.

> **Atenção.** No esquemático, os pinos A0, A1 e A2 dos três PCF8574 estão todos ligados no mesmo
> nó, e esse nó vai ao terra. Isso faz com que os três CIs respondam no endereço `0x20`
> simultaneamente, o que é um conflito de barramento. O diagnóstico completo e a correção estão em
> [09. Pendências, item P1](09-pendencias-e-roadmap.md). Trate as atribuições de U1, U2 e U3 nesta
> documentação como a intenção do projeto, não como algo que funcione da forma como está desenhado.

O esquemático também não mostra resistores de pull-up externos em SDA e SCL. Na prática a Raspberry
Pi tem pull-ups de 1,8k internos nesses dois pinos, o que costuma ser suficiente para trechos
curtos. Como o cabeamento dentro de uma mesa de pinball é longo e passa perto de solenoides, isso
merece verificação. Ver [P5](09-pendencias-e-roadmap.md).

## 2.5 Alimentação

O esquemático usa três fontes, representadas como baterias por ser um ambiente de simulação.

| Fonte | Tensão | O que alimenta |
|---|---|---|
| BAT1 | 5 V | Alimentação lógica dos três PCF8574 |
| BAT2 | 5 V | Pinos VSS (lógica) e VS (potência) dos três L293D |
| BAT3 | 3,3 V | Referência da rede de pull-up RN3, nas entradas de sensor |

A escolha de 3,3 V para RN3 é correta e importante: os GPIOs da Raspberry Pi trabalham em 3,3 V e
não são tolerantes a 5 V. Puxar uma entrada para 5 V danificaria o SoC.

Já os PCF8574 estão em 5 V, o que cria uma questão de compatibilidade de níveis no barramento I²C
que precisa ser resolvida antes da montagem. Está registrado em
[P4](09-pendencias-e-roadmap.md).

Uma observação sobre dimensionamento: o esquemático não contempla a fonte das solenoides. Solenoides
de pinball tipicamente operam entre 24 V e 48 V e consomem alguns ampères em pulsos curtos. Isso
demanda uma fonte separada, e o estágio de acionamento precisa ser compatível com essa tensão.
Está registrado em [P2](09-pendencias-e-roadmap.md).

## 2.6 Caminho de sinal, entrada

```mermaid
flowchart LR
    A["Bola de metal<br/>ou alvo mecânico"] --> B["Sensor<br/>indutivo ou fim de curso"]
    B --> C["Rede de pull-up<br/>RN3 10k em 3V3<br/>ou pull-up interno"]
    C --> D["GPIO da Raspberry Pi<br/>configurado como entrada"]
    D --> E["GPIO.input()<br/>no Python"]
```

Todos os sensores são ligados em configuração de contato para o terra. O contato em repouso está
aberto, e o pull-up mantém a entrada em nível alto. Quando o sensor atua, ele fecha o caminho para
o terra e a entrada vai a nível baixo.

Consequência prática para o software: a lógica é invertida. `GPIO.input(pin) == 0` significa sensor
acionado, e `== 1` significa sensor em repouso. Isso é o padrão em circuitos de contato seco e é
mais imune a ruído do que a alternativa, mas precisa estar explícito no código.

## 2.7 Caminho de sinal, saída

Há dois caminhos distintos de saída, e a diferença entre eles importa.

O primeiro caminho vai para as solenoides. As saídas P0 a P7 de U1 e P0 e P1 de U2 vão diretamente
para SL01 a SL10. No esquemático essas solenoides aparecem como componentes sem modelo atribuído,
que é a forma do Proteus indicar um símbolo genérico ainda não definido. Ou seja, o estágio de
acionamento das solenoides ainda não foi projetado.

```mermaid
flowchart LR
    A["Software chama<br/>pcf.aciona_saida(n)"] --> B["Escrita I2C<br/>write_byte"]
    B --> C["Pino Pn do PCF8574<br/>vai a nível baixo"]
    C --> D["SL01 a SL10<br/>estágio de potência<br/>ainda não definido"]
    D --> E["Solenoide empurra a bola"]
```

O segundo caminho vai para os LEDs, e este está completo no esquemático. As saídas P2 a P7 de U2 e
P0 a P7 de U3 alimentam as entradas IN1 a IN4 dos três L293D. Cada saída OUT do L293D passa por um
resistor de 180 ohms e acende um LED vermelho.

```mermaid
flowchart LR
    A["Software chama<br/>pcf.aciona_saida(n)"] --> B["Escrita I2C"]
    B --> C["Pino Pn do PCF8574"]
    C --> D["Entrada INn do L293D<br/>via rede RN1 ou RN2"]
    D --> E["Saída OUTn<br/>meia-ponte chaveada"]
    E --> F["Resistor de 180R"]
    F --> G["LED vermelho D1 a D12"]
```

## 2.8 As redes resistivas

O esquemático usa três redes resistivas de 8 elementos com terminal comum, referência `RES8SIPB`.
São encapsulamentos SIP que agrupam oito resistores iguais, usados para economizar espaço quando
várias linhas precisam do mesmo resistor.

| Rede | Valor | Onde está |
|---|---|---|
| RN1 | 10 kΩ | Entre as saídas dos PCF8574 e as entradas dos L293D |
| RN2 | 10 kΩ | Entre as saídas dos PCF8574 e as entradas dos L293D |
| RN3 | 10 kΩ | Pull-up em 3,3 V para os sensores SI01 a SI03, CF09 e CF10 |

A função de RN3 é clara: garantir nível alto definido nas entradas quando o sensor está em repouso.

A função de RN1 e RN2 é definir o nível das entradas dos L293D. Isso faz sentido porque a saída do
PCF8574 é quase bidirecional: ela puxa firmemente para o nível baixo, mas para o nível alto conta
apenas com uma fonte de corrente interna fraca, de cerca de 100 microampères. Um pull-up externo
firma o nível alto e melhora o tempo de subida.

Vale notar que os sensores CF01 a CF08 não têm rede de pull-up externa no esquemático. Eles dependem
do pull-up interno da Raspberry Pi, que o código de fato habilita com `GPIO.PUD_UP`. Funciona, mas
o pull-up interno é da ordem de 50 kΩ, bem mais fraco que os 10 kΩ usados nos outros sensores, o que
os torna mais suscetíveis a ruído captado no cabeamento. Ver [P6](09-pendencias-e-roadmap.md).

## 2.9 Recortes do esquemático

Para facilitar a leitura, os blocos principais estão ampliados abaixo.

### Bloco do controlador e sensores

![Detalhe da Raspberry Pi](assets/detalhe-raspberry.png)

Aqui se vê a Raspberry Pi 4 (RB01) com os números de pino físico ao lado de cada GPIO, e à direita
os três sensores indutivos SI01 a SI03 e as chaves CF09 e CF10.

### Bloco dos expansores de I/O

![Detalhe dos PCF8574](assets/detalhe-pcf8574.png)

À esquerda as oito chaves de fim de curso CF01 a CF08, cada uma com um terminal ao barramento de
terra e o outro indo para um GPIO. À direita os três PCF8574, com SCL no pino 14, SDA no pino 15,
INT no pino 13 e os pinos de endereço A0, A1 e A2 embaixo. As saídas de U1 vão para SL01 a SL08, e
as duas primeiras de U2 para SL09 e SL10.

### Bloco de potência

![Detalhe dos L293D](assets/detalhe-l293d.png)

Cada L293D recebe 5 V de BAT2 nos pinos 16 (VSS) e 8 (VS), tem GND aterrado, recebe comando em IN1,
IN2, IN3 e IN4, e entrega em OUT1, OUT2, OUT3 e OUT4. Cada saída vai a um resistor de 180 ohms e a
um LED.

Note os blocos com o valor `0` ligados a EN1 e EN2: são atuadores de estado lógico do Proteus,
usados para alternar o sinal manualmente durante a simulação. No hardware real esses pinos de
habilitação precisam de uma origem definida, seja uma saída de expansor ou uma amarração fixa em
nível alto. Ver [P3](09-pendencias-e-roadmap.md).

---

Anterior: [01. Visão geral](01-visao-geral.md) · Próximo: [03. Componentes](03-componentes.md)
