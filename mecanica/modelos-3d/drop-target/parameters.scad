// Parâmetros compartilhados do drop target (milímetros).

$fn = 64;
epsilon = 0.01;

// Banco visível: os 120 mm são divididos entre três alvos independentes.
bank_width = 120;
targets_per_bank = 3;
target_gap = 4;
target_width = (bank_width - (targets_per_bank - 1) * target_gap)
    / targets_per_bank;
target_pitch = target_width + target_gap;
target_height = 60;
target_thickness = 6;
target_corner_radius = 4;
target_bottom_above_playfield = 3;

// Movimento e haste
target_drop_travel = target_height + 4;
target_stem_width = 18;
target_stem_thickness = 8;
target_stem_length = 55;
target_foot_width = 32;
target_foot_depth = 12;
target_foot_height = 5;
target_elastic_hole_diameter = 3.2;

// Mesa e guia
playfield_width = 450;
playfield_length = 900;
playfield_thickness = 10;
playfield_preview_depth = 180;
print_clearance = 0.5;
guide_wall = 4;
guide_frame_width = 12;
guide_height = target_height + 8;
guide_depth = max([
    target_thickness,
    target_stem_thickness,
    target_foot_depth
]) + 2 * print_clearance + 2 * guide_wall;
cage_flange_width = bank_width + 30;
cage_flange_depth = 38;
cage_flange_thickness = 4;
mount_hole_diameter = 4.2;
base_join_hole_diameter = 3.2;

// Base inferior
base_width = bank_width + 60;
base_depth = 55;
base_thickness = 5;
base_corner_radius = 5;
base_z = -135;
base_post_size = 8;
base_post_height = 57;

// Microservo no envelope aproximado de um Tower Pro SG90
servo_width = 24;
servo_depth = 13;
servo_height = 29;
servo_clearance = 0.6;
servo_mount_wall = 3;
servo_axis_x = bank_width / 2 + 18;
servo_axis_z = base_z + base_thickness + servo_height + 1;

// Braço de rearme
servo_stick_length = 145;
servo_stick_width = 12;
servo_stick_tip_width = 20;
servo_stick_thickness = 4;
servo_spline_hole_diameter = 4.8;
servo_angle_dropped = -10;
servo_angle_raised = 32;

// Distribuição dos dois bancos no playfield.
bank_count = 2;
bank_spacing = 210;
target_bank_angle = 15;

// Usado quando target_state = "individual" na montagem principal.
target_states = ["elevado", "elevado", "elevado"];
