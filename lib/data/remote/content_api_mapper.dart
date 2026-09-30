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
      throw const FormatException('Series thiếu bookId hoặc bookName.');
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
    );
  }

  static Episode episode(
    Map<String, dynamic> json, {
    required String seriesId,
  }) {
    final chapterId = _string(json['chapterId'] ?? json['id']);
    final index = _int(json['chapterIndex'] ?? json['serialNumber']);
    final id = chapterId.isEmpty ? '$seriesId::$index' : chapterId;
    return Episode(
      id: id,
      seriesId: seriesId,
      order: index + 1,
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
    );
  }

  static String watchUrl(Map<String, dynamic> json) {
    final url = _string(json['videoUrl']);
    if (url.isEmpty) {
      throw const FormatException('Watch response thiếu videoUrl.');
    }
    return url;
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _date(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
