import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/colors.dart';

/// Stateless CustomPainter for the dot grid.
/// All interactive state is passed in; no gesture handling here.
class DotGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<(int, int)> path;
  final int playerProgress; // number of correctly traced segments
  final (int, int)? wrongFrom; // start dot of the wrong-move flash
  final (int, int)? wrongTo; // end dot of the wrong-move flash

  const DotGridPainter({
    required this.rows,
    required this.cols,
    required this.path,
    required this.playerProgress,
    this.wrongFrom,
    this.wrongTo,
  });

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// cellSize = gridSize / n  so dot[i] is at cellSize*(0.5 + i)
  static double cellSize(Size size, int n) => size.width / n;

  static Offset dotPos(Size size, int n, int r, int c) {
    final cell = cellSize(size, n);
    return Offset(cell * (0.5 + c), cell * (0.5 + r));
  }

  /// Snap a pixel position within the painter to the nearest dot index.
  static (int row, int col) snapToDot(
    Offset pos,
    Size size,
    int rows,
    int cols,
  ) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final c = (pos.dx / cellW - 0.5).round().clamp(0, cols - 1);
    final r = (pos.dy / cellH - 0.5).round().clamp(0, rows - 1);
    return (r, c);
  }

  // ── Paint ────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(int r, int c) => dotPos(size, cols, r, c);
    final cell = cellSize(size, cols);

    // 1. Background dots (lavender grid)
    final dotPaint = Paint()..color = const Color(0xFFD1D5DB);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(p(r, c), 3.5, dotPaint);
      }
    }

    // 2. Target path — dark navy lines
    final navyLine = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.75)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < path.length - 1; i++) {
      final from = p(path[i].$1, path[i].$2);
      final to = p(path[i + 1].$1, path[i + 1].$2);
      canvas.drawLine(from, to, navyLine);
      _arrowHead(
        canvas,
        from,
        to,
        AppColors.navy.withValues(alpha: 0.75),
        cell,
      );
    }

    // 3. Player traced segments — blue overlay
    if (playerProgress > 0) {
      final blueLine = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < playerProgress; i++) {
        final from = p(path[i].$1, path[i].$2);
        final to = p(path[i + 1].$1, path[i + 1].$2);
        canvas.drawLine(from, to, blueLine);
        _arrowHead(canvas, from, to, AppColors.primary, cell);
      }
    }

    // 4. Wrong-move flash — red
    if (wrongFrom != null && wrongTo != null) {
      final redLine = Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        p(wrongFrom!.$1, wrongFrom!.$2),
        p(wrongTo!.$1, wrongTo!.$2),
        redLine,
      );
    }

    // 5. Start dot — blue filled circle
    canvas.drawCircle(
      p(path.first.$1, path.first.$2),
      9,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      p(path.first.$1, path.first.$2),
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 6. End dot — green filled circle
    canvas.drawCircle(
      p(path.last.$1, path.last.$2),
      9,
      Paint()..color = const Color(0xFF16A34A),
    );
    canvas.drawCircle(
      p(path.last.$1, path.last.$2),
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  // ── Arrow head (drawn at 65% along the segment) ──────────────────────────

  void _arrowHead(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double cell,
  ) {
    final diff = to - from;
    final dist = diff.distance;
    if (dist < 1) return;

    final dir = diff / dist;
    final mid = from + diff * 0.65;
    final headLen = cell * 0.18;
    final headWid = cell * 0.12;
    final perp = Offset(-dir.dy, dir.dx);

    final tip = mid + dir * headLen;
    final left = mid - perp * headWid;
    final right = mid + perp * headWid;

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.playerProgress != playerProgress ||
      old.wrongFrom != wrongFrom ||
      old.wrongTo != wrongTo ||
      old.path != path;
}

// ── Confetti painter (used by BrilliantOverlay) ───────────────────────────────

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double t; // 0.0 → 1.0

  const ConfettiPainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = -p.size + (size.height + p.size * 2) * t * p.speed;
      if (y > size.height + p.size) continue;
      final x =
          p.startX * size.width +
          sin(p.phase + t * 5) * p.amplitude * size.width;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t;
}

class ConfettiParticle {
  final double startX;
  final double speed;
  final double phase;
  final double amplitude;
  final double spin;
  final Color color;
  final double size;
  final double rotation;

  const ConfettiParticle({
    required this.startX,
    required this.speed,
    required this.phase,
    required this.amplitude,
    required this.spin,
    required this.color,
    required this.size,
    required this.rotation,
  });

  factory ConfettiParticle.seeded(int seed) {
    final rng = Random(seed * 17 + 3);
    const colors = [
      AppColors.navy,
      AppColors.primary,
      Color(0xFF7C3AED),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      AppColors.primaryLight,
    ];
    return ConfettiParticle(
      startX: rng.nextDouble(),
      speed: 0.4 + rng.nextDouble() * 0.9,
      phase: rng.nextDouble() * pi * 2,
      amplitude: 0.02 + rng.nextDouble() * 0.04,
      spin: 2 + rng.nextDouble() * 4,
      color: colors[rng.nextInt(colors.length)],
      size: 6 + rng.nextDouble() * 9,
      rotation: rng.nextDouble() * pi,
    );
  }
}
