[Voltar ao índice](../README.md)

# 08. Simulação no Proteus

## 8.1 Por que simular

A equipe anterior optou por validar o circuito no Proteus antes de montar, com dois objetivos.
O primeiro foi confirmar que a comunicação I²C entre a Raspberry Pi e o PCF8574 funcionava como
esperado. O segundo foi verificar a expansão de GPIO e o acionamento de cargas sem risco de queimar
componentes.

É uma abordagem correta, e vale notar que a simulação é justamente onde o problema de endereçamento
descrito em [P1](09-pendencias-e-roadmap.md) passou sem ser detectado. O Proteus não reclama de dois
CIs no mesmo endereço porque o circuito simulado usava apenas um expansor de cada vez.

## 8.2 O arquivo de projeto

O projeto está em
[`upstream/pinball/hardware/diagrama-pinball.pdsprj`](../upstream/pinball/hardware/diagrama-pinball.pdsprj).

O `.pdsprj` é um contêiner compactado. Seu conteúdo interno é:

| Arquivo | Conteúdo |
|---|---|
| `ROOT.DSN` | Esquemático, no formato ISIS |
| `ROOT.LYT` | Layout de placa, praticamente vazio |
| `ROOT.CDB` | Dados de configuração do projeto |
| `PROJECT.XML` | Metadados, versão e scripts |
| `FIRMWARE.XML` | Declara a família Raspberry Pi, compilador Python 3, tipo RPI4 |
| `FIRMWARE/Raspberry Pi 4/main.py` | Código Python executado na simulação |
| `SCRIPTS/PWRRAILS.DAT` | Definição de trilhas de alimentação |

Dois pontos vale registrar. O primeiro é que o layout de placa não foi desenvolvido, apenas o
esquemático, então não existe PCB projetada. O segundo é que existe um `main.py` dentro do projeto do
Proteus que não está versionado em `src/`, e é diferente do código do repositório.

## 8.3 O firmware da simulação

O código que roda dentro do Proteus é este:

```python
import smbus
import time

DEVICE_ADDRESS = 0x20   # confirme com i2cdetect

bus = smbus.SMBus(1)    # 1 = bus I2C do RPi (I2C1)

def write_pcf8574(valor):
    bus.write_byte(DEVICE_ADDRESS, valor)

try:
    estado = 0x01       # bit 0 ativo
    while True:
        write_pcf8574(estado)
        estado ^= 0x01  # alterna bit 0
        time.sleep(1)

except KeyboardInterrupt:
    write_pcf8574(0x00)
```

É um teste de vida: alterna o bit 0 do expansor a cada segundo, o que na prática faz um LED piscar.
Serve para confirmar que o barramento está funcionando de ponta a ponta.

Duas diferenças em relação ao código do repositório merecem atenção. Este usa o endereço `0x20`,
coerente com o esquemático, enquanto `src/main.py` usa `0x27`. E este usa a biblioteca `smbus`,
enquanto o repositório usa `smbus2`. As duas têm API compatível para as operações usadas aqui, mas a
`smbus2` é a mantida atualmente e é a escolha correta.

O relatório traz ainda uma variante desse mesmo teste, que além de escrever também lê de volta:

```python
import smbus
import time

PCF_ADDR = 0x20
bus = smbus.SMBus(1)
estado = 0xFF

bus.write_byte(PCF_ADDR, estado)
print("Iniciando teste com PCF8574...")

while True:
    estado ^= 0x01
    bus.write_byte(PCF_ADDR, estado)
    print(f"Estado enviado: {bin(estado)}")

    leitura = bus.read_byte(PCF_ADDR)
    print(f"Leitura do PCF8574: {bin(leitura)}")

    time.sleep(1)
```

A leitura de volta é uma boa prática de diagnóstico: se o valor lido não corresponder ao escrito, ou
o CI não está respondendo, ou existe algo externo forçando o nível de um pino.

## 8.4 Como abrir e rodar

Requisitos: Proteus 8.10 ou superior, com a biblioteca da Raspberry Pi instalada. O suporte a
Raspberry Pi no Proteus é um recurso das versões mais recentes.

O procedimento é o seguinte.

1. Clonar este repositório com o submódulo, conforme instruções do [README](../README.md).
2. Abrir `upstream/pinball/hardware/diagrama-pinball.pdsprj` no Proteus.
3. O esquemático abre na aba principal, e o código Python fica visível na aba de projeto de firmware.
4. Iniciar a simulação com o botão de play, ou tecla F12.

Durante a simulação, os elementos interativos disponíveis são os atuadores de estado lógico ligados
aos pinos EN1 e EN2 dos L293D, que aparecem como blocos com o valor `0` e setas para alternar. As
chaves de fim de curso e os sensores indutivos também podem ser acionados clicando neles.

O que se observa é o LED ligado ao bit 0 piscando a cada segundo, confirmando que a Raspberry Pi
simulada está escrevendo no expansor e que o expansor está acionando a saída.

## 8.5 Limites da simulação

Vale ter clareza sobre o que essa simulação não prova, para não criar falsa confiança.

Ela não testa endereçamento múltiplo. O firmware fala com um único endereço, então o conflito entre
U1, U2 e U3 nunca se manifesta. Foi assim que o problema passou.

Ela não testa as solenoides, que aparecem no esquemático como símbolos sem modelo atribuído. Ou seja,
a parte mais crítica do acionamento não foi simulada.

Ela não representa o comportamento elétrico real. O Proteus modela componentes ideais em muitos
aspectos, e não reproduz ruído de chaveamento, queda em cabos longos, nem a interferência que uma
solenoide de vários ampères injeta no sistema ao desligar. Numa mesa de pinball, com cabeamento longo
passando perto de bobinas, esse é justamente o tipo de problema que aparece na bancada e não na
simulação.

Ela não representa o comportamento temporal do Linux. A simulação executa o Python de forma
determinística, o que esconde exatamente o problema de latência que motivou a proposta de migrar para
um RTOS.

O relatório menciona que na bancada houve falhas intermitentes no reconhecimento de sensores e
dificuldades no I²C, problemas que a simulação não antecipou. A combinação de conflito de endereço,
níveis de 5 V contra 3,3 V e ruído de cabeamento explica bem esses sintomas.

## 8.6 Referências usadas pela equipe anterior

O relatório cita como material de apoio a documentação da Labcenter Electronics sobre simulação de
Raspberry Pi no Proteus, e um vídeo demonstrativo do mesmo tema.

---

Anterior: [07. Mecânica](07-mecanica.md) ·
Próximo: [09. Pendências e roadmap](09-pendencias-e-roadmap.md)
