import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/features/episode_player/presentation/main_player_page.dart';

void main() {
  final episodes = List.generate(
    10,
    (index) => Episode(
      id: 'ep${index + 1}',
      seriesId: 's1',
      order: index + 1,
      videoUrl: 'https://example.com/ep${index + 1}.mp4',
      thumbnailUrl: '',
      durationSec: 60,
      sourceAvailable: index != 0,
    ),
  );

  test('no deep link starts at the first playable episode', () {
    expect(resolveInitialEpisodeIndex(episodes, null), 1);
  });

  test('deep link resolves requested episode before playback', () {
    expect(resolveInitialEpisodeIndex(episodes, 'ep7'), 6);
  });

  test('adjacent preload only keeps previous and next episode', () {
    expect(adjacentEpisodeIndices(6, episodes.length), [5, 7]);
    expect(adjacentEpisodeIndices(0, episodes.length), [1]);
  });

  test('auto-next stops at the last episode instead of looping', () {
    expect(nextEpisodeIndex(2, episodes.length), 3);
    expect(nextEpisodeIndex(9, episodes.length), -1);
  });

  test('seek position is clamped to the real duration', () {
    expect(clampSeekPosition(-10, 100), 0);
    expect(clampSeekPosition(50, 100), 50);
    expect(clampSeekPosition(120, 100), 100);
    expect(clampSeekPosition(50, 0), 0);
  });
}
