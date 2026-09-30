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
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = _categories[index];
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

  static const _categories = [
    Category.forYou,
    Category.newReleases,
    Category.hot,
    Category.romance,
    Category.ceo,
    Category.revenge,
    Category.family,
    Category.action,
    Category.fantasy,
    Category.recommended,
  ];

  String _label(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;
    return switch (category) {
      Category.forYou => l10n.forYou,
      Category.newReleases => l10n.newUpdates,
      Category.hot => l10n.hot,
      Category.romance => l10n.romance,
      Category.ceo => l10n.ceo,
      Category.revenge => l10n.revenge,
      Category.family => l10n.family,
      Category.action => l10n.action,
      Category.fantasy => l10n.fantasy,
      Category.recommended => l10n.recommended,
      Category.adventure => l10n.action,
      Category.scary => l10n.fantasy,
      Category.anime => l10n.recommended,
      Category.vip => l10n.vip,
    };
  }
}
