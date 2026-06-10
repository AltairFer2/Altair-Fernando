import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/level_generator.dart';
import '../data/progress_repository.dart';
import '../models/decision_record.dart';
import '../models/effects.dart';
import '../models/game_enums.dart';
import '../models/level_config.dart';
import '../rendering/game_layout.dart';
import '../theme/game_palette.dart';

/// ViewModel del juego: contiene **todo el estado y la lógica**.
///
/// No depende de `BuildContext`: la vista le inyecta el [TickerProvider] (para
/// animar el recorrido del nivel) y el [screenSize] actual. Notifica los
/// cambios mediante [ChangeNotifier], de modo que el render se actualiza sin
/// que la vista tenga que llamar a `setState`.
///
/// El progreso (nivel más alto desbloqueado) se carga y guarda a través de un
/// [ProgressRepository], inyectable para facilitar las pruebas.
class GameViewModel extends ChangeNotifier {
  GameViewModel({
    required TickerProvider vsync,
    ProgressRepository? progressRepository,
  }) : _progressRepository = progressRepository ?? ProgressRepository() {
    _levels = LevelGenerator.generate();
    _levelController = AnimationController(
      vsync: vsync,
      duration: _levelDuration,
    )
      ..addListener(_onLevelTick)
      ..addStatusListener(_onLevelStatus);
    unawaited(_loadProgress());
  }

  // ── Constantes de tiempo ──
  static const Duration _levelDuration = Duration(seconds: 14);
  static const Duration _frame = Duration(milliseconds: 16); // ~60 fps
  static const Duration _autoShootInterval = Duration(milliseconds: 500);
  static const Duration _hintDelay = Duration(milliseconds: 2200);
  static const int _introTicks = 90; // ~2.7 s a 30 ms/tick
  static const int _lastLevelIndex = 9;
  static const double _centreDeadZone = 0.10;

  /// Generador aleatorio reutilizable (antes se instanciaba en cada disparo).
  final Random _rng = Random();

  final ProgressRepository _progressRepository;
  bool _disposed = false;

  /// Tamaño de pantalla, provisto por la vista. Mantiene al ViewModel libre de
  /// dependencias con `BuildContext`/`MediaQuery`.
  Size _screenSize = Size.zero;
  Size get screenSize => _screenSize;
  set screenSize(Size value) => _screenSize = value;

  // ───────────────────────── Estado general ─────────────────────────
  GameState _state = GameState.menu;
  int _currentLevel = 0;
  int _crowdCount = 10;
  double _playerX = 0.5; // posición horizontal del grupo, 0..1
  late final List<LevelConfig> _levels;
  late final AnimationController _levelController;

  GameState get state => _state;
  int get currentLevel => _currentLevel;
  int get crowdCount => _crowdCount;
  double get playerX => _playerX;
  List<LevelConfig> get levels => _levels;
  LevelConfig get _level => _levels[_currentLevel];

  /// Progreso del recorrido del nivel actual (0.0–1.0).
  double get levelProgress => _levelController.value;

  // ───────────────────────────── Progreso ───────────────────────────
  int _highestUnlockedLevel = 0;

  /// Índice del nivel más alto desbloqueado (0 = solo el nivel 1).
  int get highestUnlockedLevel => _highestUnlockedLevel;

  /// Indica si el nivel [index] está disponible para jugar.
  bool isLevelUnlocked(int index) => index <= _highestUnlockedLevel;

  /// Verdadero cuando el jugador está en la zona muerta central y hay una
  /// puerta visible a punto de activarse (usado por el painter para la alerta).
  bool get isInDangerZone {
    if (_state != GameState.playing) return false;
    if ((_playerX - 0.5).abs() >= _centreDeadZone) return false;
    final p = _levelController.value;
    return _level.gates.any((g) => !g.triggered && p >= g.triggerTime - 0.15);
  }

  // ───────────────────────── Fase "playing" ─────────────────────────
  List<DecisionRecord> _decisions = [];
  List<FloatingText> _floatingTexts = [];
  List<Sparkle> _sparkles = [];
  int _animTime = 0;
  bool _showHint = true;
  Timer? _hintTimer;
  Timer? _gameTickTimer;

