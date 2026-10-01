// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Series {
  String get id;
  String get title;
  String get description;
  String get coverUrl;
  Category get category;
  bool get isVip;
  int get episodeCount;
  int get totalDurationSec;
  DateTime get createdAt;
  int get popularity;
  int get watchCount;
  int get saveCount;
  int get followerCount;
  bool get isPublished;
  List<String> get genres;
  List<String> get tags;
  bool get isNew;
  bool get isDubbed;
  String? get audioType;
  String? get provider;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SeriesCopyWith<Series> get copyWith =>
      _$SeriesCopyWithImpl<Series>(this as Series, _$identity);

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Series &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isVip, isVip) || other.isVip == isVip) &&
            (identical(other.episodeCount, episodeCount) ||
                other.episodeCount == episodeCount) &&
            (identical(other.totalDurationSec, totalDurationSec) ||
                other.totalDurationSec == totalDurationSec) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.watchCount, watchCount) ||
                other.watchCount == watchCount) &&
            (identical(other.saveCount, saveCount) ||
                other.saveCount == saveCount) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            const DeepCollectionEquality().equals(other.genres, genres) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.isDubbed, isDubbed) ||
                other.isDubbed == isDubbed) &&
            (identical(other.audioType, audioType) ||
                other.audioType == audioType) &&
            (identical(other.provider, provider) ||
                other.provider == provider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        description,
        coverUrl,
        category,
        isVip,
        episodeCount,
        totalDurationSec,
        createdAt,
        popularity,
        watchCount,
        saveCount,
        followerCount,
        isPublished,
        const DeepCollectionEquality().hash(genres),
        const DeepCollectionEquality().hash(tags),
        isNew,
        isDubbed,
        audioType,
        provider
      ]);

  @override
  String toString() {
    return 'Series(id: $id, title: $title, description: $description, coverUrl: $coverUrl, category: $category, isVip: $isVip, episodeCount: $episodeCount, totalDurationSec: $totalDurationSec, createdAt: $createdAt, popularity: $popularity, watchCount: $watchCount, saveCount: $saveCount, followerCount: $followerCount, isPublished: $isPublished, genres: $genres, tags: $tags, isNew: $isNew, isDubbed: $isDubbed, audioType: $audioType, provider: $provider)';
  }
}

/// @nodoc
abstract mixin class $SeriesCopyWith<$Res> {
  factory $SeriesCopyWith(Series value, $Res Function(Series) _then) =
      _$SeriesCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String coverUrl,
      Category category,
      bool isVip,
      int episodeCount,
      int totalDurationSec,
      DateTime createdAt,
      int popularity,
      int watchCount,
      int saveCount,
      int followerCount,
      bool isPublished,
      List<String> genres,
      List<String> tags,
      bool isNew,
      bool isDubbed,
      String? audioType,
      String? provider});
}

/// @nodoc
class _$SeriesCopyWithImpl<$Res> implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._self, this._then);

  final Series _self;
  final $Res Function(Series) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? coverUrl = null,
    Object? category = null,
    Object? isVip = null,
    Object? episodeCount = null,
    Object? totalDurationSec = null,
    Object? createdAt = null,
    Object? popularity = null,
    Object? watchCount = null,
    Object? saveCount = null,
    Object? followerCount = null,
    Object? isPublished = null,
    Object? genres = null,
    Object? tags = null,
    Object? isNew = null,
    Object? isDubbed = null,
    Object? audioType = freezed,
    Object? provider = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      coverUrl: null == coverUrl
          ? _self.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      isVip: null == isVip
          ? _self.isVip
          : isVip // ignore: cast_nullable_to_non_nullable
              as bool,
      episodeCount: null == episodeCount
          ? _self.episodeCount
          : episodeCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalDurationSec: null == totalDurationSec
          ? _self.totalDurationSec
          : totalDurationSec // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      popularity: null == popularity
          ? _self.popularity
          : popularity // ignore: cast_nullable_to_non_nullable
              as int,
      watchCount: null == watchCount
          ? _self.watchCount
          : watchCount // ignore: cast_nullable_to_non_nullable
              as int,
      saveCount: null == saveCount
          ? _self.saveCount
          : saveCount // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _self.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPublished: null == isPublished
          ? _self.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      genres: null == genres
          ? _self.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isNew: null == isNew
          ? _self.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
      isDubbed: null == isDubbed
          ? _self.isDubbed
          : isDubbed // ignore: cast_nullable_to_non_nullable
              as bool,
      audioType: freezed == audioType
          ? _self.audioType
          : audioType // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _self.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Series].
