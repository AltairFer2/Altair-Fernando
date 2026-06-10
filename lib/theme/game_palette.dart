import 'package:flutter/material.dart';

/// Paleta de colores centralizada del juego.
///
/// Agrupa los colores reutilizados en varias pantallas y las listas de colores
/// usadas para dibujar a los personajes, evitando repetir literales hexa-
/// decimales por todo el código de render.
class GamePalette {
  const GamePalette._();

  // ── Fondos ──
  static const Color bgTop = Color(0xFF07071A);
  static const Color bgBottom = Color(0xFF12124A);

  // ── Acentos ──
  static const Color purple = Color(0xFF7C3AED);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color lilac = Color(0xFFA78BFA);

  // ── Indicadores ──
  static const Color positive = Color(0xFF4ADE80);
  static const Color negative = Color(0xFFC084FC);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF97316);
  static const Color gold = Color(0xFFFBBF24);

  /// Colores de camiseta de los personajes del grupo.
  static const List<Color> shirtColors = [
    Color(0xFFEF4444), // rojo
    Color(0xFF3B82F6), // azul
    Color(0xFF22C55E), // verde
    Color(0xFFF59E0B), // ámbar
    Color(0xFFEC4899), // rosa
    Color(0xFF8B5CF6), // violeta
    Color(0xFF06B6D4), // cian
    Color(0xFFF97316), // naranja
  ];

  /// Colores de cabello de los personajes.
  static const List<Color> hairColors = [
    Color(0xFF1C1917), // negro
    Color(0xFF78350F), // castaño
    Color(0xFFFBBF24), // rubio
    Color(0xFFB91C1C), // rojizo
    Color(0xFF1E3A5F), // azul marino
    Color(0xFF4C1D95), // morado oscuro
  ];

  /// Tonos de piel de los personajes.
  static const List<Color> skinColors = [
    Color(0xFFFDE8D0), // claro
    Color(0xFFD4A574), // medio
    Color(0xFFA0785A), // tostado
    Color(0xFF6B4226), // oscuro
  ];
}
