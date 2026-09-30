import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
abstract class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String seriesId,
    required int order,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationSec,
    @Default(false) bool isVipLocked,
    @Default(true) bool sourceAvailable,
    @Default(false) bool sourceLocked,
    String? chapterName,
    int? sourceChapterIndex,
    int? bonusUnlockCost,
    @Default(0) int watchCount,
    @Default(0) int likeCount,
    @Default(0) int shareCount,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
}

extension EpisodeAccess on Episode {
  bool get canUnlockWithBonus =>
      !isVipLocked && bonusUnlockCost != null && bonusUnlockCost! > 0;
}
