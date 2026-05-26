import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class CatRescuedOverlay extends StatefulWidget {
  final int level;
  final VoidCallback onContinue;

  const CatRescuedOverlay({
    super.key,
    required this.level,
    required this.onContinue,
  });

  @override
  State<CatRescuedOverlay> createState() => _CatRescuedOverlayState();
}

class _CatRescuedOverlayState extends State<CatRescuedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(55, _Particle.seeded);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.35, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onContinue,
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  t: _ctrl.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cat face
                  ScaleTransition(
                    scale: _scale,
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: _CatFacePainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ScaleTransition(
                    scale: _scale,
                    child: const Text(
                      'Rescued!',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
                    ),
                    child: Text(
                      'Cat saved at Level ${widget.level}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
                    ),
                    child: Text(
                      'Tap to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simple cat face for the overlay ──────────────────────────────────────────

class _CatFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xFFFEF3C7),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12,
    );

    for (final side in [-1.0, 1.0]) {
      final earTip = Offset(cx + side * r * 0.48, cy - r * 0.9);
      final earL = Offset(cx + side * r * 0.78, cy - r * 0.42);
      final earR = Offset(cx + side * r * 0.18, cy - r * 0.55);
      final path = Path()
        ..moveTo(earTip.dx, earTip.dy)
        ..lineTo(earL.dx, earL.dy)
        ..lineTo(earR.dx, earR.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFF59E0B));
    }

    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + side * r * 0.3, cy - r * 0.1),
        r * 0.12,
        Paint()..color = const Color(0xFF1A1A3E),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.18),
        width: r * 0.22,
        height: r * 0.15,
      ),
      Paint()..color = const Color(0xFFEC4899),
    );

    final wPaint = Paint()
      ..color = const Color(0xFF1A1A3E)
      ..strokeWidth = r * 0.045;
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(cx + side * r * 0.5, cy + r * 0.14),
        Offset(cx + side * r * 0.1, cy + r * 0.2),
        wPaint,
      );
      canvas.drawLine(
        Offset(cx + side * r * 0.5, cy + r * 0.28),
        Offset(cx + side * r * 0.1, cy + r * 0.27),
        wPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CatFacePainter old) => false;
}

// ── Confetti (same system as brilliant_overlay) ───────────────────────────────

class _Particle {
  final double startX;
  final double speed;
  final double phase;
  final double amplitude;
  final double spin;
  final Color color;
  final double size;
  final double rotation;

  const _Particle({
    required this.startX,
    required this.speed,
    required this.phase,
    required this.amplitude,
    required this.spin,
    required this.color,
    required this.size,
    required this.rotation,
  });

  factory _Particle.seeded(int seed) {
    final rng = Random(seed * 17 + 3);
    const colors = [
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF10B981),
      Color(0xFF7C3AED),
      Color(0xFF3B82F6),
      Color(0xFFF97316),
    ];
    return _Particle(
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

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  const _ConfettiPainter({required this.particles, required this.t});

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
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
