import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/remote/content_api_mapper.dart';

void main() {
  test('maps DramaBox book fields to the ShortiGo series model', () {
    final series = ContentApiMapper.series({
      'bookId': 'reel.1',
      'bookName': 'Một bộ phim',
      'introduction': 'Mô tả',
      'cover': 'https://img.example/cover.jpg',
      'chapterCount': 42,
      'popularity': 99,
      'playable': true,
    });

    expect(series.id, 'reel.1');
    expect(series.title, 'Một bộ phim');
    expect(series.description, 'Mô tả');
    expect(series.coverUrl, 'https://img.example/cover.jpg');
    expect(series.episodeCount, 42);
    expect(series.popularity, 99);
    expect(series.isVip, isFalse);
  });

  test('maps chapters without resolving video URLs or inventing duration', () {
    final episode = ContentApiMapper.episode(
      {
        'chapterId': 'chapter-7',
        'chapterIndex': 7,
        'serialNumber': 8,
        'chapterName': 'Tập 8',
        'chapterImg': 'https://img.example/episode.jpg',
        'available': true,
        'isCharge': 0,
        'isPay': 0,
      },
      seriesId: 'book-1',
    );

    expect(episode.id, 'chapter-7');
    expect(episode.seriesId, 'book-1');
    expect(episode.order, 8);
    expect(episode.videoUrl, 'remote://7');
    expect(episode.thumbnailUrl, 'https://img.example/episode.jpg');
    expect(episode.durationSec, 0);
    expect(episode.isVipLocked, isFalse);
  });

  test('rejects a catalog item without the required identity fields', () {
    expect(
      () => ContentApiMapper.series({'bookName': 'Missing id'}),
      throwsFormatException,
    );
  });
}
