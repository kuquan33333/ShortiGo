import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/data/remote/content_api_models.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/interfaces/series_repository.dart';
import 'package:shortigo/features/discover/presentation/discover_page.dart';
import 'package:shortigo/l10n/app_localizations.dart';

class _FakeSeriesRepository implements SeriesRepository {
  @override
  Future<List<Series>> forYou({int limit = 20}) async => const [];

  @override
  Future<List<Series>> byCategory(Category category, {int limit = 20}) async {
    if (category == Category.romance) {
      return [_series('romance', 'Romance result', Category.romance)];
    }
    if (category == Category.hot) {
      return [_series('hot', 'Hot result', Category.hot)];
    }
    return const [];
  }

  @override
  Future<Series> byId(String id) async => _series(id, id, Category.forYou);
}

Series _series(String id, String title, Category category) => Series(
      id: id,
      title: title,
      coverUrl: '',
      category: category,
      createdAt: DateTime.utc(2026),
    );

void main() {
  testWidgets('home uses grid tabs and category selection loads results',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(_FakeSeriesRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi', 'VN'),
          home: const DiscoverPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text('Xếp hạng'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);

    await tester.tap(find.text('Danh mục'));
    await tester.pumpAndSettle();
    expect(find.text('Ngôn tình'), findsOneWidget);

    final romanceButton = find.text('Ngôn tình');
    await tester.ensureVisible(romanceButton);
    await tester.tap(romanceButton);
    await tester.pumpAndSettle();
    expect(find.text('Romance result'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('missing content source shows setup CTA instead of retry error',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(
            _NotConfiguredSeriesRepository(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi', 'VN'),
          home: const DiscoverPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa cấu hình nguồn phim'), findsOneWidget);
    expect(find.text('Cấu hình nguồn phim'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });
}

class _NotConfiguredSeriesRepository extends _FakeSeriesRepository {
  @override
  Future<List<Series>> byCategory(Category category, {int limit = 20}) async {
    throw const ContentApiException(code: 'not-configured');
  }
}
