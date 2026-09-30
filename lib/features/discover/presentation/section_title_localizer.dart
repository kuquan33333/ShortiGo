import '../../../l10n/app_localizations.dart';

String localizedSectionTitle(
  AppLocalizations l10n,
  String slug,
  String fallback,
) {
  return switch (slug.trim().toLowerCase()) {
    'trending' => l10n.trending,
    'dubbed' => l10n.dubbed,
    'vietsub' => l10n.vietsub,
    'new' => l10n.newUpdates,
    'romance' => l10n.romance,
    'ceo' => l10n.ceo,
    'revenge' => l10n.revenge,
    'rebirth' => l10n.rebirth,
    'family' => l10n.family,
    'action' => l10n.action,
    'fantasy' => l10n.fantasy,
    'recommended' => l10n.recommended,
    _ => fallback,
  };
}
