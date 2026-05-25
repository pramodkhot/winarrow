import 'package:flutter/material.dart';
import 'colors.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

class WinArrowApp extends StatelessWidget {
  const WinArrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WinArrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
