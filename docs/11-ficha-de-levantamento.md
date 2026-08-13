[Voltar ao índice](../README.md)

# 11. Ficha de levantamento

Formulário para preencher nos encontros de 13/08 e 17/08, fechando o Sprint 0. O objetivo é sair
daqui com dados, não com impressões.

Com a nova ordem de trabalho, registrada em
[12. Projeto novo do circuito](12-projeto-novo-do-circuito.md), o Sprint 0 passou a ser preparação
para o protótipo do bumper. As seções de mapeamento de sensores, inventário mecânico, simulação e
contatos saíram desta ficha por ora, e voltam quando os sprints correspondentes chegarem.

Preencha direto neste arquivo e faça commit ao final do encontro.

## 11.1 Inventário de hardware

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

### Material do protótipo do bumper

Esta é a compra que precisa sair deste encontro, porque é o que o Sprint 1 consome. Comprar **uma
unidade de cada** por enquanto: o objetivo é validar um mecanismo antes de replicar.

| Item | Especificação | Motivo | Comprado |
|---|---|---|---|
| Solenoide | a definir, ver abaixo | O atuador do bumper | |
| Fonte dedicada | conforme a solenoide | Não pode dividir com a lógica | |
| MOSFET de canal N | corrente de pico com folga | Estágio de potência | |
| Diodo de recuperação rápida | corrente da bobina | Obrigatório, protege o MOSFET | |
| Resistor de gate | centenas de ohms | Limita o pico no acionamento | |
| Capacitor de desacoplamento | eletrolítico, perto do driver | Absorve o transiente do pulso | |

**A especificação da solenoide é a primeira decisão técnica do semestre**, porque todo o resto do
estágio de potência depende dela. Anote aqui o que for escolhido:

- Tensão: ________________
- Corrente nominal: ________________
- Corrente de pico: ________________
- Curso do núcleo: ________________
- Força: ________________

Solenoide de pinball comercial costuma operar entre 24 V e 48 V, com pulsos de 30 a 50 ms. No
mercado nacional, vale procurar solenoide de trava elétrica ou de máquina de venda, que são mais
fáceis de encontrar.

Não compre ainda o material do circuito completo, como expansores, conversor de nível ou drivers de
luz. Essa lista sai do esquemático, no Sprint 4, e comprar antes é comprar por estimativa.

## 11.2 Medidas necessárias

O protótipo depende destes números.

| Medida | Valor | Observação |
|---|---|---|
| Caixa | 450 x 900 mm | medido em 13/08 |
| Área interna útil do playfield | | descontando as paredes do gabinete |
| Diâmetro da bola | | define o vão dos flippers e a força do bumper |
| Inclinação de trabalho | | entre 6 e 7 graus |

A inclinação e o diâmetro da bola são o que permite calibrar a força do bumper no Sprint 1. Sem
eles, não há como saber se o arremesso faz sentido.

## 11.3 Registro do encontro

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

Anterior: [10. Plano do semestre](10-plano-do-semestre.md) ·
Próximo: [12. Projeto novo do circuito](12-projeto-novo-do-circuito.md)
