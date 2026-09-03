include <parameters.scad>

// Guia fixa sob o playfield. A superfície superior da mesa está em Z = 0.
module cage(
    face_width = bank_width,
    face_thickness = target_thickness,
    clearance = print_clearance,
    wall = guide_wall,
    height = guide_height
) {
    outer_width = face_width + 2 * (clearance + wall);
    slot_inner_depth = max(face_thickness, target_stem_thickness)
        + 2 * clearance;
    channel_inner_depth = max([
        face_thickness,
        target_stem_thickness,
        target_foot_depth
    ]) + 2 * clearance;
    outer_depth = channel_inner_depth + 2 * wall;
    guide_pad_depth = (channel_inner_depth
        - face_thickness - 2 * clearance) / 2;
    flange_top_z = -playfield_thickness;
    flange_bottom_z = flange_top_z - cage_flange_thickness;
    guide_bottom_z = flange_bottom_z - height;

    difference() {
        union() {
            // Flange de fixação contra a parte inferior da mesa.
            translate([
                -cage_flange_width / 2,
                -cage_flange_depth / 2,
                flange_bottom_z
            ])
                cube([
                    cage_flange_width,
                    cage_flange_depth,
                    cage_flange_thickness
                ]);

            // Trilhos laterais.
            for (x = [
                -face_width / 2 - clearance - wall,
                face_width / 2 + clearance
            ])
                translate([x, -outer_depth / 2, guide_bottom_z])
                    cube([wall, outer_depth, height]);

            // Quadros frontal e traseiro evitam movimento no eixo Y.
            for (y = [
                -channel_inner_depth / 2 - wall,
                channel_inner_depth / 2
            ])
                difference() {
                    translate([-outer_width / 2, y, guide_bottom_z])
                        cube([outer_width, wall, height]);

                    translate([
                        -face_width / 2 + guide_frame_width,
                        y - epsilon,
                        guide_bottom_z + guide_frame_width
                    ])
                        cube([
                            face_width - 2 * guide_frame_width,
                            wall + 2 * epsilon,
                            height - 2 * guide_frame_width
                        ]);
                }

            // Ressaltos próximos às bordas guiam a face sem bloquear a
            // sapata central, que é mais profunda.
            for (x = [
                -face_width / 2 + guide_frame_width / 2,
                face_width / 2 - guide_frame_width / 2
            ]) {
                translate([
                    x - guide_frame_width / 2,
                    -channel_inner_depth / 2,
                    guide_bottom_z
                ])
                    cube([guide_frame_width, guide_pad_depth, height]);

                translate([
                    x - guide_frame_width / 2,
                    face_thickness / 2 + clearance,
                    guide_bottom_z
                ])
                    cube([guide_frame_width, guide_pad_depth, height]);
            }

            // Nervuras entre os canais mantêm os três alvos alinhados,
            // sem interferir com as sapatas de rearme.
            for (index = [0 : targets_per_bank - 2]) {
                divider_x = (index - (targets_per_bank - 2) / 2)
                    * target_pitch;

                translate([
                    divider_x - target_gap / 4,
                    -channel_inner_depth / 2,
                    guide_bottom_z
                ])
                    cube([target_gap / 2, guide_pad_depth, height]);

                translate([
                    divider_x - target_gap / 4,
                    face_thickness / 2 + clearance,
                    guide_bottom_z
                ])
                    cube([target_gap / 2, guide_pad_depth, height]);
            }

            // Travessa inferior removendo carga dos quadros.
            translate([
                -outer_width / 2,
                -outer_depth / 2,
                guide_bottom_z
            ])
                cube([outer_width, outer_depth, wall]);
        }

        // Uma passagem independente para cada alvo.
        for (index = [0 : targets_per_bank - 1])
            translate([
                (index - (targets_per_bank - 1) / 2) * target_pitch
                    - target_width / 2 - clearance,
                -slot_inner_depth / 2,
                flange_bottom_z - epsilon
            ])
                cube([
                    target_width + 2 * clearance,
                    slot_inner_depth,
                    cage_flange_thickness + 2 * epsilon
                ]);

        // Passagem da sapata pela travessa inferior.
        for (index = [0 : targets_per_bank - 1])
            translate([
                (index - (targets_per_bank - 1) / 2) * target_pitch
                    - target_foot_width / 2 - clearance,
                -target_foot_depth / 2 - clearance,
                guide_bottom_z - epsilon
            ])
                cube([
                    target_foot_width + 2 * clearance,
                    target_foot_depth + 2 * clearance,
                    wall + 2 * epsilon
                ]);

        // União horizontal entre a gaiola e as colunas da base.
        for (x = [
            -outer_width / 2 + wall / 2,
            outer_width / 2 - wall / 2
        ])
            translate([x, 0, guide_bottom_z + wall + 1])
                rotate([90, 0, 0])
                    cylinder(
                        d = base_join_hole_diameter,
                        h = outer_depth + 2 * base_post_size,
                        center = true
                    );

        // Quatro parafusos da flange no playfield.
        for (x = [-face_width / 2 - 10, face_width / 2 + 10])
            for (y = [-cage_flange_depth / 2 + 8, cage_flange_depth / 2 - 8])
                translate([x, y, flange_bottom_z - epsilon])
                    cylinder(
                        d = mount_hole_diameter,
                        h = cage_flange_thickness + 2 * epsilon
                    );
    }
}

cage();
