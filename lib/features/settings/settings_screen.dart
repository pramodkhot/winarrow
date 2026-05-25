import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/colors.dart';
import '../../shared/storage/local_storage.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sounds;
  late bool _vibrations;
  late bool _darkMode;
  bool _accountConnected = false;

  @override
  void initState() {
    super.initState();
    _sounds     = LocalStorage.soundsEnabled;
    _vibrations = LocalStorage.vibrationsEnabled;
    _darkMode   = LocalStorage.darkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  // ── Group 1: Preferences ──────────────────────────
                  _Card(children: [
                    _NavRow(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      trailing: const Text(
                        'English  ›',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                      ),
                      onTap: () {},
                    ),
                    const _Divider(),
                    _ToggleRow(
                      icon: Icons.vibration_rounded,
                      label: 'Vibrations',
                      value: _vibrations,
                      onChanged: (v) async {
                        await LocalStorage.setVibrationsEnabled(v);
                        setState(() => _vibrations = v);
                      },
                    ),
                    const _Divider(),
                    _ToggleRow(
                      icon: Icons.volume_up_rounded,
                      label: 'Sounds',
                      value: _sounds,
                      onChanged: (v) async {
                        await LocalStorage.setSoundsEnabled(v);
                        setState(() => _sounds = v);
                      },
                    ),
                    const _Divider(),
                    _ToggleRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark mode',
                      value: _darkMode,
                      onChanged: (v) async {
                        await LocalStorage.setDarkMode(v);
                        setState(() => _darkMode = v);
                      },
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Group 2: Account ──────────────────────────────
                  _Card(children: [
                    _ToggleRow(
                      icon: Icons.person_rounded,
                      label: 'Account Connection',
                      value: _accountConnected,
                      onChanged: (v) => setState(() => _accountConnected = v),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Group 3: Purchases ────────────────────────────
                  _Card(children: [
                    _NavRow(
                      icon: Icons.refresh_rounded,
                      label: 'Restore purchases',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Group 4: Support ──────────────────────────────
                  _Card(children: [
                    _NavRow(
                      icon: Icons.star_rounded,
                      label: 'Rate us',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _NavRow(
                      icon: Icons.edit_rounded,
                      label: 'Write us',
                      onTap: () => launchUrl(
                        Uri.parse('mailto:Pramodsk1214@gmail.com?subject=WinArrow%20Feedback'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Group 5: Legal ────────────────────────────────
                  _Card(children: [
                    _NavRow(
                      icon: Icons.description_rounded,
                      label: 'Privacy',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _NavRow(
                      icon: Icons.info_rounded,
                      label: 'Terms of Service',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: WinArrowBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Reusable components ───────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF0F0F0));
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primaryLight,
      ),
    );
  }
}
