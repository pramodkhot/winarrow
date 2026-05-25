import 'package:flutter/material.dart';
import '../../../app/colors.dart';
import 'dot_grid_painter.dart';

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
  late final List<ConfettiParticle> _particles;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(55, ConfettiParticle.seeded);
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
            // Confetti
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => CustomPaint(
                painter: ConfettiPainter(particles: _particles, t: _ctrl.value),
                child: const SizedBox.expand(),
              ),
            ),
            // Content
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
