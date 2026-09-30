import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../l10n/app_localizations.dart';

class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final Category current;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Category.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = Category.values[index];
          final selected = category == current;

          return ChoiceChip(
            label: Text(_label(context, category)),
            selected: selected,
            onSelected: (_) => onSelect(category),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  String _label(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;
    return switch (category) {
      Category.forYou => l10n.forYou,
      Category.newReleases => l10n.newUpdates,
      Category.hot => l10n.hot,
      Category.adventure => l10n.adventure,
      Category.scary => l10n.scary,
      Category.anime => l10n.anime,
      Category.vip => l10n.vip,
    };
  }
}