  List<DecisionRecord> get decisions => _decisions;
  List<FloatingText> get floatingTexts => _floatingTexts;
  List<Sparkle> get sparkles => _sparkles;
  int get animTime => _animTime;
  bool get showHint => _showHint;

  // ─────────────────────────── Fase "boss" ──────────────────────────
  double _bossHP = 100;
  double _bossMaxHP = 100;
  double _bossTimer = 0;
  int _bossDuration = 10;
  bool _playerWins = false;
  List<Bullet> _bullets = [];
  Timer? _bossTickTimer;
  Timer? _autoShootTimer;
  double _monBob = 0;
  double _bossShake = 0;
  bool _bossFlash = false;
  int _bossFlashFrames = 0;

  double get bossHP => _bossHP;
  double get bossMaxHP => _bossMaxHP;
  double get bossTimer => _bossTimer;
  int get bossDuration => _bossDuration;
  bool get playerWins => _playerWins;
  List<Bullet> get bullets => _bullets;
  double get monBob => _monBob;
  double get bossShake => _bossShake;
  bool get bossFlash => _bossFlash;

  // ─────────────────────── Fase "level intro" ───────────────────────
  double _introProgress = 0;
  Timer? _introTimer;
  double get introProgress => _introProgress;

  // ────────────────────────── Fase "result" ─────────────────────────
  bool _isChampion = false;
  bool get isChampion => _isChampion;

  // ═══════════════════════════ Carga de progreso ════════════════════

  Future<void> _loadProgress() async {
    final highest = await _progressRepository.loadHighestUnlocked();
    if (_disposed) return;
    _highestUnlockedLevel = highest.clamp(0, _lastLevelIndex);
    notifyListeners();
  }

  /// Desbloquea el siguiente nivel (si procede) y lo persiste. Se llama tras
  /// ganar un nivel.
  void _unlockNextLevel() {
    final next = _currentLevel + 1;
    if (next <= _lastLevelIndex && next > _highestUnlockedLevel) {
      _highestUnlockedLevel = next;
      unawaited(_progressRepository.saveHighestUnlocked(_highestUnlockedLevel));
    }
  }

  // ════════════════════════════ Navegación ══════════════════════════

  void goToMenu() {
    _cancelTimersAndAnimation();
    _state = GameState.menu;
    _currentLevel = 0;
    notifyListeners();
  }

  /// Abre la pantalla de selección de niveles.
  void goToLevelSelect() {
    _cancelTimersAndAnimation();
    _state = GameState.levelSelect;
    notifyListeners();
  }

  /// Inicia el nivel [index] si está desbloqueado.
  void selectLevel(int index) {
    if (!isLevelUnlocked(index)) return;
    _currentLevel = index;
    startLevelIntro();
  }

