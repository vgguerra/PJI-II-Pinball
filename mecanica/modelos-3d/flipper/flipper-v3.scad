// ====================================================================
// PROJETO COMPLETO: FLIPPER MECÂNICO DE PINBALL 90mm (Paramétrico)
// ====================================================================
$fn = 60;

// Geometria da madeira e distâncias
espessura_madeira = 10.0;
distancia_lateral = 120.0;

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
altura_poste_mola = 8.0;   // Altura do poste
d_poste_mola      = 7.5;   // Poste robusto e maciço
d_furo_mola       = 3.6;   // Furo passante amplo para mola e elástico
z_furo_transv     = 4.5;   // Posição central do furo
dist_ancora_mola  = 36.0;  // Distância radial afastada da alavanca
ang_ancora_mola   = 162;   // Ângulo de tração ideal

// 4. Alavanca Inferior
comp_alavanca            = 30.0;
raio_alavanca            = 10.0;
altura_alavanca          = 8.0;
d_pino_articulacao       = 5.0;   // Reforçado para suportar alto cisalhamento
dist_mola_alavanca       = 16.0;
d_furo_elastico_alavanca = 3.8;

// 5. Geometria dos Batentes (Stops)
raio_batente     = 24.0;
d_pino_batente   = 5.0;
altura_batente   = altura_mancal + altura_alavanca; 
ang_dente        = 45;    
ang_repouso      = -15;
ang_disparo      = 35;

// Ângulo de contato tangencial compensado no raio de 24mm
ang_offset_contato = asin((d_pino_batente/2 + 3.0) / raio_batente); 

// 6. Haste de Acionamento Quadrada (120mm)
largura_haste_quadrada = 8.0;   
espessura_haste        = 8.0;   
curso_haste            = 120.0; 
comp_oblongo           = 10.0;  // Compensação perfeita para a variação em Y de ~5.4mm
folga_slot             = 0.4;   

// Linha média de guiamento em Y (onde o rasgo fica centralizado)
y_linha_guia_haste = -comp_alavanca + (comp_oblongo / 2);

// ====================================================================
// COTAS GLOBAIS DE EMPILHAMENTO EM Z
// ====================================================================
z_base_inferior = -(h_aba + altura_mancal);
z_alavanca      = z_base_inferior - altura_alavanca;
altura_total_eixo = (espessura_madeira + prof_encaixe_flip) + (h_aba + altura_mancal + altura_alavanca);

// ====================================================================
// CÁLCULO DINÂMICO DE ANIMAÇÃO ($t varia de 0.0 a 1.0)
// ====================================================================
fator_ciclo = (1 - cos($t * 360)) / 2; 
ang_atual = ang_repouso + (ang_disparo - ang_repouso) * fator_ciclo;

pino_x_atual = comp_alavanca * sin(ang_atual);
pino_y_atual = -comp_alavanca * cos(ang_atual);

// ====================================================================
// CONTROLE DE VISUALIZAÇÃO
// Opções: "montagem", "mesa_impressao", "flipper", "eixo", "base", "alavanca", "haste"
// ====================================================================
modo_visualizacao = "montagem";

// ====================================================================
// MÓDULOS MECÂNICOS
// ====================================================================
module prisma_hexagonal(d, h) {
    cylinder(r = (d / 2) / cos(30), h = h, $fn = 6);
}

// 1. FLIPPER SUPERIOR
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

// 2. EIXO SEXTAVADO COM FLANGE ANTI-QUEDA
module eixo() {
    union() {
        prisma_hexagonal(eixo_sextavado_d, altura_total_eixo);
        cylinder(d = eixo_sextavado_d + 4.0, h = 2.0);
    }
}

// 3. BASE / MANCAL COM GUIA INTEGRADO E POSTE UNIVERSAL
module base_suporte_com_stops() {
    altura_guia_z = h_aba + altura_mancal + altura_alavanca + espessura_haste;
    folga_guia = 0.8;
    y_guia_interno = -y_linha_guia_haste; 

    ang_b1 = -(ang_dente + ang_repouso - ang_offset_contato);
    ang_b2 = -(ang_dente + ang_disparo + ang_offset_contato);
    ang_meio_batentes = (ang_b1 + ang_b2) / 2;
    raio_parafuso_batente = raio_batente + 6.5;

