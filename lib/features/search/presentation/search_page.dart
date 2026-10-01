import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/error/friendly_error.dart';
import '../../../data/remote/content_api_mapper.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
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
  List<Series> _results = const [];
  List<String> _suggestions = const [];
  String _lastQuery = '';
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  Object? _loadMoreError;
  String? _error;
  bool _loading = false;

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
        _error = localizedFriendlyErrorFor(context, error).message;
        _loading = false;
        _results = const [];
        _hasMore = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? Center(child: Text(_error!))
              : _results.isEmpty
                  ? Center(child: Text(l10n.noResults))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_suggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Wrap(
                              spacing: 8,
                              children: _suggestions
                                  .take(5)
                                  .map(
                                    (item) => ActionChip(
                                      label: Text(item),
                                      onPressed: () => _selectSuggestion(item),
                                    ),
                                  )
                                  .toList(),
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
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  onTap: () =>
                                      context.push('/series/${series.id}'),
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
                                localizedFriendlyErrorFor(
                                  context,
                                  _loadMoreError!,
                                ).message,
                              ),
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.loadMore),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
