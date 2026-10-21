// Alojamento externo do lançador: o tubo parafusado na face de fora da parede
// do gabinete, que recebe o cilindro quando o jogador puxa e abriga a mola.
//
// Ele faz quatro coisas ao mesmo tempo:
//   - parafusa na parede, alinhado com o furo de 31 mm;
//   - engole o cilindro de 30 mm, que corre dentro dele como um pistão;
//   - trava o curso no ponto certo, pelo cone que estreita o vão;
//   - dá o encosto fixo para a mola, no assento da tampa do fundo.
//
// A mola mora aqui dentro, inteira, entre a face do cilindro e a tampa. O
// cilindro não a engole: ele só tem um anel na face que segura a ponta dela.
//
// Não tem nada de solenoide aqui: ele age sobre o cilindro, do lado de dentro
// do playfield.
//
// Geometria do conjunto: em repouso o cilindro sobressai 30 mm para dentro da
// mesa e os outros 15 preenchem a parede. Puxando 30 mm, a face dele fica
// rente à parede e o corpo inteiro passa para o furo e para este tubo. O furo
// nunca abre, então a bola de 27 mm não cai nele, e os 30 mm liberados são o
// espaço onde ela desce para a frente do lançador.
//
// Unidades: mm. Orientação: Z = 0 é a face que encosta na parede, e a peça
// cresce para fora da mesa. É também a posição de impressão.
//
// ESBOÇO — medidas marcadas com "(conferir)" ainda são estimativas.
$fn = 96;
eps = 0.05;

// ---------------------------------------------------------------------------
// Mola
// ---------------------------------------------------------------------------
// Medidos com régua na mola real; o diâmetro externo saiu de foto (conferir).
spring_free_length = 58.3;
spring_solid_length = 17.0;     // espiras encostadas, compressão máxima
spring_outer_diameter = 9.5;

// Assento da mola na tampa: rebaixo raso que acomoda a ponta dela em vez de
// deixá-la patinando na face lisa. É o par do anel que fica no cilindro.
spring_seat_clearance = 1.5;
spring_seat_depth = 2.0;

// ---------------------------------------------------------------------------
// Cilindro, vindo de plunger-cylinder.scad
// ---------------------------------------------------------------------------
cylinder_diameter = 30.0;
cylinder_length = 45.0;
cylinder_clearance = 1.0;       // folga diametral para correr sem raspar
cylinder_chamfer = 1.0;         // o chanfro da face dele, que assenta no cone
cylinder_retainer_diameter = 14.0;  // o anel que sobressai dessa face

// Parede do gabinete. Entra na conta porque é ela que decide o curso.
wall_thickness = 15.0;

// ---------------------------------------------------------------------------
// Haste
// ---------------------------------------------------------------------------
rod_diameter = 6.1;
rod_clearance = 0.9;        // mesma folga do pegador, que funcionou

// ---------------------------------------------------------------------------
// Corpo
// ---------------------------------------------------------------------------
tube_wall = 3.0;
end_cap_thickness = 5.0;
tube_fillet = 4.0;          // reforço cônico na saída da chapa, que é onde a
                            // peça mais sofre quando o jogador puxa

// ---------------------------------------------------------------------------
// Flange de fixação na parede
// ---------------------------------------------------------------------------
plate_size = 56.0;          // lado do quadrado
plate_thickness = 5.0;
plate_corner_radius = 6.0;
// Parafuso soberbo de 4,0 mm, cabeça chata, para MDF.
//
// O furo é PASSANTE, não roscado: o parafuso tem de atravessar a chapa solto
// e morder só o MDF, porque é isso que puxa uma peça contra a outra. Furo
// justo faz o contrário — ele rosqueia no plástico e as duas peças ficam
// apenas encostadas. Por isso a folga, ainda mais em FDM, onde o furo sai
// cerca de 0,04 mm menor que o nominal.
//
// Comprimento do parafuso: a chapa tem 5 mm e a parede do gabinete 15, então
// 4,0 × 16 mm é o certo — pega 11 mm de MDF e não atravessa. Um 4 × 25 sairia
// 5 mm do outro lado, dentro do playfield. Faça furo-guia de 2,5 mm no MDF,
// senão ele incha ou racha.
plate_screw_nominal = 4.0;
plate_screw_clearance = 0.5;    // folga diametral do furo passante
plate_screw_head = 8.5;         // cabeça de 8 mm, com 0,5 de folga
plate_screw_angle = 90;         // ângulo incluso da cabeça chata
plate_screw_inset = 7.0;        // centro do furo até a borda da chapa

// Furo da parede: é o próprio cilindro que passa por ele, então ele acompanha
// o vão largo do tubo.
wall_hole_diameter = 31.0;

// ---------------------------------------------------------------------------
// Cotas derivadas
// ---------------------------------------------------------------------------
// O escareado acompanha o ângulo da cabeça, em vez de ser um número solto:
// é isso que faz a cabeça assentar no cone inteiro e não na borda de cima.
plate_screw_diameter = plate_screw_nominal + plate_screw_clearance;
plate_screw_head_depth = (plate_screw_head - plate_screw_diameter)
    / (2 * tan(plate_screw_angle / 2));
plate_screw_meat = plate_thickness - plate_screw_head_depth;

bore_diameter = cylinder_diameter + cylinder_clearance;
tube_outer_diameter = bore_diameter + 2 * tube_wall;
rod_bore_diameter = rod_diameter + rod_clearance;

