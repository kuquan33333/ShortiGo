import 'package:flutter/foundation.dart';

@immutable
class ContentApiProviderStatus {
  const ContentApiProviderStatus({
    required this.name,
    this.available = false,
    this.mode,
    this.playback,
  });

  final String name;
  final bool available;
  final String? mode;
  final String? playback;

  factory ContentApiProviderStatus.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] ?? json['provider'] ?? json['id'];
    final state = json['status']?.toString().toLowerCase();
    final available = json.containsKey('ok')
        ? json['ok'] == true
        : json['available'] != false &&
            state != 'offline' &&
            state != 'unavailable';
    return ContentApiProviderStatus(
      name: rawName?.toString() ?? 'Unknown',
      available: available,
      mode: json['mode']?.toString(),
      playback: json['playback']?.toString(),
    );
  }
}

@immutable
class ContentApiSourceStatus {
  const ContentApiSourceStatus({
    required this.providers,
    this.language,
    this.apiVersion,
    this.resolver,
    this.lockedEpisodePolicy,
  });

  final List<ContentApiProviderStatus> providers;
  final String? language;
  final int? apiVersion;
  final String? resolver;
  final String? lockedEpisodePolicy;

  factory ContentApiSourceStatus.fromJson(Map<String, dynamic> json) {
    final rawProviders = json['providers'];
    if (rawProviders is! List) {
      throw const ContentApiException(
        code: 'invalid-source-status',
      );
    }

    return ContentApiSourceStatus(
      providers: rawProviders
          .whereType<Map<String, dynamic>>()
          .map((item) => ContentApiProviderStatus.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false),
      language: json['language']?.toString(),
      apiVersion: _asInt(json['apiVersion']),
      resolver: json['resolver']?.toString(),
      lockedEpisodePolicy: json['lockedEpisodePolicy']?.toString(),
    );
  }
}

class ContentApiException implements Exception {
  const ContentApiException({
    required this.code,
    this.message,
    this.statusCode,
    this.cause,
  });

  final String code;
  final String? message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ContentApiException($code)';
}

class ContentApiSourceLockedException extends ContentApiException {
  const ContentApiSourceLockedException({super.statusCode = 403})
      : super(
          code: 'source-locked',
        );
}

int? _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
