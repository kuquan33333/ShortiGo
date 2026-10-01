import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

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
      'api-incompatible' => l10n.apiIncompatibleError,
      'not-found' => l10n.notFoundError,
      'http-404' => l10n.notFoundError,
      'source-locked' => l10n.sourceLockedError,
      'http-403' => l10n.sourceLockedError,
      'http-502' || 'http-504' => l10n.contentServerUnavailable,
      _ => l10n.genericContentApiError,
    };
    return FriendlyError(
      title: l10n.contentSource,
      message: message,
      cause: error,
    );
  }
  if (error is fb.FirebaseAuthException ||
      error is String &&
          (error.startsWith('auth-') ||
              error == 'account-service-unavailable')) {
    final code =
        error is fb.FirebaseAuthException ? error.code : error.toString();
    final message = switch (code) {
      'invalid-email' || 'auth-invalid-email' => l10n.authInvalidEmail,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'auth-invalid-credential' =>
        l10n.authInvalidCredential,
      'email-already-in-use' || 'auth-email-in-use' => l10n.authEmailInUse,
      'weak-password' || 'auth-weak-password' => l10n.authWeakPassword,
      'too-many-requests' ||
      'auth-too-many-requests' =>
        l10n.authTooManyRequests,
      'network-request-failed' || 'auth-network' => l10n.authNetwork,
      'user-disabled' || 'auth-user-disabled' => l10n.authUserDisabled,
      'operation-not-allowed' || 'auth-unavailable' => l10n.authUnavailable,
      'account-service-unavailable' => l10n.accountServiceUnavailable,
      _ => l10n.authUnknown,
    };
    return FriendlyError(
        title: l10n.accountError, message: message, cause: error);
  }
  if (error is String && error.startsWith('subscription-')) {
    final message = switch (error) {
      'subscription-purchase-failed' => l10n.subscriptionPurchaseFailed,
      'subscription-restore-failed' => l10n.subscriptionRestoreFailed,
      'subscription-not-configured' => l10n.subscriptionNotConfigured,
      _ => l10n.subscriptionError,
    };
    return FriendlyError(
      title: l10n.subscriptionError,
      message: message,
      cause: error,
    );
  }
  if (error is String && error.startsWith('account-')) {
    final message = switch (error) {
      'account-sign-in-required' => l10n.accountSignInRequired,
      'account-recent-login-required' => l10n.accountRecentLoginRequired,
      'account-deletion-failed' => l10n.accountDeletionFailed,
      _ => l10n.accountError,
    };
    return FriendlyError(
        title: l10n.accountError, message: message, cause: error);
  }
  return FriendlyError(
    title: l10n.somethingWentWrong,
    message: l10n.unexpectedError,
    cause: error,
  );
}
