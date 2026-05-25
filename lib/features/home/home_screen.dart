import 'package:flutter/material.dart';
import '../../app/colors.dart';
import '../../shared/storage/local_storage.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/winarrow_logo.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _currentLevel = LocalStorage.currentLevel;
  }

  void _onNavTap(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ).then(
        (_) => setState(() {
          _currentLevel = LocalStorage.currentLevel;
        }),
      );
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ── Logo ──────────────────────────────────────────────
            const WinArrowLogo(size: 110),
            const SizedBox(height: 24),

            // ── App name ──────────────────────────────────────────
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Win',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Arrow',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Current level badge ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.levelBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Level $_currentLevel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.levelBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const Spacer(flex: 4),

            // ── Play button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GameScreen(level: LocalStorage.currentLevel),
                      ),
                    ).then(
                      (_) => setState(() {
                        _currentLevel = LocalStorage.currentLevel;
                      }),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: WinArrowBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
