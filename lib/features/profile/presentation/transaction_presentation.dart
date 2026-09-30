import '../../../domain/entities/transaction.dart';
import '../../../l10n/app_localizations.dart';

extension TransactionPresentation on Transaction {
  String friendlyTitle(AppLocalizations l10n) {
    return switch (type) {
      TxType.adReward => l10n.rewardedAdTransaction,
      TxType.dailyCheckIn => l10n.dailyCheckIn,
      TxType.purchase => l10n.purchaseTransaction,
      TxType.spend => l10n.episodeUnlockedTransaction,
      TxType.refund => l10n.refundTransaction,
    };
  }

  String walletDeltaLabel(AppLocalizations l10n) {
    final value = bonusDelta != 0 ? bonusDelta : coinsDelta;
    final unit = bonusDelta != 0 ? l10n.bonus : l10n.coins;
    return '${value > 0 ? '+' : ''}$value $unit';
  }
}