    difference() {
        union() {
            // Cubo central do mancal
            cylinder(r = raio_mancal + 3, h = altura_mancal + h_aba);

            // Braço rígido ligando o mancal à torre guia
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                translate([-45, y_guia_interno, 0])
                    cylinder(r = largura_haste_quadrada/2 + 3.5, h = h_aba);
            }

            // Setor arqueado dos batentes e parafuso central
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                rotate([0, 0, ang_b1])
                    translate([raio_batente, 0, 0])
                        cylinder(r = d_pino_batente/2 + 3.5, h = h_aba);
                rotate([0, 0, ang_b2])
                    translate([raio_batente, 0, 0])
                        cylinder(r = d_pino_batente/2 + 3.5, h = h_aba);
                rotate([0, 0, ang_meio_batentes])
                    translate([raio_parafuso_batente, 0, 0])
                        cylinder(r = 5.5, h = h_aba);
            }

            // Braço estendido que ancora o poste da mola
            hull() {
                cylinder(r = raio_mancal, h = h_aba);
                rotate([0, 0, ang_ancora_mola])
                    translate([dist_ancora_mola, 0, 0])
                        cylinder(r = d_poste_mola/2 + 2.0, h = h_aba);
            }

            // POSTE 100% MACIÇO (Sem canal/cintura frágil)
            rotate([0, 0, ang_ancora_mola])
                translate([dist_ancora_mola, 0, h_aba])
                    cylinder(d = d_poste_mola, h = altura_poste_mola);

            // Orelhas de fixação na madeira (M3/M4)
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

            // Pinos batentes verticais
            rotate([0, 0, ang_b1])
                translate([raio_batente, 0, h_aba])
                    cylinder(d = d_pino_batente, h = altura_batente);

            rotate([0, 0, ang_b2])
                translate([raio_batente, 0, h_aba])
                    cylinder(d = d_pino_batente, h = altura_batente);

            // Bloco maciço da torre guia da haste
            translate([-45, y_guia_interno - (largura_haste_quadrada/2 + 3.5), 0])
                cube([14, largura_haste_quadrada + 7, altura_guia_z]);
        }
        
        // Furo central passante para o eixo
        translate([0, 0, -1])
            cylinder(d = eixo_sextavado_d + 1.5, h = altura_mancal + h_aba + altura_batente + 5);
        
        // Furos de fixação na madeira
        translate([-42, y_guia_interno + 10, -1]) cylinder(d=3.5, h=h_aba + 2);
        translate([-42, y_guia_interno - 14, -1]) cylinder(d=3.5, h=h_aba + 2);
        translate([12, 22, -1])                   cylinder(d=3.5, h=h_aba + 2);

        // Furo centralizado entre os batentes
        rotate([0, 0, ang_meio_batentes])
            translate([raio_parafuso_batente, 0, -1])
                cylinder(d=3.5, h=h_aba + 2);

        // FURO HORIZONTAL PASSANTE NO POSTE MACIÇO
        rotate([0, 0, ang_ancora_mola])
            translate([dist_ancora_mola, 0, h_aba + z_furo_transv])
                rotate([90, 0, 0])
                    cylinder(d = d_furo_mola, h = d_poste_mola + 4, center = true);

        // Túnel passante para a haste quadrada deslizar
        translate([-50, y_guia_interno - (largura_haste_quadrada + folga_guia)/2, altura_guia_z - espessura_haste - folga_guia/2])
            cube([25, largura_haste_quadrada + folga_guia, espessura_haste + folga_guia]);
    }
}

