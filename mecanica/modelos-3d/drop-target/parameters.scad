// Parâmetros do drop target (milímetros).
//
// As três peças foram convertidas a partir dos STL em references/ e as
// medidas abaixo são as reais da malha. Alterar um valor aqui muda a peça
// no OpenSCAD; os STL originais continuam intactos como referência.

$fn = 64;
epsilon = 0.01;

// ---------------------------------------------------------------------------
// Quantidades e ajuste de tamanho peça a peça
// ---------------------------------------------------------------------------
// Esta etapa valida somente um módulo completo. A repetição fica para depois
// que a geometria e o curso forem aprovados no protótipo.
cage_count = 1;
target_count = 1;
servo_stick_count = 1;

// Escala independente por peça, no formato [X, Y, Z].
// [1, 1, 1] reproduz o STL original. Use, por exemplo,
// target_scale = [1, 1.2, 1] para deixar só o alvo mais comprido.
cage_scale = [1, 1, 1];
target_scale = [1, 1, 1];
servo_stick_scale = [1, 1, 1];

// ---------------------------------------------------------------------------
// Gaiola (cage.stl) — 40 × 85 × 47,5 mm
// ---------------------------------------------------------------------------
// Duas laterais idênticas em espessura, ligadas pela base e pela travessa
// frontal. O alvo desliza no vão entre elas.
cage_wall = 4.5;            // espessura de cada lateral
cage_bay_width = 40;        // passo entre gaiolas vizinhas no banco
cage_left_x = -5;           // face externa da lateral esquerda
cage_right_x = 30.5;        // face interna da lateral direita
cage_slot_width = 31;       // vão livre entre as laterais
cage_screw_diameter = 3;    // furo de fixação inferior
cage_pin_diameter = 2;      // furos de pino e do microswitch
cage_window = [[-77, 24.5], [-53, 37.5]];  // janela da lateral esquerda
cage_side_slot = [[-81, 0], [-46, 5.2]];   // fenda inferior das duas laterais

// Base e travessa atravessam a largura toda da gaiola.
cage_base_span = [-86, -81];   // faixa em Y ocupada pela base
cage_base_depth = [-6, 41.5];  // faixa em Z da base
cage_bar_span = [-11, -1];     // travessa frontal em Y
cage_bar_depth = [4, 8];       // travessa frontal em Z

// ---------------------------------------------------------------------------
// Alvo (target.stl) — 38,4 × 80 × 12,5 mm
// ---------------------------------------------------------------------------
target_width = 30;          // largura que desliza dentro da gaiola
target_length = 80;         // comprimento total (Y de -50 a 30)
target_plate_thickness = 4; // espessura da haste
target_head_height = 30;    // altura da cabeça visível (Y de 0 a 30)
target_head_thickness = 8;  // espessura da cabeça
target_head_draft = 1;      // recuo da face frontal ao longo da espessura
target_tab_width = 4.2;     // orelhas de retenção em cada lado
target_tab_span = [-50, -46];

// Bloco do laço, com furo passante para o fio.
target_knot_x = [3, 9];
target_knot_base_y = [-25, -11];
target_knot_top_y = [-19, -11];
target_knot_z = [4, 10];
target_knot_hole_diameter = 3.5;
target_knot_hole_center = [-15, 6.5];  // [Y, Z]

// Pino que aciona o microswitch.
target_pin_x = [24, 29];
target_pin_top_z = 12.5;

// ---------------------------------------------------------------------------
// Braço do servo (servo_stick.stl) — 12 × 64,8 × 4 mm
// ---------------------------------------------------------------------------
// O módulo já sai com o eixo do servo na origem.
servo_stick_hub = [75, 0];      // centro do eixo nas coordenadas do STL
servo_stick_lower_thickness = 2;
servo_stick_upper_thickness = 2;
servo_stick_shaft_diameter = 2.5;

// ---------------------------------------------------------------------------
// Montagem: como o alvo se aloja na gaiola
// ---------------------------------------------------------------------------
// A haste do alvo corre encostada na face traseira da gaiola (Z = -6) e as
// orelhas de 4,2 mm ficam atrás das laterais, prendendo o alvo contra a
// estrutura. Só a metade dianteira da cabeça entra no vão de 31 mm entre as
// laterais, e é ela que guia o alvo. Foi a única posição sem interferência em
// todo o curso, testada peça contra peça.
target_depth_offset = -10;

// Curso: baixado, a base do alvo encosta na base da gaiola e o topo da cabeça
// fica rente ao topo da estrutura (Y = -1); levantado, a cabeça aparece
// inteira. O curso é exatamente a altura da cabeça.
target_drop_offset = -31;
target_travel = target_head_height;

// ---------------------------------------------------------------------------
// Microservo SG90 (envelope de referência, não é peça impressa)
// ---------------------------------------------------------------------------
servo_body_length = 22.8;
servo_body_width = 12.2;
servo_body_height = 22.5;
servo_flange_length = 32.2;
servo_flange_thickness = 2.5;
servo_flange_z = 15.9;        // altura da aba medida a partir da base
servo_shaft_from_end = 5.9;   // distância do eixo até a ponta da carcaça
servo_boss_diameter = 11.8;
servo_boss_height = 4;
servo_shaft_diameter = 4.8;
servo_shaft_height = 7.5;
servo_horn_thickness = 2;
servo_horn_length = 38;       // braço plástico de duas pontas do SG90
servo_horn_end_diameter = 7;

