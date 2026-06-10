import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el progreso del jugador entre sesiones.
///
/// Almacena el **índice del nivel más alto desbloqueado** (0 = solo el nivel 1
/// disponible). Usa `shared_preferences`, que funciona en móvil, web y
/// escritorio. Está aislado tras esta clase para que el resto del juego no
/// dependa directamente del mecanismo de almacenamiento (más fácil de testear
/// o de sustituir en el futuro).
class ProgressRepository {
  static const String _highestUnlockedKey = 'highest_unlocked_level';

  /// Devuelve el índice del nivel más alto desbloqueado. Si no hay nada
  /// guardado todavía, devuelve 0 (solo el primer nivel).
  Future<int> loadHighestUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highestUnlockedKey) ?? 0;
  }

  /// Guarda el índice del nivel más alto desbloqueado.
  Future<void> saveHighestUnlocked(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highestUnlockedKey, index);
  }
}
