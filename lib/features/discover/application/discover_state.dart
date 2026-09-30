import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';

class DiscoverState {
  const DiscoverState({
    this.currentCategory = Category.forYou,
    this.series = const [],
    this.sections = const [],
    this.hero,
    this.isLoading = false,
    this.error,
  });

  final Category currentCategory;
  final List<Series> series;
  final List<DiscoverSection> sections;
  final Series? hero;
  final bool isLoading;
  final String? error;

  DiscoverState copyWith({
    Category? currentCategory,
    List<Series>? series,
    List<DiscoverSection>? sections,
    Series? hero,
    bool clearHero = false,
    bool? isLoading,
    String? error,
  }) {
    return DiscoverState(
      currentCategory: currentCategory ?? this.currentCategory,
      series: series ?? this.series,
      sections: sections ?? this.sections,
      hero: clearHero ? null : hero ?? this.hero,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
