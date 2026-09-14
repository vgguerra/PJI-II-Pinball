// ====================================================================
// PROJETO COMPLETO: FLIPPER MECÂNICO DE PINBALL 90mm (Paramétrico)
// ====================================================================
$fn = 60;

// Geometria da madeira e distâncias
espessura_madeira = 10.0;
distancia_lateral = 95.0;  // Distância até a face externa da madeira

// Eixo sextavado (chave / bitola)
eixo_sextavado_d = 8.0;
folga_impressao  = 0.3;

// 1. Flipper (Superior)
comp_flipper      = 90.0;
raio_base_flip    = 14.0;
raio_ponta_flip   = 5.0;
altura_flipper    = 14.0;
prof_encaixe_flip = altura_flipper - 2.0;

// Canal da borracha de impacto
largura_canal     = 4.5;
prof_canal        = 1.5;

// 2. Base / Mancal (Inferior)
h_aba            = 5.0;   // Espessura otimizada da chapa de fixação
raio_mancal      = 9.0;
altura_mancal    = 6.0;   // Projeção do colar além da aba

// 3. Sistema de Retorno (Mola de tração / Elástico universal)
altura_poste_mola = 8.0;   
d_poste_mola      = 7.5;   
d_furo_mola       = 3.6;   
z_furo_transv     = 4.5;   
dist_ancora_mola  = 36.0;  
ang_ancora_mola   = 162;   

// 4. Alavanca Inferior
comp_alavanca            = 30.0;
raio_alavanca            = 10.0;
altura_alavanca          = 8.0;
d_pino_articulacao       = 5.0;   
dist_mola_alavanca       = 16.0;
d_furo_elastico_alavanca = 3.8;

// 5. Geometria dos Batentes (Stops)
raio_batente     = 24.0;
d_pino_batente   = 5.0;
altura_batente   = altura_mancal + altura_alavanca; 
ang_dente        = 45;    
ang_repouso      = -15;
ang_disparo      = 35;

ang_offset_contato = asin((d_pino_batente/2 + 3.0) / raio_batente); 

// 6. Haste de Acionamento Quadrada (Peça Única Corrigida)
largura_haste_quadrada = 8.0;   
espessura_haste        = 8.0;   
curso_haste            = 125.0; // 95mm(parede) + 25mm(curso) + 5mm(folga)
comp_oblongo           = 10.0;  
folga_slot             = 0.4;   

y_linha_guia_haste = -comp_alavanca + (comp_oblongo / 2);

// 7. Botão do Jogador
raio_botao         = 15.0; 
espessura_botao    = 10.0; 
prof_encaixe_botao = 7.0;  

// ====================================================================
// COTAS GLOBAIS DE EMPILHAMENTO EM Z
// ====================================================================
z_base_inferior = -(h_aba + altura_mancal);
z_alavanca      = z_base_inferior - altura_alavanca;
altura_total_eixo = (espessura_madeira + prof_encaixe_flip) + (h_aba + altura_mancal + altura_alavanca);

fator_ciclo = (1 - cos($t * 360)) / 2; 
ang_atual = ang_repouso + (ang_disparo - ang_repouso) * fator_ciclo;

pino_x_atual = comp_alavanca * sin(ang_atual);
pino_y_atual = -comp_alavanca * cos(ang_atual);

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
            translate([comp_flipper, 0, 0]) cylinder(r = raio_ponta_flip, h = altura_flipper);
        }
        translate([0, 0, -1]) prisma_hexagonal(eixo_sextavado_d + folga_impressao, prof_encaixe_flip + 1);
        translate([0, 0, (altura_flipper - largura_canal) / 2])
            difference() {
                hull() {
                    cylinder(r = raio_base_flip + 1.0, h = largura_canal);
                    translate([comp_flipper, 0, 0]) cylinder(r = raio_ponta_flip + 1.0, h = largura_canal);
                }
                hull() {
                    cylinder(r = raio_base_flip - prof_canal, h = largura_canal);
                    translate([comp_flipper, 0, 0]) cylinder(r = raio_ponta_flip - prof_canal, h = largura_canal);
                }
            }
    }
}

module eixo() {
    union() {
        prisma_hexagonal(eixo_sextavado_d, altura_total_eixo);
        cylinder(d = eixo_sextavado_d + 4.0, h = 2.0);
    }
}

module base_suporte_com_stops() {
    z_base_haste = h_aba + altura_mancal + altura_alavanca;
    espessura_teto_guia = 4.0; 
    altura_guia_z = z_base_haste + espessura_haste + espessura_teto_guia;
    folga_guia = 0.8;
    y_guia_interno = -y_linha_guia_haste; 

    ang_b1 = -(ang_dente + ang_repouso - ang_offset_contato);
    ang_b2 = -(ang_dente + ang_disparo + ang_offset_contato);
    ang_meio_batentes = (ang_b1 + ang_b2) / 2;
    raio_parafuso_batente = raio_batente + 6.5;

