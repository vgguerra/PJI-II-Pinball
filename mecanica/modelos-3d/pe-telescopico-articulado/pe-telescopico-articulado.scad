// ====================================================================
// PÉ TELESCOPICO ARTICULADO PARA PINBALL (100% Sem Suportes)
// ====================================================================
$fn = 60;

// ====================================================================
// SELEÇÃO DO TIPO DE PÉ
// ====================================================================
tipo_pe = "dianteiro"; // Opções: "dianteiro" ou "traseiro"

// ====================================================================
// PARÂMETROS GERAIS E DIMENSIONAMENTO AUTOMÁTICO
// ====================================================================
comp_perna_externa = (tipo_pe == "traseiro") ? 160.0 : 70.0;
comp_perna_interna = (tipo_pe == "traseiro") ? 180.0 : 90.0;

// Furação e Parafusos
d_parafuso_principal = 8.5;
d_parafuso_madeira   = 5.0;
passo_furos          = 15.0;

// Perfil e Estrutura Otimizada
perfil_externo       = 30.0; 
espessura_parede     = 4.0;  
folga_deslizamento   = 0.6;  
base_chao            = 50.0; 

// Geometria da Dobradiça
largura_orelha       = 8.0;  
largura_bloco_base   = perfil_externo - (2 * largura_orelha) - 1.0; 

// Geometria da Base (Fixação na Madeira)
base_x = 80.0;
base_y = 80.0;
espessura_base = 8.0;

// Geometria da Sapata Separada (Encaixe Macho/Fêmea)
altura_sapata = 20.0;
prof_encaixe_sapata = 15.0;
folga_cola = 0.4; 

// Variáveis Calculadas
perfil_interno = perfil_externo - (2 * espessura_parede) - folga_deslizamento;
altura_eixo = 20.0; 

// ====================================================================
// ÂNGULO DE TESTE PARA MONTAGEM
// ====================================================================
angulo_pitch = 6.5; 

// ====================================================================
// CONTROLE DE VISUALIZAÇÃO E EXPORTAÇÃO (STL)
// ====================================================================
// Altere o texto dentro das aspas abaixo para exportar cada peça individualmente.
//
// Opções disponíveis:
// "montagem"         -> Mostra todas as peças montadas na inclinação correta (apenas visualização).
// "mesa_impressao"   -> Mostra as 6 peças deitadas na posição ideal de impressão (zero suporte).
// "base"             -> Isola apenas a Base de fixação na madeira (imprimir 1x por pé).
// "perna_ext_metade" -> Isola apenas a metade em "U" da perna externa (imprimir 2x por pé e colar).
// "perna_int_L"      -> Isola apenas a metade em "L" da perna interna (imprimir 2x por pé e colar).
// "sapata"           -> Isola apenas a sapata inferior com cavidade de encaixe (imprimir 1x por pé).

modo_visualizacao = "montagem";

// ====================================================================
// MÓDULOS MECÂNICOS
// ====================================================================

module base_gabinete() {
    difference() {
        union() {
            translate([0, 0, altura_eixo + (espessura_base/2)]) cube([base_x, base_y, espessura_base], center=true);
            translate([0, 0, altura_eixo/2]) cube([largura_bloco_base, 30, altura_eixo], center=true);
            rotate([0, 90, 0]) cylinder(d=30, h=largura_bloco_base, center=true);
        }
        rotate([0, 90, 0]) cylinder(d=d_parafuso_principal, h=perfil_externo + 20, center=true);
        dist_furo_x = (base_x / 2) - 10;
        dist_furo_y = (base_y / 2) - 10;
        for (dx = [-1, 1]) {
            for (dy = [-1, 1]) {
                translate([dx * dist_furo_x, dy * dist_furo_y, altura_eixo - 1])
                    cylinder(d=d_parafuso_madeira, h=espessura_base + 5);
                translate([dx * dist_furo_x, dy * dist_furo_y, altura_eixo - 1])
                    cylinder(d1=d_parafuso_madeira + 4, d2=0, h=espessura_base + 5);
            }
        }
    }
}

module furos_regulagem(comprimento) {
    offset_inicial = 40; 
    num_furos = floor((comprimento - offset_inicial - 15) / passo_furos);
    for (i = [0 : num_furos]) {
        translate([0, 0, -offset_inicial - (i * passo_furos)])
            rotate([0, 90, 0]) cylinder(d=d_parafuso_principal, h=perfil_externo + 20, center=true);
    }
}

