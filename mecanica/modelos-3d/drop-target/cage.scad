// Malha de referência do suporte do drop target.
// Dimensões aproximadas: 40 x 85 x 47,5 mm.

module cage() {
    import(file = "references/cage.stl", convexity = 10);
}

cage();
