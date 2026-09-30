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

FriendlyError localizedFriendlyErrorFor(
  BuildContext context,
  Object error,
) {
  final l10n = AppLocalizations.of(context)!;
  if (error is ContentApiException) {
    final message = switch (error.code) {
      'invalid-url' => l10n.invalidUrlError,
      'not-configured' => l10n.notConfiguredError,
      'timeout' => l10n.timeoutError,
      'network' => l10n.networkError,
      'malformed-json' => l10n.malformedJsonError,
      'invalid-schema' => l10n.invalidSchemaError,
      'invalid-source-status' => l10n.invalidSchemaError,
      'not-found' => l10n.notFoundError,
      'http-404' => l10n.notFoundError,
      'source-locked' => l10n.sourceLockedError,
      'http-403' => l10n.sourceLockedError,
      _ => l10n.genericContentApiError,
    };
    return FriendlyError(
      title: l10n.contentSource,
      message: message,
      cause: error,
    );
  }
  return FriendlyError(
    title: l10n.contentSource,
    message: l10n.genericContentApiError,
    cause: error,
  );
}
