[Voltar ao índice](../README.md)

# 11. Ficha de levantamento

Formulário para preencher nos encontros de 13/08 e 17/08, fechando o Sprint 0. Cada seção
corresponde a uma tarefa do quadro de atividades. O objetivo é sair daqui com dados, não com
impressões.

Preencha direto neste arquivo e faça commit ao final do encontro.

## 11.1 Mapeamento sensor para GPIO

Resolve a pendência [P7](09-pendencias-e-roadmap.md). É a tarefa mais importante do sprint, porque
sem ela não se escreve a lógica do jogo.

Há dois caminhos. O primeiro é abrir o `.pdsprj` no Proteus e inspecionar cada nó, que funciona sem
o hardware montado. O segundo é rodar na Raspberry Pi:

```bash
python3 tools/levantar_entradas.py identificar
```

O programa pede para acionar um sensor por vez e registra qual GPIO respondeu, gravando um
`mapeamento.csv` ao final. Vale usar os dois caminhos e comparar, porque a fiação real pode divergir
do esquemático, e essa divergência é justamente o tipo de coisa que consome tarde de depuração
depois.

| Sensor | Tipo | GPIO | Pino físico | Função no jogo | Confirmado por |
|---|---|---|---|---|---|
| SI01 | Indutivo | | | | |
| SI02 | Indutivo | | | | |
| SI03 | Indutivo | | | | |
| CF01 | Fim de curso | | | | |
| CF02 | Fim de curso | | | | |
| CF03 | Fim de curso | | | | |
| CF04 | Fim de curso | | | | |
| CF05 | Fim de curso | | | | |
| CF06 | Fim de curso | | | | |
| CF07 | Fim de curso | | | | |
| CF08 | Fim de curso | | | | |
| CF09 | Fim de curso | | | | |
| CF10 | Fim de curso | | | | |

Em "Confirmado por", anote Proteus, bancada, ou ambos.

Os 16 GPIOs disponíveis são 4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26 e 27. Sobram
três sem sensor. Se sobrar um número diferente de três, algo não bate e vale investigar antes de
seguir.

GPIOs que ficaram livres: ________________

## 11.2 Inventário de hardware

O que existe, o que queimou e o que falta. A coluna de observação é onde se registra estado
duvidoso, por exemplo um CI que já esquentou demais.

| Componente | Previsto | Em mãos | Comprar | Observação |
|---|---|---|---|---|
| Raspberry Pi 4 | 1 | | | |
| PCF8574 | 3 | | | |
| L293D | 3 | | | |
| Sensor indutivo LJ12A3-4-Z/BX | 3 | | | |
| Chave KW11-3Z-3 | 10 | | | |
| Solenoide | 10 | | | |
| LED vermelho 5 mm | 12 | | | |
| Resistor 180 Ω | 12 | | | |
| Rede resistiva 8x10 kΩ | 3 | | | |
| Fonte 5 V | 1 | | | |
| Fonte para solenoides | 1 | | | |
| Protoboard | | | | |
| Cabos e conectores | | | | |

Itens que a documentação indica comprar, mas que ainda não estavam no projeto original:

| Item | Motivo | Pendência |
|---|---|---|
| MOSFET de canal N para solenoide | Não existe estágio de potência no esquemático | [P2](09-pendencias-e-roadmap.md) |
| Diodo de recuperação rápida | Obrigatório em carga indutiva | [P2](09-pendencias-e-roadmap.md) |
| Fonte dedicada de 24 V ou 48 V | Solenoides não podem usar a fonte lógica | [P2](09-pendencias-e-roadmap.md) |
| Rede de pull-up 10 kΩ extra | Padronizar CF01 a CF08 | [P6](09-pendencias-e-roadmap.md) |
| Conversor de nível, se manter 5 V | Proteger os GPIOs de 3,3 V | [P4](09-pendencias-e-roadmap.md) |
| Capacitores de desacoplamento | Absorver o transiente do pulso | [P2](09-pendencias-e-roadmap.md) |

A decisão sobre o conversor de nível depende de uma escolha do Sprint 1: alimentar os PCF8574 em
3,3 V dispensa o conversor. Vale decidir isso antes de comprar.

## 11.3 Inventário mecânico

| Peça | Existe | Estado | Reimprimir |
|---|---|---|---|
| Estrutura da mesa | | | |
| Bumper 1 | | | |
| Bumper 2 | | | |
| Flipper esquerdo | | | |
| Flipper direito | | | |
| Injetor de bolas | | | |
| Repositor de bolas | | | |
| Bola | | | |

Em "Estado", use íntegra, trincada, quebrada ou faltando.

Arquivos 3D recuperados com a turma anterior: ( ) sim ( ) não ( ) parcial

Se parcial, quais faltam: ________________

Isso é a pendência [P11](09-pendencias-e-roadmap.md). Sem os arquivos, uma peça que quebre precisa
ser reprojetada do zero.

## 11.4 Simulação no Proteus

- ( ) O projeto abre sem erro
- ( ) A biblioteca da Raspberry Pi está instalada
- ( ) A simulação roda e o LED do bit 0 pisca

Versão do Proteus usada: ________________

Se a simulação não abrir, registre o erro aqui, porque isso muda o caminho do Sprint 1:

________________________________________________

## 11.5 Contatos com a turma anterior

| Assunto | Pendência | Status |
|---|---|---|
| Arquivos 3D (stl, 3mf, projeto editável) | [P11](09-pendencias-e-roadmap.md) | |
| Parâmetros de impressão usados | [P11](09-pendencias-e-roadmap.md) | |
| Arquivo LICENSE no repositório | [P8](09-pendencias-e-roadmap.md) | |
| Qual sensor cumpre qual papel na mesa | [P7](09-pendencias-e-roadmap.md) | |
| Quais componentes queimaram nos testes | | |

A última linha vale perguntar de forma direta. O relatório menciona substituição de componentes, e
saber o que queimou e em que circunstância pode poupar repetir o mesmo erro.

## 11.6 Registro do encontro

Anote ao final de cada encontro, em duas ou três linhas.

### 13/08

Feito:

Pendente:

Próxima ação:

### 17/08

Feito:

Pendente:

Próxima ação:

---

Anterior: [10. Plano do semestre](10-plano-do-semestre.md)
