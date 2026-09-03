// ====================================================================
// PARÂMETROS GERAIS DO SISTEMA (em milímetros)
// ====================================================================
$fn = 60;

// Geometria da madeira e distâncias
espessura_madeira = 10.0;
distancia_lateral = 80.0;

// Eixo sextavado (chave / bitola)
eixo_sextavado_d = 8.0;
folga_impressao  = 0.3;

// Flipper (Superior)
comp_flipper      = 90.0;
raio_base_flip    = 14.0;
raio_ponta_flip   = 5.0;
altura_flipper    = 14.0;
prof_encaixe_flip = altura_flipper - 2.0;

// Canal da borracha
largura_canal     = 4.5;
prof_canal        = 1.5;

// Base / Mancal (Inferior)
espessura_base   = 8.0;
raio_mancal      = 9.0;
altura_mancal    = 6.0;
dist_ancora_mola = 28.0;
d_furo_mola      = 2.5;

// Alavanca Inferior
comp_alavanca      = 30.0;
raio_alavanca      = 10.0;
altura_alavanca    = 8.0;
d_pino_articulacao = 4.0;
dist_mola_alavanca = 16.0;

// Geometria dos Batentes (Stops)
raio_batente     = 19.0;
d_pino_batente   = 5.0;
altura_batente   = altura_mancal + altura_alavanca; 
ang_repouso      = -15;
ang_disparo      = 35;

// Haste de Acionamento Redonda
diametro_haste   = 8.0;
espessura_haste  = 8.0;
curso_haste      = 80.0;
comp_oblongo     = 12.0;
folga_slot       = 0.4;

// ====================================================================
// CÁLCULO DINÂMICO DE ANIMAÇÃO ($t varia de 0.0 a 1.0)
// ====================================================================
// Movimento senoidal de ida e volta suave
fator_ciclo = (1 - cos($t * 360)) / 2; 

// Ângulo instantâneo durante a animação
ang_atual = ang_repouso + (ang_disparo - ang_repouso) * fator_ciclo;

// Posição calculada do pino da alavanca
pino_x_atual = comp_alavanca * sin(ang_atual);
pino_y_atual = -comp_alavanca * cos(ang_atual);

// ====================================================================
// COTAS GLOBAIS DE EMPILHAMENTO EM Z
// ====================================================================
z_base_inferior = -(espessura_base + altura_mancal);
z_alavanca      = z_base_inferior - altura_alavanca;
altura_total_eixo = (espessura_madeira + prof_encaixe_flip) + (espessura_base + altura_mancal + altura_alavanca);

// ====================================================================
// CONTROLE DE VISUALIZAÇÃO
// ====================================================================
modo_visualizacao = "montagem";

// ====================================================================
// MÓDULOS MECÂNICOS
// ====================================================================
module prisma_hexagonal(d, h) {
    cylinder(r = (d / 2) / cos(30), h = h, $fn = 6);
}

module flipper() {
    difference() {
        hull() {
            cylinder(r = raio_base_flip, h = altura_flipper);
            translate([comp_flipper, 0, 0])
                cylinder(r = raio_ponta_flip, h = altura_flipper);
        }
        
        translate([0, 0, -1])
            prisma_hexagonal(eixo_sextavado_d + folga_impressao, prof_encaixe_flip + 1);

        translate([0, 0, (altura_flipper - largura_canal) / 2])
            difference() {
                hull() {
                    cylinder(r = raio_base_flip + 1.0, h = largura_canal);
                    translate([comp_flipper, 0, 0])
                        cylinder(r = raio_ponta_flip + 1.0, h = largura_canal);
                }
                hull() {
                    cylinder(r = raio_base_flip - prof_canal, h = largura_canal);
                    translate([comp_flipper, 0, 0])
                        cylinder(r = raio_ponta_flip - prof_canal, h = largura_canal);
                }
            }
    }
}

module eixo() {
    prisma_hexagonal(eixo_sextavado_d, altura_total_eixo);
}

