# Simulação de um drop target

`drop-target-simulation.scad` monta **um único módulo completo** para validar o
movimento antes de repetir o conjunto três vezes.

O conjunto usa as peças convertidas a partir dos STL de referência:

- `cage.scad`: gaiola;
- `target.scad`: alvo amarelo;
- `servo_stick.scad`: braço plástico que encaixa no eixo do SG90.

O servo e o micro-switch são envelopes de componentes comerciais. A esfera é
um elemento visual de teste: ela toca a cabeça amarela e inicia a queda. O
OpenSCAD não é um solver físico; por isso o ciclo é cinemático, mas foi
montado com a sequência mecânica do protótipo:

```text
esfera atinge o alvo
  -> alvo desce 30 mm
  -> cordão fica frouxo e o micro-switch libera
  -> servo retorna o braço ao ponto de tração
  -> cordão tensiona e o alvo sobe
```

## Como animar

Abra `drop-target-simulation.scad` no OpenSCAD e use **View > Animate**. A
vista padrão é `view_mode = "modulo"`, que mostra o mecanismo sem o tamanho
do playfield atrapalhar a inspeção. Para conferir a instalação sob a mesa,
use:

```scad
view_mode = "mesa";
```

Estados fixos úteis:

```scad
target_state = "levantado";
target_state = "baixado";
target_state = "animado";
```

Os principais ajustes estão no início do arquivo: `simulation_servo_shaft`,
`arm_rest_angle`, `cord_sag`, `impact_time`, `reset_start` e
`reset_duration`. O eixo foi colocado em `[6, -54.5, 31]` no sistema da gaiola:
o corpo do SG90 fica deitado dentro da janela lateral esquerda, o eixo aponta
para cima e o braço entra no vão na horizontal. A ponta fina do braço longo
fica à frente e abaixo do alvo, próxima do ponto de amarração. Ao instalar o
primeiro servo real, esse é o primeiro ponto a conferir.

O alvo sobe pela abertura de aproximadamente 30 x 10 mm do playfield de
450 x 900 mm. O mecanismo completo permanece abaixo do playfield; somente a
cabeça amarela atravessa a abertura.
