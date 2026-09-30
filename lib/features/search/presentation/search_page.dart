import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/remote/content_api_mapper.dart';
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
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_search(value.trim(), generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(contentApiClientProvider);
      final response = await Future.wait([
        client.search(query),
        client.suggest(query),
      ]);
      if (!mounted || generation != _requestGeneration) return;
      final raw = response[0] as List<Map<String, dynamic>>;
      final results = <Series>[];
      for (final item in raw) {
        try {
          results.add(ContentApiMapper.series(item));
        } on FormatException {
          // Ignore malformed result cards.
        }
      }
      setState(() {
        _results = results;
        _suggestions = response[1] as List<String>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _results = const [];
      });
    }
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
                                  .map((item) => Chip(label: Text(item)))
                                  .toList(),
                            ),
                          ),
                        Expanded(
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
                      ],
                    ),
    );
  }
}