extension SeriesPatterns on Series {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Series value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Series value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Series value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String title,
            String description,
            String coverUrl,
            Category category,
            bool isVip,
            int episodeCount,
            int totalDurationSec,
            DateTime createdAt,
            int popularity,
            int watchCount,
            int saveCount,
            int followerCount,
            bool isPublished,
            List<String> genres,
            List<String> tags,
            bool isNew,
            bool isDubbed,
            String? audioType,
            String? provider)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.description,
            _that.coverUrl,
            _that.category,
            _that.isVip,
            _that.episodeCount,
            _that.totalDurationSec,
            _that.createdAt,
            _that.popularity,
            _that.watchCount,
            _that.saveCount,
            _that.followerCount,
            _that.isPublished,
            _that.genres,
            _that.tags,
            _that.isNew,
            _that.isDubbed,
            _that.audioType,
            _that.provider);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String title,
            String description,
            String coverUrl,
            Category category,
            bool isVip,
            int episodeCount,
            int totalDurationSec,
            DateTime createdAt,
            int popularity,
            int watchCount,
            int saveCount,
            int followerCount,
            bool isPublished,
            List<String> genres,
            List<String> tags,
            bool isNew,
            bool isDubbed,
            String? audioType,
            String? provider)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series():
        return $default(
            _that.id,
            _that.title,
            _that.description,
            _that.coverUrl,
            _that.category,
            _that.isVip,
            _that.episodeCount,
            _that.totalDurationSec,
            _that.createdAt,
            _that.popularity,
            _that.watchCount,
            _that.saveCount,
            _that.followerCount,
            _that.isPublished,
            _that.genres,
            _that.tags,
            _that.isNew,
            _that.isDubbed,
            _that.audioType,
            _that.provider);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String title,
            String description,
            String coverUrl,
            Category category,
            bool isVip,
            int episodeCount,
            int totalDurationSec,
            DateTime createdAt,
            int popularity,
            int watchCount,
            int saveCount,
            int followerCount,
            bool isPublished,
            List<String> genres,
            List<String> tags,
            bool isNew,
            bool isDubbed,
            String? audioType,
            String? provider)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.description,
            _that.coverUrl,
            _that.category,
            _that.isVip,
            _that.episodeCount,
            _that.totalDurationSec,
            _that.createdAt,
            _that.popularity,
            _that.watchCount,
            _that.saveCount,
            _that.followerCount,
            _that.isPublished,
            _that.genres,
            _that.tags,
            _that.isNew,
            _that.isDubbed,
            _that.audioType,
            _that.provider);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Series implements Series {
  const _Series(
      {required this.id,
      required this.title,
      this.description = '',
      required this.coverUrl,
      required this.category,
      this.isVip = false,
      this.episodeCount = 0,
      this.totalDurationSec = 0,
      required this.createdAt,
      this.popularity = 0,
      this.watchCount = 0,
      this.saveCount = 0,
      this.followerCount = 0,
      this.isPublished = true,
      final List<String> genres = const <String>[],
      final List<String> tags = const <String>[],
      this.isNew = false,
      this.isDubbed = false,
      this.audioType,
      this.provider})
      : _genres = genres,
        _tags = tags;
  factory _Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  final String coverUrl;
  @override
  final Category category;
  @override
  @JsonKey()
  final bool isVip;
  @override
  @JsonKey()
  final int episodeCount;
  @override
  @JsonKey()
  final int totalDurationSec;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final int popularity;
  @override
  @JsonKey()
  final int watchCount;
  @override
  @JsonKey()
  final int saveCount;
  @override
  @JsonKey()
  final int followerCount;
  @override
  @JsonKey()
  final bool isPublished;
  final List<String> _genres;
  @override
  @JsonKey()
  List<String> get genres {
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genres);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool isNew;
  @override
  @JsonKey()
  final bool isDubbed;
  @override
  final String? audioType;
  @override
  final String? provider;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SeriesCopyWith<_Series> get copyWith =>
      __$SeriesCopyWithImpl<_Series>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SeriesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Series &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isVip, isVip) || other.isVip == isVip) &&
            (identical(other.episodeCount, episodeCount) ||
                other.episodeCount == episodeCount) &&
            (identical(other.totalDurationSec, totalDurationSec) ||
                other.totalDurationSec == totalDurationSec) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.watchCount, watchCount) ||
                other.watchCount == watchCount) &&
            (identical(other.saveCount, saveCount) ||
                other.saveCount == saveCount) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.isDubbed, isDubbed) ||
                other.isDubbed == isDubbed) &&
            (identical(other.audioType, audioType) ||
                other.audioType == audioType) &&
            (identical(other.provider, provider) ||
                other.provider == provider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        description,
        coverUrl,
        category,
        isVip,
        episodeCount,
        totalDurationSec,
        createdAt,
        popularity,
        watchCount,
        saveCount,
        followerCount,
        isPublished,
        const DeepCollectionEquality().hash(_genres),
        const DeepCollectionEquality().hash(_tags),
        isNew,
        isDubbed,
        audioType,
        provider
      ]);

  @override
  String toString() {
    return 'Series(id: $id, title: $title, description: $description, coverUrl: $coverUrl, category: $category, isVip: $isVip, episodeCount: $episodeCount, totalDurationSec: $totalDurationSec, createdAt: $createdAt, popularity: $popularity, watchCount: $watchCount, saveCount: $saveCount, followerCount: $followerCount, isPublished: $isPublished, genres: $genres, tags: $tags, isNew: $isNew, isDubbed: $isDubbed, audioType: $audioType, provider: $provider)';
  }
}

