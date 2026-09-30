import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/features/shorts/application/shorts_share_link.dart';
import 'package:shortigo/l10n/app_localizations_en.dart';

void main() {
  test('builds a stable share URL for an episode', () {
    expect(
      shortShareUrl(seriesId: 's1', episodeId: 'e7').toString(),
      'https://shortigo.app/series/s1/episodes/e7',
    );
  });

  test('builds readable share text with the URL', () {
    final text = shortShareText(
      l10n: AppLocalizationsEn(),
      seriesTitle: 'Save Me',
      episodeOrder: 7,
      seriesId: 's1',
      episodeId: 'e7',
    );

    expect(text, contains('Save Me'));
    expect(text, contains('Episode 7'));
    expect(text, contains('https://shortigo.app/series/s1/episodes/e7'));
  });
}
