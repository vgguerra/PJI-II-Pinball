include <parameters.scad>

// Envelope de referência de um microservo SG90 e do seu braço de plástico.
// Não é peça para imprimir: serve para conferir encaixe e curso.
//
// A origem fica no eixo de saída, sobre a face superior da carcaça, com o
// eixo apontando para +Z.

module servo_sg90(show_horn = true) {
    // Carcaça.
    color("royalblue")
        translate([
            -servo_shaft_from_end,
            -servo_body_width / 2,
            -servo_body_height
        ])
            cube([servo_body_length, servo_body_width, servo_body_height]);

    // Abas de fixação.
    color("royalblue")
        translate([
            -servo_shaft_from_end - (servo_flange_length - servo_body_length) / 2,
            -servo_body_width / 2,
            -servo_body_height + servo_flange_z
        ])
            cube([servo_flange_length, servo_body_width, servo_flange_thickness]);

    // Cubo e eixo estriado.
    color("white") cylinder(d = servo_boss_diameter, h = servo_boss_height);
    color("white")
        translate([0, 0, servo_shaft_height - servo_horn_thickness])
            cylinder(
                d = servo_shaft_diameter,
                h = servo_shaft_height - servo_boss_height
            );

    if (show_horn) servo_horn();
}

// Braço plástico de duas pontas que vem com o servo. Fica encaixado no
// rebaixo do servo_stick e gira junto com ele.
module servo_horn() {
    color("gainsboro")
        translate([0, 0, servo_shaft_height - servo_horn_thickness])
            linear_extrude(height = servo_horn_thickness)
                difference() {
                    hull() {
                        for (y = [-servo_horn_length / 2, servo_horn_length / 2])
                            translate([0, y])
                                circle(d = servo_horn_end_diameter);
                    }
                    circle(d = servo_shaft_diameter);
                }
}

// Microswitch preso na face interna da lateral direita da gaiola, nos dois
// furos que já existem na peça. A origem fica no meio dos dois furos, com o
// corpo avançando para dentro do vão (-X) e o comprimento em Z.
// pressed = true desenha a alavanca acionada pelo pino do alvo.
module microswitch(pressed = false) {
    angle = pressed ? switch_lever_pressed_angle : switch_lever_free_angle;

    color("black")
        translate([-switch_thickness, -switch_width / 2, -switch_length / 2])
            cube([switch_thickness, switch_width, switch_length]);

    // Terminais.
    color("silver")
        for (z = [-6, 0, 6])
            translate([-switch_thickness + 1, switch_width / 2, z - 1.5])
                cube([1.5, 4, 3]);

    // Alavanca articulada na ponta inferior, descendo até o dente do alvo.
    color("silver")
        translate([-switch_thickness / 2, -switch_width / 2, -switch_length / 2])
            rotate([angle, 0, 0])
                translate([-2, -switch_lever_length, -0.5])
                    cube([4, switch_lever_length, 0.6]);
}

servo_sg90();