// O servo fica baixo e à frente, próximo da lateral direita, mas dentro do
// envelope da gaiola. Com rotate([0, 90, 0]) o corpo ocupa o lado -X e a came
// sai pelo eixo +X em direção à alavanca.
// Origem: [X, Y, Z] no eixo de saída do SG90.
// Z = -5 deixa o corpo no plano frontal da gaiola depois da rotação da
// unidade; valores muito negativos projetam o servo para fora da estrutura.
servo_shaft = [23, -70, -5];
servo_cam_x = servo_shaft[0]
    + servo_shaft_height
    - servo_horn_thickness;
servo_cam_thickness = 4;
servo_cam_hub_diameter = 8;
servo_cam_lobe_diameter = 7;
servo_cam_lobe_length = 10;
servo_mount_depth = 20;
servo_mount_thickness = 4;
servo_mount_overlap = 1;

// ---------------------------------------------------------------------------
// Fio entre o braço e o alvo
// ---------------------------------------------------------------------------
// O fio é amarrado na ponta fina do braço e passa pelo furo do bloco do alvo.
// Com o fio esticado, o ângulo do servo define a altura do alvo: é assim que
// a simulação calcula o movimento.
// O fio é amarrado na ponta longa do braço, a aproximadamente 42 mm do eixo,
// e sobe até o furo do bloco do alvo. O comprimento permite que a ponta faça
// o arco necessário para os 30 mm de curso sem soltar o fio.
servo_stick_tie = [76, 42];   // ponto de amarração, coordenadas do STL
string_length = 38;
string_diameter = 1;
string_branch = -1;           // mantido para compatibilidade com a versão anterior

// ---------------------------------------------------------------------------
// Alavanca, micro-switch, came e retorno elástico
// ---------------------------------------------------------------------------
// Tudo permanece nas coordenadas da gaiola deitada; Y vira altura e Z vira
// profundidade quando a unidade é colocada em pé.
lever_pivot_x = 29.5;
lever_pivot_y = -76;
// A face frontal da gaiola está em torno de Z = -6. A alavanca fica logo à
// frente dela, e não dezenas de milímetros afastada.
lever_pivot_z = -14;
lever_length = 42;
lever_width = 5;
lever_thickness = 4;
lever_pivot_diameter = 6;
lever_pivot_axis_length = 9;
lever_rest_angle = -25;
lever_active_angle = 0;
lever_elastic_distance = 29;

// A came encosta na região do pivô e desloca a alavanca; ela não é uma união
// rígida entre o servo e a barra preta.
cam_release_sweep = 110;

// Ponto separado do bloco original do alvo para o elástico/barbante.
target_elastic_x = 17;
target_elastic_y = -18;
target_post_length = 4;
target_post_diameter = 3.5;
elastic_diameter = 1.4;

// Corpo centralizado e acionador voltado para a extremidade superior da barra.
switch_center_x = 21;
switch_center_y = -38;
switch_center_z = -17;
switch_body_size = [12, 14, 7];
switch_mount_band = 4;
switch_contact_x = 29.5;
switch_contact_y_pressed = -34.5;
switch_contact_z_pressed = -14;
switch_contact_y_free = -36;
switch_contact_z_free = -10;
switch_actuator_diameter = 1.8;
switch_roller_diameter = 3;
switch_press_threshold = 0.65;

// ---------------------------------------------------------------------------
// Microswitch (envelope de referência)
// ---------------------------------------------------------------------------
// A chave é presa na face interna da lateral direita, nos dois furos de 2 mm
// que já existem na peça. O corpo avança para dentro do vão até encostar na
// faixa por onde passa o pino do alvo.
switch_thickness = 6.4;       // avanço para dentro do vão
switch_width = 10.2;
switch_length = 20;           // sentido Z, com os furos a 10 mm
switch_holes = [[-32, 12], [-32, 22]];  // furos já existentes na lateral
// A alavanca sai da ponta inferior do corpo e desce até a faixa por onde o
// dente do alvo sobe. Com o alvo levantado o dente encosta nela e fecha o
// contato; quando o alvo cai, a alavanca solta e o contato abre.
switch_lever_length = 11;
switch_lever_free_angle = 30;
switch_lever_pressed_angle = 22;

// ---------------------------------------------------------------------------
// Playfield
// ---------------------------------------------------------------------------
// A caixa do pinball mede 45 x 90 cm.
playfield_width = 450;
playfield_length = 900;
playfield_thickness = 10;
// Posição de UMA unidade na mesa. O X é a borda esquerda da cabeça de 30 mm;
// 210 + 15 = 225 mm, o centro da mesa.
reference_module_target_left = 210;
reference_module_origin_y = 640;
// Posição antiga mantida apenas para compatibilidade com anotações anteriores.
bank_position = [225, 640];
bank_angle = 0;
// Folga da abertura por onde a cabeça do alvo sobe.
playfield_slot_clearance = 0.5;

// ---------------------------------------------------------------------------
// Animação
// ---------------------------------------------------------------------------
// Instante em que o único alvo é derrubado e a janela de retorno. Valores de 0
// a 1, na escala do $t do OpenSCAD.
target_drop_time = 0.35;
target_drop_duration = 0.05;
reset_start = 0.62;
reset_duration = 0.28;

// Espaço entre peças na vista de mesa de impressão.
print_layout_gap = 8;
