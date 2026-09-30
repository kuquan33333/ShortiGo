import 'package:flutter/material.dart';

import '../../data/remote/content_api_models.dart';
import '../../l10n/app_localizations.dart';

@immutable
class FriendlyError {
  const FriendlyError({required this.title, required this.message, this.cause});
  final String title;
  final String message;
  final Object? cause;

  @override
  String toString() => '$title: $message';
}

FriendlyError friendlyErrorFor(Object e) {
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return FriendlyError(
      title: 'No connection',
      message: 'Check your internet and try again.',
      cause: e,
    );
  }
  if (s.contains('TimeoutException')) {
    return FriendlyError(
      title: 'That took too long',
      message: 'Try again in a moment.',
      cause: e,
    );
  }
  return FriendlyError(
    title: 'Something went wrong',
    message: 'We hit an unexpected error. Pull to refresh or try again.',
    cause: e,
  );
}

FriendlyError localizedFriendlyErrorFor(
  BuildContext context,
  Object error,
) {
  final l10n = AppLocalizations.of(context)!;
  if (error is ContentApiException) {
    final message = switch (error.code) {
      'not-configured' => l10n.notConfigured,
      'source-locked' => l10n.sourceLocked,
      'timeout' => l10n.contentServerSlow,
      'network' => l10n.contentServerUnavailable,
      _ => error.message,
    };
    return FriendlyError(
      title: l10n.contentSource,
      message: message,
      cause: error,
    );
  }
  return friendlyErrorFor(error);
}
