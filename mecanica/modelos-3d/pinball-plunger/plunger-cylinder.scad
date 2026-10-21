// Cilindro do lançador: a peça que envolve a haste e fica para dentro do
// pinball. A bola desce a rampa, chega nele e espera ali até ser liberada.
//
// Ele acumula três funções:
//
//   - a cabeça da haste fica presa no rebaixo do fundo;
//   - o anel do topo segura a ponta da mola;
//   - o corpo de 30 mm é a superfície onde a bola encosta e espera.
//
// A mola fica INTEIRA para fora daqui, espremida entre esta face e a tampa da
// casa, como na peça de referência. O anel é o que impede a ponta dela de
// escapar de lado.
//
// Houve uma versão em que a mola entrava num furo fundo aqui dentro. Ela foi
// abandonada: naquele arranjo a casa ficava curta (35 mm), mas não sobrava
// onde pôr o anel — ele seria um aro de 14 mm em volta de um furo de 11.
//
// Unidades: mm. Z = 0 é a ponta do anel; o corpo começa logo atrás dele e
// cresce no sentido do fundo, onde entra a cabeça da haste.
//
// Impressão: de pé, anel para cima, a face do rebaixo da cabeça na mesa. O
// anel sai sem suporte nenhum. O rebaixo, aberto para baixo, pede suporte
// dentro dele — é um teto anelar de 6,5 mm, e o suporte sai fácil porque o
// bolso é largo e aberto.
//
// ESBOÇO — medidas marcadas com "(conferir)" ainda são estimativas.
$fn = 120;
eps = 0.05;

// ---------------------------------------------------------------------------
// Corpo
// ---------------------------------------------------------------------------
body_diameter = 30.0;
body_length = 45.0;
edge_chamfer = 1.0;         // quebra as duas arestas: a de trás para a bola
                            // não bater num canto vivo, e a da frente porque
                            // ela assenta no cone da casa no fim do curso

// ---------------------------------------------------------------------------
// Haste
// ---------------------------------------------------------------------------
// ATENÇÃO: você mencionou 0,5 cm, mas a medida de paquímetro que usamos no
// pegador foi 6,1 mm, e foi ela que funcionou. Mantive 6,1 porque furo grande
// demais se resolve com um calço, e furo pequeno demais joga a peça fora — foi
// o que aconteceu na primeira impressão do pegador, feita com 6,00 para uma
// haste de 6,10. Se a haste for mesmo 5,0, troque só esta linha.
rod_diameter = 6.1;
rod_clearance = 0.9;        // mesma folga que funcionou no pegador

// ---------------------------------------------------------------------------
// Rebaixo da cabeça da haste, no fundo
// ---------------------------------------------------------------------------
head_recess_diameter = 20.0;    // "algo em volta de 2 cm", como na peça atual
head_recess_depth = 10.0;       // cabeça mais pescoço do parafuso (conferir)

// ---------------------------------------------------------------------------
// Mola e o anel que segura a ponta dela
// ---------------------------------------------------------------------------
// (conferir) O diâmetro externo saiu de medição em foto, não de paquímetro, e
// é ele que dimensiona o anel: mola mais grossa e o anel aperta nela, mola bem
// mais fina e ela dança lá dentro. Meça com paquímetro antes de imprimir.
spring_outer_diameter = 9.5;
spring_free_length = 58.3;      // medido com régua
spring_solid_length = 17.0;     // espiras encostadas

// O anel é uma sobressalência e a mola entra DENTRO dele, não por cima. Com
// furo de haste de 7 mm e mola de 9,5, não sobra parede para um pino que
// coubesse no miolo da mola — por isso ele a abraça por fora.
retainer_clearance = 1.5;       // folga para a ponta da mola entrar
retainer_wall = 1.5;
retainer_height = 2.0;          // "algo em torno de 2 mm", do seu esboço

// ---------------------------------------------------------------------------
// Parede do gabinete
// ---------------------------------------------------------------------------
wall_thickness = 15.0;

// ---------------------------------------------------------------------------
// Cotas derivadas
// ---------------------------------------------------------------------------
rod_bore_diameter = rod_diameter + rod_clearance;
rod_bore_length = body_length - head_recess_depth;
wall_at_head = (body_diameter - head_recess_diameter) / 2;

retainer_inner_diameter = spring_outer_diameter + retainer_clearance;
retainer_outer_diameter = retainer_inner_diameter + 2 * retainer_wall;

// O corpo sobra isto para dentro da mesa, e é exatamente o curso: o cilindro
// recua até acabar de sair da parede, nem mais nem menos. Menos, e a bola de
// 27 mm não cabe à frente dele; mais, e o furo da parede abre e ela cai nele.
// Quem garante essa parada é o cone da casa, não a mola.
protrusion = body_length - wall_thickness;
stroke = protrusion;
spring_at_end_of_stroke = spring_free_length - stroke;

total_height = retainer_height + body_length;

echo(str(
    "corpo ", body_diameter, " x ", body_length,
    " mm | anel da mola ", retainer_outer_diameter, " x ", retainer_height,
    " mm (vao ", retainer_inner_diameter,
    ") | altura total ", total_height,
    " mm | furo da haste ", rod_bore_diameter, " x ", rod_bore_length,
    " mm | rebaixo da cabeca ", head_recess_diameter, " x ", head_recess_depth,
    " mm | curso ", stroke,
    " mm | mola no fim do curso ", spring_at_end_of_stroke,
    " mm (solida com ", spring_solid_length, ")"
));

// ---------------------------------------------------------------------------
// Peça
// ---------------------------------------------------------------------------
module body() {
    translate([0, 0, retainer_height])
        difference() {
            cylinder(d = body_diameter, h = body_length);

            // Chanfro nas duas pontas.
            for (z = [0, body_length])
                translate([0, 0, z])
                    mirror([0, 0, z == 0 ? 0 : 1])
                        difference() {
                            translate([0, 0, -eps])
                                cylinder(
                                    d = body_diameter + 2,
                                    h = edge_chamfer + eps
                                );
                            cylinder(
                                d1 = body_diameter - 2 * edge_chamfer,
                                d2 = body_diameter,
                                h = edge_chamfer
                            );
                        }
        }
}

// O anel entra um pouco no corpo, para a junção não deixar face coplanar. Ele
// é estreito o bastante para isso acontecer em material maciço.
module retainer() {
    cylinder(d = retainer_outer_diameter, h = retainer_height + edge_chamfer);
}

// Vão do anel: onde a ponta da mola entra. O fundo dele é a própria face do
// corpo, que é contra quem a mola empurra.
module retainer_bore() {
    translate([0, 0, -eps])
        cylinder(d = retainer_inner_diameter, h = retainer_height + eps);
}

// Furo da haste: atravessa o anel e o corpo até o rebaixo da cabeça.
module rod_bore() {
    translate([0, 0, -eps])
        cylinder(
            d = rod_bore_diameter,
            h = retainer_height + rod_bore_length + eps
        );
}

// Rebaixo da cabeça da haste, no fundo.
module head_recess() {
    translate([0, 0, total_height - head_recess_depth])
        cylinder(d = head_recess_diameter, h = head_recess_depth + eps);
}

module plunger_cylinder() {
    difference() {
        union() {
            retainer();
            body();
        }

        retainer_bore();
        rod_bore();
        head_recess();
    }
}

plunger_cylinder();
