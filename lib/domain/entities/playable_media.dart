import 'package:flutter/foundation.dart';

@immutable
class PlaybackCandidate {
  const PlaybackCandidate({
    required this.url,
    this.provider,
    this.headers = const {},
    this.quality,
    this.mediaKind,
  });

  final String url;
  final String? provider;
  final Map<String, String> headers;
  final int? quality;
  final String? mediaKind;
}

@immutable
class PlayableMedia {
  const PlayableMedia({
    required this.primaryUrl,
    required this.candidateUrls,
    this.provider,
    this.candidates = const [],
  });

  final String primaryUrl;
  final List<String> candidateUrls;
  final String? provider;
  final List<PlaybackCandidate> candidates;

  bool get hasFallbacks => candidateUrls.length > 1;

  List<PlaybackCandidate> get typedCandidates {
    if (candidates.isNotEmpty) return candidates;
    return candidateUrls
        .map((url) => PlaybackCandidate(url: url, provider: provider))
        .toList(growable: false);
  }
}