module perna_externa_completa() {
    difference() {
        union() {
            translate([0, 0, -comp_perna_externa/2]) cube([perfil_externo, perfil_externo, comp_perna_externa], center=true);
            rotate([0, 90, 0]) cylinder(d=30, h=perfil_externo, center=true);
            translate([0, 0, -15]) cube([perfil_externo, 30, 30], center=true);
        }
        translate([0, 0, -(comp_perna_externa/2) - 20])
            cube([perfil_externo - (2*espessura_parede), perfil_externo - (2*espessura_parede), comp_perna_externa], center=true);
        rotate([0, 90, 0]) cylinder(d=d_parafuso_principal, h=perfil_externo + 20, center=true);
        cube([largura_bloco_base + 1.0, 35, 40], center=true);
        furos_regulagem(comp_perna_externa);
    }
}

// O bloco de corte agora desce cobrindo 100% da perna
module perna_externa_metade() {
    difference() {
        perna_externa_completa();
        translate([perfil_externo, 0, -comp_perna_externa/2])
            cube([perfil_externo * 2, perfil_externo * 2, comp_perna_externa * 3], center=true);
    }
}

module tubo_interno_completo() {
    difference() {
        translate([0, 0, -comp_perna_interna/2]) cube([perfil_interno, perfil_interno, comp_perna_interna], center=true);
        translate([0, 0, -comp_perna_interna/2]) cube([perfil_interno - 8, perfil_interno - 8, comp_perna_interna + 5], center=true);
        furos_regulagem(comp_perna_interna);
    }
}

module perna_interna_L() {
    difference() {
        tubo_interno_completo();
        translate([0, 0, -comp_perna_interna/2])
            rotate([0, 0, 45])
                translate([perfil_interno, 0, 0])
                    cube([perfil_interno * 2, perfil_interno * 2, comp_perna_interna + 10], center=true);
    }
}

module sapata_inferior() {
    difference() {
        hull() {
            translate([0, 0, altura_sapata]) cube([perfil_interno, perfil_interno, 0.1], center=true);
            translate([0, 0, 1]) cube([base_chao, base_chao, 2], center=true);
        }
        translate([0, 0, altura_sapata - (prof_encaixe_sapata/2) + 1])
            cube([perfil_interno + folga_cola, perfil_interno + folga_cola, prof_encaixe_sapata + 2], center=true);
    }
}

// ====================================================================
// RENDERIZAÇÃO E EXPORTAÇÃO
// ====================================================================
if (modo_visualizacao == "montagem") {
    color("darkgray") rotate([angulo_pitch, 0, 0]) base_gabinete();
    
    color("burlywood", 0.3) rotate([angulo_pitch, 0, 0]) 
        translate([0, 0, altura_eixo + espessura_base + 5]) cube([120, 120, 10], center=true);
            
    color("steelblue") perna_externa_metade();
    color("royalblue") mirror([1, 0, 0]) perna_externa_metade();
    
    color("darkorange") translate([0, 0, -(comp_perna_externa/2) + 20]) perna_interna_L();
    color("orange") translate([0, 0, -(comp_perna_externa/2) + 20]) rotate([0, 0, 180]) perna_interna_L();
    
    color("gold") translate([0, 0, -(comp_perna_externa/2) - comp_perna_interna + 20]) sapata_inferior();
    
    color("silver") translate([0, 0, -55]) rotate([0, 90, 0]) cylinder(d=d_parafuso_principal - 0.5, h=perfil_externo + 15, center=true);

} else if (modo_visualizacao == "mesa_impressao") {
    translate([-30, 40, 0]) base_gabinete();
    
    translate([30, 0, perfil_externo/2]) rotate([0, -90, 0]) perna_externa_metade();
    translate([70, 0, perfil_externo/2]) rotate([0, -90, 0]) perna_externa_metade();
    
    translate([-20, -50, perfil_interno/2]) rotate([0, 90, 0]) rotate([0, 0, 90]) perna_interna_L();
    translate([-60, -50, perfil_interno/2]) rotate([0, 90, 0]) rotate([0, 0, 90]) perna_interna_L();
    
    translate([60, 60, 0]) sapata_inferior();
    
} else if (modo_visualizacao == "base") { base_gabinete();
} else if (modo_visualizacao == "perna_ext_metade") { perna_externa_metade();
} else if (modo_visualizacao == "perna_int_L") { perna_interna_L();
} else if (modo_visualizacao == "sapata") { sapata_inferior();
}