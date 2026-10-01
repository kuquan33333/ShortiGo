import '../../domain/entities/category.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/series.dart';

class ContentApiMapper {
  const ContentApiMapper._();

  static Series series(
    Map<String, dynamic> json, {
    Category category = Category.forYou,
  }) {
    final id = _string(json['bookId'] ?? json['id']);
    final title = _string(json['bookName'] ?? json['title']);
    if (id.isEmpty || title.isEmpty) {
      throw const FormatException('missing-book-metadata');
    }

    return Series(
      id: id,
      title: title,
      description: _string(json['introduction'] ?? json['description']),
      coverUrl: _string(json['cover'] ?? json['coverUrl']),
      category: category,
      // Provider paywalls are intentionally not mapped to ShortiGo VIP.
      isVip: false,
      episodeCount: _int(json['chapterCount'] ?? json['episodeCount']),
      totalDurationSec: _int(json['totalDurationSec']),
      createdAt: _date(json['createdAt']),
      popularity: _int(json['popularity'] ?? json['playCount']),
      watchCount: _int(json['watchCount'] ?? json['playCount']),
      saveCount: _int(json['saveCount']),
      followerCount: _int(json['followerCount']),
      isPublished: json['playable'] != false,
      genres: _strings(json['genres']),
      tags: _strings(json['tags']),
      isNew: json['isNew'] == true,
      isDubbed: json['isDubbed'] == true ||
          _string(json['audioType']).toLowerCase() == 'dubbed',
      audioType: _stringOrNull(json['audioType']),
      provider: _stringOrNull(json['provider']),
    );
  }

  static Episode episode(
    Map<String, dynamic> json, {
    required String seriesId,
  }) {
    final chapterId = _string(json['chapterId'] ?? json['id']);
    final sourceChapterIndex = _intOrNull(json['chapterIndex']);
    final serialNumber = _intOrNull(json['serialNumber']);
    final index = sourceChapterIndex ??
        ((serialNumber ?? 1) - 1).clamp(0, 1 << 30).toInt();
    final id = chapterId.isEmpty ? '$seriesId::$index' : chapterId;
    final sourceLocked = _flag(json['isCharge']) ||
        _flag(json['isPay']) ||
        _flag(json['locked']);
    final sourceAvailable = json.containsKey('available')
        ? json['available'] == true && !sourceLocked
        : !sourceLocked;
    return Episode(
      id: id,
      seriesId: seriesId,
      order: serialNumber ?? index + 1,
      // Keep the chapter index in a private sentinel. The player resolves the
      // playable URL lazily through /api/watch instead of resolving every
      // chapter while the list is displayed.
      // Always resolve through /api/watch so provider lock policy and the
      // latest public URL are applied at playback time.
      videoUrl: 'remote://$index',
      thumbnailUrl: _string(json['chapterImg'] ?? json['thumbnailUrl']),
      durationSec: _int(json['durationSec'] ?? json['duration']),
      // Source lock and ShortiGo VIP are deliberately independent.
      isVipLocked: false,
      sourceAvailable: sourceAvailable,
      sourceLocked: sourceLocked,
      chapterName: _string(json['chapterName'] ?? json['chapter_name']),
      sourceChapterIndex: sourceChapterIndex,
    );
  }

  static String watchUrl(Map<String, dynamic> json) {
    final url = _string(json['videoUrl']);
    if (url.isEmpty) {
      throw const FormatException('missing-video-url');
    }
    return url;
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static String? _stringOrNull(Object? value) {
    final valueString = _string(value);
    return valueString.isEmpty ? null : valueString;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _intOrNull(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _flag(Object? value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static DateTime _date(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
