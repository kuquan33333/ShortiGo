import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/l10n/app_localizations.dart';

Widget _localizedApp(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
          children: [
            Text(l10n.discover),
            Text(l10n.shorts),
            Text(l10n.rewards),
            Text(l10n.myList),
            Text(l10n.profile),
            Text(l10n.settings),
            Text(l10n.getVip),
            Text(l10n.restorePurchases),
          ],
        );
      },
    ),
  );
}

void main() {
  testWidgets('Vietnamese navigation and subscription labels are localized',
      (tester) async {
    await tester.pumpWidget(_localizedApp(const Locale('vi', 'VN')));

    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Phim ngắn'), findsOneWidget);
    expect(find.text('Phần thưởng'), findsOneWidget);
    expect(find.text('Danh sách của tôi'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Nâng cấp VIP'), findsOneWidget);
    expect(find.text('Khôi phục giao dịch mua'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
    expect(find.text('Rewards'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
  });

  testWidgets('English navigation contains no Vietnamese labels',
      (tester) async {
    await tester.pumpWidget(_localizedApp(const Locale('en', 'US')));

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Shorts'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('My List'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Get VIP'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Khám phá'), findsNothing);
    expect(find.text('Phim ngắn'), findsNothing);
    expect(find.text('Phần thưởng'), findsNothing);
  });
}
