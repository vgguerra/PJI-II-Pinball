include <parameters.scad>

// Braço plano do servo. A origem coincide com o eixo do servo e o braço
// cresce no sentido negativo de X. Na montagem, ele gira no plano XZ.
module servo_stick(
    length = servo_stick_length,
    width = servo_stick_width,
    tip_width = servo_stick_tip_width,
    thickness = servo_stick_thickness,
    spline_hole = servo_spline_hole_diameter
) {
    difference() {
        hull() {
            cylinder(d = width + 4, h = thickness);

            translate([-length, 0, 0])
                cylinder(d = tip_width, h = thickness);
        }

        translate([0, 0, -epsilon])
            cylinder(d = spline_hole, h = thickness + 2 * epsilon);

        // Furo opcional para rolete ou pino de contato.
        translate([-length, 0, -epsilon])
            cylinder(d = 4.2, h = thickness + 2 * epsilon);
    }
}

servo_stick();
