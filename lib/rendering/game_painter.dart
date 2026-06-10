import 'dart:math';

import 'package:flutter/material.dart';

import '../models/boss_type.dart';
import '../models/decision_record.dart';
import '../models/effects.dart';
import '../models/game_enums.dart';
import '../models/gate.dart';
import '../models/level_config.dart';
import '../theme/game_palette.dart';
import '../viewmodels/game_view_model.dart';
import 'game_layout.dart';

/// Renderiza por completo el juego sobre un [Canvas].
///
/// Lee el estado desde [GameViewModel] (pasado como `repaint`, de modo que se
/// repinta automáticamente en cada notificación) sin almacenar copias locales.
/// Los getters privados son simples atajos de lectura para mantener legible el
/// código de dibujo.
class GamePainter extends CustomPainter {
  GamePainter(this.vm) : super(repaint: vm);

  final GameViewModel vm;

  // ── Atajos de lectura del ViewModel ──
  GameState get state => vm.state;
  int get level => vm.currentLevel;
  List<LevelConfig> get levels => vm.levels;
  int get crowdCount => vm.crowdCount;
  double get playerX => vm.playerX;
  double get progress => vm.levelProgress;
  int get animTime => vm.animTime;
  bool get showHint => vm.showHint;
  List<FloatingText> get floatingTexts => vm.floatingTexts;
  List<Sparkle> get sparkles => vm.sparkles;
  List<DecisionRecord> get decisions => vm.decisions;
  double get bossHP => vm.bossHP;
  double get bossMaxHP => vm.bossMaxHP;
  double get bossTimer => vm.bossTimer;
  int get bossDuration => vm.bossDuration;
  bool get playerWins => vm.playerWins;
  List<Bullet> get bullets => vm.bullets;
  double get monBob => vm.monBob;
  double get bossShake => vm.bossShake;
  bool get bossFlash => vm.bossFlash;
  double get introProgress => vm.introProgress;
  bool get isChampion => vm.isChampion;
  int get highestUnlockedLevel => vm.highestUnlockedLevel;
  bool get isInDangerZone => vm.isInDangerZone;
  double get bossOutroProgress => vm.bossOutroProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    switch (state) {
      case GameState.menu:
        _drawMenu(canvas, size);
      case GameState.levelSelect:
        _drawLevelSelect(canvas, size);
      case GameState.levelIntro:
        _drawLevelIntro(canvas, size);
      case GameState.playing:
        _drawPlaying(canvas, size);
      case GameState.boss:
        _drawBoss(canvas, size);
      case GameState.bossOutro:
        _drawBossOutro(canvas, size);
      case GameState.result:
        _drawResult(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;

  // ════════════════════════════════ MENÚ ════════════════════════════

  void _drawMenu(Canvas canvas, Size size) {
    // Fondo en degradado
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GamePalette.bgTop, GamePalette.bgBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Partículas de ambiente
    _drawAmbientParticles(canvas, size, GamePalette.purple, 20);

    // Círculo del logo
    final cx = size.width / 2;
    final logoY = size.height * 0.28;
    final logoR = size.width * 0.16;
    final logoPaint = Paint()
      ..shader = const RadialGradient(
        colors: [GamePalette.violet, GamePalette.blue],
      ).createShader(Rect.fromCircle(center: Offset(cx, logoY), radius: logoR));
    canvas.drawCircle(Offset(cx, logoY), logoR, logoPaint);

    // Resplandor
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          GamePalette.violet.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, logoY), radius: logoR * 1.8),
      );
    canvas.drawCircle(Offset(cx, logoY), logoR * 1.8, glowPaint);

    // Icono de personas en el logo
    _drawPersonIcon(canvas, cx, logoY, logoR * 0.5);

    // Título
    _drawText(
      canvas,
      'PATH OF CHOICES',
      Offset(cx, size.height * 0.44),
      fontSize: 32,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      center: true,
    );

    // Subtítulo
    _drawText(
      canvas,
      'Guía al grupo a través de 10 niveles',
      Offset(cx, size.height * 0.50),
      fontSize: 14,
      color: Colors.white70,
      center: true,
    );

    // Fila decorativa de personajes
    final rowY = size.height * 0.60;
    for (var i = 0; i < 8; i++) {
      final px = size.width * 0.15 + (size.width * 0.7 / 7) * i;
      final color = GamePalette.shirtColors[i % GamePalette.shirtColors.length];
      canvas.drawCircle(Offset(px, rowY), 10, Paint()..color = color);
      canvas.drawCircle(
        Offset(px, rowY - 14),
        7,
        Paint()..color = GamePalette.skinColors[i % GamePalette.skinColors.length],
      );
    }

