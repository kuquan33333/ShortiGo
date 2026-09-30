// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Episode {
  String get id;
  String get seriesId;
  int get order;
  String get videoUrl;
  String get thumbnailUrl;
  int get durationSec;
  bool get isVipLocked;
  bool get sourceAvailable;
  bool get sourceLocked;
  String? get chapterName;
  int? get bonusUnlockCost;
  int get watchCount;
  int get likeCount;
  int get shareCount;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EpisodeCopyWith<Episode> get copyWith =>
      _$EpisodeCopyWithImpl<Episode>(this as Episode, _$identity);

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Episode &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.durationSec, durationSec) ||
                other.durationSec == durationSec) &&
            (identical(other.isVipLocked, isVipLocked) ||
                other.isVipLocked == isVipLocked) &&
            (identical(other.sourceAvailable, sourceAvailable) ||
                other.sourceAvailable == sourceAvailable) &&
            (identical(other.sourceLocked, sourceLocked) ||
                other.sourceLocked == sourceLocked) &&
            (identical(other.chapterName, chapterName) ||
                other.chapterName == chapterName) &&
            (identical(other.bonusUnlockCost, bonusUnlockCost) ||
                other.bonusUnlockCost == bonusUnlockCost) &&
            (identical(other.watchCount, watchCount) ||
                other.watchCount == watchCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      seriesId,
      order,
      videoUrl,
      thumbnailUrl,
      durationSec,
      isVipLocked,
      sourceAvailable,
      sourceLocked,
      chapterName,
      bonusUnlockCost,
      watchCount,
      likeCount,
      shareCount);

  @override
  String toString() {
    return 'Episode(id: $id, seriesId: $seriesId, order: $order, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, durationSec: $durationSec, isVipLocked: $isVipLocked, sourceAvailable: $sourceAvailable, sourceLocked: $sourceLocked, chapterName: $chapterName, bonusUnlockCost: $bonusUnlockCost, watchCount: $watchCount, likeCount: $likeCount, shareCount: $shareCount)';
  }
}

/// @nodoc
abstract mixin class $EpisodeCopyWith<$Res> {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) _then) =
      _$EpisodeCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String seriesId,
      int order,
      String videoUrl,
      String thumbnailUrl,
      int durationSec,
      bool isVipLocked,
      bool sourceAvailable,
      bool sourceLocked,
      String? chapterName,
      int? bonusUnlockCost,
      int watchCount,
      int likeCount,
      int shareCount});
}

/// @nodoc
class _$EpisodeCopyWithImpl<$Res> implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._self, this._then);

  final Episode _self;
  final $Res Function(Episode) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? order = null,
    Object? videoUrl = null,
    Object? thumbnailUrl = null,
    Object? durationSec = null,
    Object? isVipLocked = null,
    Object? sourceAvailable = null,
    Object? sourceLocked = null,
    Object? chapterName = freezed,
    Object? bonusUnlockCost = freezed,
    Object? watchCount = null,
    Object? likeCount = null,
    Object? shareCount = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      videoUrl: null == videoUrl
          ? _self.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      durationSec: null == durationSec
          ? _self.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int,
      isVipLocked: null == isVipLocked
          ? _self.isVipLocked
          : isVipLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceAvailable: null == sourceAvailable
          ? _self.sourceAvailable
          : sourceAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceLocked: null == sourceLocked
          ? _self.sourceLocked
          : sourceLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      chapterName: freezed == chapterName
          ? _self.chapterName
          : chapterName // ignore: cast_nullable_to_non_nullable
              as String?,
      bonusUnlockCost: freezed == bonusUnlockCost
          ? _self.bonusUnlockCost
          : bonusUnlockCost // ignore: cast_nullable_to_non_nullable
              as int?,
      watchCount: null == watchCount
          ? _self.watchCount
          : watchCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _self.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      shareCount: null == shareCount
          ? _self.shareCount
          : shareCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [Episode].
