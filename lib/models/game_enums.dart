/// Estados de alto nivel por los que transita el juego.
///
/// - [menu]: pantalla inicial con el botón JUGAR.
/// - [levelSelect]: cuadrícula para elegir nivel (bloqueados/desbloqueados).
/// - [levelIntro]: transición que presenta el nivel antes de empezar.
/// - [playing]: el grupo avanza por el camino atravesando puertas.
/// - [boss]: combate final contra el monstruo del nivel.
/// - [result]: pantalla de victoria/derrota con el resumen de decisiones.
enum GameState { menu, levelSelect, levelIntro, playing, boss, result }
