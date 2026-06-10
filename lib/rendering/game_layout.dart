import 'dart:math';
import 'package:flutter/material.dart';

/// Geometría de los elementos interactivos del juego.
///
/// Es la **fuente única de verdad** para la posición de los botones: el
/// [GamePainter] la usa para dibujarlos y la vista para detectar los toques.
/// Antes estas coordenadas estaban duplicadas (con números mágicos distintos
/// que casualmente coincidían), lo que era frágil ante cualquier ajuste.
class GameLayout {
  const GameLayout._();

  /// Botón "JUGAR" de la pantalla de menú.
  static Rect menuPlay(Size size) => Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.78),
        width: size.width * 0.7,
        height: 64,
      );

  /// Altura común de los botones de la pantalla de resultado.
  static const double resultButtonHeight = 56;

  static double _resultButtonWidth(Size size) => size.width * 0.42;
  static double _resultButtonTop(Size size) => size.height * 0.80;

  /// Botón "REINTENTAR".
  static Rect resultRetry(Size size) => Rect.fromLTWH(
        size.width * 0.06,
        _resultButtonTop(size),
        _resultButtonWidth(size),
        resultButtonHeight,
      );

  /// Botón "SIGUIENTE" (solo visible al ganar un nivel que no es el último).
  static Rect resultNext(Size size) => Rect.fromLTWH(
        size.width * 0.52,
        _resultButtonTop(size),
        _resultButtonWidth(size),
        resultButtonHeight,
      );

  /// Botón "MENÚ", centrado bajo la fila anterior.
  static Rect resultMenu(Size size) => Rect.fromLTWH(
        size.width / 2 - _resultButtonWidth(size) / 2,
        _resultButtonTop(size) + resultButtonHeight + 16,
        _resultButtonWidth(size),
        resultButtonHeight,
      );

  // ── Selección de niveles ──

  /// Total de niveles y número de columnas de la cuadrícula de selección.
  static const int levelCount = 10;
  static const int gridColumns = 3;

  static int get _gridRows => (levelCount / gridColumns).ceil();
  static double _gridMargin(Size size) => size.width * 0.08;
  static double _gridGap(Size size) => size.width * 0.04;
  static double _gridTop(Size size) => size.height * 0.20;

  static double _cellSize(Size size) {
    final usableW = size.width - _gridMargin(size) * 2;
    return (usableW - _gridGap(size) * (gridColumns - 1)) / gridColumns;
  }

  /// Celda (cuadrada) del nivel [index] dentro de la cuadrícula de selección.
  static Rect levelCell(Size size, int index) {
    final cell = _cellSize(size);
    final gap = _gridGap(size);
    final row = index ~/ gridColumns;
    final col = index % gridColumns;
    final x = _gridMargin(size) + col * (cell + gap);
    final y = _gridTop(size) + row * (cell + gap);
    return Rect.fromLTWH(x, y, cell, cell);
  }

  /// Botón "← MENÚ" de la pantalla de selección, situado bajo la cuadrícula.
  static Rect levelSelectBack(Size size) {
    final cell = _cellSize(size);
    final gap = _gridGap(size);
    final gridBottom = _gridTop(size) + _gridRows * (cell + gap);
    final w = size.width * 0.5;
    return Rect.fromLTWH(size.width / 2 - w / 2, gridBottom + 12, w, 48);
  }

  /// Calcula la lista de coordenadas (Offset) de cada miembro del grupo
  /// basándose en la coordenada base (cx, cy) de la masa y el número de elementos a mostrar.
  static List<Offset> crowdPositions({
    required double cx,
    required double cy,
    required int displayCount,
    required double maxSpread,
  }) {
    if (displayCount <= 0) return const [];
    final radius = maxSpread.clamp(14.0, max(14.0, sqrt(displayCount) * 7.5));
    final positions = <Offset>[];

    for (var i = 0; i < displayCount; i++) {
      final angle = i * 2.399963; // Ángulo áureo
      final r = radius * sqrt(i / displayCount);
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r * 0.5; // Achatar en Y para efecto perspectiva
      positions.add(Offset(px, py));
    }

    // Ordenar de atrás hacia adelante en Y (perspectiva de renderizado)
    positions.sort((a, b) => a.dy.compareTo(b.dy));
    return positions;
  }
}
