include <parameters.scad>
use <target.scad>
use <cage.scad>
use <servo_stick.scad>
use <base.scad>

// "montagem_dupla", "unidade", "explodida", "alvo", "gaiola",
// "braco_servo" ou "base".
view_mode = "montagem_dupla";

// "elevado", "baixado", "animado" ou "individual". No último caso,
// altere target_states em parameters.scad para controlar cada alvo.
target_state = "elevado";

show_playfield = true;
show_hardware = true;

animation_factor = (1 - cos($t * 360)) / 2;

function drop_for_state(state) =
    state == "baixado" ? target_drop_travel :
    state == "animado" ? target_drop_travel * animation_factor :
    0;

function arm_angle_for_state(state) =
    state == "baixado" ? servo_angle_dropped :
    state == "animado"
        ? servo_angle_raised
            + (servo_angle_dropped - servo_angle_raised) * animation_factor
        : servo_angle_raised;

function state_for_target(bank_state, index) =
    bank_state == "individual" ? target_states[index] : bank_state;

function angle_for_bank(index, count) =
    count == 2
        ? (index == 0 ? -target_bank_angle : target_bank_angle)
        : 0;

module servo_mockup() {
    color("dimgray", 0.75)
        translate([
            servo_axis_x - servo_width / 2,
            -servo_depth / 2,
            base_z + base_thickness
        ])
            cube([servo_width, servo_depth, servo_height]);

    color("silver")
        translate([servo_axis_x, 0, servo_axis_z])
            rotate([90, 0, 0])
                cylinder(d = 5, h = servo_depth + 5, center = true);
}

module microswitch_mockup() {
    color("black", 0.75)
        translate([
            0,
            guide_depth / 2 + 2,
            -playfield_thickness - 28
        ])
            cube([20, 7, 10], center = true);
}

module target_unit(index = 0, state = target_state, exploded = 0) {
    drop = drop_for_state(state);
    target_x = (index - (targets_per_bank - 1) / 2) * target_pitch;

    color("firebrick")
        translate([
            target_x,
            -exploded,
            target_bottom_above_playfield - drop
        ])
            target();

    if (show_hardware && exploded == 0)
        translate([target_x, 0, 0])
            microswitch_mockup();
}

module drop_target_bank(state = target_state, exploded = 0) {
    arm_angle = arm_angle_for_state(state);

    for (index = [0 : targets_per_bank - 1])
        target_unit(index, state_for_target(state, index), exploded);

    color("royalblue")
        translate([0, exploded, 0])
            cage();

    color("slategray")
        translate([0, 0, base_z - exploded])
            drop_target_base();

    color("orange")
        translate([servo_axis_x, 0, servo_axis_z])
            rotate([0, arm_angle, 0])
                rotate([90, 0, 0])
                    servo_stick();

    if (show_hardware && exploded == 0)
        servo_mockup();
}

module playfield_preview(count = bank_count) {
    slot_depth = max(target_thickness, target_stem_thickness)
        + 2 * print_clearance;

    color("burlywood", 0.35)
        difference() {
            translate([
                -playfield_width / 2,
                -playfield_preview_depth / 2,
                -playfield_thickness
            ])
                cube([
                    playfield_width,
                    playfield_preview_depth,
                    playfield_thickness
                ]);

            for (index = [0 : count - 1]) {
                x = (index - (count - 1) / 2) * bank_spacing;
                translate([x, 0, -playfield_thickness - epsilon])
                    rotate([0, 0, angle_for_bank(index, count)])
                        for (target_index = [0 : targets_per_bank - 1])
                            translate([
                                (target_index - (targets_per_bank - 1) / 2)
                                    * target_pitch
                                    - target_width / 2 - print_clearance,
                                -slot_depth / 2,
                                0
                            ])
                                cube([
                                    target_width + 2 * print_clearance,
                                    slot_depth,
                                    playfield_thickness + 2 * epsilon
                                ]);
            }
        }
}

module table_layout(count = bank_count, state = target_state) {
    if (show_playfield)
        playfield_preview(count);

    for (index = [0 : count - 1])
        translate([
            (index - (count - 1) / 2) * bank_spacing,
            0,
            0
        ])
            rotate([0, 0, angle_for_bank(index, count)])
                drop_target_bank(state);
}

if (view_mode == "montagem_dupla") {
    table_layout(bank_count);
} else if (view_mode == "unidade") {
    drop_target_bank();
} else if (view_mode == "explodida") {
    drop_target_bank("elevado", 18);
} else if (view_mode == "alvo") {
    target();
} else if (view_mode == "gaiola") {
    cage();
} else if (view_mode == "braco_servo") {
    servo_stick();
} else if (view_mode == "base") {
    drop_target_base();
}
