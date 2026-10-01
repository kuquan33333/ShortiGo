import 'package:flutter/foundation.dart';

@immutable
class PlayableMedia {
  const PlayableMedia({
    required this.primaryUrl,
    required this.candidateUrls,
    this.provider,
  });

  final String primaryUrl;
  final List<String> candidateUrls;
  final String? provider;

  bool get hasFallbacks => candidateUrls.length > 1;
}
