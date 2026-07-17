import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared soft pastel rainbow background used across every Arvenland screen.
///
/// The gradient is intentionally very low saturation — it should feel like
/// warm paper with a whisper of rainbow, never compete with the artwork.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.softRainbowBg,
        ),
      ),
      child: child,
    );
  }
}