    difference() {
        union() {
            cylinder(r = raio_mancal + 3, h = altura_mancal + h_aba);
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                translate([-45, y_guia_interno, 0]) cylinder(r = largura_haste_quadrada/2 + 3.5, h = h_aba);
            }
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                rotate([0, 0, ang_b1]) translate([raio_batente, 0, 0]) cylinder(r = d_pino_batente/2 + 3.5, h = h_aba);
                rotate([0, 0, ang_b2]) translate([raio_batente, 0, 0]) cylinder(r = d_pino_batente/2 + 3.5, h = h_aba);
                rotate([0, 0, ang_meio_batentes]) translate([raio_parafuso_batente, 0, 0]) cylinder(r = 5.5, h = h_aba);
            }
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                rotate([0, 0, ang_ancora_mola]) translate([dist_ancora_mola, 0, 0]) cylinder(r = d_poste_mola/2 + 2.0, h = h_aba);
            }
            rotate([0, 0, ang_ancora_mola]) translate([dist_ancora_mola, 0, h_aba]) cylinder(d = d_poste_mola, h = altura_poste_mola);
            
            hull() {
                translate([-45, y_guia_interno, 0]) cylinder(r = 4, h = h_aba);
                translate([-42, y_guia_interno + 10, 0]) cylinder(r = 5, h = h_aba);
            }
            hull() {
                translate([-45, y_guia_interno, 0]) cylinder(r = 4, h = h_aba);
                translate([-42, y_guia_interno - 14, 0]) cylinder(r = 5, h = h_aba);
            }
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                translate([12, 22, 0]) cylinder(r = 5, h = h_aba);
            }

            rotate([0, 0, ang_b1]) translate([raio_batente, 0, h_aba]) cylinder(d = d_pino_batente, h = altura_batente);
            rotate([0, 0, ang_b2]) translate([raio_batente, 0, h_aba]) cylinder(d = d_pino_batente, h = altura_batente);

            translate([-45, y_guia_interno - (largura_haste_quadrada/2 + 3.5), 0])
                cube([14, largura_haste_quadrada + 7, altura_guia_z]);
        }
        
        translate([0, 0, -1]) cylinder(d = eixo_sextavado_d + 1.5, h = altura_mancal + h_aba + altura_batente + 5);
        translate([-42, y_guia_interno + 10, -1]) cylinder(d=3.5, h=h_aba + 2);
        translate([-42, y_guia_interno - 14, -1]) cylinder(d=3.5, h=h_aba + 2);
        translate([12, 22, -1]) cylinder(d=3.5, h=h_aba + 2);
        rotate([0, 0, ang_meio_batentes]) translate([raio_parafuso_batente, 0, -1]) cylinder(d=3.5, h=h_aba + 2);
        rotate([0, 0, ang_ancora_mola]) translate([dist_ancora_mola, 0, h_aba + z_furo_transv])
            rotate([90, 0, 0]) cylinder(d = d_furo_mola, h = d_poste_mola + 4, center = true);

        translate([-50, y_guia_interno - (largura_haste_quadrada + folga_guia)/2, z_base_haste - folga_guia/2])
            cube([25, largura_haste_quadrada + folga_guia, espessura_haste + folga_guia]);
    }
}

module mancal_guia_frontal() {
    z_base_haste = h_aba + altura_mancal + altura_alavanca;
    espessura_teto_guia = 4.0;
    altura_guia_z = z_base_haste + espessura_haste + espessura_teto_guia;
    folga_guia = 0.8;
    
    largura_bloco = largura_haste_quadrada + 8; // Paredes de 4mm laterais
    comp_base = 36; // Comprimento da chapa no eixo Y

    difference() {
        union() {
            // Orelhas de fixação orientadas na vertical (Eixo Y)
            hull() {
                translate([0, -comp_base/2, 0]) cylinder(r=5, h=h_aba);
                translate([0, comp_base/2, 0]) cylinder(r=5, h=h_aba);
            }
            // Bloco maciço do túnel
            translate([-6, -largura_bloco/2, 0])
                cube([12, largura_bloco, altura_guia_z]);
        }
        
        // Furos M3 na vertical
        translate([0, -comp_base/2, -1]) cylinder(d=3.5, h=h_aba+2);
        translate([0, comp_base/2, -1])  cylinder(d=3.5, h=h_aba+2);
        
        // Túnel passante
        translate([-10, -(largura_haste_quadrada + folga_guia)/2, z_base_haste - folga_guia/2])
            cube([20, largura_haste_quadrada + folga_guia, espessura_haste + folga_guia]);
    }
}

