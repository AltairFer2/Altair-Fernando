import 'dart:math';

import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../models/level_config.dart';

/// Parámetros estáticos de cada uno de los 10 niveles.
///
/// Se mantiene separado de [LevelConfig] porque describe la "receta" del nivel
/// (incluido cuántas puertas generar), mientras que [LevelConfig] ya contiene
/// las puertas materializadas.
class _LevelRecipe {
  final String name;
  final int startCrowd;
  final int minCrowd;
  final int bossSecs;
  final Color bossColor;
  final String skulls;
  final int gateCount;

  const _LevelRecipe(
    this.name,
    this.startCrowd,
    this.minCrowd,
    this.bossSecs,
    this.bossColor,
    this.skulls,
    this.gateCount,
  );
}

/// Generador procedural de los niveles del juego.
///
/// Usa una semilla fija para que la secuencia de puertas sea idéntica en cada
/// partida (reproducibilidad). La dificultad de cada puerta escala según el
/// número de nivel mediante una cascada de generadores ([_simpleGate] …
/// [_extremeGate]).
class LevelGenerator {
  const LevelGenerator._();

  /// Semilla fija para resultados reproducibles entre partidas.
  static const int _seed = 42;

  static const List<_LevelRecipe> _recipes = [
    _LevelRecipe('El Camino del Aprendiz', 10, 18, 13, Color(0xFF22C55E), '😈', 4),
    _LevelRecipe('La Encrucijada', 12, 25, 12, Color(0xFF3B82F6), '😈😈', 5),
    _LevelRecipe('El Bosque Oscuro', 14, 30, 11, Color(0xFF8B5CF6), '😈😈', 5),
    _LevelRecipe('Las Arenas de la Trampa', 15, 35, 11, Color(0xFFEF4444), '😈😈😈', 6),
    _LevelRecipe('El Laberinto sin Salida', 16, 40, 10, Color(0xFFF97316), '😈😈😈', 7),
    _LevelRecipe('La Caverna Maldita', 18, 45, 9, Color(0xFF6366F1), '😈😈😈😈', 7),
    _LevelRecipe('El Volcán en Erupción', 20, 50, 9, Color(0xFFDC2626), '😈😈😈😈', 8),
    _LevelRecipe('La Tormenta de Acero', 22, 55, 8, Color(0xFF0EA5E9), '😈😈😈😈😈', 8),
    _LevelRecipe('El Abismo Eterno', 24, 60, 7, Color(0xFF7C2D12), '😈😈😈😈😈', 9),
    _LevelRecipe('¡El Desafío Legendario!', 25, 70, 6, Color(0xFF1C1917), '😈😈😈😈😈😈', 10),
  ];

  /// Genera la lista completa de niveles configurados y listos para jugar.
  static List<LevelConfig> generate() {
    final rng = Random(_seed);
    return _recipes.asMap().entries.map((entry) {
      final level = entry.key + 1;
      final recipe = entry.value;
      return LevelConfig(
        name: recipe.name,
        startCrowd: recipe.startCrowd,
        minCrowd: recipe.minCrowd,
        bossSecs: recipe.bossSecs,
        bossColor: recipe.bossColor,
        skulls: recipe.skulls,
        gates: _makeGates(rng, recipe.gateCount, level),
      );
    }).toList();
  }

  static List<GateModel> _makeGates(Random rng, int count, int level) {
    return List.generate(count, (i) {
      final t = (i + 1) / (count + 1);
      if (level <= 2) return _simpleGate(rng, t, level);
      if (level <= 4) return _mediumGate(rng, t, level);
      if (level <= 6) return _hardGate(rng, t, level);
      if (level <= 8) return _veryHardGate(rng, t, level);
      return _extremeGate(rng, t, level);
    });
  }

  static GateModel _simpleGate(Random rng, double t, int level) {
    final add = rng.nextInt(8) + 5;
    final sub = rng.nextInt(5) + 3;
    final useMultiply = rng.nextDouble() < 0.25 && level >= 2;
    if (useMultiply) {
      return GateModel(
        leftText: '×2',
        rightText: '-$sub',
        leftDesc: 'Duplicar grupo',
        rightDesc: 'Perder $sub personas',
        leftEffect: (c) => c * 2,
        rightEffect: (c) => max(1, c - sub),
        leftIsGood: true,
        triggerTime: t,
      );
    }
    final leftGood = rng.nextBool();
    return GateModel(
      leftText: leftGood ? '+$add' : '-$sub',
      rightText: leftGood ? '-$sub' : '+$add',
      leftDesc: leftGood ? 'Sumar $add personas' : 'Perder $sub personas',
      rightDesc: leftGood ? 'Perder $sub personas' : 'Sumar $add personas',
      leftEffect: leftGood ? (c) => c + add : (c) => max(1, c - sub),
      rightEffect: leftGood ? (c) => max(1, c - sub) : (c) => c + add,
      leftIsGood: leftGood,
      triggerTime: t,
    );
  }