  void startLevelIntro() {
    _cancelTimersAndAnimation();
    _state = GameState.levelIntro;
    _introProgress = 0;
    notifyListeners();

    var ticks = 0;
    _introTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      ticks++;
      _introProgress = (ticks / _introTicks).clamp(0.0, 1.0);
      notifyListeners();
      if (ticks >= _introTicks) {
        t.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    _cancelTimersAndAnimation();
    final lvl = _level;
    _state = GameState.playing;
    _crowdCount = lvl.startCrowd;
    _playerX = 0.5;
    _decisions = [];
    _floatingTexts = [];
    _sparkles = [];
    _animTime = 0;
    _showHint = true;
    for (final gate in lvl.gates) {
      gate.reset();
    }
    notifyListeners();

    _levelController
      ..reset()
      ..forward();

    _hintTimer = Timer(_hintDelay, () {
      _showHint = false;
      notifyListeners();
    });
    _gameTickTimer = Timer.periodic(_frame, (_) {
      if (_state != GameState.playing) return;
      _animTime++;
      _updateParticles();
      notifyListeners();
    });
  }

  void _startBoss() {
    _cancelTimersAndAnimation();
    final lvl = _level;
    _playerWins = _crowdCount >= lvl.minCrowd;
    _state = GameState.boss;
    _bossHP = 100;
    _bossMaxHP = 100;
    _bossTimer = lvl.bossSecs.toDouble();
    _bossDuration = lvl.bossSecs;
    _bullets = [];
    _monBob = 0;
    _bossShake = 0;
    _bossFlash = false;
    _bossFlashFrames = 0;
    notifyListeners();

    _bossTickTimer = Timer.periodic(_frame, (_) {
      if (_state != GameState.boss) return;
      _tickBoss();
    });
    _autoShootTimer = Timer.periodic(_autoShootInterval, (_) {
      if (_state != GameState.boss) return;
      shoot();
    });
  }

  void _showResult() {
    _cancelTimersAndAnimation();
    _isChampion = _playerWins && _currentLevel == _lastLevelIndex;
    if (_playerWins) _unlockNextLevel();
    _state = GameState.result;
    notifyListeners();
  }

  // ══════════════════════════ Bucle del jefe ════════════════════════

  void _tickBoss() {
    _bossTimer -= 0.016;
    _monBob += 0.04;
    _animTime++;

    if (_playerWins) {
      _bossHP -= 100.0 / (_bossDuration / 0.016);
      if (_bossHP < 0) _bossHP = 0;
    }

    _advanceBullets();

    if (_bossFlash) {
      _bossFlashFrames--;
      if (_bossFlashFrames <= 0) _bossFlash = false;
    }
    if (_bossShake > 0) _bossShake *= 0.9;

    if (_bossTimer <= 0) {
      _bossTickTimer?.cancel();
      _autoShootTimer?.cancel();
      _showResult();
      return;
    }
    notifyListeners();
  }

  void _advanceBullets() {
    for (final b in _bullets) {
      final dx = b.targetX - b.x;
      final dy = b.targetY - b.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < b.speed) {
        b.x = b.targetX;
        b.y = b.targetY;
      } else {
        b.x += (dx / dist) * b.speed;
        b.y += (dy / dist) * b.speed;
      }
    }
    _bullets.removeWhere(
      (b) => (b.x - b.targetX).abs() < 5 && (b.y - b.targetY).abs() < 5,
    );
  }

  /// Lanza un proyectil desde el grupo hacia el monstruo.
  void shoot() {
    final size = _screenSize;
    if (size == Size.zero) return;

    final cx = size.width / 2;
    final crowdY = size.height * 0.78;
    final monsterY = size.height * 0.3;
    _bullets.add(
      Bullet(
        cx + (_rng.nextDouble() - 0.5) * 40,
        crowdY,
        cx + (_rng.nextDouble() - 0.5) * 30,
        monsterY,
        speed: 8.0,
      ),
    );
    if (_playerWins) {
      _bossFlash = true;
      _bossFlashFrames = 4;
      _bossShake = 8;
    }
    notifyListeners();
  }

  // ═══════════════════════ Recorrido del nivel ══════════════════════

  /// Listener del [AnimationController]: aplica las puertas cuyo momento de
  /// activación ya se ha alcanzado.
  void _onLevelTick() {
    if (_state != GameState.playing) return;
    final progress = _levelController.value;

    for (final gate in _level.gates) {
      if (gate.triggered || progress < gate.triggerTime) continue;

      gate.triggered = true;

      // Zona muerta: el jugador no eligió un lado claro → penalización del 30%
      if ((_playerX - 0.5).abs() < _centreDeadZone) {
        final before = _crowdCount;
        final penalty = (_crowdCount * 0.30).ceil().clamp(1, _crowdCount - 1);
        _crowdCount = (_crowdCount - penalty).clamp(1, 9999);
        _decisions.add(DecisionRecord('¡Indeciso!', 'Sin decisión', _crowdCount - before));
        _spawnGateEffects(_crowdCount - before);
        continue;
      }

      final choseLeft = _playerX < 0.5;
      gate.choseLeft = choseLeft;

      final before = _crowdCount;
      final effect = choseLeft ? gate.leftEffect : gate.rightEffect;
      _crowdCount = effect(_crowdCount);
      if (_crowdCount < 1) _crowdCount = 1;

      final delta = _crowdCount - before;
      final text = choseLeft ? gate.leftText : gate.rightText;
      final desc = choseLeft ? gate.leftDesc : gate.rightDesc;
      _decisions.add(DecisionRecord(text, desc, delta));

      _spawnGateEffects(delta);
    }
  }

