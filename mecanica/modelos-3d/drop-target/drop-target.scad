include <parameters.scad>
use <cage.scad>
use <target.scad>

// Validação geométrica do drop target ORIGINAL.
//
// Esta etapa intentionally mostra somente UMA gaiola e UM alvo. O servo, a
// alavanca e o micro-switch entram depois que o encaixe dos STL e a abertura
// do playfield forem aprovados.
//
// Coordenadas dos STL antes da montagem:
//   X = largura da gaiola
//   Y = comprimento/altura
//   Z = profundidade
//
// Na montagem, a unidade gira 90 graus em X. O topo da gaiola fica alinhado à
// face inferior do playfield e a cabeça do alvo sobe pela abertura.

// "unidade"  : uma gaiola e um alvo, fora do playfield
// "playfield": playfield 450 x 900 com UMA abertura e a unidade instalada
// "abertura" : somente o playfield e a abertura nominal de 30 x 10 mm
// "gaiola"   : peça de referência isolada
// "alvo"     : peça de referência isolada
view_mode = "playfield";

// "levantado", "baixado" ou "animado".
target_state = "levantado";

show_playfield = true;
show_target = true;

// Escala de validação. 1.0 reproduz os STL originais; 1.15 e 1.20 são apenas
// alternativas para avaliar se o alvo precisa ficar mais visível no pinball.
reference_scale = 1.0;

function clamp01(v) = min(1, max(0, v));
function smooth(v) = v * v * (3 - 2 * v);

function target_lift() =
    target_state == "levantado" ? 1 :
    target_state == "baixado" ? 0 :
    let (
        queda = 1 - smooth(clamp01(
            ($t - target_drop_time) / target_drop_duration
        )),
        retorno = smooth(clamp01(
            ($t - reset_start) / reset_duration
        ))
    )
    max(queda, retorno);

function target_y_offset() =
    target_drop_offset + target_lift() * target_travel;

// Posição do alvo no playfield. O valor X é a borda esquerda da cabeça
// nominal de 30 mm; 210 mm centraliza essa cabeça em X = 225 mm.
module reference_unit_local() {
    color("dimgray")
        scale([reference_scale, reference_scale, reference_scale])
            cage();

    if (show_target)
        color("gold")
            translate([
                0,
                target_y_offset() * reference_scale,
                target_depth_offset * reference_scale
            ])
                scale([reference_scale, reference_scale, reference_scale])
                    target();
}

// A gaiola é fornecida deitada. A translação Z = 1 faz o topo original
// Y = -1 coincidir com Z = 0 antes de aplicar a posição sob o playfield.
module standing_reference_unit(origin = [0, 0, 0]) {
    translate([origin[0], origin[1], origin[2] + 1])
        rotate([90, 0, 0])
            reference_unit_local();
}

// A cabeça tem 30 x 8 mm. O desenho do usuário reserva 30 x 10 mm; usamos
// 10 mm de profundidade nominal e 0,5 mm de folga lateral na largura.
playfield_opening_width = target_width * reference_scale
    + 2 * playfield_slot_clearance;
playfield_opening_depth = 10 * reference_scale;

// Depois da rotação, a cabeça ocupa Y = -target_depth_offset até
// -target_depth_offset - target_head_thickness. O centro fica em 6 mm à
// frente da origem da unidade para os parâmetros atuais.
playfield_opening_center_y = -target_depth_offset * reference_scale
    - target_head_thickness * reference_scale / 2;

module playfield_opening(origin = [reference_module_target_left,
    reference_module_origin_y, -playfield_thickness]) {
    translate([
        origin[0] - playfield_slot_clearance,
        origin[1] + playfield_opening_center_y
            - playfield_opening_depth / 2,
        -playfield_thickness - epsilon
    ])
        cube([
            playfield_opening_width,
            playfield_opening_depth,
            playfield_thickness + 2 * epsilon
        ]);
}

module playfield_with_one_unit() {
    difference() {
        color("burlywood", 0.55)
            translate([0, 0, -playfield_thickness])
                cube([
                    playfield_width,
                    playfield_length,
                    playfield_thickness
                ]);

        playfield_opening();
    }

    standing_reference_unit([
        reference_module_target_left,
        reference_module_origin_y,
        -playfield_thickness
    ]);
}

if (view_mode == "unidade") {
    standing_reference_unit();
} else if (view_mode == "playfield") {
    playfield_with_one_unit();
} else if (view_mode == "abertura") {
    difference() {
        color("burlywood", 0.55)
            translate([0, 0, -playfield_thickness])
                cube([
                    playfield_width,
                    playfield_length,
                    playfield_thickness
                ]);
        playfield_opening();
    }
} else if (view_mode == "gaiola") {
    scale(cage_scale) cage();
} else if (view_mode == "alvo") {
    scale(target_scale) target();
}
