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
  final Map<int, double> escapeOffsets;
  final int? flashId;

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
        canvas.drawCircle(m.center(c, r), m.cellSize * 0.032, dotPaint);
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
    final Color color;
    if (isFlash) {
      color = kColorArrowBlocked;
    } else if (arrow.status == ArrowStatus.animating) {
      color = kColorArrowFreed;
    } else {
      color = kColorArrowDefault;
    }

    final (dx, dy) = arrow.headDir.vector;
    double slideX = 0, slideY = 0;
    if (arrow.status == ArrowStatus.animating) {
      final offset = escapeOffsets[arrow.id] ?? 0;
      slideX = dx * offset;
      slideY = dy * offset;
    }

    // Dot-rail in head direction (escape path hint)
    _drawDotRail(canvas, arrow, m, slideX, slideY);

    // Snake body: connected line segments through all path cells
    final bodyPath = Path();
    for (int i = 0; i < arrow.cells.length; i++) {
      final pt = m
          .center(arrow.cells[i].$1, arrow.cells[i].$2)
          .translate(slideX, slideY);
      if (i == 0) {
        bodyPath.moveTo(pt.dx, pt.dy);
      } else {
        bodyPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = color
        ..strokeWidth = m.cellSize * 0.020
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Tail dot (filled circle at start of path)
    final tailPt = m
        .center(arrow.tail.$1, arrow.tail.$2)
        .translate(slideX, slideY);
    canvas.drawCircle(tailPt, m.cellSize * 0.022, Paint()..color = color);

    // Arrowhead at head cell, pointing in headDir
    final headPt = m
        .center(arrow.headCol, arrow.headRow)
        .translate(slideX, slideY);
    _drawHead(canvas, headPt, arrow.headDir, m.cellSize, color);
  }

  void _drawDotRail(
    Canvas canvas,
    ArrowModel arrow,
    GridMetrics m,
    double slideX,
    double slideY,
  ) {
    final (dx, dy) = arrow.headDir.vector;
    int c = arrow.headCol + dx;
    int r = arrow.headRow + dy;
    final railPaint = Paint()..color = kColorDotTrack;
    while (c >= 0 && c < cols && r >= 0 && r < rows) {
      canvas.drawCircle(
        m.center(c, r).translate(slideX, slideY),
        m.cellSize * 0.035,
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

    final hs = cell * 0.075;
    final arrowPath = Path()
      ..moveTo(hs * 1.4, 0)
      ..lineTo(-hs * 0.4, -hs)
      ..lineTo(-hs * 0.4, hs)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.arrows != arrows ||
      old.escapeOffsets != escapeOffsets ||
      old.flashId != flashId;
}
