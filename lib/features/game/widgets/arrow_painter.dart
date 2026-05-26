import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_model.dart';
import '../models/cat_model.dart';

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
  final CatModel? cat;
  final double catEscapeOffset;

  const BoardPainter({
    required this.cols,
    required this.rows,
    required this.arrows,
    required this.escapeOffsets,
    this.flashId,
    this.cat,
    this.catEscapeOffset = 0,
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

    // 4. Cat (drawn on top of arrows)
    if (cat != null && cat!.status != CatStatus.freed) {
      _drawCat(canvas, cat!, m);
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

  void _drawCat(Canvas canvas, CatModel catM, GridMetrics m) {
    final (dx, dy) = catM.exitDir.vector;
    final slideX = catM.status == CatStatus.escaping
        ? dx * catEscapeOffset
        : 0.0;
    final slideY = catM.status == CatStatus.escaping
        ? dy * catEscapeOffset
        : 0.0;

    final center = m.center(catM.col, catM.row).translate(slideX, slideY);
    final r = (m.cellSize * 0.44).clamp(10.0, 28.0);

    // Exit-path rail (amber tinted)
    {
      int c = catM.col + dx;
      int row = catM.row + dy;
      final railPaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.45);
      while (c >= 0 && c < cols && row >= 0 && row < rows) {
        canvas.drawCircle(
          m.center(c, row).translate(slideX, slideY),
          m.cellSize * 0.07,
          railPaint,
        );
        c += dx;
        row += dy;
      }
    }

    // Head (cream fill + amber border)
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFEF3C7));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13,
    );

    // Ears
    for (final side in [-1.0, 1.0]) {
      final earTip = center.translate(side * r * 0.48, -r * 0.88);
      final earL = center.translate(side * r * 0.78, -r * 0.42);
      final earR = center.translate(side * r * 0.18, -r * 0.55);
      final earPath = Path()
        ..moveTo(earTip.dx, earTip.dy)
        ..lineTo(earL.dx, earL.dy)
        ..lineTo(earR.dx, earR.dy)
        ..close();
      canvas.drawPath(earPath, Paint()..color = const Color(0xFFF59E0B));
    }

    // Eyes
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        center.translate(side * r * 0.3, -r * 0.1),
        r * 0.12,
        Paint()..color = const Color(0xFF1A1A3E),
      );
    }

    // Nose
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, r * 0.18),
        width: r * 0.22,
        height: r * 0.15,
      ),
      Paint()..color = const Color(0xFFEC4899),
    );

    // Whiskers (2 per side)
    final wPaint = Paint()
      ..color = const Color(0xFF1A1A3E)
      ..strokeWidth = r * 0.045;
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        center.translate(side * r * 0.48, r * 0.14),
        center.translate(side * r * 0.1, r * 0.2),
        wPaint,
      );
      canvas.drawLine(
        center.translate(side * r * 0.48, r * 0.28),
        center.translate(side * r * 0.1, r * 0.27),
        wPaint,
      );
    }

    // "FREE ME!" label below cat (only while waiting)
    if (catM.status == CatStatus.waiting) {
      final fontSize = (r * 0.38).clamp(6.0, 12.0);
      final tp = TextPainter(
        text: TextSpan(
          text: 'FREE ME!',
          style: TextStyle(
            color: const Color(0xFFF59E0B),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center.translate(-tp.width / 2, r + r * 0.18));
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.arrows != arrows ||
      old.escapeOffsets != escapeOffsets ||
      old.flashId != flashId ||
      old.catEscapeOffset != catEscapeOffset ||
      old.cat?.status != cat?.status;
}