module alavanca_com_dente() {
    difference() {
        union() {
            hull() {
                cylinder(r = raio_alavanca, h = altura_alavanca);
                translate([0, -comp_alavanca, 0]) cylinder(r = d_pino_articulacao/2 + 3.2, h = altura_alavanca);
            }
            hull() {
                translate([0, -dist_mola_alavanca, 0]) cylinder(r = 4.5, h = altura_alavanca);
                translate([-11, -dist_mola_alavanca, 0]) cylinder(r = 4.5, h = altura_alavanca);
            }
            rotate([0, 0, ang_dente]) hull() {
                cylinder(r = raio_alavanca, h = altura_alavanca);
                translate([raio_batente, 0, 0]) cylinder(r = 3.0, h = altura_alavanca);
            }
            translate([0, -comp_alavanca, -(espessura_haste + 1.5)]) cylinder(d = d_pino_articulacao, h = espessura_haste + 1.5);
        }
        
        translate([0, 0, -(espessura_haste + 2.5)]) prisma_hexagonal(eixo_sextavado_d + folga_impressao, altura_alavanca + espessura_haste + 4);
        translate([-11, -dist_mola_alavanca, altura_alavanca / 2]) rotate([0, 90, 0]) cylinder(d = d_furo_elastico_alavanca, h = 15, center = true);
        translate([-11, -dist_mola_alavanca, altura_alavanca / 2]) rotate([90, 0, 0]) cylinder(d = 3.0, h = 12, center = true);
        translate([0, -comp_alavanca, -(espessura_haste + 3)]) cylinder(d = 2.5, h = espessura_haste + 5);
    }
}

module haste_acionamento() {
    largura_cabeca_slot = d_pino_articulacao + 8;
    difference() {
        union() {
            hull() {
                translate([0, -comp_oblongo / 2, 0]) cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
                translate([0, comp_oblongo / 2, 0]) cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
            }
            // Corpo íntegro estendido para 125mm
            translate([-curso_haste, -largura_haste_quadrada / 2, 0])
                cube([curso_haste, largura_haste_quadrada, espessura_haste]);
        }
        translate([0, 0, -1]) hull() {
            translate([0, -comp_oblongo / 2, 0]) cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
            translate([0, comp_oblongo / 2, 0]) cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
        }
    }
}

module botao_haste() {
    difference() {
        cylinder(r = raio_botao, h = espessura_botao);
        translate([-(largura_haste_quadrada + folga_impressao)/2, -(espessura_haste + folga_impressao)/2, espessura_botao - prof_encaixe_botao])
            cube([largura_haste_quadrada + folga_impressao, espessura_haste + folga_impressao, prof_encaixe_botao + 1]);
    }
}

// ====================================================================
// RENDERIZAÇÃO
// ====================================================================
if (modo_visualizacao == "montagem") {
    color("crimson") translate([0, 0, espessura_madeira]) rotate([0, 0, ang_atual]) flipper();
    
    // Mesa de madeira ilustrativa ajustada: Inicia em -95mm e vai até +95mm (comprimento total 190)
    color("burlywood", 0.35) translate([-95, -50, 0]) cube([190, 90, espessura_madeira]);

    color("darkgray") translate([0, 0, z_alavanca]) rotate([0, 0, ang_atual]) eixo();
    
    // Base Traseira
    color("royalblue") translate([0, 0, 0]) rotate([180, 0, 0]) base_suporte_com_stops();
    
    // Guia Frontal Posicionada em X = -75 (Logo antes da parede interna da máquina)
    color("teal") 
        translate([-75, y_linha_guia_haste, 0]) 
            rotate([180, 0, 0]) 
                mancal_guia_frontal();
                
    color("seagreen") translate([0, 0, z_alavanca]) rotate([0, 0, ang_atual]) alavanca_com_dente();
    
    // Haste de 125mm
    color("orange") translate([pino_x_atual, y_linha_guia_haste, z_alavanca - espessura_haste]) haste_acionamento();
    
    // Botão encaixado no fim da haste (Sempre para fora da máquina)
    color("purple") translate([pino_x_atual - curso_haste - espessura_botao, y_linha_guia_haste, z_alavanca - espessura_haste/2])
        rotate([0, 90, 0]) botao_haste();

} else if (modo_visualizacao == "mesa_impressao") {
    translate([-15, 35, altura_flipper]) rotate([180, 0, 0]) flipper();
    translate([-65, 35, 0]) rotate([0, 90, 0]) eixo();
    translate([35, 35, 0]) base_suporte_com_stops();
    translate([-35, -25, 0]) rotate([180, 0, 0]) alavanca_com_dente();
    
    translate([30, -25, 0]) rotate([0, 0, 90]) haste_acionamento();
    
    // Guia frontal deitada plana na mesa
    translate([10, -50, 0]) mancal_guia_frontal();
    
    translate([-20, -60, 0]) botao_haste();

} else if (modo_visualizacao == "haste") {
    haste_acionamento();
} else if (modo_visualizacao == "guia_frontal") {
    mancal_guia_frontal();
} else if (modo_visualizacao == "botao") {
    botao_haste();
}