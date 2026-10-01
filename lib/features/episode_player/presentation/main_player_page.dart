import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/async/retryable_future_cache.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/user.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/save_series_button.dart';
import '../application/episode_access.dart';
import 'episode_player_view.dart';
import '../../series_detail/presentation/series_detail_page.dart';
import '../../shorts/application/shorts_share_link.dart';

int resolveInitialEpisodeIndex(List<Episode> episodes, String? requestedId) {
  if (episodes.isEmpty) return 0;
  final requested = requestedId == null
      ? -1
      : episodes.indexWhere((episode) => episode.id == requestedId);
  if (requested >= 0) return requested;
  final firstPlayable = episodes.indexWhere(
    (episode) =>
        episode.sourceAvailable &&
        !episode.sourceLocked &&
        !episode.isVipLocked,
  );
  return firstPlayable >= 0 ? firstPlayable : 0;
}

int nextEpisodeIndex(int currentIndex, int episodeCount) {
  return currentIndex + 1 < episodeCount ? currentIndex + 1 : -1;
}

List<int> adjacentEpisodeIndices(int currentIndex, int episodeCount) {
  return [currentIndex - 1, currentIndex + 1]
      .where((index) => index >= 0 && index < episodeCount)
      .toList(growable: false);
}

double clampSeekPosition(double value, double duration) {
  if (duration <= 0) return 0;
  return value.clamp(0, duration).toDouble();
}

/// Full-screen player used by Home, Collection and Shorts "Watch all".
///
/// There is one BetterPlayer controller for the active episode. PageView owns
/// the vertical transition while the controller is reused for the next source,
/// keeping the player light even for long series.
class MainPlayerPage extends ConsumerStatefulWidget {
  const MainPlayerPage({
    super.key,
    required this.seriesId,
    this.episodeId,
  });

  final String seriesId;
  final String? episodeId;

  @override
  ConsumerState<MainPlayerPage> createState() => _MainPlayerPageState();
}

