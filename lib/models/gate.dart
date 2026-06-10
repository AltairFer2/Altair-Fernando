/// Una puerta de decisión que aparece en el camino.
///
/// Ofrece dos opciones (izquierda/derecha). Cada una transforma el tamaño del
/// grupo mediante una operación matemática ([leftEffect] / [rightEffect]).
/// El jugador elige moviéndose hacia un lado antes de que la puerta se active.
class GateModel {
  /// Etiqueta corta mostrada en la puerta (p. ej. "+5", "×2", "÷3").
  final String leftText, rightText;

  /// Descripción legible de cada opción para el resumen final.
  final String leftDesc, rightDesc;

  /// Operación aplicada al grupo según la opción elegida.
  final int Function(int) leftEffect, rightEffect;

  /// Indica si la opción izquierda es la "buena" (solo para variar el diseño).
  final bool leftIsGood;

  /// Momento del recorrido (0.0–1.0) en el que la puerta se activa.
  final double triggerTime;

  /// Estado mutable durante la partida.
  bool triggered = false;
  bool? choseLeft;

  GateModel({
    required this.leftText,
    required this.rightText,
    required this.leftDesc,
    required this.rightDesc,
    required this.leftEffect,
    required this.rightEffect,
    required this.leftIsGood,
    required this.triggerTime,
  });

  /// Reinicia el estado mutable para poder volver a jugar el nivel.
  void reset() {
    triggered = false;
    choseLeft = null;
  }
}
