include <parameters.scad>

// Alvo convertido de references/target.stl.
//
// Orientação idêntica à do STL (deitado, como é impresso):
//   X = largura (30 mm no vão + orelhas)   Y = comprimento   Z = espessura
// A cabeça visível fica em Y de 0 a 30; a haste desce até Y = -50.

// Contorno da haste e da cabeça, medido na base da peça (Z = 0).
target_footprint = [
    [0, target_head_height],
    [target_width, target_head_height],
    [target_width, target_tab_span[1]],
    [target_width + target_tab_width, target_tab_span[1]],
    [target_width + target_tab_width, target_tab_span[0]],
    [25.4, -50], [24, -48.6], [24, -48.5],
    [21.5, -45], [21.5, -42], [15.5, -42], [15.5, -44.59],
    [10.79, -49.29], [10, -50],
    [-target_tab_width, target_tab_span[0]],
    [-target_tab_width, target_tab_span[1]],
    [0, target_tab_span[1]]
];

// Base do pino do microswitch, com o alargamento chanfrado.
target_pin_base = [
    [target_pin_x[1], -40], [22, -40], [22, -45.7],
    [24, -48.6], [24, -48.5], [target_pin_x[1], -48.5]
];

// Placa fina usada nas transições em hull().
module target_layer(points, z) {
    translate([0, 0, z])
        linear_extrude(height = epsilon)
            polygon(points);
}

module target_knot_block() {
    hull() {
        target_layer([
            [target_knot_x[0], target_knot_base_y[0]],
            [target_knot_x[1], target_knot_base_y[0]],
            [target_knot_x[1], target_knot_base_y[1]],
            [target_knot_x[0], target_knot_base_y[1]]
        ], target_knot_z[0]);

        target_layer([
            [target_knot_x[0], target_knot_top_y[0]],
            [target_knot_x[1], target_knot_top_y[0]],
            [target_knot_x[1], target_knot_top_y[1]],
            [target_knot_x[0], target_knot_top_y[1]]
        ], target_knot_z[1] - epsilon);
    }
}

module target_pin() {
    // Alargamento de 45° na saída da haste.
    hull() {
        target_layer(target_pin_base, target_plate_thickness);
        target_layer([
            [target_pin_x[0], -40], [target_pin_x[1], -40],
            [target_pin_x[1], -46.69], [target_pin_x[0], -46.69]
        ], 6 - epsilon);
    }

    // Corpo do pino, com a face inclinada que sobe até o topo.
    hull() {
        target_layer([
            [target_pin_x[0], -40], [target_pin_x[1], -40],
            [target_pin_x[1], -46.69], [target_pin_x[0], -46.69]
        ], 6 - epsilon);
        target_layer([
            [target_pin_x[0], -40], [target_pin_x[1], -40],
            [target_pin_x[1], -44], [target_pin_x[0], -44]
        ], target_pin_top_z - epsilon);
    }
}

module target() {
    difference() {
        union() {
            linear_extrude(height = target_plate_thickness)
                polygon(target_footprint);

            // Cabeça, mais espessa que a haste.
            linear_extrude(height = target_head_thickness)
                square([target_width, target_head_height]);

            target_knot_block();
            target_pin();
        }

        // Furo do fio que liga o alvo ao braço do servo.
        translate([
            target_knot_x[0] - epsilon,
            target_knot_hole_center[0],
            target_knot_hole_center[1]
        ])
            rotate([0, 90, 0])
                cylinder(
                    d = target_knot_hole_diameter,
                    h = target_knot_x[1] - target_knot_x[0] + 2 * epsilon
                );

        // Saída de molde da face frontal: recua target_head_draft ao longo
        // da espessura da cabeça.
        translate([0, target_head_height, 0])
            rotate([atan(target_head_draft / target_head_thickness), 0, 0])
                translate([-10, 0, -20])
                    cube([target_width + 20, 20, 60]);
    }
}

scale(target_scale) target();
