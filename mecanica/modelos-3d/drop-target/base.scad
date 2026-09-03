include <parameters.scad>

module rounded_base_plate(width, depth, thickness, radius) {
    hull()
        for (x = [-width / 2 + radius, width / 2 - radius])
            for (y = [-depth / 2 + radius, depth / 2 - radius])
                translate([x, y, 0])
                    cylinder(r = radius, h = thickness);
}

// Base inferior com colunas de união e berço para o microservo.
// A origem fica no centro da face inferior da placa.
module drop_target_base() {
    cage_outer_width = bank_width + 2 * (print_clearance + guide_wall);
    post_x = cage_outer_width / 2 - base_post_size / 2;
    post_y = guide_depth / 2 + base_post_size / 2;

    difference() {
        union() {
            rounded_base_plate(
                base_width,
                base_depth,
                base_thickness,
                base_corner_radius
            );

            // Colunas que conectam a base à parte inferior da gaiola.
            for (x = [-post_x, post_x])
                for (y = [-post_y, post_y])
                    translate([
                        x - base_post_size / 2,
                        y - base_post_size / 2,
                        base_thickness
                    ])
                        cube([
                            base_post_size,
                            base_post_size,
                            base_post_height
                        ]);

            // Duas paredes formam o berço do servo.
            for (y = [
                -servo_depth / 2 - servo_clearance - servo_mount_wall,
                servo_depth / 2 + servo_clearance
            ])
                translate([
                    servo_axis_x - servo_width / 2 - servo_clearance,
                    y,
                    base_thickness
                ])
                    cube([
                        servo_width + 2 * servo_clearance,
                        servo_mount_wall,
                        servo_height
                    ]);
        }

        // Fixação da base à estrutura.
        for (x = [-base_width / 2 + 12, base_width / 2 - 12])
            for (y = [-base_depth / 2 + 10, base_depth / 2 - 10])
                translate([x, y, -epsilon])
                    cylinder(
                        d = mount_hole_diameter,
                        h = base_thickness + 2 * epsilon
                    );

        // Parafusos que prendem as colunas à parte inferior da gaiola.
        for (x = [-post_x, post_x])
            translate([
                x,
                0,
                base_thickness + base_post_height - 4
            ])
                rotate([90, 0, 0])
                    cylinder(
                        d = base_join_hole_diameter,
                        h = 2 * post_y + base_post_size + 2,
                        center = true
                    );

        // Parafusos laterais do servo, atravessando o berço no eixo Y.
        for (x = [servo_axis_x - 7, servo_axis_x + 7])
            translate([x, 0, base_thickness + servo_height - 5])
                rotate([90, 0, 0])
                    cylinder(
                        d = 2.5,
                        h = servo_depth + 2 * servo_clearance
                            + 2 * servo_mount_wall + 2,
                        center = true
                    );
    }
}

drop_target_base();
