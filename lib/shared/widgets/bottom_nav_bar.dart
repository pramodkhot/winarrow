import 'package:flutter/material.dart';
import '../storage/local_storage.dart';
import '../../app/colors.dart';

class WinArrowBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WinArrowBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = LocalStorage.currentLevel;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBg,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: level >= 20 ? Icons.filter_2_rounded : Icons.lock_rounded,
                label: 'Level 20',
                isActive: currentIndex == 1,
                isLocked: level < 20,
                onTap: () {
                  if (level < 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reach Level 20 to unlock!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    onTap(1);
                  }
                },
              ),
              _NavItem(
                icon: level >= 10 ? Icons.filter_1_rounded : Icons.lock_rounded,
                label: 'Level 10',
                isActive: currentIndex == 2,
                isLocked: level < 10,
                onTap: () {
                  if (level < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reach Level 10 to unlock!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    onTap(2);
                  }
                },
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive
        ? Colors.white
        : isLocked
            ? AppColors.textGrey.withValues(alpha: 0.4)
            : AppColors.textGrey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
