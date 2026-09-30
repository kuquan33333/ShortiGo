import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/error/friendly_error.dart';
import '../../../l10n/app_localizations.dart';

class AccountActionsSection extends StatelessWidget {
  const AccountActionsSection({
    required this.isDeleting,
    required this.onRestorePurchases,
    required this.onDeleteAccount,
    this.error,
    super.key,
  });

  final bool isDeleting;
  final VoidCallback onRestorePurchases;
  final Future<void> Function() onDeleteAccount;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountAndSubscription,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: Text(l10n.restorePurchases),
          onTap: onRestorePurchases,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: Text(
            l10n.deleteAccount,
            style: TextStyle(color: AppColors.error),
          ),
          trailing: isDeleting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isDeleting ? null : () => _confirmDelete(context),
        ),
        if (error != null)
          Text(
            localizedFriendlyErrorFor(context, error!).message,
            style: const TextStyle(color: AppColors.error),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountPrompt),
        content: Text(l10n.deleteAccountDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDeleteAccount();
    }
  }
}