// 4. ALAVANCA INFERIOR
module alavanca_com_dente() {
    difference() {
        union() {
            // Braço mecânico principal
            hull() {
                cylinder(r = raio_alavanca, h = altura_alavanca);
                translate([0, -comp_alavanca, 0])
                    cylinder(r = d_pino_articulacao/2 + 3.2, h = altura_alavanca);
            }
            
            // Aba lateral de fixação de mola/elástico
            hull() {
                translate([0, -dist_mola_alavanca, 0])
                    cylinder(r = 4.5, h = altura_alavanca);
                translate([-11, -dist_mola_alavanca, 0])
                    cylinder(r = 4.5, h = altura_alavanca);
            }
            
            // Dente de batente a +45°
            rotate([0, 0, ang_dente])
                hull() {
                    cylinder(r = raio_alavanca, h = altura_alavanca);
                    translate([raio_batente, 0, 0])
                        cylinder(r = 3.0, h = altura_alavanca);
                }

            // Pino inferior reforçado (5.0mm)
            translate([0, -comp_alavanca, -espessura_haste])
                cylinder(d = d_pino_articulacao, h = espessura_haste + 1);
        }
        
        // Encaixe fêmea sextavado para o eixo
        translate([0, 0, -espessura_haste - 1])
            prisma_hexagonal(eixo_sextavado_d + folga_impressao, altura_alavanca + espessura_haste + 2);
            
        // Furo horizontal para gancho de mola / elástico dobrado
        translate([-11, -dist_mola_alavanca, altura_alavanca / 2])
            rotate([0, 90, 0])
                cylinder(d = d_furo_elastico_alavanca, h = 15, center = true);

        // Canal externo vertical para laçar elástico
        translate([-11, -dist_mola_alavanca, altura_alavanca / 2])
            rotate([90, 0, 0])
                cylinder(d = 3.0, h = 12, center = true);
    }
}

// 5. HASTE DE ACIONAMENTO QUADRADA
module haste_acionamento() {
    largura_cabeca_slot = d_pino_articulacao + 8;

    difference() {
        union() {
            hull() {
                translate([0, -comp_oblongo / 2, 0])
                    cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
                translate([0, comp_oblongo / 2, 0])
                    cylinder(r = largura_cabeca_slot / 2, h = espessura_haste);
            }
            
            translate([-curso_haste, -largura_haste_quadrada / 2, 0])
                cube([curso_haste, largura_haste_quadrada, espessura_haste]);
            
            translate([-curso_haste, 0, 0])
                cylinder(r = 11, h = espessura_haste);
        }
        
        // Rasgo oblongo no eixo Y com folga adequada para o pino de 5mm
        translate([0, 0, -1])
            hull() {
                translate([0, -comp_oblongo / 2, 0])
                    cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
                translate([0, comp_oblongo / 2, 0])
                    cylinder(d = d_pino_articulacao + folga_slot, h = espessura_haste + 2);
            }
    }
}

// ====================================================================
// RENDERIZAÇÃO
// ====================================================================
if (modo_visualizacao == "montagem") {
    // 1. Flipper Superior
    color("crimson") 
        translate([0, 0, espessura_madeira]) 
            rotate([0, 0, ang_atual])
                flipper();
    
    // Madeira translúcida de 10mm
    color("burlywood", 0.35) 
        translate([-140, -50, 0]) 
            cube([200, 90, espessura_madeira]);
    
    // 2. Eixo Sextavado Móvel
    color("darkgray") 
        translate([0, 0, z_alavanca]) 
            rotate([0, 0, ang_atual])
                eixo();
    
    // 3. Base com Suporte/Guia
    color("royalblue") 
        translate([0, 0, 0]) 
            rotate([180, 0, 0]) 
                base_suporte_com_stops();
    
    // 4. Alavanca Móvel
    color("seagreen") 
        translate([0, 0, z_alavanca]) 
            rotate([0, 0, ang_atual]) 
                alavanca_com_dente();
    
    // 5. Haste Quadrada Deslizante
    color("orange") 
        translate([pino_x_atual, y_linha_guia_haste, z_alavanca - espessura_haste]) 
            haste_acionamento();

} else if (modo_visualizacao == "mesa_impressao") {
    // Arranjo ordenado com todas as peças orientadas na melhor face de impressão
    translate([-15, 35, altura_flipper]) rotate([180, 0, 0]) flipper();
    translate([-65, 35, 0]) rotate([0, 90, 0]) eixo();
    translate([35, 35, 0]) base_suporte_com_stops();
    translate([-35, -25, 0]) rotate([180, 0, 0]) alavanca_com_dente();
    translate([30, -25, 0]) rotate([0, 0, 90]) haste_acionamento();

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