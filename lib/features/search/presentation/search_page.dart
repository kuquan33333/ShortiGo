import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/error/friendly_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/remote/content_api_mapper.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/content_source_setup_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../discover/presentation/series_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestGeneration = 0;
  int? _contentRevision;
  List<Series> _results = const [];
  List<String> _suggestions = const [];
  String _lastQuery = '';
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  Object? _loadMoreError;
  Object? _error;
  bool _loading = false;
  List<Series> _landingResults = const [];
  Category? _landingCategory;
  Object? _landingError;
  bool _landingLoading = true;

  static const _landingCategories = [
    Category.romance,
    Category.ceo,
    Category.revenge,
    Category.family,
    Category.action,
    Category.fantasy,
    Category.newReleases,
    Category.hot,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadLanding());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final generation = ++_requestGeneration;
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _suggestions = const [];
        _lastQuery = '';
        _page = 0;
        _hasMore = false;
        _loadingMore = false;
        _loadMoreError = null;
        _error = null;
        _loading = false;
      });
      unawaited(_loadLanding());
      return;
    }
    setState(() {
      _results = const [];
      _suggestions = const [];
      _lastQuery = value.trim();
      _page = 0;
      _hasMore = false;
      _loadingMore = false;
      _loadMoreError = null;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_search(value.trim(), generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    setState(() {
      _loading = true;
      _error = null;
      _loadMoreError = null;
    });
    try {
      final client = ref.read(contentApiClientProvider);
      final response = await Future.wait([
        client.searchPage(query, pageSize: 30),
        client.suggest(query),
      ]);
      if (!mounted || generation != _requestGeneration) return;
      final page = response[0] as ContentApiSearchPage;
      final results = <Series>[];
      for (final item in page.items) {
        try {
          results.add(ContentApiMapper.series(item));
        } on FormatException {
          // Ignore malformed result cards.
        }
      }
      setState(() {
        _results = results;
        _lastQuery = query;
        _page = page.page;
        _hasMore = page.hasMore;
        _suggestions = response[1] as List<String>;
        _loading = false;
      });
      final repository = ref.read(seriesRepositoryProvider);
      if (repository is RemoteSeriesRepository) {
        repository.rememberAll(results);
      }
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
        _results = const [];
        _hasMore = false;
      });
    }
  }

  void _resetForSourceChange() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    final generation = ++_requestGeneration;
    if (!mounted) return;
    setState(() {
      _results = const [];
      _suggestions = const [];
      _page = 0;
      _hasMore = false;
      _loadingMore = false;
      _loadMoreError = null;
      _error = null;
      _loading = query.isNotEmpty;
    });
    if (query.isNotEmpty) {
      unawaited(_search(query, generation));
    } else {
      unawaited(_loadLanding());
    }
  }

  Future<void> _loadLanding({Category? category}) async {
    if (!mounted) return;
    setState(() {
      _landingLoading = true;
      _landingError = null;
      if (category != null) _landingCategory = category;
    });
    try {
      final repository = ref.read(seriesRepositoryProvider);
      final items = await repository.byCategory(
        category ?? _landingCategory ?? Category.recommended,
        limit: 15,
      );
      if (!mounted || _controller.text.trim().isNotEmpty) return;
      setState(() {
        _landingResults = items;
        _landingLoading = false;
      });
      if (repository is RemoteSeriesRepository) {
        repository.rememberAll(items);
      }
    } catch (error) {
      if (!mounted || _controller.text.trim().isNotEmpty) return;
      setState(() {
        _landingLoading = false;
        _landingError = error;
        _landingResults = const [];
      });
    }
  }

  String _categoryLabel(AppLocalizations l10n, Category category) {
    return switch (category) {
      Category.romance => l10n.romance,
      Category.ceo => l10n.ceo,
      Category.revenge => l10n.revenge,
      Category.family => l10n.family,
      Category.action => l10n.action,
      Category.fantasy => l10n.fantasy,
      Category.newReleases => l10n.newUpdates,
      Category.hot => l10n.hot,
      _ => l10n.recommended,
    };
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _lastQuery.isEmpty) return;
    final generation = _requestGeneration;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final page = await ref.read(contentApiClientProvider).searchPage(
            _lastQuery,
            page: _page + 1,
            pageSize: 30,
          );
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = _results.map((item) => item.id).toSet();
      final additions = <Series>[];
      for (final item in page.items) {
        try {
          final series = ContentApiMapper.series(item);
          if (knownIds.add(series.id)) additions.add(series);
        } on FormatException {
          // Ignore one malformed result without losing the rest of the page.
        }
      }
      setState(() {
        _results = [..._results, ...additions];
        _page = page.page;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
      final repository = ref.read(seriesRepositoryProvider);
      if (repository is RemoteSeriesRepository) {
        repository.rememberAll(additions);
      }
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = error;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    _onChanged(suggestion);
  }

  void _clearSearch() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final revision = ref.watch(contentApiRevisionProvider);
    if (_contentRevision == null) {
      _contentRevision = revision;
    } else if (_contentRevision != revision) {
      _contentRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetForSourceChange();
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final isSearching = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              hintText: l10n.searchHint,
              onChanged: _onChanged,
              onBack: context.pop,
              onClear: isSearching ? _clearSearch : null,
            ),
            Expanded(
              child: isSearching
                  ? _searchResults(context, l10n)
                  : _landing(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landing(BuildContext context, AppLocalizations l10n) {
    if (_landingLoading && _landingResults.isEmpty) {
      return const LoadingView();
    }
    if (_landingError != null && _landingResults.isEmpty) {
      if (_landingError is ContentApiException &&
          (_landingError! as ContentApiException).code == 'not-configured') {
        return const ContentSourceSetupView();
      }
      return ErrorView(
        error: localizedFriendlyErrorFor(context, _landingError!),
        onRetry: _loadLanding,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l10n.popularCategories,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _landingCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final category = _landingCategories[index];
              final selected = category == _landingCategory;
              return AppPressable(
                onTap: () => _loadLanding(category: category),
                semanticsLabel: _categoryLabel(l10n, category),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: .18)
                        : AppColors.surface,
                    border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.divider),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text(_categoryLabel(l10n, category),
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(l10n.maybeYouLike,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 16,
            ),
            itemCount: _landingResults.length,
            itemBuilder: (_, index) {
              final series = _landingResults[index];
              return SeriesCard(
                series: series,
                onTap: () => context.push('/watch/${series.id}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchResults(BuildContext context, AppLocalizations l10n) {
    if (_loading) return const LoadingView();
    if (_error != null) {
      if (_error is ContentApiException &&
          (_error! as ContentApiException).code == 'not-configured') {
        return const ContentSourceSetupView();
      }
      return ErrorView(
        error: localizedFriendlyErrorFor(context, _error!),
        onRetry: () => _search(_lastQuery, _requestGeneration),
      );
    }
    if (_results.isEmpty) return Center(child: Text(l10n.noResults));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.take(5).map((item) {
                return AppPressable(
                  onTap: () => _selectSuggestion(item),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      child: Text(item,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 500) {
                unawaited(_loadMore());
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 9 / 16,
              ),
              itemCount: _results.length,
              itemBuilder: (_, index) {
                final series = _results[index];
                return SeriesCard(
                  series: series,
                  onTap: () => context.push('/watch/${series.id}'),
                );
              },
            ),
          ),
        ),
        if (_loadMoreError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.refresh),
              label: Text(
                  localizedFriendlyErrorFor(context, _loadMoreError!).message),
            ),
          )
        else if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: _loadingMore
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.loadMore),
            ),
          ),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            AppPressable(
              onTap: onBack,
              semanticsLabel:
                  MaterialLocalizations.of(context).backButtonTooltip,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: onClear == null
                        ? null
                        : AppPressable(
                            onTap: onClear,
                            semanticsLabel: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            child: const Icon(Icons.close_rounded),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
