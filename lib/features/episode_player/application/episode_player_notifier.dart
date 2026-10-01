import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/episode.dart';
import '../../../data/remote/content_api_models.dart';
import 'episode_access.dart';
import '../presentation/playback_data_source.dart';

class EpisodePlayerState {
  const EpisodePlayerState({this.controller, this.episode, this.error});

  final BetterPlayerController? controller;
  final Episode? episode;
  final String? error;
}

class EpisodePlayerArgs {
  const EpisodePlayerArgs({required this.seriesId, required this.episodeId});

  final String seriesId;
  final String episodeId;

  @override
  bool operator ==(Object other) {
    return other is EpisodePlayerArgs &&
        other.seriesId == seriesId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(seriesId, episodeId);
}

class EpisodePlayerNotifier
    extends FamilyAsyncNotifier<EpisodePlayerState, EpisodePlayerArgs> {
  @override
  Future<EpisodePlayerState> build(EpisodePlayerArgs args) async {
    return withTrace('episode_play', () async {
      final episodeRepo = ref.read(episodeRepositoryProvider);
      final videoSource = ref.read(videoSourceProvider);
      Episode episode;
      try {
        episode = await episodeRepo.byId(args.episodeId);
      } on ContentApiException catch (error) {
        if (error.code != 'episode-not-loaded') rethrow;
        final episodes = await episodeRepo.bySeriesId(args.seriesId);
        episode = episodes.firstWhere(
          (item) => item.id == args.episodeId,
          orElse: () => throw StateError('episode-not-found'),
        );
      }

      final user = ref.read(currentAppUserDocProvider).value;
      final effectiveVip = await ref.read(effectiveVipProvider.future);
      final access = accessFor(episode, user, effectiveVip: effectiveVip);
      if (access != EpisodeAccessState.open) {
        return EpisodePlayerState(episode: episode);
      }

      final url = await videoSource.playableUrl(
        seriesId: args.seriesId,
        episodeId: args.episodeId,
        storagePath: episode.videoUrl,
        chapterIndex: canonicalChapterIndex(episode),
      );

      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
          looping: false,
          aspectRatio: 9 / 16,
          fit: BoxFit.cover,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControls: false,
          ),
        ),
      );
      await controller.setupDataSource(
        buildNetworkVideoDataSource(url),
      );

      return EpisodePlayerState(controller: controller, episode: episode);
    });
  }
}

final episodePlayerNotifierProvider = AsyncNotifierProvider.family<
    EpisodePlayerNotifier,
    EpisodePlayerState,
    EpisodePlayerArgs>(EpisodePlayerNotifier.new);
