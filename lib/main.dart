// PATH OF CHOICES — Juego de "crowd runner" con decisiones matemáticas.
//
// Arquitectura MVVM:
//   • models/      → datos puros del juego (puertas, niveles, partículas…)
//   • data/        → generación de niveles y persistencia del progreso
//   • viewmodels/  → estado y lógica del juego (ChangeNotifier)
//   • views/       → widgets de la interfaz (delgados)
//   • rendering/   → dibujo sobre Canvas y geometría compartida
//   • theme/       → paleta de colores
//
// Única dependencia externa: shared_preferences (guardar el progreso).
// El punto de entrada solo configura la app y arranca la primera pantalla.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/game_palette.dart';
import 'views/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PathOfChoicesApp());
}

/// Widget raíz de la aplicación.
class PathOfChoicesApp extends StatelessWidget {
  const PathOfChoicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path of Choices',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: GamePalette.bgTop,
      ),
      home: const GameScreen(),
    );
  }
}
