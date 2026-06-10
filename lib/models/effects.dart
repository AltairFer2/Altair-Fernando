import 'package:flutter/material.dart';

/// Proyectil que el grupo dispara hacia el monstruo en la fase de jefe.
class Bullet {
  double x, y;
  double targetX, targetY;
  double speed;

  Bullet(this.x, this.y, this.targetX, this.targetY, {this.speed = 6.0});
}

/// Texto flotante (p. ej. "+5") que asciende y se desvanece sobre el grupo.
class FloatingText {
  double x, y;
  String text;
  Color color;
  double opacity;
  double life;

  FloatingText(
    this.x,
    this.y,
    this.text,
    this.color, {
    this.opacity = 1.0,
    this.life = 1.0,
  });
}

/// Partícula de chispa para celebrar las decisiones positivas.
class Sparkle {
  double x, y, vx, vy;
  Color color;
  double life;
  double size;

  Sparkle(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.color, {
    this.life = 1.0,
    this.size = 3.0,
  });
}
