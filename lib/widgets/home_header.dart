import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/widgets/widgets.dart';

class HomeHeader extends StatelessWidget {
  final int eventCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onQrTap;
  final VoidCallback? onFilterTap;

  const HomeHeader({
    super.key,
    required this.eventCount,
    required this.onSearchChanged,
    this.onQrTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final lightText = AppColors.surface;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            color: lightText.withValues(alpha: 0.75),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'WELCOME TO SOKA',
                          style: TextStyle(
                            color: lightText,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HeaderIconButton(
                    icon: Icons.qr_code_rounded,
                    onTap: onQrTap ?? () {},
                  ),
                  const SizedBox(width: 12),
                  HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, 'notifications');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SearchBarSoka(
                eventCount: eventCount,
                onChanged: onSearchChanged,
                onFilterTap: onFilterTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
