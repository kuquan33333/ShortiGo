import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/remote/content_api_client.dart';
import 'package:shortigo/data/remote/remote_video_source.dart';

void main() {
  test('keeps the default and quality playback candidates in order', () async {
    const bookId =
        'rs.69d49b125ab01618b60b7cdc.xJHDoW0tdGFuZy1zaW5oLXJhLcO0bmctY2jhu6c';
    final client = ContentApiClient(
      defaultBaseUrl: 'https://api.example.com',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/watch/$bookId/0');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'bookId': bookId,
              'chapterIndex': 0,
              'provider': 'reelshort',
              'videoUrl': 'https://cdn.example.com/default.m3u8',
              'qualities': [
                {
                  'quality': 720,
                  'videoPath': 'https://cdn.example.com/default.m3u8',
                  'isDefault': true,
                },
                {
                  'quality': 540,
                  'videoPath': 'https://cdn.example.com/fallback.mp4',
                },
                {
                  'quality': 360,
                  'videoPath': 'https://cdn.example.com/low.mp4',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final media = await RemoteVideoSource(client).playableMedia(
      seriesId: bookId,
      episodeId: 'episode-1',
      storagePath: 'remote://0',
      chapterIndex: 0,
    );

    expect(media.provider, 'reelshort');
    expect(media.primaryUrl, 'https://cdn.example.com/default.m3u8');
    expect(media.candidateUrls, [
      'https://cdn.example.com/default.m3u8',
      'https://cdn.example.com/fallback.mp4',
      'https://cdn.example.com/low.mp4',
    ]);
  });

  test('drops invalid and duplicate quality URLs', () async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://api.example.com',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'bookId': 's1',
              'chapterIndex': 0,
              'videoUrl': 'https://cdn.example.com/a.m3u8',
              'qualities': [
                {
                  'quality': '720p',
                  'videoPath': 'https://cdn.example.com/a.m3u8',
                },
                {
                  'quality': 540,
                  'videoPath': 'ftp://private.example.com/b.mp4',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final media = await RemoteVideoSource(client).playableMedia(
      seriesId: 's1',
      episodeId: 'episode-1',
      storagePath: 'remote://0',
      chapterIndex: 0,
    );

    expect(media.candidateUrls, ['https://cdn.example.com/a.m3u8']);
  });
}