  static GateModel _mediumGate(Random rng, double t, int level) {
    final roll = rng.nextDouble();
    if (roll < 0.3) {
      final a = rng.nextInt(6) + 8;
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '+$a' : '÷2',
        rightText: leftGood ? '÷2' : '+$a',
        leftDesc: leftGood ? 'Sumar $a' : 'Dividir entre 2',
        rightDesc: leftGood ? 'Dividir entre 2' : 'Sumar $a',
        leftEffect: leftGood ? (c) => c + a : (c) => max(1, c ~/ 2),
        rightEffect: leftGood ? (c) => max(1, c ~/ 2) : (c) => c + a,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else if (roll < 0.55) {
      final a = rng.nextInt(5) + 8;
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×2' : '+$a',
        rightText: leftGood ? '+$a' : '×2',
        leftDesc: leftGood ? 'Duplicar' : 'Sumar $a',
        rightDesc: leftGood ? 'Sumar $a' : 'Duplicar',
        leftEffect: leftGood ? (c) => c * 2 : (c) => c + a,
        rightEffect: leftGood ? (c) => c + a : (c) => c * 2,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else {
      return _simpleGate(rng, t, level);
    }
  }

  static GateModel _hardGate(Random rng, double t, int level) {
    final roll = rng.nextDouble();
    if (roll < 0.3) {
      final sub = rng.nextInt(10) + 15;
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×2' : '-$sub',
        rightText: leftGood ? '-$sub' : '×2',
        leftDesc: leftGood ? 'Duplicar' : 'Perder $sub',
        rightDesc: leftGood ? 'Perder $sub' : 'Duplicar',
        leftEffect: leftGood ? (c) => c * 2 : (c) => max(1, c - sub),
        rightEffect: leftGood ? (c) => max(1, c - sub) : (c) => c * 2,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else if (roll < 0.55) {
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×2' : '÷3',
        rightText: leftGood ? '÷3' : '×2',
        leftDesc: leftGood ? 'Duplicar' : 'Dividir entre 3',
        rightDesc: leftGood ? 'Dividir entre 3' : 'Duplicar',
        leftEffect: leftGood ? (c) => c * 2 : (c) => max(1, c ~/ 3),
        rightEffect: leftGood ? (c) => max(1, c ~/ 3) : (c) => c * 2,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else {
      return _mediumGate(rng, t, level);
    }
  }

  static GateModel _veryHardGate(Random rng, double t, int level) {
    final roll = rng.nextDouble();
    if (roll < 0.3) {
      final sub = rng.nextInt(20) + 30;
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×3' : '-$sub',
        rightText: leftGood ? '-$sub' : '×3',
        leftDesc: leftGood ? 'Triplicar' : 'Perder $sub',
        rightDesc: leftGood ? 'Perder $sub' : 'Triplicar',
        leftEffect: leftGood ? (c) => c * 3 : (c) => max(1, c - sub),
        rightEffect: leftGood ? (c) => max(1, c - sub) : (c) => c * 3,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else if (roll < 0.55) {
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×2' : '÷4',
        rightText: leftGood ? '÷4' : '×2',
        leftDesc: leftGood ? 'Duplicar' : 'Dividir entre 4',
        rightDesc: leftGood ? 'Dividir entre 4' : 'Duplicar',
        leftEffect: leftGood ? (c) => c * 2 : (c) => max(1, c ~/ 4),
        rightEffect: leftGood ? (c) => max(1, c ~/ 4) : (c) => c * 2,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else {
      return _hardGate(rng, t, level);
    }
  }

  static GateModel _extremeGate(Random rng, double t, int level) {
    final roll = rng.nextDouble();
    if (roll < 0.35) {
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '×3' : '÷4',
        rightText: leftGood ? '÷4' : '×3',
        leftDesc: leftGood ? 'Triplicar' : 'Dividir entre 4',
        rightDesc: leftGood ? 'Dividir entre 4' : 'Triplicar',
        leftEffect: leftGood ? (c) => c * 3 : (c) => max(1, c ~/ 4),
        rightEffect: leftGood ? (c) => max(1, c ~/ 4) : (c) => c * 3,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else if (roll < 0.6) {
      final sub = rng.nextInt(25) + 40;
      final add = rng.nextInt(10) + 20;
      final leftGood = rng.nextBool();
      return GateModel(
        leftText: leftGood ? '+$add' : '-$sub',
        rightText: leftGood ? '-$sub' : '+$add',
        leftDesc: leftGood ? 'Sumar $add' : 'Perder $sub',
        rightDesc: leftGood ? 'Perder $sub' : 'Sumar $add',
        leftEffect: leftGood ? (c) => c + add : (c) => max(1, c - sub),
        rightEffect: leftGood ? (c) => max(1, c - sub) : (c) => c + add,
        leftIsGood: leftGood,
        triggerTime: t,
      );
    } else {
      return _veryHardGate(rng, t, level);
    }
  }
}
