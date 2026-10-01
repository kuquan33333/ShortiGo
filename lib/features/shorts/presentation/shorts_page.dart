import 'dart:async';
import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/async/retryable_future_cache.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/episode.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../episode_player/application/episode_access.dart';
import '../../episode_player/presentation/episode_player_view.dart';
import '../application/shorts_feed_notifier.dart';
import '../application/video_pre_cache_manager.dart';
import 'shorts_action_rail.dart';
import 'shorts_info_panel.dart';
import 'shorts_video_progress_bar.dart';
import 'video_card.dart';

class ShortsPage extends ConsumerStatefulWidget {
  const ShortsPage({super.key});

  @override
  ConsumerState<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends ConsumerState<ShortsPage>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  final _preCache = VideoPreCacheManager();
  final _urlCache = RetryableFutureCache<String, String>();

  late final BetterPlayerController _playerController;

  int _current = 0;
  Set<String> _keepIds = const {};
  int _playGeneration = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _playerMounted = false;
  String? _attachedEpisodeId;
  double _playbackProgress = 0;
  bool _isPausedByUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerController = BetterPlayerController(shortsPlayerConfiguration());
    _playerController.addEventsListener(_onPlayerEvent);
    _maybeShrinkWindow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerMounted = false;
    _playerController.dispose(forceDispose: true);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldPauseVideoForLifecycle(state)) {
      setState(() => _isPausedByUser = true);
      unawaited(_safePause());
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) {
      return;
    }

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.exception:
        setState(() => _hasError = true);
      case BetterPlayerEventType.progress:
      case BetterPlayerEventType.finished:
        if (event.betterPlayerEventType == BetterPlayerEventType.finished &&
            _current <
                (ref.read(shortsFeedNotifierProvider).value?.episodes.length ??
                        0) -
                    1) {
          unawaited(_pageController.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ));
        }
        final next = _progressFromEvent(event);
        if (next != null && (next - _playbackProgress).abs() > 0.001) {
          setState(() => _playbackProgress = next);
        }
      default:
        break;
    }
  }

  double? _progressFromEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      return 1;
    }

    final position = event.parameters?['progress'] as Duration?;
    final duration = event.parameters?['duration'] as Duration?;
    if (position == null || duration == null || duration.inMilliseconds <= 0) {
      return null;
    }

    return position.inMilliseconds / duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(shortsFeedNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(shortsFeedNotifierProvider),
        ),
        data: (state) {
          final l10n = AppLocalizations.of(context)!;
          final user = ref.watch(currentAppUserDocProvider).value;
          final effectiveVip =
              ref.watch(effectiveVipProvider).value ?? user?.isVip ?? false;
          if (state.episodes.isEmpty) {
            return Center(
              child: Text(l10n.noShorts, style: TextStyle(color: Colors.white)),
            );
          }

          if (_keepIds.isEmpty) {
            _keepIds = _preCache.keepIdsFor(
              currentIndex: _current,
              episodes: state.episodes,
            );
            _prefetchUrls(state.episodes);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_playEpisodeAt(_current, state.episodes));
            });
          }

          final activeEpisode = state.episodes[_current];
          final series = state.seriesById[activeEpisode.seriesId];

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: state.episodes.length,
                  onPageChanged: (index) =>
                      _onPageChanged(index, state.episodes),
                  itemBuilder: (_, index) {
                    final episode = state.episodes[index];
                    final isActive = index == _current;
                    final access = accessFor(
                      episode,
                      user,
                      effectiveVip: effectiveVip,
                    );
                    final showPlayer = isActive &&
                        _playerMounted &&
                        access == EpisodeAccessState.open;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (showPlayer)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Force the video surface to match the full
                                  // viewport so it fills edge-to-edge instead
                                  // of letterboxing to a fixed 9:16 box.
                                  if (constraints.maxHeight > 0) {
                                    _playerController.setOverriddenAspectRatio(
                                      constraints.maxWidth /
                                          constraints.maxHeight,
                                    );
                                  }
                                  return BetterPlayer(
                                    key: ValueKey(
                                      _attachedEpisodeId ?? 'shorts_player',
                                    ),
                                    controller: _playerController,
                                  );
                                },
                              ),
                            ),
                          ),
                        VideoCard(
                          key: ValueKey('chrome_${episode.id}'),
                          episode: episode,
                          isActive: isActive,
                          isLoading: isActive && _isLoading,
                          hasError: isActive && _hasError,
                          access: access,
                          bonusBalance: user?.bonus ?? 0,
                          onRetry: () => unawaited(
                            _playEpisodeAt(_current, state.episodes),
                          ),
                          onUnlock: () =>
                              unawaited(_unlockShortEpisode(episode)),
                          onEarnBonus: () => context.go('/rewards'),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Center(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isPausedByUser ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ShortsVideoProgressBar(
                  progress: _playbackProgress,
                  visible: _playerMounted &&
                      !_isLoading &&
                      !_hasError &&
                      accessFor(
                            activeEpisode,
                            user,
                            effectiveVip: effectiveVip,
                          ) ==
                          EpisodeAccessState.open,
                ),
              ),
              if (series != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ShortsInfoPanel(
                    key: ValueKey('shorts_info_${series.id}'),
                    series: series,
                    episode: activeEpisode,
                    onTitle: () => context.push('/series/${series.id}'),
                    onWatchAll: () {
                      unawaited(_safePause());
                      context.push(
                        '/watch/${series.id}?episodeId=${Uri.encodeComponent(activeEpisode.id)}',
                      );
                    },
                  ),
                ),
              if (series != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ShortsActionRail(
                    key: ValueKey('shorts_actions_${activeEpisode.id}'),
                    series: series,
                    episode: activeEpisode,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onPageChanged(int index, List<Episode> episodes) {
    setState(() {
      _current = index;
      _keepIds = _preCache.keepIdsFor(currentIndex: index, episodes: episodes);
      _isLoading = true;
      _hasError = false;
      _playbackProgress = 0;
      _isPausedByUser = false;
    });
    _prefetchUrls(episodes);
    unawaited(_playEpisodeAt(index, episodes));
  }

  Future<void> _playEpisodeAt(int index, List<Episode> episodes) async {
    if (index < 0 || index >= episodes.length) {
      return;
    }

    final episode = episodes[index];
    final generation = ++_playGeneration;
    final user = ref.read(currentAppUserDocProvider).value;
    final effectiveVip = await ref.read(effectiveVipProvider.future);
    if (accessFor(episode, user, effectiveVip: effectiveVip) !=
        EpisodeAccessState.open) {
      await _safePause();
      if (!mounted || generation != _playGeneration) {
        return;
      }
      setState(() {
        _attachedEpisodeId = null;
        _isLoading = false;
        _hasError = false;
        _playbackProgress = 0;
        _isPausedByUser = false;
      });
      return;
    }

    if (!_playerMounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _playerMounted = true;
        _playbackProgress = 0;
        _isPausedByUser = false;
      });
      await _waitEndOfFrame();
      if (!mounted || generation != _playGeneration) {
        return;
      }
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _playbackProgress = 0;
        _isPausedByUser = false;
      });
    }

    try {
      await _safePause();
      if (!mounted || generation != _playGeneration) {
        return;
      }

      final url = await _urlFor(episode);
      if (!mounted || generation != _playGeneration) {
        return;
      }

      await _playerController.setupDataSource(
        BetterPlayerDataSource.network(
          url,
          cacheConfiguration: const BetterPlayerCacheConfiguration(
            useCache: true,
          ),
        ),
      );
      if (!mounted || generation != _playGeneration) {
        return;
      }

      setState(() {
        _attachedEpisodeId = episode.id;
        _isLoading = false;
      });

      await _waitEndOfFrame();
      if (!mounted || generation != _playGeneration) {
        return;
      }

      await _safePlay();
    } catch (_) {
      if (mounted && generation == _playGeneration) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _urlFor(Episode episode) {
    return _urlCache.getOrCreate(
      episode.id,
      () => ref.read(videoSourceProvider).playableUrl(
            seriesId: episode.seriesId,
            episodeId: episode.id,
            storagePath: episode.videoUrl,
            chapterIndex: episode.sourceChapterIndex ?? episode.order - 1,
          ),
    );
  }

  void _prefetchUrls(List<Episode> episodes) {
    final user = ref.read(currentAppUserDocProvider).value;
    final effectiveVip =
        ref.read(effectiveVipProvider).value ?? user?.isVip ?? false;
    for (final episode in episodes) {
      if (_keepIds.contains(episode.id) &&
          episode.sourceAvailable &&
          !episode.sourceLocked &&
          accessFor(episode, user, effectiveVip: effectiveVip) ==
              EpisodeAccessState.open) {
        unawaited(_urlFor(episode).catchError((_) => ''));
      }
    }
  }

  Future<void> _unlockShortEpisode(Episode episode) async {
    try {
      await ref.read(rewardGatewayProvider).unlockEpisode(episode.id);
      ref.invalidate(currentAppUserDocProvider);
      ref.invalidate(shortsFeedNotifierProvider);
      if (!mounted) {
        return;
      }
      unawaited(
        _playEpisodeAt(
          _current,
          ref.read(shortsFeedNotifierProvider).value?.episodes ?? const [],
        ),
      );
    } catch (_) {
      if (mounted) {
        context.go('/rewards');
      }
    }
  }

  Future<void> _waitEndOfFrame() async {
    await SchedulerBinding.instance.endOfFrame;
  }

  Future<void> _safePause() async {
    try {
      await _playerController.pause();
    } catch (_) {
      // Ignore pause races while switching sources.
    }
  }

  Future<void> _safePlay() async {
    try {
      await _playerController.play();
    } catch (_) {
      // Ignore play races while switching sources.
    }
  }

  void _togglePlayback() {
    if (!_playerMounted || _isLoading || _hasError) {
      return;
    }

    if (_isPausedByUser) {
      setState(() => _isPausedByUser = false);
      unawaited(_safePlay());
    } else {
      setState(() => _isPausedByUser = true);
      unawaited(_safePause());
    }
  }

  void _maybeShrinkWindow() {
    if (!Platform.isAndroid) {
      return;
    }

    final meminfo = File('/proc/meminfo');
    if (!meminfo.existsSync()) {
      return;
    }

    final text = meminfo.readAsStringSync();
    final match = RegExp(r'MemTotal:\s+(\d+)').firstMatch(text);
    if (match == null) {
      return;
    }

    final totalMb = (int.parse(match.group(1)!) / 1024).round();
    if (totalMb < 3000) {
      _preCache.windowSize = 2;
    }
  }
}

BetterPlayerConfiguration shortsPlayerConfiguration() {
  return const BetterPlayerConfiguration(
    autoPlay: false,
    autoDispose: false,
    handleLifecycle: false,
    looping: true,
    aspectRatio: 9 / 16,
    fit: BoxFit.cover,
    controlsConfiguration: BetterPlayerControlsConfiguration(
      showControls: false,
    ),
  );
}
