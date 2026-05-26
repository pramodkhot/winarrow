import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/colors.dart';
import '../../shared/ads/ad_service.dart';
import '../../shared/storage/local_storage.dart';
import 'logic/freedom_checker.dart';
import 'logic/puzzle_generator.dart';
import 'models/arrow_model.dart';
import 'models/puzzle_model.dart';
import 'widgets/arrow_painter.dart';
import 'models/cat_model.dart';
import 'widgets/brilliant_overlay.dart';
import 'widgets/cat_rescued_overlay.dart';
import 'widgets/hearts_widget.dart';

// Escape animation speed (pixels per second)
const _kEscapeSpeed = 500.0;

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int _maxHearts = 3;

  late PuzzleModel _puzzle;
  int _hearts = _maxHearts;
  bool _solved = false;
  bool _inputFrozen = false; // true during flash-error (500 ms)

  // Flash-error state
  int? _flashId;
  Timer? _flashTimer;

  // Escape animations: arrowId → controller
  final Map<int, AnimationController> _escapeCtrl = {};
  final Map<int, double> _escapeOffsets = {}; // pixels slid so far

  // Timer
  int _seconds = 0;
  Timer? _ticker;

  // Cat rescue state
  int _catSecondsLeft = 45;
  Timer? _catTimer;
  double _catEscapeOffset = 0;
  AnimationController? _catEscapeCtrl;

  // Grid metrics (computed in build)
  GridMetrics? _metrics;
  double _boardSize = 0;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.level);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _ticker?.cancel();
    _catTimer?.cancel();
    _catEscapeCtrl?.dispose();
    for (final c in _escapeCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Level lifecycle ──────────────────────────────────────────────────────────

  void _loadLevel(int level) {
    _puzzle = generatePuzzle(level);
    _hearts = _maxHearts;
    _solved = false;
    _inputFrozen = false;
    _flashId = null;
    _flashTimer?.cancel();
    for (final c in _escapeCtrl.values) {
      c.dispose();
    }
    _escapeCtrl.clear();
    _escapeOffsets.clear();
    _seconds = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_solved) setState(() => _seconds++);
    });
    // Cat state
    _catTimer?.cancel();
    _catEscapeCtrl?.dispose();
    _catEscapeCtrl = null;
    _catEscapeOffset = 0;
    _catSecondsLeft = 45;
    if (_puzzle.isCatLevel) _startCatTimer();
  }

  // ── Tap handler ──────────────────────────────────────────────────────────────

  void _onBoardTap(Offset localPos) {
    if (_inputFrozen || _solved) return;
    final metrics = _metrics;
    if (metrics == null) return;

    final hit = metrics.hitTest(localPos);
    if (hit == null) return;
    final (tapCol, tapRow) = hit;

    // Find which arrow was tapped (any cell of its body)
    final arrow = _puzzle.arrows.where((a) {
      if (a.status == ArrowStatus.freed || a.status == ArrowStatus.animating) {
        return false;
      }
      return a.cells.any((cell) => cell.$1 == tapCol && cell.$2 == tapRow);
    }).firstOrNull;

    if (arrow == null) return;

    if (canFree(arrow, _puzzle.arrows, _puzzle.cols, _puzzle.rows)) {
      _startEscape(arrow);
    } else {
      _triggerFlash(arrow);
    }
  }

  // ── Correct tap: escape animation ───────────────────────────────────────────

  void _startEscape(ArrowModel arrow) {
    HapticFeedback.selectionClick();

    setState(() {
      arrow.status = ArrowStatus.animating;
    });

    // Slide the entire snake body until its LAST cell exits the board edge.
    final metrics = _metrics;
    final cellSize = metrics?.cellSize ?? 40.0;
    final cs = arrow.cells;
    final totalPx = switch (arrow.headDir) {
      ArrowDir.right =>
        (_puzzle.cols - cs.map((c) => c.$1).reduce(min) + 1) * cellSize,
      ArrowDir.left => (cs.map((c) => c.$1).reduce(max) + 2) * cellSize,
      ArrowDir.up => (cs.map((c) => c.$2).reduce(max) + 2) * cellSize,
      ArrowDir.down =>
        (_puzzle.rows - cs.map((c) => c.$2).reduce(min) + 1) * cellSize,
    };
    final duration = Duration(
      milliseconds: (totalPx / _kEscapeSpeed * 1000).round().clamp(250, 1000),
    );

    final ctrl = AnimationController(vsync: this, duration: duration);
    _escapeCtrl[arrow.id] = ctrl;

    ctrl.addListener(() {
      setState(() {
        _escapeOffsets[arrow.id] = ctrl.value * totalPx;
      });
    });

    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          arrow.status = ArrowStatus.freed;
          _escapeOffsets.remove(arrow.id);
        });
        ctrl.dispose();
        _escapeCtrl.remove(arrow.id);
        _checkSolved();
        _checkCatFree();
      }
    });

    ctrl.forward();
  }

  void _checkSolved() async {
    // Cat levels complete via _checkCatFree, not arrow count.
    if (_puzzle.isCatLevel) return;

    final allFreed = _puzzle.arrows.every((a) => a.status == ArrowStatus.freed);
    if (!allFreed) return;

    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    final isNew = widget.level >= LocalStorage.currentLevel;
    if (isNew) await LocalStorage.advanceLevel();
    if (mounted) setState(() => _solved = true);
  }

  // ── Cat rescue ───────────────────────────────────────────────────────────────

  void _startCatTimer() {
    _catTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _solved) return;
      setState(() {
        _catSecondsLeft--;
        if (_catSecondsLeft <= 0) _onCatTimerExpired();
      });
    });
  }

  void _onCatTimerExpired() {
    _catTimer?.cancel();
    HapticFeedback.mediumImpact();
    _hearts--;
    _catSecondsLeft = 45;
    if (_hearts <= 0) {
      _ticker?.cancel();
      _showOutOfLives();
    } else {
      _startCatTimer();
    }
  }

  void _checkCatFree() {
    final cat = _puzzle.cat;
    if (cat == null || cat.status != CatStatus.waiting) return;

    final occupied = {
      for (final a in _puzzle.arrows)
        if (a.status != ArrowStatus.freed && a.status != ArrowStatus.animating)
          for (final cell in a.cells) cell.$1 * 1000 + cell.$2,
    };
    final (dx, dy) = cat.exitDir.vector;
    int c = cat.col + dx;
    int r = cat.row + dy;
    while (c >= 0 && c < _puzzle.cols && r >= 0 && r < _puzzle.rows) {
      if (occupied.contains(c * 1000 + r)) return; // still blocked
      c += dx;
      r += dy;
    }
    _startCatEscape();
  }

  void _startCatEscape() async {
    final cat = _puzzle.cat!;
    _catTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => cat.status = CatStatus.escaping);

    final cellSize = _metrics?.cellSize ?? 40.0;
    final totalPx = switch (cat.exitDir) {
      ArrowDir.right => (_puzzle.cols - cat.col + 1) * cellSize,
      ArrowDir.left => (cat.col + 2) * cellSize,
      ArrowDir.up => (cat.row + 2) * cellSize,
      ArrowDir.down => (_puzzle.rows - cat.row + 1) * cellSize,
    };

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _catEscapeCtrl = ctrl;

    ctrl.addListener(() {
      setState(() => _catEscapeOffset = ctrl.value * totalPx);
    });

    ctrl.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() => cat.status = CatStatus.freed);
        ctrl.dispose();
        _catEscapeCtrl = null;
        _ticker?.cancel();
        final isNew = widget.level >= LocalStorage.currentLevel;
        if (isNew) await LocalStorage.advanceLevel();
        if (mounted) setState(() => _solved = true);
      }
    });

    ctrl.forward();
  }

  // ── Blocked tap: flash error ─────────────────────────────────────────────────

  void _triggerFlash(ArrowModel arrow) {
    HapticFeedback.mediumImpact();
    _inputFrozen = true;

    setState(() {
      arrow.status = ArrowStatus.flashError;
      _flashId = arrow.id;
      _hearts--;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        arrow.status = ArrowStatus.locked;
        _flashId = null;
        _inputFrozen = false;
      });
      if (_hearts <= 0) {
        _ticker?.cancel();
        _showOutOfLives();
      }
    });
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showOutOfLives() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OutOfLivesDialog(
        onAddLives: () {
          Navigator.pop(context);
          // Show rewarded ad; grant lives on completion (fallback: grant immediately).
          AdService.instance.showRewarded(
            onRewarded: () {
              if (!mounted) return;
              setState(() {
                _hearts = _maxHearts;
                _inputFrozen = false;
                _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
                  if (!_solved) setState(() => _seconds++);
                });
              });
            },
          );
        },
        onRestart: () {
          Navigator.pop(context);
          setState(() => _loadLevel(widget.level));
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _difficultyLabel {
    if (widget.level <= 5) return 'Tutorial';
    if (widget.level <= 20) return 'Easy';
    if (widget.level <= 50) return 'Medium';
    return 'Hard';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    _boardSize = (screenW - 16)
        .clamp(200.0, screenH * 0.70)
        .clamp(200.0, 520.0);
    _metrics = GridMetrics.fit(
      Size(_boardSize, _boardSize),
      _puzzle.cols,
      _puzzle.rows,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  level: widget.level,
                  difficulty: _difficultyLabel,
                  timeLabel: _timeLabel,
                  onBack: () => Navigator.pop(context),
                  onRestart: () => setState(() => _loadLevel(widget.level)),
                ),
                const SizedBox(height: 12),
                HeartsWidget(hearts: _hearts),
                if (_puzzle.isCatLevel) ...[
                  const SizedBox(height: 8),
                  _CatTimerBar(secondsLeft: _catSecondsLeft),
                ],
                const SizedBox(height: 12),
                // Board
                GestureDetector(
                  onTapDown: (d) => _onBoardTap(d.localPosition),
                  child: Container(
                    width: _boardSize,
                    height: _boardSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        size: Size(_boardSize, _boardSize),
                        painter: BoardPainter(
                          cols: _puzzle.cols,
                          rows: _puzzle.rows,
                          arrows: _puzzle.arrows,
                          escapeOffsets: _escapeOffsets,
                          flashId: _flashId,
                          cat: _puzzle.cat,
                          catEscapeOffset: _catEscapeOffset,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _puzzle.isCatLevel
                      ? 'Clear the path to free the cat!'
                      : '${_puzzle.arrows.where((a) => a.status != ArrowStatus.freed).length} arrows remaining',
                  style: TextStyle(
                    fontSize: 13,
                    color: _puzzle.isCatLevel
                        ? const Color(0xFFF59E0B)
                        : AppColors.textGrey,
                    fontWeight: _puzzle.isCatLevel
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (_solved)
              _puzzle.isCatLevel
                  ? CatRescuedOverlay(
                      level: widget.level,
                      onContinue: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(level: widget.level + 1),
                        ),
                      ),
                    )
                  : BrilliantOverlay(
                      level: widget.level,
                      onContinue: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(level: widget.level + 1),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int level;
  final String difficulty;
  final String timeLabel;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const _Header({
    required this.level,
    required this.difficulty,
    required this.timeLabel,
    required this.onBack,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Level $level',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  difficulty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── Out of lives dialog ───────────────────────────────────────────────────────

class _OutOfLivesDialog extends StatelessWidget {
  final VoidCallback onAddLives;
  final VoidCallback onRestart;

  const _OutOfLivesDialog({required this.onAddLives, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: Color(0xFFE05252),
            ),
            const SizedBox(height: 12),
            const Text(
              'Out of Lives',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Watch an ad to get more lives\nor restart for free.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddLives,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text(
                  'Add More Lives',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Restart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cat timer bar ─────────────────────────────────────────────────────────────

class _CatTimerBar extends StatelessWidget {
  final int secondsLeft;
  const _CatTimerBar({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 10;
    final color = urgent ? const Color(0xFFE05252) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(urgent ? '⚠️' : '🐱', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            'Rescue the cat!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${secondsLeft}s',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
