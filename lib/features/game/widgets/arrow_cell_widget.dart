import 'package:flutter/material.dart';
import '../models/arrow_direction.dart';
import '../models/cell.dart';
import '../../../app/colors.dart';

class ArrowCellWidget extends StatelessWidget {
  final Cell cell;
  final VoidCallback onTap;

  const ArrowCellWidget({super.key, required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color arrowColor;
    final Color borderColor;

    if (cell.isStart) {
      bg = AppColors.primary.withValues(alpha: 0.15);
      arrowColor = AppColors.primary;
      borderColor = AppColors.primary;
    } else if (cell.isExit) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.15);
      arrowColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFF16A34A);
    } else {
      switch (cell.state) {
        case CellState.traced:
          bg = AppColors.primary.withValues(alpha: 0.12);
          arrowColor = AppColors.primary;
          borderColor = AppColors.primary.withValues(alpha: 0.5);
        case CellState.deadEnd:
          bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
          arrowColor = const Color(0xFFD97706);
          borderColor = const Color(0xFFF59E0B);
        case CellState.idle:
          bg = Colors.white;
          arrowColor = AppColors.textPrimary.withValues(alpha: 0.55);
          borderColor = const Color(0xFFE5E7EB);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(28, 28),
            painter: _ArrowPainter(
              direction: cell.direction,
              color: arrowColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;

  const _ArrowPainter({required this.direction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final shaft = size.width * 0.28;
    final head = size.width * 0.22;

    // Rotation angle in radians
    final angle = switch (direction) {
      ArrowDirection.up => -3.14159 / 2,
      ArrowDirection.right => 0.0,
      ArrowDirection.down => 3.14159 / 2,
      ArrowDirection.left => 3.14159,
    };

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Shaft
    canvas.drawLine(Offset(-shaft, 0), Offset(shaft, 0), paint);

    // Head
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(shaft + head, 0)
      ..lineTo(shaft - head * 0.5, -head * 0.7)
      ..lineTo(shaft - head * 0.5, head * 0.7)
      ..close();
    canvas.drawPath(path, headPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.direction != direction || old.color != color;
}
