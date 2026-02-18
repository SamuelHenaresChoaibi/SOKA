import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class SokaLuxuryBackground extends StatelessWidget {
  final Widget child;

  const SokaLuxuryBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.background,
                AppColors.primary,
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -100,
          child: _GlowOrb(
            size: 260,
            color: AppColors.accent.withValues(alpha: 0.23),
          ),
        ),
        Positioned(
          top: 220,
          left: -120,
          child: _GlowOrb(
            size: 240,
            color: AppColors.accent.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          bottom: -130,
          right: -120,
          child: _GlowOrb(
            size: 290,
            color: AppColors.accent.withValues(alpha: 0.1),
          ),
        ),
        child,
      ],
    );
  }
}

class SokaEntrance extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const SokaEntrance({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 440 + delayMs);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - value)),
            child: builtChild,
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
