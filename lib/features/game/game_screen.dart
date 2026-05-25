import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/colors.dart';
import '../../shared/storage/local_storage.dart';
import 'logic/path_generator.dart';
import 'models/difficulty.dart';
import 'models/puzzle.dart';
import 'widgets/brilliant_overlay.dart';
import 'widgets/dot_grid_painter.dart';
import 'widgets/hearts_widget.dart';

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _maxHearts = 3;

  late Puzzle _puzzle;
  late Difficulty _difficulty;
  int _progress = 0; // correctly traced segments
  int _hearts = _maxHearts;
  bool _solved = false;
  bool _gameOver = false;

  // Wrong-move flash
  (int, int)? _wrongFrom;
  (int, int)? _wrongTo;
  Timer? _flashTimer;

  // Drag state
  bool _isTracing = false;
  (int, int)? _lastDot;
  bool _wrongCooldown = false; // prevents rapid repeated deductions

  // Timer
  int _seconds = 0;
  Timer? _ticker;

  // Grid metrics (computed in build)
  double _gridSize = 0;
  double _cellW = 0;
  double _cellH = 0;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.level);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  // ── Level management ───────────────────────────────────────────────────────

  void _loadLevel(int level) {
    _difficulty = Difficulty.forLevel(level);
    _puzzle = PathGenerator.generate(_difficulty, seed: level * 7919);
    _progress = 0;
    _hearts = _maxHearts;
    _solved = false;
    _gameOver = false;
    _isTracing = false;
    _lastDot = null;
    _wrongFrom = null;
    _wrongTo = null;
    _seconds = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_solved && !_gameOver) setState(() => _seconds++);
    });
  }

  // ── Drag / snap logic ──────────────────────────────────────────────────────

  (int, int) _snapToDot(Offset local) {
    final c = (local.dx / _cellW - 0.5).round().clamp(0, _puzzle.cols - 1);
    final r = (local.dy / _cellH - 0.5).round().clamp(0, _puzzle.rows - 1);
    return (r, c);
  }

  void _onPanStart(DragStartDetails d) {
    if (_solved || _gameOver) return;
    final dot = _snapToDot(d.localPosition);
    final startDot = _puzzle.startDot;
    final leadDot = _puzzle.path[_progress];

    if (dot == startDot) {
      setState(() => _progress = 0);
      _lastDot = dot;
      _isTracing = true;
    } else if (dot == leadDot) {
      _lastDot = dot;
      _isTracing = true;
    } else {
      _isTracing = false;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isTracing || _solved || _gameOver) return;
    final dot = _snapToDot(d.localPosition);
    if (dot == _lastDot) return; // still on same dot

    final prevDot = _lastDot;
    _lastDot = dot;

    final leadDot = _puzzle.path[_progress];

    if (dot == leadDot) return; // moved back to current lead (no-op)

    final hasNext = _progress < _puzzle.segmentCount;
    final nextDot = hasNext ? _puzzle.path[_progress + 1] : null;
    final hasPrev = _progress > 0;
    final prevCorrect = hasPrev ? _puzzle.path[_progress - 1] : null;

    if (dot == nextDot) {
      // Correct segment traced
      HapticFeedback.selectionClick();
      setState(() {
        _progress++;
        _wrongFrom = null;
        _wrongTo = null;
      });
      if (_progress == _puzzle.segmentCount) _onSolved();
    } else if (dot == prevCorrect) {
      // Undo last correct step
      setState(() => _progress--);
    } else {
      // Wrong move
      if (!_wrongCooldown) {
        _wrongCooldown = true;
        HapticFeedback.mediumImpact();
        final from = prevDot ?? leadDot;
        setState(() {
          _wrongFrom = from;
          _wrongTo = dot;
          _hearts--;
        });
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted) {
            setState(() {
              _wrongFrom = null;
              _wrongTo = null;
            });
          }
          _wrongCooldown = false;
        });

        if (_hearts <= 0) {
          _ticker?.cancel();
          Future.delayed(const Duration(milliseconds: 400), _showOutOfLives);
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _isTracing = false;
  }

  // ── Solve / game over ──────────────────────────────────────────────────────

  void _onSolved() async {
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    final isNew = widget.level >= LocalStorage.currentLevel;
    if (isNew) await LocalStorage.advanceLevel();
    if (mounted) setState(() => _solved = true);
  }

  void _showOutOfLives() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OutOfLivesDialog(
        onAddLives: () {
          Navigator.pop(context);
          setState(() {
            _hearts = _maxHearts;
            _gameOver = false;
            _wrongCooldown = false;
            _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!_solved) setState(() => _seconds++);
            });
          });
        },
        onRestart: () {
          Navigator.pop(context);
          setState(() => _loadLevel(widget.level));
        },
      ),
    );
  }

  // ── Timer label ────────────────────────────────────────────────────────────

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    _gridSize = min(screenW - 32, screenH * 0.58).clamp(200.0, 440.0);
    _cellW = _gridSize / _puzzle.cols;
    _cellH = _gridSize / _puzzle.rows;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  level: widget.level,
                  difficulty: _difficulty.label,
                  timeLabel: _timeLabel,
                  onBack: () => Navigator.pop(context),
                  onRestart: () => setState(() => _loadLevel(widget.level)),
                ),
                const SizedBox(height: 12),
                HeartsWidget(hearts: _hearts),
                const SizedBox(height: 16),
                // Dot grid
                Center(
                  child: Container(
                    width: _gridSize,
                    height: _gridSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          size: Size(_gridSize, _gridSize),
                          painter: DotGridPainter(
                            rows: _puzzle.rows,
                            cols: _puzzle.cols,
                            path: _puzzle.path,
                            playerProgress: _progress,
                            wrongFrom: _wrongFrom,
                            wrongTo: _wrongTo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _Legend(),
              ],
            ),
            // Brilliant overlay
            if (_solved)
              BrilliantOverlay(
                level: widget.level,
                onContinue: () {
                  final next = widget.level + 1;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => GameScreen(level: next)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

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

// ── Legend ─────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(color: AppColors.primary, label: 'Start'),
        const SizedBox(width: 20),
        _Dot(color: const Color(0xFF16A34A), label: 'End'),
        const SizedBox(width: 20),
        _Dot(color: const Color(0xFFEF4444), label: 'Wrong'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

// ── Out of lives dialog ─────────────────────────────────────────────────────

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
              color: Color(0xFFEF4444),
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
