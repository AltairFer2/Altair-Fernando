import 'package:flutter/material.dart';

/// Un widget que muestra una animación fotograma a fotograma (frame-by-frame)
/// a partir de una secuencia de imágenes en la carpeta de assets.
///
/// La animación se sincroniza directamente con el reloj del juego [animTime]
/// provisto por el ViewModel, evitando la sobrecarga de múltiples temporizadores.
class FrameAnimation extends StatelessWidget {
  const FrameAnimation({
    required this.basePath,
    required this.frameCount,
    required this.animTime,
    this.indexOffset = 0,
    this.ticksPerFrame = 5,
    this.fit = BoxFit.fill,
    super.key,
  });

  /// Ruta base del asset (ej: 'assets/images/runner/runner_').
  /// Los archivos finales se buscarán como `basePath + frameIndex + .png`.
  final String basePath;

  /// Cantidad total de fotogramas de la animación.
  final int frameCount;

  /// Tiempo actual del ciclo de juego (tick).
  final int animTime;

  /// Desfase único para evitar que todos los personajes se muevan en perfecta sincronía.
  final int indexOffset;

  /// Cantidad de ticks del juego que dura cada fotograma.
  /// Por ejemplo, un valor de 5 a 60 FPS equivale a ~83ms por frame.
  final int ticksPerFrame;

  /// Ajuste de la imagen en su contenedor.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // Calculamos el índice del frame actual basado en el animTime y el offset
    final frameIndex = ((animTime + indexOffset) ~/ ticksPerFrame) % frameCount;
    final imageAsset = '$basePath$frameIndex.png';

    return Image.asset(
      imageAsset,
      fit: fit,
      // filterQuality: FilterQuality.none mantiene los bordes pixelados nítidos (crisp retro art)
      filterQuality: FilterQuality.none,
      // gaplessPlayback evita parpadeos al alternar entre las imágenes de la secuencia
      gaplessPlayback: true,
    );
  }
}
