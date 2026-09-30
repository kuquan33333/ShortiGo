import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/features/rewards/presentation/rewards_page.dart';
import 'package:shortigo/l10n/app_localizations.dart';

void main() {
  testWidgets('signed-out users see a sign-in prompt on Rewards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAuthUserProvider.overrideWith((_) => Stream.value(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RewardsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to use this feature.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Claim'), findsNothing);
    expect(find.text('Watch'), findsNothing);
  });
}
