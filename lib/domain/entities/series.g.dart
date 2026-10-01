// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Series _$SeriesFromJson(Map<String, dynamic> json) => _Series(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String,
      category: $enumDecode(_$CategoryEnumMap, json['category']),
      isVip: json['isVip'] as bool? ?? false,
      episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
      totalDurationSec: (json['totalDurationSec'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
      watchCount: (json['watchCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      isPublished: json['isPublished'] as bool? ?? true,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      isNew: json['isNew'] as bool? ?? false,
      isDubbed: json['isDubbed'] as bool? ?? false,
      audioType: json['audioType'] as String?,
      provider: json['provider'] as String?,
    );

Map<String, dynamic> _$SeriesToJson(_Series instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'category': _$CategoryEnumMap[instance.category]!,
      'isVip': instance.isVip,
      'episodeCount': instance.episodeCount,
      'totalDurationSec': instance.totalDurationSec,
      'createdAt': instance.createdAt.toIso8601String(),
      'popularity': instance.popularity,
      'watchCount': instance.watchCount,
      'saveCount': instance.saveCount,
      'followerCount': instance.followerCount,
      'isPublished': instance.isPublished,
      'genres': instance.genres,
      'tags': instance.tags,
      'isNew': instance.isNew,
      'isDubbed': instance.isDubbed,
      'audioType': instance.audioType,
      'provider': instance.provider,
    };

const _$CategoryEnumMap = {
  Category.forYou: 'forYou',
  Category.newReleases: 'newReleases',
  Category.hot: 'hot',
  Category.romance: 'romance',
  Category.ceo: 'ceo',
  Category.revenge: 'revenge',
  Category.family: 'family',
  Category.action: 'action',
  Category.fantasy: 'fantasy',
  Category.recommended: 'recommended',
  Category.adventure: 'adventure',
  Category.scary: 'scary',
  Category.anime: 'anime',
  Category.vip: 'vip',
};