extension EpisodePatterns on Episode {
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
    TResult Function(_Episode value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
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
    TResult Function(_Episode value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode():
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
    TResult? Function(_Episode value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
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
            String seriesId,
            int order,
            String videoUrl,
            String thumbnailUrl,
            int durationSec,
            bool isVipLocked,
            bool sourceAvailable,
            bool sourceLocked,
            String? chapterName,
            int? bonusUnlockCost,
            int watchCount,
            int likeCount,
            int shareCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.order,
            _that.videoUrl,
            _that.thumbnailUrl,
            _that.durationSec,
            _that.isVipLocked,
            _that.sourceAvailable,
            _that.sourceLocked,
            _that.chapterName,
            _that.bonusUnlockCost,
            _that.watchCount,
            _that.likeCount,
            _that.shareCount);
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
            String seriesId,
            int order,
            String videoUrl,
            String thumbnailUrl,
            int durationSec,
            bool isVipLocked,
            bool sourceAvailable,
            bool sourceLocked,
            String? chapterName,
            int? bonusUnlockCost,
            int watchCount,
            int likeCount,
            int shareCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode():
        return $default(
            _that.id,
            _that.seriesId,
            _that.order,
            _that.videoUrl,
            _that.thumbnailUrl,
            _that.durationSec,
            _that.isVipLocked,
            _that.sourceAvailable,
            _that.sourceLocked,
            _that.chapterName,
            _that.bonusUnlockCost,
            _that.watchCount,
            _that.likeCount,
            _that.shareCount);
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
            String seriesId,
            int order,
            String videoUrl,
            String thumbnailUrl,
            int durationSec,
            bool isVipLocked,
            bool sourceAvailable,
            bool sourceLocked,
            String? chapterName,
            int? bonusUnlockCost,
            int watchCount,
            int likeCount,
            int shareCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.order,
            _that.videoUrl,
            _that.thumbnailUrl,
            _that.durationSec,
            _that.isVipLocked,
            _that.sourceAvailable,
            _that.sourceLocked,
            _that.chapterName,
            _that.bonusUnlockCost,
            _that.watchCount,
            _that.likeCount,
            _that.shareCount);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Episode implements Episode {
  const _Episode(
      {required this.id,
      required this.seriesId,
      required this.order,
      required this.videoUrl,
      required this.thumbnailUrl,
      required this.durationSec,
      this.isVipLocked = false,
      this.sourceAvailable = true,
      this.sourceLocked = false,
      this.chapterName,
      this.bonusUnlockCost,
      this.watchCount = 0,
      this.likeCount = 0,
      this.shareCount = 0});
  factory _Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);

  @override
  final String id;
  @override
  final String seriesId;
  @override
  final int order;
  @override
  final String videoUrl;
  @override
  final String thumbnailUrl;
  @override
  final int durationSec;
  @override
  @JsonKey()
  final bool isVipLocked;
  @override
  @JsonKey()
  final bool sourceAvailable;
  @override
  @JsonKey()
  final bool sourceLocked;
  @override
  final String? chapterName;
  @override
  final int? bonusUnlockCost;
  @override
  @JsonKey()
  final int watchCount;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final int shareCount;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EpisodeCopyWith<_Episode> get copyWith =>
      __$EpisodeCopyWithImpl<_Episode>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EpisodeToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Episode &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.durationSec, durationSec) ||
                other.durationSec == durationSec) &&
            (identical(other.isVipLocked, isVipLocked) ||
                other.isVipLocked == isVipLocked) &&
            (identical(other.sourceAvailable, sourceAvailable) ||
                other.sourceAvailable == sourceAvailable) &&
            (identical(other.sourceLocked, sourceLocked) ||
                other.sourceLocked == sourceLocked) &&
            (identical(other.chapterName, chapterName) ||
                other.chapterName == chapterName) &&
            (identical(other.bonusUnlockCost, bonusUnlockCost) ||
                other.bonusUnlockCost == bonusUnlockCost) &&
            (identical(other.watchCount, watchCount) ||
                other.watchCount == watchCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      seriesId,
      order,
      videoUrl,
      thumbnailUrl,
      durationSec,
      isVipLocked,
      sourceAvailable,
      sourceLocked,
      chapterName,
      bonusUnlockCost,
      watchCount,
      likeCount,
      shareCount);

  @override
  String toString() {
    return 'Episode(id: $id, seriesId: $seriesId, order: $order, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, durationSec: $durationSec, isVipLocked: $isVipLocked, sourceAvailable: $sourceAvailable, sourceLocked: $sourceLocked, chapterName: $chapterName, bonusUnlockCost: $bonusUnlockCost, watchCount: $watchCount, likeCount: $likeCount, shareCount: $shareCount)';
  }
}

/// @nodoc
abstract mixin class _$EpisodeCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$EpisodeCopyWith(_Episode value, $Res Function(_Episode) _then) =
      __$EpisodeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String seriesId,
      int order,
      String videoUrl,
      String thumbnailUrl,
      int durationSec,
      bool isVipLocked,
      bool sourceAvailable,
      bool sourceLocked,
      String? chapterName,
      int? bonusUnlockCost,
      int watchCount,
      int likeCount,
      int shareCount});
}

/// @nodoc
class __$EpisodeCopyWithImpl<$Res> implements _$EpisodeCopyWith<$Res> {
  __$EpisodeCopyWithImpl(this._self, this._then);

  final _Episode _self;
  final $Res Function(_Episode) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? order = null,
    Object? videoUrl = null,
    Object? thumbnailUrl = null,
    Object? durationSec = null,
    Object? isVipLocked = null,
    Object? sourceAvailable = null,
    Object? sourceLocked = null,
    Object? chapterName = freezed,
    Object? bonusUnlockCost = freezed,
    Object? watchCount = null,
    Object? likeCount = null,
    Object? shareCount = null,
  }) {
    return _then(_Episode(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      videoUrl: null == videoUrl
          ? _self.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      durationSec: null == durationSec
          ? _self.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int,
      isVipLocked: null == isVipLocked
          ? _self.isVipLocked
          : isVipLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceAvailable: null == sourceAvailable
          ? _self.sourceAvailable
          : sourceAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceLocked: null == sourceLocked
          ? _self.sourceLocked
          : sourceLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      chapterName: freezed == chapterName
          ? _self.chapterName
          : chapterName // ignore: cast_nullable_to_non_nullable
              as String?,
      bonusUnlockCost: freezed == bonusUnlockCost
          ? _self.bonusUnlockCost
          : bonusUnlockCost // ignore: cast_nullable_to_non_nullable
              as int?,
      watchCount: null == watchCount
          ? _self.watchCount
          : watchCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _self.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      shareCount: null == shareCount
          ? _self.shareCount
          : shareCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