class _MainPlayerPageState extends ConsumerState<MainPlayerPage>
    with WidgetsBindingObserver {
  late final BetterPlayerController _controller;
  late PageController _pageController;
  final _urlCache = RetryableFutureCache<String, String>();

  Series? _series;
  List<Episode> _episodes = const [];
  int _currentIndex = 0;
  int _generation = 0;
  bool _loading = true;
  bool _controllerReady = false;
  bool _paused = false;
  bool _ended = false;
  bool _showingTransientPause = false;
  double? _seekPreview;
  Timer? _transientControlTimer;
  double _position = 0;
  double _duration = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        looping: false,
        fit: BoxFit.cover,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
    )..addEventsListener(_onPlayerEvent);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _urlCache.clear();
    _transientControlTimer?.cancel();
    _controller
      ..removeEventsListener(_onPlayerEvent)
      ..dispose(forceDispose: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldPauseVideoForLifecycle(state)) {
      _paused = true;
      unawaited(_controller.pause());
    }
  }

  Future<void> _load() async {
    try {
      final series =
          await ref.read(seriesRepositoryProvider).byId(widget.seriesId);
      final episodes =
          await ref.read(episodeRepositoryProvider).bySeriesId(widget.seriesId);
      if (!mounted) return;
      final resolvedIndex =
          resolveInitialEpisodeIndex(episodes, widget.episodeId);
      _pageController.dispose();
      _pageController = PageController(initialPage: resolvedIndex);
      setState(() {
        _series = series;
        _episodes = episodes;
        _currentIndex = resolvedIndex;
        _loading = false;
        _error = null;
      });
      await _switchToEpisode(_currentIndex, autoplay: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      if (_loading) return;
      setState(() => _error = event.parameters?['exception'] ?? 'playback');
      return;
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      if (_loading) return;
      if (_ended) return;
      _ended = true;
      if (nextEpisodeIndex(_currentIndex, _episodes.length) >= 0) {
        unawaited(_pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ));
      } else {
        setState(() => _paused = true);
      }
      return;
    }
    if (event.betterPlayerEventType != BetterPlayerEventType.progress) return;
    if (_loading) return;
    final position = event.parameters?['progress'] as Duration?;
    final duration = event.parameters?['duration'] as Duration?;
    if (position == null || duration == null) return;
    setState(() {
      _position = position.inMilliseconds.toDouble();
      _duration = duration.inMilliseconds.toDouble();
    });
  }

  Future<void> _switchToEpisode(int index, {required bool autoplay}) async {
    if (index < 0 || index >= _episodes.length) return;
    final generation = ++_generation;
    final episode = _episodes[index];
    _urlCache.retainOnly(
      _episodes
          .asMap()
          .entries
          .where((entry) => (entry.key - index).abs() <= 1)
          .where((entry) => _accessFor(entry.value) == EpisodeAccessState.open)
          .map((entry) => entry.value.id),
    );
    setState(() {
      _currentIndex = index;
      _loading = true;
      _controllerReady = false;
      _error = null;
      _ended = false;
      _position = 0;
      _duration = 0;
      _showingTransientPause = false;
      _seekPreview = null;
    });
    final user = ref.read(currentAppUserDocProvider).value;
    final effectiveVip =
        ref.read(effectiveVipProvider).value ?? user?.isVip ?? false;
    if (accessFor(episode, user, effectiveVip: effectiveVip) !=
        EpisodeAccessState.open) {
      await _controller.pause();
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final url = await _urlFor(episode);
      if (!mounted || generation != _generation) return;
      await _controller.pause();
      await _controller.setupDataSource(
        BetterPlayerDataSource.network(
          url,
          cacheConfiguration: const BetterPlayerCacheConfiguration(
            useCache: true,
          ),
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _controllerReady = true;
        _paused = !autoplay;
      });
      if (autoplay) await _controller.play();
      _prefetchAdjacent(index);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _togglePlayback() {
    if (!_controllerReady) return;
    final nextPaused = !_paused;
    setState(() {
      _paused = nextPaused;
      _showingTransientPause = !nextPaused;
    });
    if (_paused) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
      _transientControlTimer?.cancel();
      _transientControlTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showingTransientPause = false);
      });
    }
  }

  void _seek(double value) {
    if (_duration <= 0) return;
    final target = Duration(
      milliseconds: clampSeekPosition(value, _duration).round(),
    );
    unawaited(_controller.seekTo(target));
  }

  EpisodeAccessState _accessFor(Episode episode) {
    final user = ref.read(currentAppUserDocProvider).value;
    final effectiveVip =
        ref.read(effectiveVipProvider).value ?? user?.isVip ?? false;
    return accessFor(episode, user, effectiveVip: effectiveVip);
  }

  Future<String> _urlFor(Episode episode) {
    return _urlCache.getOrCreate(
      episode.id,
      () => ref.read(videoSourceProvider).playableUrl(
            seriesId: widget.seriesId,
            episodeId: episode.id,
            storagePath: episode.videoUrl,
            chapterIndex: episode.sourceChapterIndex,
          ),
    );
  }

  void _prefetchAdjacent(int index) {
    for (final adjacent in adjacentEpisodeIndices(index, _episodes.length)) {
      final episode = _episodes[adjacent];
      if (_accessFor(episode) != EpisodeAccessState.open) continue;
      unawaited(_urlFor(episode).then<void>((_) {}, onError: (_, __) {}));
    }
  }

  Future<void> _showEpisodes() async {
    if (_series == null) return;
    final selected = await showSeriesDetailSheet(
      context,
      series: _series!,
      episodes: _episodes,
      initialTab: 1,
      currentIndex: _currentIndex,
    );
    if (selected != null && mounted) {
      await _pageController.animateToPage(
        selected,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _showDetailSheet() async {
    final series = _series;
    if (series == null) return;
    final selected = await showSeriesDetailSheet(
      context,
      series: series,
      episodes: _episodes,
      currentIndex: _currentIndex,
    );
    if (selected != null && mounted) {
      await _pageController.animateToPage(
        selected,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _share() async {
    final series = _series;
    if (series == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shortShareText(
            l10n: AppLocalizations.of(context)!,
            seriesTitle: series.title,
            episodeOrder: _episodes[_currentIndex].order,
            seriesId: series.id,
            episodeId: _episodes[_currentIndex].id,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizedFriendlyErrorFor(context, error).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading && _series == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _series == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: FilledButton(
            onPressed: _load,
            child: Text(localizedFriendlyErrorFor(context, _error!).message),
          ),
        ),
      );
    }
    final series = _series!;
    if (_episodes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(child: Text(l10n.sourceUnavailable)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _episodes.length,
        onPageChanged: (index) => unawaited(
          _switchToEpisode(index, autoplay: true),
        ),
        itemBuilder: (context, index) {
          final active = index == _currentIndex;
          final item = _episodes[index];
          final itemAccess = _accessFor(item);
          return Stack(
            fit: StackFit.expand,
            children: [
              _EpisodeBackdrop(episode: item),
              if (active &&
                  _controllerReady &&
                  itemAccess == EpisodeAccessState.open)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 0 &&
                            constraints.maxHeight > 0) {
                          _controller.setOverriddenAspectRatio(
                            constraints.maxWidth / constraints.maxHeight,
                          );
                        }
                        return BetterPlayer(
                          key: ValueKey('main_player_${item.id}'),
                          controller: _controller,
                        );
                      },
                    ),
                  ),
                ),
              _MainPlayerChrome(
                series: series,
                episode: item,
                access: itemAccess,
                interactive: active,
                loading: active && _loading,
                error: active ? _error : null,
                paused: active && _paused,
                showTransientPause: active && _showingTransientPause,
                ended: active && _ended && index == _episodes.length - 1,
                onTapVideo: active ? _togglePlayback : null,
                onBack: active ? context.pop : null,
                onTitle: active ? _showDetailSheet : null,
                onEpisodes: active ? _showEpisodes : null,
                onShare: active ? _share : null,
                onRetry: active
                    ? () => unawaited(_switchToEpisode(index, autoplay: true))
                    : null,
                position: active ? _position : 0,
                duration: active ? _duration : 0,
                onSeekStart: active ? (_) {} : null,
                onSeekChanged: active
                    ? (value) => setState(() => _seekPreview = value)
                    : null,
                onSeekEnd: active
                    ? (value) {
                        _seek(value);
                        setState(() => _seekPreview = null);
                      }
                    : null,
                seekPreview: active ? _seekPreview : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EpisodeBackdrop extends StatelessWidget {
  const _EpisodeBackdrop({required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: episode.thumbnailUrl.isEmpty
          ? const SizedBox.expand()
          : Image.network(
              episode.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
    );
  }
}

class _MainPlayerChrome extends StatelessWidget {
  const _MainPlayerChrome({
    required this.series,
    required this.episode,
    required this.access,
    required this.interactive,
    required this.loading,
    required this.error,
    required this.paused,
    required this.showTransientPause,
    required this.ended,
    required this.onTapVideo,
    required this.onBack,
    required this.onTitle,
    required this.onEpisodes,
    required this.onShare,
    required this.onRetry,
    required this.position,
    required this.duration,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.seekPreview,
  });

  final Series series;
  final Episode episode;
  final EpisodeAccessState access;
  final bool interactive;
  final bool loading;
  final Object? error;
  final bool paused;
  final bool showTransientPause;
  final bool ended;
  final VoidCallback? onTapVideo;
  final VoidCallback? onBack;
  final VoidCallback? onTitle;
  final VoidCallback? onEpisodes;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final double position;
  final double duration;
  final ValueChanged<double>? onSeekStart;
  final ValueChanged<double>? onSeekChanged;
  final ValueChanged<double>? onSeekEnd;
  final double? seekPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ProviderScope.containerOf(context)
        .read(currentAppUserDocProvider)
        .value;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (interactive)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTapVideo,
            child: const SizedBox.expand(),
          ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .58),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .8)
                ],
                stops: const [0, .42, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  Text(
                    l10n.episodeLabel(episode.order),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        if (loading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (access != EpisodeAccessState.open) _AccessOverlay(access: access),
        if (error != null && access == EpisodeAccessState.open)
          Center(
              child: FilledButton(
                  onPressed: onRetry, child: Text(l10n.tapToRetry))),
        if (interactive &&
            access == EpisodeAccessState.open &&
            !loading &&
            error == null &&
            (paused || showTransientPause))
          Center(
            child: AnimatedOpacity(
              opacity: paused || showTransientPause ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                    color: Colors.black45, shape: BoxShape.circle),
                child: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 52),
              ),
            ),
          ),
        Positioned(
          right: 10,
          bottom: 152,
          child: SafeArea(
            child: _PlayerRail(
              series: series,
              episode: episode,
              user: user,
              onEpisodes: onEpisodes,
              onShare: onShare,
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 80,
          bottom: 40,
          child: SafeArea(
            top: false,
            child: _BottomInfo(
              series: series,
              episode: episode,
              ended: ended,
              onTitle: onTitle,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 10,
          child: SafeArea(
            top: false,
            child: _SeekBar(
              position: seekPreview ?? position,
              duration: duration,
              onSeekStart: onSeekStart,
              onSeekChanged: onSeekChanged,
              onSeekEnd: onSeekEnd,
            ),
          ),
        ),
      ],
    );
    return interactive ? content : IgnorePointer(child: content);
  }
}

class _PlayerRail extends ConsumerWidget {
  const _PlayerRail({
    required this.series,
    required this.episode,
    required this.user,
    required this.onEpisodes,
    required this.onShare,
  });

  final Series series;
  final Episode episode;
  final AppUser? user;
  final VoidCallback? onEpisodes;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final liked = user?.likedEpisodeIds.contains(episode.id) ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SaveSeriesCircleButton(
            seriesId: series.id, series: series, countLabel: l10n.save),
        const SizedBox(height: 14),
        _RailAction(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: l10n.like,
          color: liked ? AppColors.primary : Colors.white,
          onTap: () async {
            if (user == null) {
              if (context.mounted) await context.push('/login');
              return;
            }
            try {
              await ref.read(socialActionsGatewayProvider).setEpisodeLiked(
                    episodeId: episode.id,
                    liked: !liked,
                  );
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizedFriendlyErrorFor(context, error).message,
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 14),
        _RailAction(
            icon: Icons.playlist_play_rounded,
            label: l10n.chooseEpisode,
            onTap: onEpisodes),
        const SizedBox(height: 14),
        _RailAction(
            icon: Icons.share_rounded, label: l10n.share, onTap: onShare),
      ],
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction(
      {required this.icon,
      required this.label,
      this.color = Colors.white,
      this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Column(
        children: [
          Icon(icon,
              color: color,
              size: 31,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 8)]),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
        ],
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  const _BottomInfo(
      {required this.series,
      required this.episode,
      required this.ended,
      required this.onTitle});

  final Series series;
  final Episode episode;
  final bool ended;
  final VoidCallback? onTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTitle,
          child: Row(
            children: [
              Expanded(
                  child: Text(series.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800))),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
            '${l10n.episodeLabel(episode.order)} · ${series.description.isEmpty ? l10n.noDescription : series.description}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.35)),
        if (ended) ...[
          const SizedBox(height: 6),
          Text(l10n.ended,
              style: const TextStyle(
                  color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar(
      {required this.position,
      required this.duration,
      required this.onSeekStart,
      required this.onSeekChanged,
      required this.onSeekEnd});

  final double position;
  final double duration;
  final ValueChanged<double>? onSeekStart;
  final ValueChanged<double>? onSeekChanged;
  final ValueChanged<double>? onSeekEnd;

  @override
  Widget build(BuildContext context) {
    if (duration <= 0) return const SizedBox(height: 4);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white38,
        thumbColor: Colors.white,
      ),
      child: Slider(
          value: position.clamp(0, duration),
          min: 0,
          max: duration,
          onChangeStart: onSeekStart,
          onChanged: onSeekChanged,
          onChangeEnd: onSeekEnd),
    );
  }
}

class _AccessOverlay extends StatelessWidget {
  const _AccessOverlay({required this.access});

  final EpisodeAccessState access;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = access == EpisodeAccessState.sourceLocked;
    final unavailable = access == EpisodeAccessState.sourceUnavailable;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              locked ? Icons.lock_outline_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 56),
          const SizedBox(height: 12),
          Text(
              locked
                  ? l10n.sourceLocked
                  : unavailable
                      ? l10n.sourceUnavailable
                      : l10n.vipEpisode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
