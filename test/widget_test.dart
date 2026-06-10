// Pruebas básicas de humo para Path of Choices.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path_of_choices/data/level_generator.dart';
import 'package:path_of_choices/data/progress_repository.dart';
import 'package:path_of_choices/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Sin progreso guardado por defecto en cada prueba.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('La app arranca y muestra la pantalla de juego', (tester) async {
    await tester.pumpWidget(const PathOfChoicesApp());
    await tester.pump(); // procesa la carga asíncrona del progreso

    expect(find.byType(PathOfChoicesApp), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('El generador produce los 10 niveles con sus puertas', () {
    final levels = LevelGenerator.generate();

    expect(levels, hasLength(10));
    for (final level in levels) {
      expect(level.gates, isNotEmpty);
      expect(level.minCrowd, greaterThan(0));
    }
  });

  test('La generación es reproducible (semilla fija)', () {
    final a = LevelGenerator.generate();
    final b = LevelGenerator.generate();

    for (var i = 0; i < a.length; i++) {
      expect(a[i].gates.length, b[i].gates.length);
      for (var j = 0; j < a[i].gates.length; j++) {
        expect(a[i].gates[j].leftText, b[i].gates[j].leftText);
        expect(a[i].gates[j].rightText, b[i].gates[j].rightText);
      }
    }
  });

  group('ProgressRepository', () {
    test('por defecto no hay niveles desbloqueados (solo el primero)', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();
      expect(await repo.loadHighestUnlocked(), 0);
    });

    test('guarda y recupera el nivel más alto desbloqueado', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();

      await repo.saveHighestUnlocked(5);
      expect(await repo.loadHighestUnlocked(), 5);
    });

    test('lee un valor previamente persistido', () async {
      SharedPreferences.setMockInitialValues({'highest_unlocked_level': 3});
      final repo = ProgressRepository();
      expect(await repo.loadHighestUnlocked(), 3);
    });
  });
}