module base_suporte_com_stops() {
    difference() {
        union() {
            hull() {
                translate([-20, -22, 0]) cylinder(r=4, h=espessura_base);
                translate([22, -22, 0])  cylinder(r=4, h=espessura_base);
                translate([22, 22, 0])   cylinder(r=4, h=espessura_base);
                translate([-20, 22, 0])  cylinder(r=4, h=espessura_base);
            }
            
            cylinder(r = raio_mancal, h = altura_mancal + espessura_base);
            
            hull() {
                cylinder(r = raio_mancal, h = espessura_base);
                rotate([0, 0, -120])
                    translate([dist_ancora_mola, 0, 0])
                        cylinder(r = 5, h = espessura_base);
            }
            
            rotate([0, 0, ang_repouso])
                translate([raio_batente, 0, espessura_base])
                    cylinder(d = d_pino_batente, h = altura_batente);

            rotate([0, 0, ang_disparo])
                translate([raio_batente, 0, espessura_base])
                    cylinder(d = d_pino_batente, h = altura_batente);
        }
        
        translate([0, 0, -1])
            cylinder(d = eixo_sextavado_d + 1.5, h = altura_mancal + espessura_base + altura_batente + 2);
        
        translate([-15, -16, -1]) cylinder(d=3.5, h=espessura_base + 2);
        translate([-15, 16, -1])  cylinder(d=3.5, h=espessura_base + 2);
        translate([16, -16, -1])  cylinder(d=3.5, h=espessura_base + 2);
        translate([16, 16, -1])   cylinder(d=3.5, h=espessura_base + 2);

        rotate([0, 0, -120])
            translate([dist_ancora_mola, 0, -1])
                cylinder(d = d_furo_mola, h = espessura_base + 2);
    }
}

module alavanca_com_dente() {
    difference() {
        union() {
            hull() {
                cylinder(r = raio_alavanca, h = altura_alavanca);
                translate([0, -comp_alavanca, 0])
                    cylinder(r = d_pino_articulacao/2 + 3, h = altura_alavanca);
            }
            
            hull() {
                translate([0, -dist_mola_alavanca, 0])
                    cylinder(r = 4, h = altura_alavanca);
                translate([-9, -dist_mola_alavanca, 0])
                    cylinder(r = 3.5, h = altura_alavanca);
            }
            
            hull() {
                cylinder(r = raio_alavanca, h = altura_alavanca);
                translate([raio_batente, 0, 0])
                    cylinder(r = 3.0, h = altura_alavanca);
            }

            translate([0, -comp_alavanca, -espessura_haste])
                cylinder(d = d_pino_articulacao, h = espessura_haste + 1);
        }
        
        translate([0, 0, -espessura_haste - 1])
            prisma_hexagonal(eixo_sextavado_d + folga_impressao, altura_alavanca + espessura_haste + 2);
            
        translate([-9, -dist_mola_alavanca, -1])
            cylinder(d = d_furo_mola, h = altura_alavanca + 2);
    }
}

module haste_acionamento() {
    largura_cabeca_slot = d_pino_articulacao + 8;

    difference() {
        union() {
            hull() {
                cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
                translate([comp_oblongo, 0, 0])
                    cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
            }
            
            translate([0, 0, espessura_haste / 2])
                rotate([0, -90, 0])
                    cylinder(d = diametro_haste, h = curso_haste);
            
            translate([-curso_haste, 0, espessura_haste / 2])
                rotate([0, -90, 0])
                    cylinder(r = 11, h = 6);
        }
        
        translate([0, 0, -1])
            hull() {
                cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
                translate([comp_oblongo, 0, 0])
                    cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
            }
    }
}

// ====================================================================
// RENDERIZAÇÃO ANIMADA
// ====================================================================
if (modo_visualizacao == "montagem") {
    // 1. Flipper Superior Móvel
    color("crimson") 
        translate([0, 0, espessura_madeira]) 
            rotate([0, 0, ang_atual])
                flipper();
    
    // Madeira (Translúcida Estática)
    color("burlywood", 0.35) 
        translate([-100, -50, 0]) 
            cube([160, 90, espessura_madeira]);
    
    // 2. Eixo Sextavado Móvel
    color("darkgray") 
        translate([0, 0, z_alavanca]) 
            rotate([0, 0, ang_atual])
                eixo();
    
    // 3. Base / Mancal Fixa com Batentes
    color("royalblue") 
        translate([0, 0, 0]) 
            rotate([180, 0, 0]) 
                base_suporte_com_stops();
    
    // 4. Alavanca Móvel
    color("seagreen") 
        translate([0, 0, z_alavanca]) 
            rotate([0, 0, ang_atual]) 
                alavanca_com_dente();
    
    // 5. Haste de Acionamento Móvel (Deslocamento linear em X acompanhando o arco em Y)
    color("orange") 
        translate([pino_x_atual, pino_y_atual, z_alavanca - espessura_haste]) 
            haste_acionamento();

} else if (modo_visualizacao == "flipper") {
    flipper();
} else if (modo_visualizacao == "eixo") {
    eixo();
} else if (modo_visualizacao == "base") {
    base_suporte_com_stops();
} else if (modo_visualizacao == "alavanca") {
    alavanca_com_dente();
} else if (modo_visualizacao == "haste") {
    haste_acionamento();
}