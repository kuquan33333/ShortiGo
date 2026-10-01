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
class ContentApiCapabilities {
  const ContentApiCapabilities({
    this.home = false,
    this.collections = false,
    this.cursorPagination = false,
    this.sorting = false,
    this.search = false,
    this.searchPagination = false,
    this.suggest = false,
    this.book = false,
    this.chapters = false,
    this.watch = false,
  });

  final bool home;
  final bool collections;
  final bool cursorPagination;
  final bool sorting;
  final bool search;
  final bool searchPagination;
  final bool suggest;
  final bool book;
  final bool chapters;
  final bool watch;

  factory ContentApiCapabilities.fromJson(Map<String, dynamic> json) {
    bool read(String key) => json[key] == true;

    return ContentApiCapabilities(
      home: read('home'),
      collections: read('collections'),
      cursorPagination: read('cursorPagination'),
      sorting: read('sorting'),
      search: read('search'),
      searchPagination: read('searchPagination'),
      suggest: read('suggest'),
      book: read('book'),
      chapters: read('chapters'),
      watch: read('watch'),
    );
  }

  bool get supportsV2 =>
      home &&
      collections &&
      cursorPagination &&
      sorting &&
      search &&
      searchPagination &&
      suggest &&
      book &&
      chapters &&
      watch;
}

@immutable
class ContentApiSourceStatus {
  const ContentApiSourceStatus({
    required this.providers,
    this.language,
    this.apiVersion,
    this.resolver,
    this.lockedEpisodePolicy,
    this.catalogMode,
    this.apiKeyRequired = false,
    this.capabilities = const ContentApiCapabilities(),
  });

  final List<ContentApiProviderStatus> providers;
  final String? language;
  final int? apiVersion;
  final String? resolver;
  final String? lockedEpisodePolicy;
  final String? catalogMode;
  final bool apiKeyRequired;
  final ContentApiCapabilities capabilities;

  bool get isCompatible =>
      apiVersion != null &&
      apiVersion! >= 2 &&
      capabilities.supportsV2 &&
      apiKeyRequired == false;

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
      catalogMode: json['catalogMode']?.toString(),
      apiKeyRequired: json['apiKeyRequired'] == true,
      capabilities: json['capabilities'] is Map
          ? ContentApiCapabilities.fromJson(
              Map<String, dynamic>.from(json['capabilities'] as Map),
            )
          : const ContentApiCapabilities(),
    );
  }
}

@immutable
class ContentApiHomePayload {
  const ContentApiHomePayload({
    this.hero,
    this.heroes = const [],
    this.sections = const [],
  });

  final Map<String, dynamic>? hero;
  final List<Map<String, dynamic>> heroes;
  final List<ContentApiHomeSection> sections;

  factory ContentApiHomePayload.fromJson(Map<String, dynamic> json) {
    final rawHeroes = json['heroes'];
    final rawSections = json['sections'];
    return ContentApiHomePayload(
      hero: json['hero'] is Map
          ? Map<String, dynamic>.from(json['hero'] as Map)
          : null,
      heroes: rawHeroes is List
          ? rawHeroes
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : const [],
      sections: rawSections is List
          ? rawSections
              .whereType<Map<String, dynamic>>()
              .map((item) => ContentApiHomeSection.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

@immutable
class ContentApiHomeSection {
  const ContentApiHomeSection({
    required this.slug,
    required this.title,
    required this.items,
  });

  final String slug;
  final String title;
  final List<Map<String, dynamic>> items;

  factory ContentApiHomeSection.fromJson(Map<String, dynamic> json) {
    final raw = json['list'];
    return ContentApiHomeSection(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : const [],
    );
  }
}

@immutable
class ContentApiCollectionPage {
  const ContentApiCollectionPage({
    required this.slug,
    required this.title,
    required this.page,
    required this.pageSize,
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final String slug;
  final String title;
  final int page;
  final int pageSize;
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final String? nextCursor;

  factory ContentApiCollectionPage.fromJson(Map<String, dynamic> json) {
    final raw = json['list'];
    if (raw is! List) {
      throw const ContentApiException(code: 'invalid-schema');
    }
    return ContentApiCollectionPage(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? raw.length,
      items: raw
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}

@immutable
class ContentApiSearchPage {
  const ContentApiSearchPage({
    required this.page,
    required this.pageSize,
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final int page;
  final int pageSize;
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final String? nextCursor;

  factory ContentApiSearchPage.fromJson(Map<String, dynamic> json) {
    final raw = json['list'];
    if (raw is! List) {
      throw const ContentApiException(code: 'invalid-schema');
    }
    return ContentApiSearchPage(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? raw.length,
      items: raw
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}

@immutable
class ContentApiPlayback {
  const ContentApiPlayback({
    required this.bookId,
    required this.chapterIndex,
    required this.videoUrl,
    this.provider,
    this.expiresAt,
  });

  final String bookId;
  final int chapterIndex;
  final String videoUrl;
  final String? provider;
  final String? expiresAt;

  factory ContentApiPlayback.fromJson(Map<String, dynamic> json) {
    final videoUrl = json['videoUrl']?.toString() ?? '';
    if (videoUrl.isEmpty) {
      throw const ContentApiException(code: 'invalid-schema');
    }
    return ContentApiPlayback(
      bookId: json['bookId']?.toString() ?? '',
      chapterIndex: _asInt(json['chapterIndex']) ?? 0,
      videoUrl: videoUrl,
      provider: json['provider']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
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