// Curso: o cilindro corre até parar no cone, e isso precisa acontecer no
// instante em que ele acaba de sair da parede. Antes disso sobra corpo para
// dentro e a bola não cabe à frente; depois disso o furo da parede abre.
stroke_available = cylinder_length - wall_thickness;

// Vão estreito, por onde passam a mola e o anel do cilindro. O cone que liga
// os dois vãos é o batente do curso.
spring_bore_diameter = cylinder_retainer_diameter + 2.0;
cone_length = (bore_diameter - spring_bore_diameter) / 2;   // 45 graus

// O cone começa antes dos 30 mm de propósito: o chanfro da face do cilindro
// também é de 45 graus, então as duas superfícies assentam casadas em vez de
// se tocarem numa aresta. Recuar o começo do cone por esta conta é o que faz a
// face do cilindro parar exatamente nos 30 mm.
cone_start = stroke_available - cylinder_chamfer
    - (bore_diameter - cylinder_diameter) / 2;
cone_end = cone_start + cone_length;

// A mola, solta, vai da face do cilindro em repouso (Z = 0) até o fundo do
// assento. É isso que fixa o comprimento da peça.
seat_bottom = spring_free_length;
cap_inner = seat_bottom - spring_seat_depth;
body_length = cap_inner + end_cap_thickness;

spring_seat_diameter = spring_outer_diameter + spring_seat_clearance;
end_cap_solid = end_cap_thickness - spring_seat_depth;
spring_at_end_of_stroke = spring_free_length - stroke_available;

echo(str(
    "comprimento total ", body_length,
    " mm | vao largo ", bore_diameter, " x ", cone_start,
    " mm | cone ", cone_start, " a ", cone_end,
    " | vao estreito ", spring_bore_diameter, " x ", cap_inner - cone_end,
    " mm | assento ", spring_seat_diameter, " x ", spring_seat_depth,
    " mm | tampa macica ", end_cap_solid,
    " mm | curso ", stroke_available,
    " mm | mola no fim ", spring_at_end_of_stroke,
    " mm (solida com ", spring_solid_length, ")"
));

echo(str(
    "parafusos: furo passante ", plate_screw_diameter,
    " mm para soberbo de ", plate_screw_nominal,
    " | escareado ", plate_screw_head, " x ", plate_screw_head_depth,
    " mm a ", plate_screw_angle, " graus | material sob a cabeca ",
    plate_screw_meat, " mm | ", plate_size - 2 * plate_screw_inset,
    " mm entre centros"
));

// ---------------------------------------------------------------------------
// Peça
// ---------------------------------------------------------------------------
module rounded_square(size, radius, height) {
    hull()
        for (x = [-1, 1], y = [-1, 1])
            translate([
                x * (size / 2 - radius),
                y * (size / 2 - radius),
                0
            ])
                cylinder(r = radius, h = height);
}

module mounting_plate() {
    rounded_square(plate_size, plate_corner_radius, plate_thickness);
}

module plate_screws() {
    offset = plate_size / 2 - plate_screw_inset;

    // Os dois cortes passam 1 mm da face da chapa. Se terminassem rente a
    // ela, as duas bordas cairiam no mesmo plano e a malha saía cheia de
    // triângulos degenerados na boca de cada furo.
    over = 1.0;
    cone_slope = (plate_screw_head - plate_screw_diameter)
        / plate_screw_head_depth;

    for (x = [-1, 1], y = [-1, 1])
        translate([x * offset, y * offset, 0]) {
            translate([0, 0, -over])
                cylinder(
                    d = plate_screw_diameter,
                    h = plate_thickness + 2 * over
                );

            // Escareado: abre exatamente plate_screw_head na face da chapa e
            // segue com a mesma inclinação além dela.
            translate([0, 0, plate_thickness - plate_screw_head_depth])
                cylinder(
                    d1 = plate_screw_diameter,
                    d2 = plate_screw_head + cone_slope * over,
                    h = plate_screw_head_depth + over
                );
        }
}

module tube() {
    // O tubo nasce em Z = 0 e atravessa a chapa: assim os dois viram um sólido
    // só, sem face coplanar na junção.
    cylinder(d = tube_outer_diameter, h = body_length);

    translate([0, 0, plate_thickness])
        cylinder(
            d1 = tube_outer_diameter + 2 * tube_fillet,
            d2 = tube_outer_diameter,
            h = tube_fillet
        );
}

// Vão interno, em três trechos: o largo onde o cilindro corre, o cone que o
// trava e o estreito onde só a mola e o anel entram. Cada trecho invade o
// seguinte por eps, para não deixar duas bocas no mesmo plano.
module cavity() {
    translate([0, 0, -eps])
        cylinder(d = bore_diameter, h = cone_start + 2 * eps);

    translate([0, 0, cone_start])
        cylinder(d1 = bore_diameter, d2 = spring_bore_diameter, h = cone_length);

    translate([0, 0, cone_end - eps])
        cylinder(d = spring_bore_diameter, h = cap_inner - cone_end + eps);
}

// Assento da mola: rebaixo raso na face interna da tampa.
module spring_seat() {
    translate([0, 0, cap_inner - eps])
        cylinder(d = spring_seat_diameter, h = spring_seat_depth + eps);
}

// Furo da haste na tampa do fundo.
module rod_bore() {
    translate([0, 0, body_length - end_cap_thickness - eps])
        cylinder(d = rod_bore_diameter, h = end_cap_thickness + 2 * eps);
}

module plunger_housing() {
    difference() {
        union() {
            mounting_plate();
            tube();
        }

        cavity();
        spring_seat();
        rod_bore();
        plate_screws();
    }
}

plunger_housing();
