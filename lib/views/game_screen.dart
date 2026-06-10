import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/frame_animation.dart';

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

            if (state == GameState.playing || state == GameState.boss) {
              final pathW = size.width * 0.76;
              final cx = state == GameState.playing
                  ? (size.width / 2 - pathW / 2) + pathW * _viewModel.playerX.clamp(0.0, 1.0)
                  : size.width / 2;
              final cy = size.height * (state == GameState.playing ? 0.76 : 0.82);
              final displayCount = _viewModel.crowdCount.clamp(1, 40);
              final maxSpread = state == GameState.playing ? pathW * 0.38 : size.width * 0.26;

              final positions = GameLayout.crowdPositions(
                cx: cx,
                cy: cy,
                displayCount: displayCount,
                maxSpread: maxSpread,
              );

              final baseSz = (28.0 - displayCount * 0.15).clamp(14.0, 28.0);
              final sz = baseSz * 7.5;

              for (var i = 0; i < positions.length; i++) {
                final pos = positions[i];
                final runnerHeight = sz * 1.34;
                characterWidgets.add(
                  Positioned(
                    left: pos.dx - sz / 2,
                    top: pos.dy - runnerHeight / 2,
                    width: sz,
                    height: runnerHeight,
                    child: IgnorePointer(
                      child: FrameAnimation(
                        basePath: 'assets/images/runner/runner_',
                        frameCount: 5,
                        animTime: _viewModel.animTime,
                        indexOffset: i * 3,
                        ticksPerFrame: 5,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                );
              }
            }

            if (state == GameState.boss) {
              final cx = size.width / 2;
              final monsterX = cx + (_viewModel.bossShake > 0.5 ? (Random().nextDouble() - 0.5) * _viewModel.bossShake : 0);
              final monsterY = size.height * 0.33 + sin(_viewModel.monBob) * 6;
              final scale = (size.height * 0.42 / 280).clamp(0.5, 1.3);
              final monsterSizeW = 160.0 * scale;
              final monsterSizeH = 180.0 * scale;

              characterWidgets.add(
                Positioned(
                  left: monsterX - monsterSizeW / 2,
                  top: monsterY - monsterSizeH / 2,
                  width: monsterSizeW,
                  height: monsterSizeH,
                  child: IgnorePointer(
                    child: FrameAnimation(
                      basePath: 'assets/images/monster/monster_',
                      frameCount: 2,
                      animTime: _viewModel.animTime,
                      ticksPerFrame: 12,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              );
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
