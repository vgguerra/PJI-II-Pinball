// Handle do plunger: corpo externo da referência com o encaixe interno
// refeito para a haste e o parafuso que vamos usar.
// Unidades: mm.
$fn = 96;
eps = 0.05;

reference_file = "ref/Pinball_Plunger_Handle_v5.stl";

// ---------------------------------------------------------------------------
// Medidas tiradas da malha de referência
// ---------------------------------------------------------------------------
// A referência é um desenho em polegadas: base de 1", pescoço de 3/4",
// envelope de 1 1/4", furo axial de 0,52" e furo de pino de 3/32".
axis_x = 1.371;             // eixo da haste
axis_z = -12.360;
front_y = 10.950;           // face de entrada da haste
base_diameter = 25.40;      // diâmetro externo da base
ref_bore_diameter = 13.21;  // furo axial original
ref_bore_end_y = 23.75;     // onde o furo original termina
screw_y = 17.300;           // centro do furo do parafuso, 6,35 mm da face

// Topo da base no plano do eixo: é por onde o parafuso entra.
top_surface_z = axis_z + base_diameter / 2;

// ---------------------------------------------------------------------------
// Haste
// ---------------------------------------------------------------------------
// Haste medida na peça real: 6,1 mm. A folga é generosa de propósito, porque
// furo em FDM sai menor que o nominal e a primeira impressão, com 6,0, não
// aceitou a haste.
rod_diameter = 6.1;
rod_clearance = 0.9;        // folga diametral, deixa o furo em 7,0 mm
rod_bore_diameter = rod_diameter + rod_clearance;
rod_bore_depth = 34.0;

// Chanfro de entrada: guia a haste e, de quebra, tira da face a borda do furo
// original de 13,21 mm, que é o que sujava a malha na boca do encaixe.
rod_lead_in_diameter = 14.0;
rod_lead_in_depth = 4.0;

// ---------------------------------------------------------------------------
// Parafuso de pressão
// ---------------------------------------------------------------------------
// O furo desce do topo da base até dentro do encaixe: a ponta do parafuso
// aperta a haste e é isso que prende as duas peças.
//
// O furo é cônico: entra com 4,2 mm no assento e fecha até 3,8 mm lá embaixo,
// junto ao encaixe da haste. O M4 começa a descer solto e vai apertando à
// medida que avança, até morder o plástico nas últimas voltas. Assim a partida
// é fácil, o esforço é progressivo e no fim existe aperto de verdade.
//
// A conicidade é suave: 0,4 mm em 7,8 mm de profundidade, pouco menos de 3° de
// ângulo incluso. O parafuso cruza a marca dos 4,0 mm na metade do caminho, e é
// dali para baixo que ele começa a abrir rosca.
screw_entry_diameter = 4.2;  // no fundo do assento
screw_end_diameter = 3.8;    // junto ao encaixe da haste

// Assento plano no topo. A base é cilíndrica, então sem ele a cabeça do
// parafuso apoiaria torta e a ponta escorregaria ao começar a entrar. Os 9 mm
// cobrem a cabeça de 8 mm de um M4 cabeça panela; com parafuso sem cabeça o
// assento só serve de guia.
screw_seat_diameter = 9.0;
screw_seat_depth = 0.6;

seat_edge_z = axis_z + sqrt(
    pow(base_diameter / 2, 2) - pow(screw_seat_diameter / 2, 2)
);
screw_seat_z = seat_edge_z - screw_seat_depth;

// Cotas derivadas. A haste é medida no pior caso: empurrada pelo parafuso, ela
// desce até o fundo do encaixe, e é dali que a ponta precisa alcançá-la.
bore_top_z = axis_z + rod_bore_diameter / 2;
rod_top_z = axis_z - rod_bore_diameter / 2 + rod_diameter;

// ---------------------------------------------------------------------------
// Peça
// ---------------------------------------------------------------------------
module reference_body() {
    import(reference_file);
}

// Tapa o furo axial original de 13,21 mm antes de abrir o encaixe novo. O
// cilindro é um pouco maior que o furo, para não sobrar casca entre os dois, e
// avança além do fundo do furo, onde já é material maciço.
module original_bore_fill() {
    translate([axis_x, front_y, axis_z])
        rotate([-90, 0, 0])
            cylinder(
                h = ref_bore_end_y - front_y + 1,
                d = ref_bore_diameter + 0.4
            );
}

// Encaixe da haste, com o chanfro de entrada.
module rod_bore() {
    translate([axis_x, front_y - eps, axis_z])
        rotate([-90, 0, 0]) {
            cylinder(h = rod_bore_depth + eps, d = rod_bore_diameter);

            cylinder(
                h = rod_lead_in_depth + eps,
                d1 = rod_lead_in_diameter,
                d2 = rod_bore_diameter
            );
        }
}

// Furo do parafuso: desce do topo da base e entra no encaixe da haste, senão
// a ponta não alcança. O furo original de 3/32" fica dentro deste.
module screw_hole() {
    // O corte passa do assento e do encaixe, então os diâmetros das pontas são
    // extrapolados para manter a conicidade exata entre os dois.
    taper = (screw_entry_diameter - screw_end_diameter)
        / (screw_seat_z - bore_top_z);
    cut_bottom_z = bore_top_z - 1;
    cut_top_z = top_surface_z + 1;

    translate([axis_x, screw_y, cut_bottom_z])
        cylinder(
            h = cut_top_z - cut_bottom_z,
            d1 = screw_end_diameter + (cut_bottom_z - bore_top_z) * taper,
            d2 = screw_end_diameter + (cut_top_z - bore_top_z) * taper
        );
}

module screw_seat() {
    translate([axis_x, screw_y, screw_seat_z])
        cylinder(
            h = top_surface_z - screw_seat_z + 1,
            d = screw_seat_diameter
        );
}

// Conferência das medidas do conjunto, impressa ao renderizar.
echo(str(
    "furo conico: ", screw_entry_diameter, " -> ", screw_end_diameter,
    " mm em ", screw_seat_z - bore_top_z,
    " mm | do assento ate a haste: ", screw_seat_z - rod_top_z,
    " mm (use parafuso mais longo que isso)"
));

difference() {
    union() {
        reference_body();
        original_bore_fill();
    }

    rod_bore();
    screw_hole();
    screw_seat();
}
