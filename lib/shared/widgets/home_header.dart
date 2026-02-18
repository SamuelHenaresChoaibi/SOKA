import 'package:flutter/material.dart';
import 'package:soka/shared/widgets/header_icon_button.dart';
import 'package:soka/shared/widgets/search_bar.dart';
import 'package:soka/shared/widgets/soka_visuals.dart';
import 'package:soka/theme/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.secondary.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: IgnorePointer(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.27),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SokaEntrance(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'SOKA LIVE',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'SOKA - The Night Network',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Events, culture and nightlife in one place',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.92,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          HeaderIconButton(
                            icon: Icons.qr_code_rounded,
                            onTap: onQrTap ?? () {},
                          ),
                          const SizedBox(height: 12),
                          HeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () {
                              Navigator.pushNamed(context, 'notifications');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SokaEntrance(
                    delayMs: 80,
                    child: SearchBarSoka(
                      eventCount: eventCount,
                      onChanged: onSearchChanged,
                      onFilterTap: onFilterTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
