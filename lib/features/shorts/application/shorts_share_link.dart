import '../../../l10n/app_localizations.dart';

Uri shortShareUrl({
  required String seriesId,
  required String episodeId,
}) {
  return Uri.https('shortigo.app', '/series/$seriesId/episodes/$episodeId');
}

String shortShareText({
  required AppLocalizations l10n,
  required String seriesTitle,
  required int episodeOrder,
  required String seriesId,
  required String episodeId,
}) {
  final url = shortShareUrl(seriesId: seriesId, episodeId: episodeId);
  return '${l10n.watchOnShortiGo(episodeOrder, seriesTitle)}\n$url';
}
