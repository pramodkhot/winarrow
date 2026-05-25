import 'package:flutter/material.dart';

class HeartsWidget extends StatelessWidget {
  final int hearts; // remaining (0–3)
  final int maxHearts;

  const HeartsWidget({super.key, required this.hearts, this.maxHearts = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxHearts, (i) {
        final filled = i < hearts;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: filled ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
            size: 26,
          ),
        );
      }),
    );
  }
}
