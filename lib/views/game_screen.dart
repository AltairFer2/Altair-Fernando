import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/frame_animation.dart';

import '../models/boss_type.dart';
import '../models/game_enums.dart';
import '../rendering/game_layout.dart';
import '../rendering/game_painter.dart';
import '../viewmodels/game_view_model.dart';

/// Vista principal del juego.
///
/// Es deliberadamente "delgada": crea el [GameViewModel] (proveyéndole el
/// `vsync`), le reenvía los gestos y delega todo el dibujo en [GamePainter]
/// junto a widgets dinámicos de Lottie para los personajes.
/// El repintado lo dispara el propio ViewModel a través de su [Listenable]
/// y se maneja de forma eficiente con [ListenableBuilder].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GameViewModel(vsync: this);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El ViewModel necesita el tamaño de pantalla para su lógica (posición de
    // proyectiles, detección de toques en botones…) sin depender de
    // `BuildContext`. Se lo pasamos aquí.
    _viewModel.screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      body: GestureDetector(
        onPanStart: (d) => _viewModel.onPointerMove(d.localPosition),
        onPanUpdate: (d) => _viewModel.onPointerMove(d.localPosition),
        onTapDown: (d) => _viewModel.onTapDown(d.localPosition),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final size = _viewModel.screenSize;
            final state = _viewModel.state;

            // Calcular posiciones de corredores y monstruo si corresponde
            final List<Widget> characterWidgets = [];

            if (state == GameState.playing ||
                state == GameState.boss ||
                state == GameState.bossOutro) {
              final outroP = state == GameState.bossOutro
                  ? _viewModel.bossOutroProgress
                  : 0.0;
              final pathW = size.width * 0.76;
              final cx = (state == GameState.playing)
                  ? (size.width / 2 - pathW / 2) +
                      pathW * _viewModel.playerX.clamp(0.0, 1.0)
                  : size.width / 2;
              final double cy;
              if (state == GameState.bossOutro) {
                if (_viewModel.playerWins) {
                  // Rebote de celebración: múltiples saltos que se amortiguan
                  cy = size.height * 0.82 -
                      sin(outroP * pi * 5).abs() * 40 * (1.0 - outroP);
                } else {
                  // Caída fuera de pantalla
                  cy = size.height * 0.82 + outroP * size.height * 0.30;
                }
              } else {
                cy = size.height * (state == GameState.playing ? 0.76 : 0.82);
              }
              final displayCount = max(1, _viewModel.crowdCount ~/ 10);
              final maxSpread = state == GameState.playing ? pathW * 0.38 : size.width * 0.26;

              final positions = GameLayout.crowdPositions(
                cx: cx,
                cy: cy,
                displayCount: displayCount,
                maxSpread: maxSpread,
              );

              final baseSz = (28.0 - displayCount * 0.15).clamp(14.0, 28.0);
              final sz = baseSz * 5.0;

              for (var i = 0; i < positions.length; i++) {
                final pos = positions[i];
                final runnerHeight = sz * 1.34;
                final Widget runnerWidget;
                if (state == GameState.bossOutro) {
                  runnerWidget = Image.asset(
                    _viewModel.playerWins
                        ? 'assets/images/runner/runner_victory.png'
                        : 'assets/images/runner/runner_defeat.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  );
                } else {
                  runnerWidget = FrameAnimation(
                    basePath: 'assets/images/runner/runner_',
                    frameCount: 5,
                    animTime: _viewModel.animTime,
                    indexOffset: i * 3,
                    ticksPerFrame: 5,
                    fit: BoxFit.fill,
                  );
                }
                characterWidgets.add(
                  Positioned(
                    left: pos.dx - sz / 2,
                    top: pos.dy - runnerHeight / 2,
                    width: sz,
                    height: runnerHeight,
                    child: IgnorePointer(
                      child: runnerWidget,
                    ),
                  ),
                );
              }
            }

            if (state == GameState.boss || state == GameState.bossOutro) {
              final outroP = state == GameState.bossOutro
                  ? _viewModel.bossOutroProgress
                  : 0.0;
              final cx = size.width / 2;
              final baseMonsterY = state == GameState.bossOutro
                  ? (_viewModel.playerWins
                      ? size.height * 0.33 + outroP * size.height * 0.42
                      : size.height * 0.33 - outroP * 20)
                  : size.height * 0.33 + sin(_viewModel.monBob) * 6;
              final baseScale = (size.height * 0.42 / 280).clamp(0.5, 1.3);
              final outroScaleMult = state == GameState.bossOutro
                  ? (_viewModel.playerWins
                      ? (1.0 - outroP * 0.88).clamp(0.02, 1.0)
                      : (1.0 + outroP * 0.28))
                  : 1.0;
              final scale = baseScale * outroScaleMult;
              final monsterSizeW = 160.0 * scale;
              final monsterSizeH = 180.0 * scale;
              final bossType = _viewModel.levels[_viewModel.currentLevel].bossType;
              final shake = (state == GameState.boss && _viewModel.bossShake > 0.5)
                  ? (Random().nextDouble() - 0.5) * _viewModel.bossShake
                  : 0.0;

              // Helper para crear un widget de monstruo
              Widget buildMonster(String basePath, int frames, double x, double y, String bossKey) {
                final Widget monsterWidget;
                if (state == GameState.bossOutro) {
                  final pose = _viewModel.playerWins ? 'defeat' : 'victory';
                  monsterWidget = Image.asset(
                    'assets/images/$bossKey/${bossKey}_$pose.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  );
                } else {
                  monsterWidget = FrameAnimation(
                    basePath: basePath,
                    frameCount: frames,
                    animTime: _viewModel.animTime,
                    ticksPerFrame: 12,
                    fit: BoxFit.fill,
                  );
                }

                return Positioned(
                  left: x - monsterSizeW / 2,
                  top: y - monsterSizeH / 2,
                  width: monsterSizeW,
                  height: monsterSizeH,
                  child: IgnorePointer(
                    child: monsterWidget,
                  ),
                );
              }

              switch (bossType) {
                case BossType.bossA:
                  characterWidgets.add(
                    buildMonster('assets/images/monster/monster_', 2, cx + shake, baseMonsterY, 'monster'),
                  );
                case BossType.bossB:
                  characterWidgets.add(
                    buildMonster('assets/images/monster_b/monster_b_', 2, cx + shake, baseMonsterY, 'monster_b'),
                  );
                case BossType.bossDual:
                  // Dos bosses lado a lado
                  final offsetX = monsterSizeW * 0.7;
                  characterWidgets.add(
                    buildMonster('assets/images/monster/monster_', 2, cx - offsetX + shake, baseMonsterY, 'monster'),
                  );
                  characterWidgets.add(
                    buildMonster('assets/images/monster_b/monster_b_', 2, cx + offsetX + shake, baseMonsterY, 'monster_b'),
                  );
              }
            }

            return Stack(
              children: [
                // Canvas de dibujo de fondo, portales, barras y HUD
                Positioned.fill(
                  child: CustomPaint(
                    painter: GamePainter(_viewModel),
                    size: Size.infinite,
                  ),
                ),
                // Capa superior de animaciones Lottie
                ...characterWidgets,
              ],
            );
          },
        ),
      ),
    );
  }
}
