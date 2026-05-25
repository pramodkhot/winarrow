import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_model.dart';

// ── Spec color tokens ─────────────────────────────────────────────────────────

const kColorArrowDefault = Color(0xFF1A1A3E);
const kColorArrowFreed = Color(0xFF5B5BD6);
const kColorArrowBlocked = Color(0xFFE05252);
const kColorDotTrack = Color(0xFFC8C8E8);
const kColorBg = Colors.white;

// ── Grid metrics helper ───────────────────────────────────────────────────────

class GridMetrics {
  final double cellSize;
  final double offsetX;
  final double offsetY;
  final int cols;
  final int rows;

  const GridMetrics({
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.cols,
    required this.rows,
  });

  factory GridMetrics.fit(Size size, int cols, int rows) {
    final cell = min(size.width / cols, size.height / rows);
    return GridMetrics(
      cellSize: cell,
      offsetX: (size.width - cell * cols) / 2,
      offsetY: (size.height - cell * rows) / 2,
      cols: cols,
      rows: rows,
    );
  }

  Offset center(int col, int row) => Offset(
    offsetX + (col + 0.5) * cellSize,
    offsetY + (row + 0.5) * cellSize,
  );

  (int col, int row)? hitTest(Offset pos) {
    final col = ((pos.dx - offsetX) / cellSize).floor();
    final row = ((pos.dy - offsetY) / cellSize).floor();
    if (col < 0 || col >= cols || row < 0 || row >= rows) return null;
    return (col, row);
  }
}

// ── Board painter (dots + all arrows) ────────────────────────────────────────

class BoardPainter extends CustomPainter {
  final int cols;
  final int rows;
  final List<ArrowModel> arrows;
  final Map<int, double> escapeOffsets; // id → pixels slid so far
  final int? flashId; // arrow id currently flashing red

  const BoardPainter({
    required this.cols,
    required this.rows,
    required this.arrows,
    required this.escapeOffsets,
    this.flashId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = GridMetrics.fit(size, cols, rows);

    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = kColorBg,
    );

    // 2. Dot-rail grid
    final dotPaint = Paint()..color = kColorDotTrack;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        canvas.drawCircle(m.center(c, r), m.cellSize * 0.07, dotPaint);
      }
    }

    // 3. Arrows
    for (final arrow in arrows) {
      if (arrow.status == ArrowStatus.freed) continue;
      _drawArrow(canvas, arrow, m);
    }
  }

  void _drawArrow(Canvas canvas, ArrowModel arrow, GridMetrics m) {
    final isFlash = arrow.id == flashId;
    Color color;
    if (isFlash) {
      color = kColorArrowBlocked;
    } else if (arrow.status == ArrowStatus.animating) {
      color = kColorArrowFreed;
    } else {
      color = kColorArrowDefault;
    }

    final (dx, dy) = arrow.dir.vector;
    double slideX = 0, slideY = 0;
    if (arrow.status == ArrowStatus.animating) {
      final offset = escapeOffsets[arrow.id] ?? 0;
      slideX = dx * offset;
      slideY = dy * offset;
    }

    final tailCenter = m.center(arrow.col, arrow.row).translate(slideX, slideY);
    final headCenter = m
        .center(arrow.headCol, arrow.headRow)
        .translate(slideX, slideY);

    // Dot-rail for this arrow's track
    _drawDotRail(canvas, arrow, m, slideX, slideY);

    // Stroke (body line)
    canvas.drawLine(
      tailCenter,
      headCenter,
      Paint()
        ..color = color
        ..strokeWidth = m.cellSize * 0.14
        ..strokeCap = StrokeCap.round,
    );

    // Tail dot
    canvas.drawCircle(tailCenter, m.cellSize * 0.12, Paint()..color = color);

    // Arrowhead triangle at head
    _drawHead(canvas, headCenter, arrow.dir, m.cellSize, color);
  }

  void _drawDotRail(
    Canvas canvas,
    ArrowModel arrow,
    GridMetrics m,
    double slideX,
    double slideY,
  ) {
    // Dots between head and board edge (escape path)
    final (dx, dy) = arrow.dir.vector;
    int c = arrow.headCol + dx;
    int r = arrow.headRow + dy;
    final railPaint = Paint()..color = kColorDotTrack;
    while (c >= 0 && c < cols && r >= 0 && r < rows) {
      canvas.drawCircle(
        m.center(c, r).translate(slideX, slideY),
        m.cellSize * 0.09,
        railPaint,
      );
      c += dx;
      r += dy;
    }
  }

  void _drawHead(
    Canvas canvas,
    Offset center,
    ArrowDir dir,
    double cell,
    Color color,
  ) {
    final angle = switch (dir) {
      ArrowDir.right => 0.0,
      ArrowDir.left => pi,
      ArrowDir.up => -pi / 2,
      ArrowDir.down => pi / 2,
    };

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final hs = cell * 0.22; // half-size of head
    final path = Path()
      ..moveTo(hs * 1.4, 0)
      ..lineTo(-hs * 0.4, -hs)
      ..lineTo(-hs * 0.4, hs)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.arrows != arrows ||
      old.escapeOffsets != escapeOffsets ||
      old.flashId != flashId;
}
