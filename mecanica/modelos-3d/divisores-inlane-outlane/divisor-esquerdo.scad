// ====================================================================
// DIVISORES INLANE/OUTLANE (VETOR IMPORTADO DO ILLUSTRATOR)
// ====================================================================
$fn = 60;

// Altura padrão da guia de pinball para conter a bolinha
altura_guia = 18.0; 

// O comando linear_extrude "estica" o seu desenho 2D para formar a peça 3D
linear_extrude(height = altura_guia) {
    // Digite o nome exato do arquivo SVG que você exportou do Illustrator
    import("divisor-esquerdo.svg");
}