    // Botón JUGAR (geometría compartida con la detección de toques)
    final playRect = GameLayout.menuPlay(size);
    final btnRRect = RRect.fromRectAndRadius(playRect, const Radius.circular(28));
    final btnPaint = Paint()
      ..shader = const LinearGradient(
        colors: [GamePalette.violet, GamePalette.blue],
      ).createShader(playRect);
    // Sombra
    canvas.drawRRect(
      btnRRect.shift(const Offset(0, 4)),
      Paint()..color = GamePalette.violet.withValues(alpha: 0.4),
    );
    canvas.drawRRect(btnRRect, btnPaint);
    _drawText(
      canvas,
      'JUGAR',
      playRect.center,
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w800,
      center: true,
    );
  }

  void _drawPersonIcon(Canvas canvas, double cx, double cy, double sz) {
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy - sz * 0.3), sz * 0.22, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + sz * 0.15),
          width: sz * 0.5,
          height: sz * 0.55,
        ),
        Radius.circular(sz * 0.15),
      ),
      paint,
    );
    // Dos personas más pequeñas a los lados
    final sp = Paint()..color = Colors.white70;
    for (final dx in [-sz * 0.45, sz * 0.45]) {
      canvas.drawCircle(Offset(cx + dx, cy - sz * 0.15), sz * 0.14, sp);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + dx, cy + sz * 0.2),
            width: sz * 0.32,
            height: sz * 0.4,
          ),
          Radius.circular(sz * 0.1),
        ),
        sp,
      );
    }
  }

  // ═══════════════════════════ INTRO DE NIVEL ═══════════════════════

  void _drawLevelIntro(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GamePalette.bgTop, GamePalette.bgBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width / 2;
    final lvl = levels[level];

    _drawChip(
      canvas,
      cx,
      size.height * 0.18,
      'NIVEL ${level + 1} / 10',
      GamePalette.purple,
    );

    _drawText(
      canvas,
      '${level + 1}',
      Offset(cx, size.height * 0.33),
      fontSize: 80,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      center: true,
    );

    _drawText(
      canvas,
      lvl.name,
      Offset(cx, size.height * 0.44),
      fontSize: 22,
      color: GamePalette.lilac,
      fontWeight: FontWeight.w700,
      center: true,
    );

    _drawText(
      canvas,
      lvl.skulls,
      Offset(cx, size.height * 0.52),
      fontSize: 24,
      center: true,
    );

    _drawText(
      canvas,
      '🛡️ Necesitas ${lvl.minCrowd} personas para el jefe',
      Offset(cx, size.height * 0.60),
      fontSize: 14,
      color: Colors.white70,
      center: true,
    );

    // Barra de progreso de la intro
    final barW = size.width * 0.6;
    const barH = 8.0;
    final barY = size.height * 0.72;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, barY), width: barW, height: barH),
      const Radius.circular(4),
    );
    canvas.drawRRect(barRect, Paint()..color = const Color(0xFF1E1B4B));
    final fillW = barW * introProgress;
    if (fillW > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barW / 2, barY - barH / 2, fillW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        fillRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [GamePalette.violet, GamePalette.blue],
          ).createShader(fillRect.outerRect),
      );
    }
  }

  // ════════════════════════ SELECCIÓN DE NIVEL ══════════════════════

  void _drawLevelSelect(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GamePalette.bgTop, GamePalette.bgBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawAmbientParticles(canvas, size, GamePalette.purple, 18);

    final cx = size.width / 2;

    _drawText(
      canvas,
      'SELECCIONA NIVEL',
      Offset(cx, size.height * 0.10),
      fontSize: 26,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      center: true,
    );

    _drawText(
      canvas,
      'Desbloqueados: ${highestUnlockedLevel + 1} / ${GameLayout.levelCount}',
      Offset(cx, size.height * 0.15),
      fontSize: 13,
      color: Colors.white70,
      center: true,
    );

    for (var i = 0; i < levels.length; i++) {
      _drawLevelCell(
        canvas,
        GameLayout.levelCell(size, i),
        i,
        unlocked: vm.isLevelUnlocked(i),
        completed: i < highestUnlockedLevel,
      );
    }

    _drawButton(canvas, GameLayout.levelSelectBack(size), '← MENÚ',
        Colors.white.withValues(alpha: 0.15));
  }

  void _drawLevelCell(
    Canvas canvas,
    Rect cell,
    int index, {
    required bool unlocked,
    required bool completed,
  }) {
    final rrect = RRect.fromRectAndRadius(cell, const Radius.circular(16));

    if (unlocked) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GamePalette.violet, GamePalette.blue],
          ).createShader(cell),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawText(
        canvas,
        '${index + 1}',
        Offset(cell.center.dx, cell.center.dy - cell.height * 0.06),
        fontSize: cell.height * 0.36,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        center: true,
      );
      if (completed) {
        _drawText(
          canvas,
          '✓',
          Offset(cell.center.dx, cell.bottom - cell.height * 0.16),
          fontSize: cell.height * 0.2,
          color: GamePalette.positive,
          fontWeight: FontWeight.w900,
          center: true,
        );
      }
    } else {
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF15132E));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawText(
        canvas,
        '${index + 1}',
        Offset(cell.center.dx, cell.top + cell.height * 0.26),
        fontSize: cell.height * 0.2,
        color: Colors.white30,
        fontWeight: FontWeight.w700,
        center: true,
      );
      _drawText(
        canvas,
        '🔒',
        Offset(cell.center.dx, cell.center.dy + cell.height * 0.12),
        fontSize: cell.height * 0.26,
        center: true,
      );
    }
  }

  // ════════════════════════════════ JUEGO ═══════════════════════════

  void _drawPlaying(Canvas canvas, Size size) {
    // Fondo
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF060612), Color(0xFF0C0C26)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width / 2;
    final pathW = size.width * 0.76;
    final pathL = cx - pathW / 2;
    final pathR = cx + pathW / 2;

    // Camino
    final pathPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF10103A), Color(0xFF1C1C58)],
      ).createShader(Rect.fromLTWH(pathL, 0, pathW, size.height));
    canvas.drawRect(Rect.fromLTWH(pathL, 0, pathW, size.height), pathPaint);

    // Bordes neón
    final borderPaint = Paint()
      ..color = GamePalette.purple
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(pathL, 0), Offset(pathL, size.height), borderPaint);
    canvas.drawLine(Offset(pathR, 0), Offset(pathR, size.height), borderPaint);

    // Resplandor de los bordes
    final glowBorderPaint = Paint()
      ..color = GamePalette.purple.withValues(alpha: 0.20)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawLine(
        Offset(pathL, 0), Offset(pathL, size.height), glowBorderPaint);
    canvas.drawLine(
        Offset(pathR, 0), Offset(pathR, size.height), glowBorderPaint);

    // Líneas centrales discontinuas (animadas)
    final dashOffset = (animTime * 3.5) % 50;
    final dashPaint = Paint()
      ..color = GamePalette.purple.withValues(alpha: 0.30)
      ..strokeWidth = 4;
    for (var y = -50 + dashOffset; y < size.height; y += 50) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 25), dashPaint);
    }

    // Puertas
    final lvl = levels[level];
    for (final gate in lvl.gates) {
      _drawGate(canvas, size, gate, pathL, pathR, progress);
    }

    // Grupo
    final crowdCx = pathL + pathW * playerX.clamp(0.0, 1.0);
    final crowdY = size.height * 0.76;
    _drawCrowd(canvas, crowdCx, crowdY, crowdCount, max(1, crowdCount ~/ 10),
        pathW * 0.38, animTime);

    // Textos flotantes
    for (final ft in floatingTexts) {
      _drawText(
        canvas,
        ft.text,
        Offset(ft.x, ft.y),
        fontSize: 40,
        color: ft.color.withValues(alpha: ft.opacity),
        fontWeight: FontWeight.w900,
        center: true,
      );
    }

    // Chispas
    for (final s in sparkles) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.size * s.life,
        Paint()..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0)),
      );
    }

    // HUD
    _drawHUD(canvas, size);

    // Barra de progreso
    _drawProgressBar(canvas, size, progress);

    // Advertencia zona muerta / pista
    if (isInDangerZone) {
      final warnOp = (sin(animTime * 0.25) * 0.5 + 0.5).clamp(0.0, 1.0);
      _drawText(
        canvas,
        '¡ELIGE UN LADO!',
        Offset(cx, size.height * 0.68),
        fontSize: 22,
        color: GamePalette.danger.withValues(alpha: warnOp),
        fontWeight: FontWeight.w800,
        center: true,
      );
    } else if (showHint) {
      final hintOpacity = (sin(animTime * 0.08) * 0.3 + 0.7).clamp(0.0, 1.0);
      _drawText(
        canvas,
        '← Desliza para elegir →',
        Offset(cx, size.height * 0.68),
        fontSize: 18,
        color: Colors.white.withValues(alpha: hintOpacity),
        center: true,
      );
    }
  }

  void _drawGate(Canvas canvas, Size size, GateModel gate, double pathL,
      double pathR, double progress) {
    // La puerta aparece un 15% antes de su activación y desaparece poco después
    final appearAt = gate.triggerTime - 0.15;
    final disappearAt = gate.triggerTime + 0.05;
    if (progress < appearAt || progress > disappearAt) return;

    final gateProgress =
        ((progress - appearAt) / (gate.triggerTime - appearAt)).clamp(0.0, 1.0);
    final gateY = -80 + (size.height * 0.82) * gateProgress;
    if (gateY < -100 || gateY > size.height) return;

    final pathW = pathR - pathL;
    final gateW = pathW * 0.47;
    const gateH = 85.0;

    final lx = pathL + pathW * 0.25 - gateW / 2;
    final rx = pathL + pathW * 0.75 - gateW / 2;

    const deadZoneHalf = 0.10;
    final inDeadZone = (playerX - 0.5).abs() < deadZoneHalf;
    final isLeft = playerX < 0.5;

    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? lx : rx;
      final text = i == 0 ? gate.leftText : gate.rightText;
      final highlighted = !inDeadZone && ((i == 0 && isLeft) || (i == 1 && !isLeft));

      final gateRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, gateY, gateW, gateH),
        const Radius.circular(18),
      );
      canvas.drawRRect(
        gateRect,
        Paint()..color = const Color(0xFF4C1D95).withValues(alpha: 0.9),
      );

      if (highlighted && !gate.triggered) {
        canvas.drawRRect(
          gateRect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0,
        );
        canvas.drawRRect(
          gateRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      if (inDeadZone && !gate.triggered) {
        canvas.drawRRect(
          gateRect,
          Paint()
            ..color = GamePalette.danger.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0,
        );
      }

      _drawText(
        canvas,
        text,
        Offset(x + gateW / 2, gateY + gateH / 2),
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.w800,
        center: true,
      );
    }
  }

  void _drawHUD(Canvas canvas, Size size) {
    final badgeText = 'Nv.${level + 1}  👥 $crowdCount';
    const badgeW = 200.0;
    const badgeH = 50.0;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - badgeW / 2, 50, badgeW, badgeH),
      const Radius.circular(25),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = const Color(0xFF0C0C26).withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = GamePalette.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    _drawText(
      canvas,
      badgeText,
      Offset(size.width / 2, 50 + badgeH / 2),
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      center: true,
    );
  }

  void _drawProgressBar(Canvas canvas, Size size, double progress) {
    final barW = size.width * 0.85;
    const barH = 12.0;
    final barY = size.height - 50;
    final cx = size.width / 2;
    final barL = cx - barW / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barL, barY, barW, barH),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1E1B4B),
    );

    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barL, barY, barW * progress, barH),
          const Radius.circular(6),
        ),
        Paint()
          ..shader = const LinearGradient(
            colors: [GamePalette.violet, GamePalette.blue],
          ).createShader(Rect.fromLTWH(barL, barY, barW, barH)),
      );
    }

    _drawText(canvas, 'INICIO', Offset(barL, barY - 20),
        fontSize: 14, color: Colors.white54, center: true);
    _drawText(canvas, '⚔️ JEFE', Offset(barL + barW, barY - 20),
        fontSize: 14, color: Colors.white54, center: true);
  }

  // ════════════════════════════════ JEFE ════════════════════════════

  void _drawBoss(Canvas canvas, Size size) {
    // Fondo radial oscuro
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        radius: 1.2,
        colors: [Color(0xFF1A0A2E), Color(0xFF060612)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawAmbientParticles(canvas, size, GamePalette.danger, 15);

    final cx = size.width / 2;
    final lvl = levels[level];
    final bossType = lvl.bossType;

    // Título según el tipo de boss
    final bossTitle = switch (bossType) {
      BossType.bossA => '👾 MONSTRUO · Nv.${level + 1}',
      BossType.bossB => '😈 DEMONIO · Nv.${level + 1}',
      BossType.bossDual => '⚔️ ¡BATALLA FINAL! · Nv.${level + 1}',
    };

    // Barra de vida del monstruo
    final hpBarW = size.width * 0.8;
    const hpBarH = 24.0;
    const hpBarY = 70.0;
    final hpBarL = cx - hpBarW / 2;

    _drawText(canvas, bossTitle, Offset(cx, hpBarY - 24),
        fontSize: 18, color: Colors.white70, center: true);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hpBarL, hpBarY, hpBarW, hpBarH),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF1E1B4B),
    );
    final hpFrac = (bossHP / bossMaxHP).clamp(0.0, 1.0);
    if (hpFrac > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(hpBarL, hpBarY, hpBarW * hpFrac, hpBarH),
          const Radius.circular(12),
        ),
        Paint()
          ..shader = const LinearGradient(
            colors: [GamePalette.danger, GamePalette.warning],
          ).createShader(Rect.fromLTWH(hpBarL, hpBarY, hpBarW, hpBarH)),
      );
    }

    _drawText(canvas, 'HP: ${bossHP.toInt()}', Offset(cx, hpBarY + hpBarH + 14),
        fontSize: 15, color: Colors.white54, center: true);

    // Info de mínimo de personas
    final minColor = playerWins ? GamePalette.positive : const Color(0xFFF87171);
    _drawText(
      canvas,
      '🛡️ Mínimo ${lvl.minCrowd} personas para ganar',
      Offset(cx, hpBarY + hpBarH + 38),
      fontSize: 16,
      color: minColor,
      center: true,
    );

    // Temporizador
    final timerSecs = bossTimer.clamp(0.0, 999.0);
    var timerColor = Colors.white;
    if (timerSecs < bossDuration * 0.3) {
      timerColor = GamePalette.danger;
    } else if (timerSecs < bossDuration * 0.6) {
      timerColor = GamePalette.warning;
    }
    _drawText(canvas, '⏱ ${timerSecs.toStringAsFixed(1)}s',
        Offset(cx, hpBarY + hpBarH + 68),
        fontSize: 24, color: timerColor, fontWeight: FontWeight.w700,
        center: true);

    // Posiciones de los monstruos (manejadas por game_screen.dart como sprites)
    final monsterY = size.height * 0.33 + sin(monBob) * 6;
    final scale = (size.height * 0.42 / 280).clamp(0.5, 1.3);
    final monsterSizeW = 160.0 * scale;
    final shakeOffset = bossShake > 0.5
        ? (Random(animTime).nextDouble() - 0.5) * bossShake
        : 0.0;

    // Calcular posiciones de monstruo(s) para escudos e insignias
    final List<Offset> monsterPositions = switch (bossType) {
      BossType.bossA => [Offset(cx + shakeOffset, monsterY)],
      BossType.bossB => [Offset(cx + shakeOffset, monsterY)],
      BossType.bossDual => [
        Offset(cx - monsterSizeW * 0.7 + shakeOffset, monsterY),
        Offset(cx + monsterSizeW * 0.7 + shakeOffset, monsterY),
      ],
    };

    // Escudo y badge para cada monstruo
    for (final mPos in monsterPositions) {
      // Escudo si aún no se gana
      if (!playerWins) {
        final shieldOpacity =
            (sin(animTime * 0.06) * 0.15 + 0.25).clamp(0.0, 1.0);
        canvas.drawCircle(
          mPos,
          80 * scale,
          Paint()
            ..shader = RadialGradient(
              colors: [
                GamePalette.blue.withValues(alpha: shieldOpacity),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(center: mPos, radius: 80 * scale)),
        );
      }

      // Insignia sobre el monstruo
      final badgeColor =
          playerWins ? GamePalette.positive : const Color(0xFFF87171);
      _drawChip(canvas, mPos.dx, mPos.dy - 110 * scale, '👥 $crowdCount',
          badgeColor);
    }

    // Proyectiles
    for (final b in bullets) {
      canvas.drawCircle(
          Offset(b.x, b.y), 4, Paint()..color = const Color(0xFF93C5FD));
      canvas.drawCircle(
        Offset(b.x, b.y),
        8,
        Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.3),
      );
    }

    // Grupo en la parte inferior
    final crowdY = size.height * 0.82;
    _drawCrowd(canvas, cx, crowdY, crowdCount, max(1, crowdCount ~/ 10),
        size.width * 0.35, animTime);

    // Pista
    final hintOp = (sin(animTime * 0.08) * 0.3 + 0.7).clamp(0.0, 1.0);
    _drawText(canvas, '👆 ¡TOCA PARA DISPARAR!', Offset(cx, size.height * 0.94),
        fontSize: 18,
        color: Colors.white.withValues(alpha: hintOp),
        center: true);
  }

  // ═══════════════════════════ OUTRO DEL JEFE ══════════════════════

  void _drawBossOutro(Canvas canvas, Size size) {
    final p = bossOutroProgress;
    final cx = size.width / 2;

    // Fondo base del combate
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const RadialGradient(
          radius: 1.2,
          colors: [Color(0xFF1A0A2E), Color(0xFF060612)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    if (playerWins) {
      _drawVictoryOutro(canvas, size, cx, p);
    } else {
      _drawDefeatOutro(canvas, size, cx, p);
    }
  }

  void _drawVictoryOutro(Canvas canvas, Size size, double cx, double p) {
    // Flash blanco inicial
    final flashAlpha = (1.0 - p / 0.12).clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: flashAlpha * 0.85),
      );
    }

    // Resplandor dorado expandiéndose
    if (p > 0.08) {
      final glowP = ((p - 0.08) / 0.5).clamp(0.0, 1.0);
      final glowR = size.width * 0.8 * glowP;
      if (glowR > 0) {
        canvas.drawCircle(
          Offset(cx, size.height * 0.42),
          glowR,
          Paint()
            ..shader = RadialGradient(
              colors: [
                GamePalette.gold.withValues(alpha: 0.4 * (1.0 - glowP * 0.6)),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(
              center: Offset(cx, size.height * 0.42),
              radius: glowR,
            )),
        );
      }
    }

    // Confetti (seed fija → posiciones consistentes frame a frame)
    final rng = Random(42);
    const confettiColors = [
      GamePalette.gold, GamePalette.positive, Colors.white,
      GamePalette.violet, GamePalette.lilac, GamePalette.blue,
    ];
    for (var i = 0; i < 44; i++) {
      final baseAngle = rng.nextDouble() * pi * 2;
      final speed = 0.35 + rng.nextDouble() * 0.65;
      final r = p * speed * size.height * 0.62;
      final angle = baseAngle + p * 2.2;
      final x = cx + cos(angle) * r;
      final y = size.height * 0.42
          - sin(angle) * r * 0.55
          + p * size.height * 0.28 * speed;
      final life = (1.0 - p * 0.85).clamp(0.0, 1.0);
      if (life <= 0 || x < -10 || x > size.width + 10) continue;
      final w = 4.0 + rng.nextDouble() * 5;
      final h = 7.0 + rng.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(baseAngle + p * (i.isEven ? 5.0 : -4.0));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()
          ..color = confettiColors[i % confettiColors.length]
              .withValues(alpha: life),
      );
      canvas.restore();
    }

    // Texto ¡VICTORIA! con escala elástica
    if (p > 0.06) {
      final textP = ((p - 0.06) / 0.32).clamp(0.0, 1.0);
      final scale = Curves.elasticOut.transform(textP).clamp(0.0, 1.5);
      final alpha = textP.clamp(0.0, 1.0);
      if (scale > 0.01) {
        _drawText(canvas, '¡VICTORIA!',
          Offset(cx + 4, size.height * 0.38 + 4),
          fontSize: 54 * scale,
          color: GamePalette.gold.withValues(alpha: alpha * 0.55),
          fontWeight: FontWeight.w900,
          center: true,
        );
        _drawText(canvas, '¡VICTORIA!',
          Offset(cx, size.height * 0.38),
          fontSize: 54 * scale,
          color: Colors.white.withValues(alpha: alpha),
          fontWeight: FontWeight.w900,
          center: true,
        );
      }
    }

    // Subtítulo con nombre del nivel
    if (p > 0.45) {
      final subP = ((p - 0.45) / 0.25).clamp(0.0, 1.0);
      _drawText(canvas, 'Nivel ${level + 1} superado',
        Offset(cx, size.height * 0.47),
        fontSize: 20,
        color: GamePalette.gold.withValues(alpha: subP),
        center: true,
      );
    }

    // Estrellas orbitando el texto
    if (p > 0.28) {
      final starAlpha = ((1.0 - p) * 2.5).clamp(0.0, 1.0);
      final starP = ((p - 0.28) / 0.72).clamp(0.0, 1.0);
      if (starAlpha > 0) {
        for (var i = 0; i < 5; i++) {
          final starAngle = i * (2 * pi / 5) + starP * pi * 3;
          final starR = size.width * 0.27 * starP;
          final sx = cx + cos(starAngle) * starR;
          final sy = size.height * 0.38 + sin(starAngle) * starR * 0.32;
          _drawText(canvas, '⭐', Offset(sx, sy),
            fontSize: 18,
            color: GamePalette.gold.withValues(alpha: starAlpha),
            center: true,
          );
        }
      }
    }

    // Fade a verde al final
    if (p > 0.78) {
      final fadeP = ((p - 0.78) / 0.22).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = const Color(0xFF052E16).withValues(alpha: fadeP * 0.55),
      );
    }
  }

  void _drawDefeatOutro(Canvas canvas, Size size, double cx, double p) {
    // Flash rojo inicial
    final flashAlpha = (1.0 - p / 0.10).clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = GamePalette.danger.withValues(alpha: flashAlpha * 0.82),
      );
    }

    // Viñeta roja oscura que crece
    final vigAlpha = (p * 0.72).clamp(0.0, 0.72);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          radius: 0.88,
          colors: [
            Colors.transparent,
            GamePalette.danger.withValues(alpha: vigAlpha),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Brasas cayendo
    final rng = Random(13);
    for (var i = 0; i < 20; i++) {
      final ix = rng.nextDouble();
      final iy = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final x = size.width * ix;
      final rawY = (p * speed + iy * 0.3) % 1.0;
      final particleAlpha =
          ((p - 0.12) * 2).clamp(0.0, 0.7) * rng.nextDouble();
      if (particleAlpha <= 0) continue;
      canvas.drawCircle(
        Offset(x, size.height * rawY),
        2.0 + rng.nextDouble() * 4,
        Paint()
          ..color = GamePalette.warning.withValues(alpha: particleAlpha),
      );
    }

    // Texto DERROTA cayendo con rebote
    if (p > 0.04) {
      final textP = ((p - 0.04) / 0.38).clamp(0.0, 1.0);
      final bounced = Curves.bounceOut.transform(textP);
      final textY = -80.0 + (size.height * 0.38 + 80) * bounced;
      final alpha = textP.clamp(0.0, 1.0);

      _drawText(canvas, 'DERROTA',
        Offset(cx + 4, textY + 4),
        fontSize: 58,
        color: Colors.black.withValues(alpha: alpha * 0.65),
        fontWeight: FontWeight.w900,
        center: true,
      );
      _drawText(canvas, 'DERROTA',
        Offset(cx, textY),
        fontSize: 58,
        color: GamePalette.danger.withValues(alpha: alpha),
        fontWeight: FontWeight.w900,
        center: true,
      );
    }

    // Subtítulo
    if (p > 0.52) {
      final subP = ((p - 0.52) / 0.28).clamp(0.0, 1.0);
      _drawText(canvas, 'El grupo fue derrotado',
        Offset(cx, size.height * 0.47),
        fontSize: 19,
        color: Colors.white54.withValues(alpha: subP),
        center: true,
      );
    }

    // Oscurecer al final
    if (p > 0.78) {
      final darkP = ((p - 0.78) / 0.22).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withValues(alpha: darkP * 0.45),
      );
    }
  }

  // ═══════════════════════════════ RESULTADO ════════════════════════

  void _drawResult(Canvas canvas, Size size) {
    Color bg1, bg2;
    if (isChampion) {
      bg1 = const Color(0xFF78350F);
      bg2 = const Color(0xFFF59E0B).withValues(alpha: 0.15);
    } else if (playerWins) {
      bg1 = const Color(0xFF052E16);
      bg2 = const Color(0xFF14532D);
    } else {
      bg1 = const Color(0xFF450A0A);
      bg2 = const Color(0xFF7F1D1D);
    }
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bg1, bg2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width / 2;
    final lvl = levels[level];

    final emoji = isChampion ? '🏅' : (playerWins ? '🏆' : '💀');
    _drawText(canvas, emoji, Offset(cx, size.height * 0.1),
        fontSize: 80, center: true);

    final title =
        isChampion ? '¡CAMPEÓN!' : (playerWins ? '¡VICTORIA!' : 'DERROTA');
    _drawText(canvas, title, Offset(cx, size.height * 0.22),
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        center: true);

    _drawText(
      canvas,
      '👥 $crowdCount personas · 🛡️ Mínimo: ${lvl.minCrowd} · Nv.${level + 1}',
      Offset(cx, size.height * 0.30),
      fontSize: 16,
      color: Colors.white70,
      center: true,
    );

    // Lista de decisiones
    final listY = size.height * 0.36;
    final maxVisible = min(decisions.length, 8);
    for (var i = 0; i < maxVisible; i++) {
      final d = decisions[i];
      final y = listY + i * 44;
      final icon = d.delta >= 0 ? '⬆️' : '⬇️';
      final deltaText = d.delta >= 0 ? '+${d.delta}' : '${d.delta}';

      _drawText(canvas, '$icon Puerta ${d.gateText}: ${d.desc}', Offset(30, y),
          fontSize: 15, color: Colors.white70);
      _drawText(canvas, deltaText, Offset(size.width - 40, y),
          fontSize: 16,
          color: GamePalette.lilac,
          fontWeight: FontWeight.w700,
          center: true);
    }

    // Botones (geometría compartida con la detección de toques)
    _drawButton(canvas, GameLayout.resultRetry(size), 'REINTENTAR',
        GamePalette.danger);
    if (playerWins && !isChampion) {
      _drawButton(canvas, GameLayout.resultNext(size), 'SIGUIENTE',
          GamePalette.violet);
    }
    _drawButton(canvas, GameLayout.resultMenu(size), 'MENÚ',
        Colors.white.withValues(alpha: 0.15));
  }

  // ════════════════════════ AYUDANTES DE DIBUJO ═════════════════════

  void _drawButton(Canvas canvas, Rect rect, String text, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      Paint()..color = color,
    );
    _drawText(canvas, text, rect.center,
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w700,
        center: true);
  }

  void _drawChip(Canvas canvas, double cx, double cy, String text, Color color) {
    final tp = _makeTextPainter(text, 16, color, FontWeight.w600);
    tp.layout();
    final w = tp.width + 28;
    const h = 36.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, {
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w400,
    bool center = false,
  }) {
    final tp = _makeTextPainter(text, fontSize, color, fontWeight);
    tp.layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    final dy = center ? pos.dy - tp.height / 2 : pos.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  TextPainter _makeTextPainter(
      String text, double fontSize, Color color, FontWeight fontWeight) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }

  void _drawAmbientParticles(Canvas canvas, Size size, Color color, int count) {
    final rng = Random(42);
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = baseY + sin(animTime * 0.02 + i * 0.7) * 20;
      final opacity =
          (sin(animTime * 0.015 + i * 1.3) * 0.3 + 0.2).clamp(0.0, 1.0);
      final r = rng.nextDouble() * 3 + 1;
      canvas.drawCircle(
        Offset(x, y % size.height),
        r,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  // ════════════════════════════════ GRUPO ═══════════════════════════

  void _drawCrowd(Canvas canvas, double cx, double cy, int count, int display,
      double maxSpread, int animTime) {
    if (display <= 0) return;
    final radius = min(maxSpread, max(14.0, sqrt(display.toDouble()) * 60));
    final positions = <List<double>>[];

    for (var i = 0; i < display; i++) {
      final angle = i * 2.399963; // ángulo áureo
      final r = radius * sqrt(i / display);
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r * 0.5; // achatar en Y
      positions.add([px, py, i.toDouble()]);
    }

    // Ordenar por Y (de atrás hacia delante)
    positions.sort((a, b) => a[1].compareTo(b[1]));

    final sz = (28.0 - display * 0.15).clamp(14.0, 28.0);
    // for (final p in positions) {
    //   _drawPerson(canvas, p[0], p[1], p[2].toInt(), sz, animTime);
    // } // Rendered via Lottie in game_screen.dart

    // Insignia con el total
    if (count > 1) {
      final badgeText = '×$count';
      final tp = _makeTextPainter(badgeText, 18, Colors.white, FontWeight.w700);
      tp.layout();
      final bw = tp.width + 20;
      const bh = 30.0;
      final by = cy - radius * 0.5 - 40;
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, by), width: bw, height: bh),
        const Radius.circular(15),
      );
      canvas.drawRRect(
        badgeRect,
        Paint()..color = GamePalette.purple.withValues(alpha: 0.7),
      );
      tp.paint(canvas, Offset(cx - tp.width / 2, by - tp.height / 2));
    }
  }

  void _drawPerson(
      Canvas canvas, double px, double py, int idx, double sz, int animTime) {
    final shirtColor = GamePalette.shirtColors[idx % GamePalette.shirtColors.length];
    final hairColor = GamePalette.hairColors[idx % GamePalette.hairColors.length];
    final skinColor = GamePalette.skinColors[idx % GamePalette.skinColors.length];

    // Animación de carrera
    final phase = (animTime + idx * 13) * 0.018 + idx * 1.1;
    final legSwing = sin(phase);
    final legX = legSwing * sz * 0.26;
    final lLift = max(0.0, legSwing) * sz * 0.16;
    final rLift = max(0.0, -legSwing) * sz * 0.16;
    final bob = sin(phase * 2).abs() * sz * 0.07;
    final armSw = -legSwing * 0.42;
    final bodyY = py - bob;

    // 1. Sombra
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px, py + sz * 0.5),
        width: sz * 0.6,
        height: sz * 0.12 + bob * 0.5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 2. Piernas
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px - legX * 0.5, bodyY + sz * 0.35 - lLift),
        width: sz * 0.18,
        height: sz * 0.22,
      ),
      Paint()..color = const Color(0xFF1E3A5F),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px + legX * 0.5, bodyY + sz * 0.35 - rLift),
        width: sz * 0.18,
        height: sz * 0.22,
      ),
      Paint()..color = const Color(0xFF1E3A5F),
    );

    // 3. Zapatos
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px - legX * 0.6, bodyY + sz * 0.44 - lLift),
        width: sz * 0.14,
        height: sz * 0.08,
      ),
      Paint()..color = Colors.black87,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px + legX * 0.6, bodyY + sz * 0.44 - rLift),
        width: sz * 0.14,
        height: sz * 0.08,
      ),
      Paint()..color = Colors.black87,
    );

    // 4. Cuerpo / camiseta
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px, bodyY + sz * 0.1),
        width: sz * 0.38,
        height: sz * 0.35,
      ),
      Paint()..color = shirtColor,
    );

    // 5. Brillo de la camiseta
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px - sz * 0.05, bodyY + sz * 0.05),
        width: sz * 0.15,
        height: sz * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // 6. Brazos
    for (final side in [-1.0, 1.0]) {
      final armAngle = armSw * side;
      final armX = px + side * sz * 0.24;
      final armY = bodyY + sz * 0.1 + armAngle * sz * 0.15;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(armX, armY),
          width: sz * 0.12,
          height: sz * 0.2,
        ),
        Paint()..color = shirtColor,
      );
      canvas.drawCircle(
        Offset(armX, armY + sz * 0.12),
        sz * 0.05,
        Paint()..color = skinColor,
      );
    }

    // 7. Cuello
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px, bodyY - sz * 0.1),
        width: sz * 0.1,
        height: sz * 0.08,
      ),
      Paint()..color = skinColor,
    );

    // 8. Cabeza
    final headY = bodyY - sz * 0.22;
    canvas.drawCircle(Offset(px, headY), sz * 0.16, Paint()..color = skinColor);

    // 9. Brillo de la cabeza
    canvas.drawCircle(
      Offset(px - sz * 0.04, headY - sz * 0.06),
      sz * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    // 10. Pelo
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(px, headY - sz * 0.02),
        width: sz * 0.34,
        height: sz * 0.32,
      ),
      pi,
      pi,
      true,
      Paint()..color = hairColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px, headY - sz * 0.14),
        width: sz * 0.28,
        height: sz * 0.12,
      ),
      Paint()..color = hairColor,
    );

    // 11. Ojos
    for (final side in [-1.0, 1.0]) {
      final eyeX = px + side * sz * 0.06;
      final eyeY = headY + sz * 0.01;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(eyeX, eyeY),
          width: sz * 0.07,
          height: sz * 0.06,
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(Offset(eyeX, eyeY), sz * 0.02, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(eyeX + sz * 0.01, eyeY - sz * 0.01),
        sz * 0.008,
        Paint()..color = Colors.white,
      );
    }

    // 12. Sonrisa
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(px, headY + sz * 0.06),
        width: sz * 0.1,
        height: sz * 0.06,
      ),
      0,
      pi,
      false,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // ═══════════════════════════════ MONSTRUO ═════════════════════════

  void _drawMonster(Canvas canvas, double cx, double cy, double scale,
      bool flash, Color baseColor) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);

    final color = flash ? GamePalette.danger : baseColor;

    // Resplandor del destello
    if (flash) {
      canvas.drawCircle(
        Offset.zero,
        100,
        Paint()
          ..color = GamePalette.danger.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Cuerpo
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 120, height: 160),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-15, -5), width: 50, height: 80),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Cabeza
    canvas.drawCircle(const Offset(0, -65), 45, Paint()..color = color);

    // Cuernos
    final hornPaint = Paint()..color = Color.lerp(color, Colors.black, 0.3)!;
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(side * 25, -85)
        ..lineTo(side * 45, -130)
        ..lineTo(side * 15, -75)
        ..close();
      canvas.drawPath(path, hornPaint);
    }

    // Ojos
    for (final side in [-1.0, 1.0]) {
      final eyeX = side * 18;
      const eyeY = -70.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(eyeX, eyeY), width: 22, height: 16),
        Paint()..color = Colors.white,
      );
      final irisColor = flash ? GamePalette.danger : GamePalette.gold;
      canvas.drawCircle(Offset(eyeX, eyeY), 6, Paint()..color = irisColor);
      canvas.drawCircle(Offset(eyeX, eyeY), 3, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(eyeX + 3, eyeY - 3),
        2,
        Paint()..color = Colors.white,
      );

      // Cejas enfadadas
      canvas.drawLine(
        Offset(eyeX - side * 12, -82),
        Offset(eyeX + side * 5, -78),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Boca
    final mouthPath = Path()
      ..moveTo(-25, -48)
      ..quadraticBezierTo(0, -35, 25, -48);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );
    // Dientes
    for (var i = 0; i < 5; i++) {
      final tx = -20.0 + i * 10;
      final toothPath = Path()
        ..moveTo(tx, -48)
        ..lineTo(tx + 5, -40)
        ..lineTo(tx + 10, -48)
        ..close();
      canvas.drawPath(toothPath, Paint()..color = Colors.white);
    }

    // Brazos
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * 65, -10);
      canvas.rotate(side * 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 35, height: 70),
        Paint()..color = color,
      );
      // Garras
      for (var c = 0; c < 3; c++) {
        final cy2 = 30.0 + c * 8;
        final clawPath = Path()
          ..moveTo(side * 8, cy2)
          ..lineTo(side * 20, cy2 + 12)
          ..lineTo(side * 4, cy2 + 6)
          ..close();
        canvas.drawPath(
            clawPath, Paint()..color = Color.lerp(color, Colors.black, 0.4)!);
      }
      canvas.restore();
    }

    canvas.restore();
  }
}
