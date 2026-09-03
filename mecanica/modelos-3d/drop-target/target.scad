include <parameters.scad>

// Placa arredondada orientada no plano XZ.
module rounded_plate_xz(width, height, depth, radius) {
    hull() {
        for (x = [-width / 2 + radius, width / 2 - radius])
            for (z = [radius, height - radius])
                translate([x, 0, z])
                    rotate([90, 0, 0])
                        cylinder(r = radius, h = depth, center = true);
    }
}

// Alvo móvel. A origem fica no centro da aresta inferior da face.
module target(
    face_width = target_width,
    face_height = target_height,
    face_thickness = target_thickness,
    corner_radius = target_corner_radius,
    stem_width = target_stem_width,
    stem_thickness = target_stem_thickness,
    stem_length = target_stem_length
) {
    difference() {
        union() {
            rounded_plate_xz(
                face_width,
                face_height,
                face_thickness,
                corner_radius
            );

            // Haste central que atravessa a mesa e recebe o rearme.
            translate([-stem_width / 2, -stem_thickness / 2, -stem_length])
                cube([stem_width, stem_thickness, stem_length + 12]);

            // Ressalto traseiro para o futuro mecanismo de retenção.
            translate([-stem_width / 2, stem_thickness / 2, -20])
                cube([stem_width, 2, 5]);

            // Sapata onde o braço do servo empurra o alvo para cima.
            translate([
                -target_foot_width / 2,
                -target_foot_depth / 2,
                -stem_length
            ])
                cube([
                    target_foot_width,
                    target_foot_depth,
                    target_foot_height
                ]);
        }

        // Ponto para elástico ou mola leve de retorno/retensão.
        translate([0, 0, -stem_length + 16])
            rotate([90, 0, 0])
                cylinder(
                    d = target_elastic_hole_diameter,
                    h = stem_thickness + 2,
                    center = true
                );
    }
}

target();
