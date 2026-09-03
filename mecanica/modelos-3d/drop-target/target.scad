// Malha de referência do alvo móvel.
// Dimensões aproximadas: 38,4 x 80 x 12,5 mm.

module target() {
    import(file = "references/target.stl", convexity = 10);
}

target();
