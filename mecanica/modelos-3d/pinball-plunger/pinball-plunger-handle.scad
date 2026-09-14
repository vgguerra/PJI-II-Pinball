// Cópia da referência com apenas os ajustes funcionais solicitados.
// Unidades: mm.
$fn = 96;

reference_file = "ref/Pinball_Plunger_Handle_v5.stl";

// Eixo da referência medido no STL.
axis_x = 1.371;
axis_z = -12.360;
front_y = 10.950;

// Haste atual.
rod_diameter = 5.7;
rod_clearance_diameter = 6.0;
rod_bore_depth = 34.0;

// Parafuso de retenção: posição e orientação da referência.
screw_x = 1.371;
screw_y = 17.300;
screw_surface_z = -2.835;
screw_diameter = 4.5;
screw_depth = 7.0;

module reference_body() {
    import(reference_file);
}

// Preenche somente o antigo vazio axial antes de abrir o novo encaixe.
module bore_fill() {
    translate([axis_x, front_y, axis_z])
        rotate([-90, 0, 0])
            cylinder(h = rod_bore_depth, d = 12.7);
}

module new_rod_bore() {
    translate([axis_x, front_y - 0.01, axis_z])
        rotate([-90, 0, 0])
            cylinder(h = rod_bore_depth + 0.02, d = rod_clearance_diameter);
}

module retaining_screw_hole() {
    // Furo cego na base, perpendicular ao eixo da haste, como na referência.
    translate([screw_x, screw_y, screw_surface_z - screw_depth])
        cylinder(h = screw_depth + 0.02, d = screw_diameter);
}

difference() {
    union() {
        reference_body();
        bore_fill();
    }
    new_rod_bore();
    retaining_screw_hole();
}
