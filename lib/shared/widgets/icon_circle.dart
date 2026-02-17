import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const IconCircle({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