  void _onLevelStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _state == GameState.playing) {
      _startBoss();
    }
  }

  /// Crea los textos flotantes y chispas tras atravesar una puerta.
  void _spawnGateEffects(int delta) {
    final size = _screenSize;
    if (size == Size.zero) return;

    final fx = size.width * _playerX;
    final fy = size.height * 0.72;
    if (delta > 0) {
      _floatingTexts.add(FloatingText(fx, fy, '+$delta', GamePalette.positive));
      for (var i = 0; i < 12; i++) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = _rng.nextDouble() * 3 + 1;
        _sparkles.add(
          Sparkle(
            fx,
            fy,
            cos(angle) * speed,
            sin(angle) * speed - 2,
            Color.lerp(
              GamePalette.positive,
              GamePalette.gold,
              _rng.nextDouble(),
            )!,
            size: _rng.nextDouble() * 3 + 2,
          ),
        );
      }
    } else if (delta < 0) {
      _floatingTexts.add(FloatingText(fx, fy, '$delta', GamePalette.negative));
    }
  }

  void _updateParticles() {
    for (final ft in _floatingTexts) {
      ft.y -= 1.2;
      ft.life -= 0.015;
      ft.opacity = ft.life.clamp(0.0, 1.0);
    }
    _floatingTexts.removeWhere((ft) => ft.life <= 0);

    for (final s in _sparkles) {
      s.x += s.vx;
      s.y += s.vy;
      s.vy += 0.05;
      s.life -= 0.02;
    }
    _sparkles.removeWhere((s) => s.life <= 0);
  }

  // ═══════════════════════════════ Input ════════════════════════════

  /// Movimiento horizontal del grupo (arrastre). Solo activo en juego.
  void onPointerMove(Offset localPosition) {
    if (_state != GameState.playing) return;
    final width = _screenSize.width;
    if (width <= 0) return;
    _playerX = (localPosition.dx / width).clamp(0.15, 0.85);
    notifyListeners();
  }

  /// Toque puntual: su efecto depende del estado actual del juego.
  void onTapDown(Offset localPosition) {
    final size = _screenSize;
    switch (_state) {
      case GameState.menu:
        if (GameLayout.menuPlay(size).contains(localPosition)) {
          goToLevelSelect();
        }
      case GameState.levelSelect:
        _handleLevelSelectTap(localPosition, size);
      case GameState.playing:
        if (size.width > 0) {
          _playerX = (localPosition.dx / size.width).clamp(0.15, 0.85);
          notifyListeners();
        }
      case GameState.boss:
        shoot();
      case GameState.result:
        _handleResultTap(localPosition, size);
      case GameState.levelIntro:
        break;
    }
  }

  void _handleLevelSelectTap(Offset pos, Size size) {
    if (GameLayout.levelSelectBack(size).contains(pos)) {
      goToMenu();
      return;
    }
    for (var i = 0; i < _levels.length; i++) {
      if (GameLayout.levelCell(size, i).contains(pos)) {
        selectLevel(i);
        return;
      }
    }
  }

  void _handleResultTap(Offset pos, Size size) {
    if (GameLayout.resultRetry(size).contains(pos)) {
      startLevelIntro();
      return;
    }
    if (_playerWins &&
        !_isChampion &&
        GameLayout.resultNext(size).contains(pos)) {
      _currentLevel++;
      startLevelIntro();
      return;
    }
    if (GameLayout.resultMenu(size).contains(pos)) {
      goToMenu();
    }
  }

  // ═════════════════════════════ Limpieza ═══════════════════════════

  void _cancelTimersAndAnimation() {
    _levelController.stop();
    _hintTimer?.cancel();
    _bossTickTimer?.cancel();
    _autoShootTimer?.cancel();
    _introTimer?.cancel();
    _gameTickTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimersAndAnimation();
    _levelController.dispose();
    super.dispose();
  }
}
