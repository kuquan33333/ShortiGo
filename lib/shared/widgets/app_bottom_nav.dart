import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'app_pressable.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static final _tabs = <_TabSpec Function(AppLocalizations)>[
    (l10n) => _TabSpec(
          icon: Icons.home_outlined,
          selected: Icons.home,
          label: l10n.discover,
          route: '/discover',
        ),
    (l10n) => _TabSpec(
          icon: Icons.play_circle_outline,
          selected: Icons.play_circle,
          label: l10n.shorts,
          route: '/shorts',
        ),
    (l10n) => _TabSpec(
          icon: Icons.card_giftcard_outlined,
          selected: Icons.card_giftcard,
          label: l10n.rewards,
          route: '/rewards',
        ),
    (l10n) => _TabSpec(
          icon: Icons.bookmark_outline,
          selected: Icons.bookmark,
          label: l10n.myList,
          route: '/my-list',
        ),
    (l10n) => _TabSpec(
          icon: Icons.person_outline,
          selected: Icons.person,
          label: l10n.profile,
          route: '/profile',
        ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var index = _tabs.length - 1; index >= 0; index--) {
      if (location
          .startsWith(_tabs[index](AppLocalizations.of(context)!).route)) {
        return index;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final l10n = AppLocalizations.of(context)!;
    final tabs = _tabs.map((factory) => factory(l10n)).toList();
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var tabIndex = 0; tabIndex < tabs.length; tabIndex++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[tabIndex],
                    selected: tabIndex == index,
                    onTap: () => context.go(tabs[tabIndex].route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: AppPressable(
        onTap: onTap,
        semanticsLabel: tab.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 30,
                child: Icon(
                  selected ? tab.selected : tab.icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.selected,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selected;
  final String label;
  final String route;
}
