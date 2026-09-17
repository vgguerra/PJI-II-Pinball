include <parameters.scad>

// Gaiola convertida de references/cage.stl.
//
// A peça é totalmente prismática no eixo X: tudo são perfis no plano YZ
// extrudados ao longo da largura. Cada perfil abaixo é o contorno medido
// na malha original, então os pontos podem ser editados diretamente.
//
// Orientação idêntica à do STL (deitada, como é impressa):
//   X = largura (40 mm)   Y = altura da estrutura (85 mm)   Z = profundidade

// Extruda um perfil (Y, Z) ao longo de X, de x_start por thickness.
module cage_prism(points, x_start, thickness) {
    translate([x_start, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = thickness)
                polygon(points);
}

// Furo redondo atravessando a lateral, posicionado em (Y, Z).
module cage_hole(center, diameter, x_start, thickness) {
    translate([x_start - epsilon, center[0], center[1]])
        rotate([0, 90, 0])
            cylinder(d = diameter, h = thickness + 2 * epsilon);
}

// Contorno externo da lateral esquerda: a que leva a janela grande.
cage_left_profile = [
    [-86, -6], [-1, -6], [-1, 8], [-11, 8], [-11, 0],
    [-40, 0], [-40, 19.8], [-48.38, 40], [-48.38, 41.5], [-86, 41.5]
];

// Contorno externo da lateral direita, com o recorte que apoia o servo.
cage_right_profile = [
    [-86, -6], [-86, 41.5], [-77, 41.5], [-77, 24.5], [-73, 24.5],
    [-60, 11.5], [-46, 11.5], [-40, 17.5], [-40, 26], [-29, 26],
    [-29, 0], [-11, 0], [-11, 8], [-1, 8], [-1, -6]
];

// Fenda comprida logo acima da base, presente nas duas laterais.
module cage_side_slot_cut(x_start) {
    translate([
        x_start - epsilon,
        cage_side_slot[0][0],
        cage_side_slot[0][1]
    ])
        cube([
            cage_wall + 2 * epsilon,
            cage_side_slot[1][0] - cage_side_slot[0][0],
            cage_side_slot[1][1] - cage_side_slot[0][1]
        ]);
}

module cage_left_wall() {
    difference() {
        cage_prism(cage_left_profile, cage_left_x, cage_wall);

        // Janela lateral.
        translate([
            cage_left_x - epsilon,
            cage_window[0][0],
            cage_window[0][1]
        ])
            cube([
                cage_wall + 2 * epsilon,
                cage_window[1][0] - cage_window[0][0],
                cage_window[1][1] - cage_window[0][1]
            ]);

        cage_hole([-76, 13], cage_screw_diameter, cage_left_x, cage_wall);
        cage_hole([-79, 31], cage_pin_diameter, cage_left_x, cage_wall);
        cage_hole([-51, 31], cage_pin_diameter, cage_left_x, cage_wall);
        cage_side_slot_cut(cage_left_x);
    }
}

module cage_right_wall() {
    difference() {
        cage_prism(cage_right_profile, cage_right_x, cage_wall);

        cage_hole([-76, 13], cage_screw_diameter, cage_right_x, cage_wall);
        cage_hole([-79, 31], cage_pin_diameter, cage_right_x, cage_wall);
        // Furos do microswitch.
        cage_hole([-32, 22], cage_pin_diameter, cage_right_x, cage_wall);
        cage_hole([-32, 12], cage_pin_diameter, cage_right_x, cage_wall);
        cage_side_slot_cut(cage_right_x);
    }
}

// Base e travessa frontal cruzam a largura inteira e unem as duas laterais.
module cage_cross_members() {
    full_width = cage_right_x + cage_wall - cage_left_x;

    cage_prism([
        [cage_base_span[0], cage_base_depth[0]],
        [cage_base_span[1], cage_base_depth[0]],
        [cage_base_span[1], cage_base_depth[1]],
        [cage_base_span[0], cage_base_depth[1]]
    ], cage_left_x, full_width);

    cage_prism([
        [cage_bar_span[0], cage_bar_depth[0]],
        [cage_bar_span[1], cage_bar_depth[0]],
        [cage_bar_span[1], cage_bar_depth[1]],
        [cage_bar_span[0], cage_bar_depth[1]]
    ], cage_left_x, full_width);
}

module cage() {
    cage_left_wall();
    cage_right_wall();
    cage_cross_members();
}

scale(cage_scale) cage();
