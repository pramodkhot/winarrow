import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/colors.dart';
import '../../shared/storage/local_storage.dart';
import 'logic/path_tracer.dart';
import 'models/arrow_direction.dart';
import 'models/cell.dart';
import 'models/level_data.dart';
import 'widgets/arrow_cell_widget.dart';

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LevelData _levelData;
  late List<List<Cell>> _grid;
  bool _solved = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.level);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadLevel(int level) {
    final idx = (level - 1).clamp(0, kLevels.length - 1);
    _levelData = kLevels[idx];
    _buildGrid();
    _seconds = 0;
    _solved = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_solved) setState(() => _seconds++);
    });
    _runTrace();
  }

  void _buildGrid() {
    _grid = List.generate(
      _levelData.rows,
      (r) => List.generate(
        _levelData.cols,
        (c) => Cell(
          row: r,
          col: c,
          direction: _levelData.grid[r * _levelData.cols + c],
          isStart: r == _levelData.startRow && c == _levelData.startCol,
          isExit: r == _levelData.exitRow && c == _levelData.exitCol,
        ),
      ),
    );
  }

  void _runTrace() {
    final result = tracePath(
      grid: _grid,
      startRow: _levelData.startRow,
      startCol: _levelData.startCol,
      exitRow: _levelData.exitRow,
      exitCol: _levelData.exitCol,
    );

    for (int r = 0; r < _levelData.rows; r++) {
      for (int c = 0; c < _levelData.cols; c++) {
        _grid[r][c] = _grid[r][c].copyWith(state: result.states[r][c]);
      }
    }

    if (result.solved && !_solved) {
      _solved = true;
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 300), _showWinDialog);
    }
  }

  void _onCellTap(int row, int col) {
    if (_solved) return;
    HapticFeedback.selectionClick();
    setState(() {
      _grid[row][col] = _grid[row][col].copyWith(
        direction: _grid[row][col].direction.rotated(),
      );
      _runTrace();
    });
  }

  Future<void> _showWinDialog() async {
    final isNewLevel = widget.level >= LocalStorage.currentLevel;
    if (isNewLevel) await LocalStorage.advanceLevel();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(
        level: widget.level,
        seconds: _seconds,
        onNext: () {
          Navigator.pop(context); // close dialog
          final nextLevel = widget.level + 1;
          if (nextLevel <= kLevels.length) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => GameScreen(level: nextLevel)),
            );
          } else {
            Navigator.pop(context); // back to home if no more levels
          }
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onReplay: () {
          Navigator.pop(context);
          setState(() => _loadLevel(widget.level));
        },
      ),
    );
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              level: widget.level,
              timeLabel: _timeLabel,
              onBack: () => Navigator.pop(context),
              onRestart: () => setState(() => _loadLevel(widget.level)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _GridView(grid: _grid, onTap: _onCellTap),
            ),
            const SizedBox(height: 16),
            _Legend(
              startRow: _levelData.startRow,
              startCol: _levelData.startCol,
              exitRow: _levelData.exitRow,
              exitCol: _levelData.exitCol,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int level;
  final String timeLabel;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const _Header({
    required this.level,
    required this.timeLabel,
    required this.onBack,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
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
          IconButton(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

class _GridView extends StatelessWidget {
  final List<List<Cell>> grid;
  final void Function(int row, int col) onTap;

  const _GridView({required this.grid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rows = grid.length;
    final cols = grid[0].length;
    final screenW = MediaQuery.of(context).size.width;
    final cellSize = ((screenW - 48) / cols).clamp(44.0, 76.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(cols, (c) {
                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: ArrowCellWidget(
                      cell: grid[r][c],
                      onTap: () => onTap(r, c),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final int startRow, startCol, exitRow, exitCol;

  const _Legend({
    required this.startRow,
    required this.startCol,
    required this.exitRow,
    required this.exitCol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Dot(color: AppColors.primary, label: 'Start ($startRow,$startCol)'),
          const SizedBox(width: 24),
          _Dot(
            color: const Color(0xFF16A34A),
            label: 'Exit ($exitRow,$exitCol)',
          ),
          const SizedBox(width: 24),
          _Dot(color: const Color(0xFFF59E0B), label: 'Dead end'),
        ],
      ),
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

// ── Win dialog ────────────────────────────────────────────────────────────────

class _WinDialog extends StatelessWidget {
  final int level;
  final int seconds;
  final VoidCallback onNext;
  final VoidCallback onHome;
  final VoidCallback onReplay;

  const _WinDialog({
    required this.level,
    required this.seconds,
    required this.onNext,
    required this.onHome,
    required this.onReplay,
  });

  String get _time {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Level Complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Level $level  •  $_time',
              style: const TextStyle(fontSize: 15, color: AppColors.textGrey),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Next Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReplay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Replay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
