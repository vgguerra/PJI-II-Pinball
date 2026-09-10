// Simulação cinemática de UM drop target completo.
//
// A simulação usa as três geometrias impressas de referência:
//   - cage.scad
//   - target.scad
//   - servo_stick.scad
//
// O conjunto é montado na mesma orientação da foto: a gaiola fica sob o
// playfield, o SG90 fica baixo e próximo da frente, e o braço plástico gira
// no eixo do servo. O cordão não é uma barra rígida: fica tenso para levantar
// o alvo e ganha folga quando uma esfera o derruba.

include <../parameters.scad>
use <../cage.scad>
use <../target.scad>
use <../servo_stick.scad>
use <../servo_sg90.scad>

// ---------------------------------------------------------------------------
// Controles da simulação
// ---------------------------------------------------------------------------

// "modulo" mostra um módulo grande e é a vista recomendada para testar o
// movimento. "mesa" mostra o mesmo módulo instalado sob o playfield.
view_mode = "modulo";

// "animado" usa $t do OpenSCAD. Também é possível forçar "levantado" ou
// "baixado" para conferir as duas posições sem iniciar a animação.
target_state = "animado";

show_playfield = true;
show_ball = true;
show_switch = true;
show_cord = true;

// O intervalo total é normalizado para $t entre 0 e 1.
impact_time = 0.28;
drop_duration = 0.10;
release_duration = 0.08;
reset_start = 0.64;
reset_duration = 0.24;

// O braço do servo é a peça laranja da foto. O ângulo 0° deixa a ponta longa
// voltada para o ponto de amarração do alvo levantado.
arm_lift_angle = -110;
arm_rest_angle = -35;

// Posição do eixo do SG90 no sistema local da gaiola deitada.
//
// O servo fica deitado no vão da lateral esquerda. A janela existente na
// cage.scad ocupa aproximadamente X=-5..0, Y=-77..-53 e Z=24.5..37.5.
// Depois da rotação abaixo, o corpo do SG90 ocupa justamente essa região:
// baixo da gaiola, dentro do vão lateral, sem ficar projetado para fora.
//
// O eixo aponta para cima (eixo local +Y). O braço fica no plano horizontal
// XZ, "caído" como na foto, e a sua ponta fina fica à frente do alvo.
// A carcaça do SG90 tem 22,5 mm de altura nessa orientação. Com o eixo em
// Y=-54,5, ela ocupa Y=-77..-54,5 e fica dentro do recorte lateral
// Y=-77..-53 da gaiola, com uma pequena folga.
simulation_servo_shaft = [1, -65, 31];

// Comprimento visual do cordão durante a queda. Não altera a geometria do
// alvo; só controla a folga desenhada quando o cordão deixa de estar tenso.
cord_sag = 12;
cord_diameter = 1.1;

// Esfera de teste: ela vem pela frente da gaiola e toca o centro da cabeça
// amarela antes do alvo iniciar a queda.
impact_ball_radius = 6.35;
impact_ball_start_z = -37;
impact_ball_end_z = -8;
impact_ball_travel_time = 0.18;

// ---------------------------------------------------------------------------
// Funções matemáticas e estados
// ---------------------------------------------------------------------------

function clamp01(value) = min(1, max(0, value));
function smooth(value) = value * value * (3 - 2 * value);
function mix(a, b, amount) = a + (b - a) * amount;

function target_lift_animation() =
    $t < impact_time ? 1 :
    $t < impact_time + drop_duration ?
        1 - smooth(clamp01(($t - impact_time) / drop_duration)) :
    $t < reset_start ? 0 :
        smooth(clamp01(($t - reset_start) / reset_duration));

function target_lift() =
    target_state == "levantado" ? 1 :
    target_state == "baixado" ? 0 :
    target_lift_animation();

function target_y_offset() =
    target_drop_offset + target_lift() * target_travel;

function reset_fraction() =
    smooth(clamp01(($t - reset_start) / reset_duration));

function release_fraction() =
    smooth(clamp01(
        ($t - impact_time - drop_duration) / release_duration
    ));

function servo_angle_animation() =
    $t < impact_time + drop_duration ? arm_lift_angle :
    $t < reset_start ?
        mix(arm_lift_angle, arm_rest_angle, release_fraction()) :
        mix(arm_rest_angle, arm_lift_angle, reset_fraction());

function servo_angle() =
    target_state == "levantado" ? arm_lift_angle :
    target_state == "baixado" ? arm_rest_angle :
    servo_angle_animation();

function target_knot_point() = [
    (target_knot_x[0] + target_knot_x[1]) / 2,
    target_y_offset() + target_knot_hole_center[0],
    target_depth_offset + target_knot_hole_center[1]
];

// O ponto de amarração usa o furo existente do servo_stick.stl. O braço
// original tem a ponta comprida em aproximadamente [76, 42], em relação ao
// cubo [75, 0].
function servo_stick_tie_local(angle) = let (
    dx = servo_stick_tie[0] - servo_stick_hub[0],
    dy = servo_stick_tie[1] - servo_stick_hub[1],
    radians = angle * PI / 180,
    // Primeiro gira no plano nativo do servo_stick (XY). Depois esse plano
    // é colocado na horizontal, perpendicularmente ao eixo vertical do
    // servo. A coordenada nativa X continua X, Y vira -Z e Z vira Y.
    native_x = dx * cos(radians) - dy * sin(radians),
    native_y = dx * sin(radians) + dy * cos(radians),
    native_z = servo_shaft_height - servo_horn_thickness,
    x = native_x,
    y = native_z,
    z = -native_y
) [
    simulation_servo_shaft[0] + x,
    simulation_servo_shaft[1] + y,
    simulation_servo_shaft[2] + z
];

