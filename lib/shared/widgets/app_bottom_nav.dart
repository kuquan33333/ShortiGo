import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

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
    return BottomNavigationBar(
      currentIndex: index,
      onTap: (index) => context.go(tabs[index].route),
      items: [
        for (final tab in tabs)
          BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.selected),
            label: tab.label,
          ),
      ],
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
