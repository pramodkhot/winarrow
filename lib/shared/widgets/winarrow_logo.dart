import 'package:flutter/material.dart';

class WinArrowLogo extends StatelessWidget {
  final double size;
  const WinArrowLogo({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 1.2,
          colors: [Color(0xFF1E3A8A), Color(0xFF0D1B3E), Color(0xFF060D1F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.5),
            blurRadius: size * 0.28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // All coordinates designed for 120×120 viewBox
    final s = size.width / 120.0;
    canvas.scale(s, s);

    final whiteLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final blueLine = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ── W: Left arrow (↖) ──────────────────────────────────
    canvas.drawLine(const Offset(24, 84), const Offset(9, 43), whiteLine);
    _head(canvas, [
      const Offset(6, 40),
      const Offset(16, 49),
      const Offset(5, 54),
    ], Colors.white);

    // ── W: Centre arrow (↑) ────────────────────────────────
    canvas.drawLine(const Offset(46, 84), const Offset(46, 37), blueLine);
    _head(canvas, [
      const Offset(46, 30),
      const Offset(40, 42),
      const Offset(52, 42),
    ], const Color(0xFF93C5FD));

    // ── W: Right arrow (↗) ─────────────────────────────────
    canvas.drawLine(const Offset(68, 84), const Offset(83, 43), whiteLine);
    _head(canvas, [
      const Offset(86, 40),
      const Offset(76, 49),
      const Offset(87, 54),
    ], Colors.white);

    // ── Arrow body (gradient left→right) ───────────────────
    final bodyShader = const LinearGradient(
      colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    ).createShader(const Rect.fromLTWH(8, 84, 74, 13));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 84, 74, 13),
        const Radius.circular(3),
      ),
      Paint()..shader = bodyShader,
    );

    // ── Highlight strip (top edge glow) ────────────────────
    final hlShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x30FFFFFF), Color(0x00FFFFFF)],
    ).createShader(const Rect.fromLTWH(8, 84, 74, 13));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 84, 74, 13),
        const Radius.circular(3),
      ),
      Paint()..shader = hlShader,
    );

    // ── Arrow head triangle ─────────────────────────────────
    _head(canvas, [
      const Offset(112, 90),
      const Offset(82, 76),
      const Offset(82, 104),
    ], const Color(0xFF3B82F6));

    // ── Inner edge line (body/head separation) ──────────────
    canvas.drawLine(
      const Offset(82, 76),
      const Offset(82, 104),
      Paint()
        ..color = const Color(0xFF1D4ED8)
        ..strokeWidth = 1.5,
    );
  }

  void _head(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
