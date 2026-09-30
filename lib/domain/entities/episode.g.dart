// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Episode _$EpisodeFromJson(Map<String, dynamic> json) => _Episode(
      id: json['id'] as String,
      seriesId: json['seriesId'] as String,
      order: (json['order'] as num).toInt(),
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      durationSec: (json['durationSec'] as num).toInt(),
      isVipLocked: json['isVipLocked'] as bool? ?? false,
      sourceAvailable: json['sourceAvailable'] as bool? ?? true,
      sourceLocked: json['sourceLocked'] as bool? ?? false,
      chapterName: json['chapterName'] as String?,
      bonusUnlockCost: (json['bonusUnlockCost'] as num?)?.toInt(),
      watchCount: (json['watchCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EpisodeToJson(_Episode instance) => <String, dynamic>{
      'id': instance.id,
      'seriesId': instance.seriesId,
      'order': instance.order,
      'videoUrl': instance.videoUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'durationSec': instance.durationSec,
      'isVipLocked': instance.isVipLocked,
      'sourceAvailable': instance.sourceAvailable,
      'sourceLocked': instance.sourceLocked,
      'chapterName': instance.chapterName,
      'bonusUnlockCost': instance.bonusUnlockCost,
      'watchCount': instance.watchCount,
      'likeCount': instance.likeCount,
      'shareCount': instance.shareCount,
    };
