import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryBar({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = index == selectedIndex;
            return ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (_) => onSelected(index),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : theme.textTheme.bodyMedium?.color ??
                        AppColors.textSecondary,
              ),
              backgroundColor: AppColors.secondary,
              selectedColor: AppColors.accent,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            );
          },
        ),
      ),
    );
  }
}
