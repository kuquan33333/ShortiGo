import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../discover/presentation/series_card.dart';

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  final _scrollController = ScrollController();
  List<Series> _items = const [];
  String _title = '';
  String _sort = 'hot';
  String? _nextCursor;
  int _page = 0;
  bool _hasMore = true;
  bool _initialLoading = true;
  bool _loadingMore = false;
  Object? _error;
  Object? _loadMoreError;
  int? _contentRevision;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    unawaited(_loadPage(append: false));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadInitial() async {
    if (_initialLoading) return;
    setState(() {
      _items = const [];
      _title = '';
      _page = 0;
      _nextCursor = null;
      _hasMore = true;
      _error = null;
      _loadMoreError = null;
      _initialLoading = true;
    });
    await _loadPage(append: false);
  }

  Future<void> _loadMore() async {
    if (_initialLoading || _loadingMore || !_hasMore) return;
    await _loadPage(append: true);
  }

  Future<void> _loadPage({required bool append}) async {
    if (append) {
      setState(() {
        _loadingMore = true;
        _loadMoreError = null;
      });
    }
    try {
      final repository = ref.read(seriesRepositoryProvider);
      if (repository is! PagedSeriesRepository) {
        throw const ContentApiException(code: 'invalid-schema');
      }
      final pagedRepository = repository as PagedSeriesRepository;
      final response = await pagedRepository.collectionPage(
        slug: widget.slug,
        page: append ? _page + 1 : 1,
        cursor: append ? _nextCursor : null,
        sort: _sort,
      );
      if (!mounted) return;
      final knownIds = _items.map((item) => item.id).toSet();
      final incoming = response.items
          .where((item) => knownIds.add(item.id))
          .toList(growable: false);
      setState(() {
        _title = response.title;
        _items = append ? [..._items, ...incoming] : incoming;
        _page = response.page;
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _initialLoading = false;
        _loadingMore = false;
        _error = null;
        _loadMoreError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _loadingMore = false;
        if (append) {
          _loadMoreError = error;
        } else {
          _error = error;
        }
      });
    }
  }

  void _changeSort(String sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _initialLoading = false;
    });
    unawaited(_loadInitial());
  }

  @override
  Widget build(BuildContext context) {
    final revision = ref.watch(contentApiRevisionProvider);
    if (_contentRevision == null) {
      _contentRevision = revision;
    } else if (_contentRevision != revision) {
      _contentRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _title = '';
          _page = 0;
          _nextCursor = null;
          _hasMore = true;
          _error = null;
          _loadMoreError = null;
          _initialLoading = false;
        });
        unawaited(_loadInitial());
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final title = _title.isEmpty ? widget.slug : _title;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sort,
            onSelected: _changeSort,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'hot', child: Text(l10n.sortHot)),
              PopupMenuItem(value: 'new', child: Text(l10n.sortNew)),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _initialLoading && _items.isEmpty
          ? const LoadingView()
          : _error != null && _items.isEmpty
              ? Center(
                  child: FilledButton(
                    onPressed: _loadInitial,
                    child: Text(
                      localizedFriendlyErrorFor(context, _error!).message,
                    ),
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .49,
                  ),
                  itemCount: _items.length +
                      (_hasMore || _loadMoreError != null ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index >= _items.length) {
                      if (_loadingMore) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_loadMoreError != null) {
                        return IconButton(
                          tooltip: l10n.retry,
                          onPressed: _loadMore,
                          icon: const Icon(Icons.refresh),
                        );
                      }
                      return FilledButton(
                        onPressed: _loadMore,
                        child: Text(l10n.loadMore),
                      );
                    }
                    final series = _items[index];
                    return SeriesCard(
                      series: series,
                      onTap: () => context.push('/watch/${series.id}'),
                    );
                  },
                ),
    );
  }
}
