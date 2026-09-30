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
    expect(episode.sourceChapterIndex, 7);
    expect(episode.videoUrl, 'remote://7');
    expect(episode.thumbnailUrl, 'https://img.example/episode.jpg');
    expect(episode.durationSec, 0);
    expect(episode.isVipLocked, isFalse);
    expect(episode.sourceAvailable, isTrue);
    expect(episode.sourceLocked, isFalse);
    expect(episode.chapterName, 'Tập 8');
  });

  test('keeps source chapter index separate from display serial number', () {
    final episode = ContentApiMapper.episode(
      {
        'chapterIndex': 17,
        'serialNumber': 18,
        'available': true,
      },
      seriesId: 'book-1',
    );

    expect(episode.order, 18);
    expect(episode.sourceChapterIndex, 17);
    expect(episode.videoUrl, 'remote://17');
  });

  test('keeps provider source access separate from ShortiGo VIP access', () {
    final available = ContentApiMapper.episode(
      {'chapterIndex': 0, 'available': true, 'isCharge': 0, 'isPay': 0},
      seriesId: 'book-1',
    );
    final locked = ContentApiMapper.episode(
      {'chapterIndex': 1, 'available': false, 'isCharge': 1, 'isPay': 0},
      seriesId: 'book-1',
    );
    final unavailable = ContentApiMapper.episode(
      {'chapterIndex': 2, 'available': false, 'isCharge': 0, 'isPay': 0},
      seriesId: 'book-1',
    );

    expect(available.sourceAvailable, isTrue);
    expect(available.sourceLocked, isFalse);
    expect(available.isVipLocked, isFalse);
    expect(locked.sourceAvailable, isFalse);
    expect(locked.sourceLocked, isTrue);
    expect(locked.isVipLocked, isFalse);
    expect(unavailable.sourceAvailable, isFalse);
    expect(unavailable.sourceLocked, isFalse);
  });

  test('rejects a catalog item without the required identity fields', () {
    expect(
      () => ContentApiMapper.series({'bookName': 'Missing id'}),
      throwsFormatException,
    );
  });
}
