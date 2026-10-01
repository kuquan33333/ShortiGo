import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/user.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/format/compact_count.dart';
import '../../../shared/widgets/episode_picker_grid.dart';
import '../../../shared/widgets/save_series_button.dart';
import '../application/episode_access.dart';
import 'episode_player_view.dart';
import '../../shorts/application/shorts_share_link.dart';

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
  late final PageController _pageController;

  Series? _series;
  List<Episode> _episodes = const [];
  int _currentIndex = 0;
  int _generation = 0;
  bool _loading = true;
  bool _controllerReady = false;
  bool _paused = false;
  bool _ended = false;
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
      final requested = widget.episodeId == null
          ? -1
          : episodes.indexWhere((episode) => episode.id == widget.episodeId);
      final firstPlayable = episodes.indexWhere(
        (episode) =>
            episode.sourceAvailable &&
            !episode.sourceLocked &&
            !episode.isVipLocked,
      );
      setState(() {
        _series = series;
        _episodes = episodes;
        _currentIndex = requested >= 0
            ? requested
            : (firstPlayable >= 0 ? firstPlayable : 0);
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
      setState(() => _error = event.parameters?['exception'] ?? 'playback');
      return;
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      if (_ended) return;
      _ended = true;
      if (_currentIndex + 1 < _episodes.length) {
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
    setState(() {
      _currentIndex = index;
      _loading = true;
      _controllerReady = false;
      _error = null;
      _ended = false;
      _position = 0;
      _duration = 0;
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
      final url = await ref.read(videoSourceProvider).playableUrl(
            seriesId: widget.seriesId,
            episodeId: episode.id,
            storagePath: episode.videoUrl,
            chapterIndex: episode.sourceChapterIndex,
          );
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
    setState(() => _paused = !_paused);
    if (_paused) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  void _seek(double value) {
    if (_duration <= 0) return;
    final target =
        Duration(milliseconds: value.round().clamp(0, _duration.round()));
    unawaited(_controller.seekTo(target));
  }

  Future<void> _showEpisodes() async {
    if (_series == null) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              _SheetHeader(series: _series!, episodes: _episodes),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.chooseEpisode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),
              EpisodePickerGrid(
                episodes: _episodes,
                currentIndex: _currentIndex,
                onSelect: Navigator.of(context).pop,
              ),
            ],
          ),
        ),
      ),
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
    final episode = _episodes[_currentIndex.clamp(0, _episodes.length - 1)];
    final user = ref.watch(currentAppUserDocProvider).value;
    final effectiveVip =
        ref.watch(effectiveVipProvider).value ?? user?.isVip ?? false;
    final access = accessFor(episode, user, effectiveVip: effectiveVip);

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
          return Stack(
            fit: StackFit.expand,
            children: [
              _EpisodeBackdrop(episode: item),
              if (active &&
                  _controllerReady &&
                  access == EpisodeAccessState.open)
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
              if (active)
                _MainPlayerChrome(
                  series: series,
                  episode: episode,
                  access: access,
                  loading: _loading,
                  error: _error,
                  paused: _paused,
                  ended: _ended && index == _episodes.length - 1,
                  onTapVideo: _togglePlayback,
                  onBack: context.pop,
                  onTitle: () => context.push('/series/${series.id}'),
                  onEpisodes: _showEpisodes,
                  onShare: _share,
                  onRetry: () =>
                      unawaited(_switchToEpisode(index, autoplay: true)),
                  position: _position,
                  duration: _duration,
                  onSeek: _seek,
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
    required this.loading,
    required this.error,
    required this.paused,
    required this.ended,
    required this.onTapVideo,
    required this.onBack,
    required this.onTitle,
    required this.onEpisodes,
    required this.onShare,
    required this.onRetry,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Series series;
  final Episode episode;
  final EpisodeAccessState access;
  final bool loading;
  final Object? error;
  final bool paused;
  final bool ended;
  final VoidCallback onTapVideo;
  final VoidCallback onBack;
  final VoidCallback onTitle;
  final VoidCallback onEpisodes;
  final VoidCallback onShare;
  final VoidCallback onRetry;
  final double position;
  final double duration;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ProviderScope.containerOf(context)
        .read(currentAppUserDocProvider)
        .value;
    return Stack(
      fit: StackFit.expand,
      children: [
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
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.speed_rounded, color: Colors.white),
                    label: Text(l10n.speed,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.more_vert, color: Colors.white)),
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
        if (access == EpisodeAccessState.open && !loading && error == null)
          Center(
            child: AnimatedOpacity(
              opacity: paused ? 1 : 0,
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
                position: position, duration: duration, onSeek: onSeek),
          ),
        ),
      ],
    );
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
  final VoidCallback onEpisodes;
  final VoidCallback onShare;

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
  final VoidCallback onTitle;

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
      {required this.position, required this.duration, required this.onSeek});

  final double position;
  final double duration;
  final ValueChanged<double> onSeek;

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
          onChanged: onSeek),
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            height: 102,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: series.coverUrl.isEmpty
                  ? const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.movie_outlined))
                  : Image.network(series.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.movie_outlined))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    AppLocalizations.of(context)!.views(compactCount(
                        series.watchCount > 0
                            ? series.watchCount
                            : series.popularity)),
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context)!.episodeCount(episodes.length),
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
