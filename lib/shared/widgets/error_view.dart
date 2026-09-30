import 'package:flutter/material.dart';
import '../../core/error/friendly_error.dart';
import '../../l10n/app_localizations.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final FriendlyError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(error.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n?.tryAgain ?? 'Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
