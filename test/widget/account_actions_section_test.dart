import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/features/profile/presentation/account_actions_section.dart';
import 'package:shortigo/l10n/app_localizations.dart';

void main() {
  testWidgets('delete account requires destructive confirmation', (
    tester,
  ) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AccountActionsSection(
            isDeleting: false,
            onRestorePurchases: () {},
            onDeleteAccount: () async {
              deleted = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Account & Subscription'), findsOneWidget);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your ShortiGo account?'), findsOneWidget);
    expect(find.textContaining('viewing activity'), findsOneWidget);
    expect(deleted, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
