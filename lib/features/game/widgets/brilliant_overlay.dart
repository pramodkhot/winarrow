import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class BrilliantOverlay extends StatefulWidget {
  final int level;
  final VoidCallback onContinue;

  const BrilliantOverlay({
    super.key,
    required this.level,
    required this.onContinue,
  });

  @override
  State<BrilliantOverlay> createState() => _BrilliantOverlayState();
}

class _BrilliantOverlayState extends State<BrilliantOverlay>
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
                  ScaleTransition(
                    scale: _scale,
                    child: const Text(
                      'Brilliant!',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
                    ),
                    child: Text(
                      'Level ${widget.level} Complete',
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

// ── Confetti ──────────────────────────────────────────────────────────────────

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
      AppColors.navy,
      AppColors.primary,
      Color(0xFF7C3AED),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      AppColors.primaryLight,
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
