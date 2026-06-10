import 'package:flutter/material.dart';

import 'boss_type.dart';
import 'gate.dart';

/// Configuración de un nivel: parámetros de dificultad y sus puertas.
class LevelConfig {
  /// Nombre temático del nivel.
  final String name;

  /// Tamaño del grupo al empezar el nivel.
  final int startCrowd;

  /// Mínimo de personas necesario para poder vencer al jefe.
  final int minCrowd;

  /// Duración del combate contra el jefe, en segundos.
  final int bossSecs;

  /// Color base del monstruo del nivel.
  final Color bossColor;

  /// Indicador visual de dificultad (calaveras 😈).
  final String skulls;

  /// Tipo de jefe que aparece al final del nivel.
  final BossType bossType;

  /// Puertas de decisión que aparecerán durante el recorrido.
  final List<GateModel> gates;

  LevelConfig({
    required this.name,
    required this.startCrowd,
    required this.minCrowd,
    required this.bossSecs,
    required this.bossColor,
    required this.skulls,
    required this.bossType,
    required this.gates,
  });
}

