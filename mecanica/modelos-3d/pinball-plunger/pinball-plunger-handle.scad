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
rod_diameter = 5.7;
rod_clearance = 0.3;        // folga diametral para impressão FDM
rod_bore_diameter = rod_diameter + rod_clearance;
rod_bore_depth = 34.0;

// Chanfro de entrada: guia a haste e, de quebra, tira da face a borda do furo
// original de 13,21 mm, que é o que sujava a malha na boca do encaixe.
rod_lead_in_diameter = 14.0;
rod_lead_in_depth = 4.0;

// ---------------------------------------------------------------------------
// Parafuso de pressão: M4 sem cabeça, roscado no próprio handle
// ---------------------------------------------------------------------------
// O furo desce do topo da base até dentro do encaixe: a ponta do parafuso
// aperta a haste e é isso que prende as duas peças.
//   3,3 mm -> furo para abrir rosca M4 com macho (padrão)
//   3,6 mm -> se for usar parafuso soberbo, que rosca sozinho no plástico
//   6,0 mm -> se for usar insert térmico M4, que dá rosca de metal
screw_diameter = 3.3;
screw_thread_depth = 9.7;   // material disponível, do topo até o encaixe

// Assento plano no topo, só para o macho (ou a broca) entrar esquadrejado: a
// base é cilíndrica e a ferramenta escorregaria na curva.
screw_seat_diameter = 7.0;
screw_seat_depth = 0.6;

seat_edge_z = axis_z + sqrt(
    pow(base_diameter / 2, 2) - pow(screw_seat_diameter / 2, 2)
);
screw_seat_z = seat_edge_z - screw_seat_depth;

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
// a ponta não encosta nela. O furo original de 3/32" fica dentro deste.
module screw_hole() {
    translate([axis_x, screw_y, axis_z])
        cylinder(h = top_surface_z - axis_z + 1, d = screw_diameter);
}

module screw_seat() {
    translate([axis_x, screw_y, screw_seat_z])
        cylinder(
            h = top_surface_z - screw_seat_z + 1,
            d = screw_seat_diameter
        );
}

difference() {
    union() {
        reference_body();
        original_bore_fill();
    }

    rod_bore();
    screw_hole();
    screw_seat();
}