/// @nodoc
abstract mixin class _$SeriesCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$SeriesCopyWith(_Series value, $Res Function(_Series) _then) =
      __$SeriesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String coverUrl,
      Category category,
      bool isVip,
      int episodeCount,
      int totalDurationSec,
      DateTime createdAt,
      int popularity,
      int watchCount,
      int saveCount,
      int followerCount,
      bool isPublished,
      List<String> genres,
      List<String> tags,
      bool isNew,
      bool isDubbed,
      String? audioType,
      String? provider});
}

/// @nodoc
class __$SeriesCopyWithImpl<$Res> implements _$SeriesCopyWith<$Res> {
  __$SeriesCopyWithImpl(this._self, this._then);

  final _Series _self;
  final $Res Function(_Series) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? coverUrl = null,
    Object? category = null,
    Object? isVip = null,
    Object? episodeCount = null,
    Object? totalDurationSec = null,
    Object? createdAt = null,
    Object? popularity = null,
    Object? watchCount = null,
    Object? saveCount = null,
    Object? followerCount = null,
    Object? isPublished = null,
    Object? genres = null,
    Object? tags = null,
    Object? isNew = null,
    Object? isDubbed = null,
    Object? audioType = freezed,
    Object? provider = freezed,
  }) {
    return _then(_Series(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      coverUrl: null == coverUrl
          ? _self.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      isVip: null == isVip
          ? _self.isVip
          : isVip // ignore: cast_nullable_to_non_nullable
              as bool,
      episodeCount: null == episodeCount
          ? _self.episodeCount
          : episodeCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalDurationSec: null == totalDurationSec
          ? _self.totalDurationSec
          : totalDurationSec // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      popularity: null == popularity
          ? _self.popularity
          : popularity // ignore: cast_nullable_to_non_nullable
              as int,
      watchCount: null == watchCount
          ? _self.watchCount
          : watchCount // ignore: cast_nullable_to_non_nullable
              as int,
      saveCount: null == saveCount
          ? _self.saveCount
          : saveCount // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _self.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPublished: null == isPublished
          ? _self.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      genres: null == genres
          ? _self._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isNew: null == isNew
          ? _self.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
      isDubbed: null == isDubbed
          ? _self.isDubbed
          : isDubbed // ignore: cast_nullable_to_non_nullable
              as bool,
      audioType: freezed == audioType
          ? _self.audioType
          : audioType // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _self.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
