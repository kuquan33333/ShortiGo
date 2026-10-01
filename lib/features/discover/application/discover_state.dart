import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';

enum DiscoverHomeTab { hot, newReleases, ranking, categories }

class DiscoverState {
  const DiscoverState({
    this.currentCategory = Category.forYou,
    this.selectedTab = DiscoverHomeTab.hot,
    this.series = const [],
    this.sections = const [],
    this.hero,
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final Category currentCategory;
  final DiscoverHomeTab selectedTab;
  final List<Series> series;
  final List<DiscoverSection> sections;
  final Series? hero;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final String? nextCursor;
  final bool isLoadingMore;
  final Object? loadMoreError;

  DiscoverState copyWith({
    Category? currentCategory,
    DiscoverHomeTab? selectedTab,
    List<Series>? series,
    List<DiscoverSection>? sections,
    Series? hero,
    bool clearHero = false,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return DiscoverState(
      currentCategory: currentCategory ?? this.currentCategory,
      selectedTab: selectedTab ?? this.selectedTab,
      series: series ?? this.series,
      sections: sections ?? this.sections,
      hero: clearHero ? null : hero ?? this.hero,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
    );
  }
}

class DiscoverSection {
  const DiscoverSection({
    required this.slug,
    required this.title,
    required this.series,
  });

  final String slug;
  final String title;
  final List<Series> series;
}
