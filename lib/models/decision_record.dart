/// Registro de una decisión tomada en una puerta, usado en el resumen final.
class DecisionRecord {
  /// Etiqueta de la opción elegida (p. ej. "+5").
  final String gateText;

  /// Descripción legible de la opción.
  final String desc;

  /// Variación neta en el tamaño del grupo provocada por la decisión.
  final int delta;

  DecisionRecord(this.gateText, this.desc, this.delta);
}
