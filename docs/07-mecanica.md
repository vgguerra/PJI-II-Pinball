[Voltar ao índice](../README.md)

# 07. Mecânica

O histórico deste documento vem do relatório da etapa anterior,
[`Projeto_Integrador_II___Pinball.pdf`](../upstream/pinball/Projeto_Integrador_II___Pinball.pdf).
O novo modelo paramétrico do mecanismo do flipper está versionado em
[`mecanica/modelos-3d`](../mecanica/modelos-3d/README.md). Os arquivos usados para fabricar as demais
peças originais ainda não foram recuperados, conforme registrado em
[P11](09-pendencias-e-roadmap.md).

## 7.1 Processo de projeto

O trabalho seguiu quatro etapas.

A concepção começou no **Tinkercad**, com um modelo tridimensional completo do pinball. O objetivo
era visualizar a disposição interna dos elementos e definir proporções antes de detalhar qualquer
peça.

O detalhamento passou para o **AutoCAD**, para o projeto da estrutura da mesa. A escolha se justifica
pela precisão dimensional maior, e as medidas foram tiradas de um modelo físico de pinball já
existente, o que ajudou a acertar proporções que são difíceis de estimar do zero.

Os obstáculos internos voltaram ao Tinkercad para modelagem individual.

A fabricação foi por **impressão 3D**, com ciclos de impressão, teste, ajuste e reimpressão.

## 7.2 Peças e origens

| Peça | Origem | Situação |
|---|---|---|
| Estrutura da mesa | Projeto próprio no AutoCAD, medidas de um pinball físico | Projetada |
| Bumpers | Adaptação de [modelo do Cults3D](https://cults3d.com/) | Impressos |
| Flippers, primeira tentativa | Modelo de referência do Cults3D | Descartada |
| Flippers, versão final | Modelagem a partir de vídeos do canal Daniele Tartaglia | Impressos |
| Injetor, primeira versão | Modelo do Thingiverse | Descartada, desempenho insuficiente |
| Injetor, segunda versão | Outro modelo do Thingiverse | Impresso, funcionamento adequado |
| Repositor de bolas | Vídeos do canal Daniele Tartaglia | Impresso |

Para os flippers e o repositor de bolas, a equipe usou a ferramenta **Hitem3D** (`hitem3d.ai`), que
gera modelos 3D a partir de imagens. A abordagem foi capturar imagens dos projetos mostrados nos
vídeos de referência e converter em malha aproveitável.

O relatório cita as referências por nome e link, mas não versiona os arquivos `.stl` ou `.3mf`
resultantes. Recuperar esses arquivos com os autores originais é uma tarefa de continuidade
importante, porque reimprimir uma peça que quebre depende deles.

## 7.3 Função de cada peça

**Estrutura da mesa.** A base inclinada onde tudo acontece. A inclinação, tipicamente entre 6 e 7
graus nas máquinas comerciais, é o que faz a bola descer em direção aos flippers e define o ritmo do
jogo. Uma inclinação pequena deixa o jogo lento, e uma grande torna a bola difícil de controlar.

**Bumpers.** Obstáculos circulares que repelem a bola ativamente. Quando a bola encosta, um contato
mecânico fecha, o software detecta e aciona a solenoide do bumper, que empurra a bola de volta ao
campo. São a principal fonte de pontos e de movimento imprevisível.

**Flippers.** Os batedores acionados pelo jogador. Cada um é uma pá girando em torno de um eixo,
movida por uma solenoide. O jogador aperta o botão, a solenoide puxa, a pá gira e rebate a bola. É o
único elemento sob controle direto do jogador, e por isso o mais sensível a atraso de resposta.

**Injetor de bolas.** Coloca a bola em jogo no começo de cada rodada. Uma solenoide empurra a bola
pela rampa lateral até o campo. A primeira versão foi descartada por não conseguir empurrar a bola
com força suficiente, e a segunda funcionou.

**Repositor de bolas.** Recolhe a bola que cai entre os flippers e a devolve ao ponto de injeção,
para a rodada seguinte. Sem essa peça, seria necessário abrir a mesa para recuperar a bola a cada
bola perdida.

## 7.4 Dificuldades relatadas

O relatório é direto sobre os problemas enfrentados na parte mecânica, e vale registrá-los porque
são exatamente os que a próxima turma vai reencontrar.

Diversas peças precisaram ser refeitas por incompatibilidade dimensional. Um modelo baixado de
repositório aberto foi feito para outra mesa, com outras medidas, e o encaixe raramente sai correto
na primeira tentativa.

Houve falhas de encaixe entre peças que individualmente estavam corretas. Tolerância de impressão 3D
é da ordem de alguns décimos de milímetro, e furos e pinos precisam ser projetados com folga
proposital.

Peças quebraram durante os testes. Um flipper recebe impacto repetido, e uma peça impressa em PLA com
preenchimento baixo e camadas na direção errada quebra rápido. Orientação de impressão e
preenchimento importam mais aqui do que em peças estáticas.

A recalibração de impressora e a reimpressão consumiram tempo considerável, o que junto com o prazo
curto e a equipe de duas pessoas explica boa parte do atraso do cronograma.

## 7.5 Recomendações para a continuidade

Continuar versionando os modelos em `mecanica/modelos-3d/`. Incluir tanto os arquivos exportados
(`.stl` ou `.3mf`) quanto os arquivos de projeto editáveis. Um modelo perdido significa reprojetar
a peça.

Registrar os parâmetros de impressão que funcionaram: material, altura de camada, preenchimento e
orientação. Sem isso, cada reimpressão é uma nova rodada de tentativa e erro.

Para as peças que sofrem impacto, principalmente flippers, considerar PETG em vez de PLA. O PETG é
mais tenaz e tolera melhor impacto repetido, ao custo de ser um pouco mais difícil de imprimir.

Fotografar a montagem em cada etapa. É o registro mais barato e mais útil que existe para quem for
remontar depois, e resolve dúvidas que nenhum desenho responde.

Medir e anotar a inclinação final da mesa. Ela afeta diretamente a jogabilidade e, se a mesa precisar
ser desmontada, é a primeira coisa que se perde.

---

Anterior: [06. Software](06-software.md) ·
Próximo: [08. Simulação no Proteus](08-simulacao-proteus.md)
