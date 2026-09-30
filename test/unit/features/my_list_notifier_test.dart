import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/data/remote/content_api_models.dart';
import 'package:shortigo/data/local/guest_favorites_repository.dart';
import 'package:shortigo/data/local/shortigo_database.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/entities/user.dart';
import 'package:shortigo/domain/interfaces/series_repository.dart';
import 'package:shortigo/features/my_list/application/my_list_notifier.dart';

class _MockSeriesRepository extends Mock implements SeriesRepository {}

Series _series(String id) {
  return Series(
    id: id,
    title: 'Series $id',
    coverUrl: 'https://example.com/$id.jpg',
    category: Category.newReleases,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

AppUser _user(List<String> favoriteSeriesIds) {
  return AppUser(
    id: 'u1',
    email: 'u@example.com',
    favoriteSeriesIds: favoriteSeriesIds,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

ProviderContainer _container({
  required _MockSeriesRepository repo,
  required AsyncValue<AppUser?> user,
  required ShortigoDatabase database,
}) {
  return ProviderContainer(
    overrides: [
      seriesRepositoryProvider.overrideWithValue(repo),
      currentAppUserDocProvider.overrideWith((_) => Stream.value(user.value)),
      shortigoDatabaseProvider.overrideWithValue(database),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockSeriesRepository repo;

  setUp(() {
    repo = _MockSeriesRepository();
  });

  test('loads local guest favorites when there is no app user', () async {
    final database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await GuestFavoritesRepository(database).save(_series('local'));
    final container = _container(
      repo: repo,
      user: const AsyncData(null),
      database: database,
    );
    addTearDown(container.dispose);

    final state = await container.read(myListNotifierProvider.future);

    expect(state.series.map((series) => series.id), ['local']);
    expect(state.requiresSignIn, isFalse);
    verifyNever(() => repo.byId(any()));
  });

  test('returns an empty list when user has no saved series', () async {
    final database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = _container(
      repo: repo,
      user: AsyncData(_user([])),
      database: database,
    );
    addTearDown(container.dispose);

    final state = await container.read(myListNotifierProvider.future);

    expect(state.series, isEmpty);
    expect(state.requiresSignIn, isFalse);
    verifyNever(() => repo.byId(any()));
  });

  test('resolves saved series in favoriteSeriesIds order', () async {
    when(() => repo.byId('s2')).thenAnswer((_) async => _series('s2'));
    when(() => repo.byId('s1')).thenAnswer((_) async => _series('s1'));
    final database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    final container = _container(
      repo: repo,
      user: AsyncData(_user(['s2', 's1'])),
      database: database,
    );
    addTearDown(database.close);
    addTearDown(container.dispose);

    final state = await container.read(myListNotifierProvider.future);

    expect(state.series.map((series) => series.id), ['s2', 's1']);
    verify(() => repo.byId('s2')).called(1);
    verify(() => repo.byId('s1')).called(1);
  });

  test('skips a dead cloud favorite without failing the whole list', () async {
    when(() => repo.byId('dead')).thenThrow(
      const ContentApiException(
        code: 'not-found',
        message: 'missing',
        statusCode: 404,
      ),
    );
    when(() => repo.byId('alive')).thenAnswer((_) async => _series('alive'));
    final database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    final container = _container(
      repo: repo,
      user: AsyncData(_user(['dead', 'alive'])),
      database: database,
    );
    addTearDown(database.close);
    addTearDown(container.dispose);

    final state = await container.read(myListNotifierProvider.future);

    expect(state.series.map((series) => series.id), ['alive']);
    verify(() => repo.byId('dead')).called(1);
    verify(() => repo.byId('alive')).called(1);
  });
}
