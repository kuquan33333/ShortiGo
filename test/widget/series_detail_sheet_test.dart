import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/features/series_detail/presentation/series_detail_page.dart';
import 'package:shortigo/l10n/app_localizations.dart';

void main() {
  testWidgets('detail sheet exposes intro, episode tab and ranges',
      (tester) async {
    final series = Series(
      id: 's1',
      title: 'Sheet Show',
      coverUrl: '',
      category: Category.romance,
      createdAt: DateTime.utc(2026),
      description: 'A short drama description.',
    );
    final episodes = List.generate(
      65,
      (index) => Episode(
        id: 'ep${index + 1}',
        seriesId: 's1',
        order: index + 1,
        videoUrl: '',
        thumbnailUrl: '',
        durationSec: 60,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAppUserDocProvider.overrideWith((_) => Stream.value(null)),
          guestFavoriteSavedProvider('s1')
              .overrideWith((_) => Future.value(false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi', 'VN'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showSeriesDetailSheet(
                    context,
                    series: series,
                    episodes: episodes,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Giới thiệu'), findsOneWidget);
    expect(find.text('Chọn tập'), findsOneWidget);
    await tester.tap(find.text('Chọn tập'));
    await tester.pumpAndSettle();

    expect(find.text('1–30'), findsOneWidget);
    expect(find.text('31–60'), findsOneWidget);
    expect(find.text('61–65'), findsOneWidget);
  });
}