// ---------------------------------------------------------------------------
// Peças da simulação no sistema local da gaiola deitada
// ---------------------------------------------------------------------------

module cord_segment(a, b, diameter = cord_diameter) {
    color("palegoldenrod")
        hull() {
            translate(a) sphere(d = diameter);
            translate(b) sphere(d = diameter);
        }
}

module return_cord() {
    knot = target_knot_point();
    tie = servo_stick_tie_local(servo_angle());
    // Com o alvo levantado, a linha é reta e fica tensionada. Com o alvo
    // baixado, o ponto intermediário cria a folga natural do barbante.
    midpoint = [
        (knot[0] + tie[0]) / 2,
        min(knot[1], tie[1]) - cord_sag,
        (knot[2] + tie[2]) / 2
    ];

    if (show_cord)
        if (target_lift() > 0.72)
            cord_segment(knot, tie);
        else {
            cord_segment(knot, midpoint);
            cord_segment(midpoint, tie);
        }
}

module servo_and_arm() {
    // Servo encaixado na parede esquerda.
    // O eixo aponta para dentro da gaiola (+X).
    translate(simulation_servo_shaft)
        rotate([0, 90, 0])
            servo_sg90(show_horn = false);

    color("darkorange")
    translate(simulation_servo_shaft)
        rotate([0, 90, 0])
            rotate([0, 0, servo_angle()])
                translate([
                    -servo_stick_hub[0],
                    -servo_stick_hub[1],
                    servo_shaft_height - servo_horn_thickness
                ])
                    mirror([0, 0, 1])
                        servo_stick();
}

module simulated_microswitch(pressed = false) {
    // O corpo fica preso à lateral direita, como no protótipo, e invade só
    // alguns milímetros o vão para alcançar o pino do alvo.
    color("black")
        translate([28.5, -49, -8])
            cube([7, 18, 10]);

    // Furos/terminais apenas como referência visual do componente comercial.
    color("silver")
        for (y = [-45, -39])
            translate([30, y, 2.1])
                rotate([0, 90, 0])
                    cylinder(d = 2, h = 5);

    // Lâmina metálica apontada para o pino inferior do alvo.
    actuator_end = pressed ? [24, -42, 1.2] : [24, -38, 1.2];
    color("silver")
        hull() {
            translate([30, -35, 1.2]) sphere(d = 2.2);
            translate(actuator_end) sphere(d = 2.2);
        }
}

module impact_ball() {
    if (show_ball && target_state == "animado") {
        ball_phase = clamp01(
            ($t - (impact_time - impact_ball_travel_time))
                / impact_ball_travel_time
        );
        if ($t <= impact_time + drop_duration)
            color("silver")
                translate([
                    target_width / 2,
                    target_y_offset() + target_head_height / 2,
                    mix(impact_ball_start_z, impact_ball_end_z, ball_phase)
                ])
                    sphere(d = impact_ball_radius * 2);
    }
}

module simulation_local() {
    // Uma gaiola e um único alvo, usando as geometrias paramétricas convertidas
    // dos STL originais.
    color("dimgray") cage();

    color("gold")
        translate([0, target_y_offset(), target_depth_offset])
            target();

    servo_and_arm();
    return_cord();

    if (show_switch)
        simulated_microswitch(target_lift() > 0.5);

    impact_ball();
}

// ---------------------------------------------------------------------------
// Montagem em pé e playfield
// ---------------------------------------------------------------------------

// A gaiola original é deitada. Esta transformação torna o eixo Y a altura e
// coloca o topo da gaiola no plano z = origin[2].
module standing_simulation(origin = [0, 0, 0]) {
    translate([origin[0], origin[1], origin[2] + 1])
        rotate([90, 0, 0])
            simulation_local();
}

playfield_opening_width = target_width + 2 * playfield_slot_clearance;
playfield_opening_depth = 10;
playfield_opening_center_y = -target_depth_offset
    - target_head_thickness / 2;

module playfield_opening() {
    translate([
        reference_module_target_left - playfield_slot_clearance,
        reference_module_origin_y + playfield_opening_center_y
            - playfield_opening_depth / 2,
        -playfield_thickness - epsilon
    ])
        cube([
            playfield_opening_width,
            playfield_opening_depth,
            playfield_thickness + 2 * epsilon
        ]);
}

module playfield_with_simulation() {
    difference() {
        color("burlywood", 0.35)
            translate([0, 0, -playfield_thickness])
                cube([
                    playfield_width,
                    playfield_length,
                    playfield_thickness
                ]);
        playfield_opening();
    }

    standing_simulation([
        reference_module_target_left,
        reference_module_origin_y,
        -playfield_thickness
    ]);
}

if (view_mode == "modulo") {
    standing_simulation();
} else if (view_mode == "mesa") {
    playfield_with_simulation();
} else if (view_mode == "gaiola") {
    color("dimgray") cage();
} else if (view_mode == "alvo") {
    color("gold") target();
}
