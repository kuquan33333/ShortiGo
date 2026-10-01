// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShortiGo';

  @override
  String get discover => 'Discover';

  @override
  String get shorts => 'Shorts';

  @override
  String get rewards => 'Rewards';

  @override
  String get myList => 'My List';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get contentSource => 'Content source';

  @override
  String get contentApiServer => 'Movie API server';

  @override
  String get testConnection => 'Test connection';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get restoreDefault => 'Restore default';

  @override
  String get serverStatus => 'Server status';

  @override
  String get active => 'Active';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get language => 'Language';

  @override
  String get providers => 'Providers';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search short dramas';

  @override
  String get noResults => 'No results found.';

  @override
  String get noShorts => 'No shorts yet.';

  @override
  String get seriesNotFound => 'Series not found.';

  @override
  String get noSavedSeries => 'You haven\'t saved any series yet.';

  @override
  String get saveSeriesHint => 'Save a series and it will appear here.';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get createAccountOrSignIn => 'Create account or sign in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get guestMessage => 'You are browsing ShortiGo as a guest.';

  @override
  String get signInToUse => 'Sign in to use this feature.';

  @override
  String get accountServiceUnavailable =>
      'Account services are not configured yet.';

  @override
  String get signOut => 'Sign out';

  @override
  String get tryAgain => 'Try again';

  @override
  String get sourceLocked =>
      'This episode does not have a public playback source yet.';

  @override
  String get sourceLockedShort => 'Locked';

  @override
  String get sourceLockedDescription =>
      'A public playback source is not available for this episode yet.';

  @override
  String get sourceUnavailable => 'Source unavailable';

  @override
  String get sourceUnavailableDescription =>
      'This episode cannot be played from a public source right now.';

  @override
  String episodeCount(Object count) {
    return '$count episodes';
  }

  @override
  String get forYou => 'For You';

  @override
  String get newUpdates => 'New';

  @override
  String get hot => 'Hot';

  @override
  String get trending => 'Trending';

  @override
  String get dubbed => 'Vietnamese Dubbed';

  @override
  String get vietsub => 'Vietnamese Subtitles';

  @override
  String get romance => 'Romance';

  @override
  String get ceo => 'CEO';

  @override
  String get revenge => 'Revenge';

  @override
  String get family => 'Family';

  @override
  String get action => 'Action';

  @override
  String get fantasy => 'Fantasy';

  @override
  String get recommended => 'Recommended';

  @override
  String get rebirth => 'Rebirth / Time Travel';

  @override
  String get adventure => 'Adventure';

  @override
  String get scary => 'Scary';

  @override
  String get anime => 'Anime';

  @override
  String get vip => 'VIP';

  @override
  String durationSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get unknownDuration => '';

  @override
  String get accountAndSubscription => 'Account & Subscription';

  @override
  String get subscribeToVip => 'Subscribe to VIP';

  @override
  String get vipMembership => 'VIP Membership';

  @override
  String get vipBenefits => 'Ad-free, 1080p, and exclusive VIP content.';

  @override
  String get noOfferingsAvailable =>
      'No VIP offerings are available right now.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get subscriptionRestored => 'VIP purchases restored.';

  @override
  String get noActiveVipPurchase => 'No active VIP purchase was found.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get bonus => 'Bonus';

  @override
  String get coins => 'Coins';

  @override
  String get vipViewer => 'VIP viewer';

  @override
  String get freeViewer => 'Free viewer';

  @override
  String get dailyCheckIn => 'Daily check-in';

  @override
  String get watchAnAd => 'Watch an ad';

  @override
  String get achievements => 'Achievements';

  @override
  String get done => 'Done';

  @override
  String get claim => 'Claim';

  @override
  String get retry => 'Retry';

  @override
  String get info => 'Info';

  @override
  String get readMore => 'Read more';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get browseAsGuest => 'Continue as guest';

  @override
  String get cancel => 'Cancel';

  @override
  String get earned => 'Earned';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get getVip => 'Get VIP';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get deleteAccountPrompt => 'Delete your ShortiGo account?';

  @override
  String get deleteAccountDescription =>
      'Your profile, My List, and viewing activity will be permanently deleted.';

  @override
  String get contentServerSlow =>
      'The content server took too long to respond.';

  @override
  String get contentServerUnavailable =>
      'Unable to connect to the content server.';

  @override
  String get keepStreakAlive => 'Keep your streak alive';

  @override
  String get enoughToUnlock => 'You have enough to unlock an episode';

  @override
  String bonusUntilNext(Object count) {
    return '$count bonus until your next episode unlock';
  }

  @override
  String get claimedToday => 'Claimed today';

  @override
  String get bonusFive => '+5 bonus';

  @override
  String get watch => 'Watch';

  @override
  String get testAdReady => 'Test ad ready · +12 bonus';

  @override
  String get bonusTwelve => '+12 bonus';

  @override
  String get preparingAd => 'Preparing an ad...';

  @override
  String get adPlaying => 'Ad is playing';

  @override
  String get confirmingReward => 'Confirming your reward...';

  @override
  String get noAdAvailable => 'No ad available yet';

  @override
  String get checkConnection => 'Check your connection';

  @override
  String get adSetupNeedsAttention => 'Ad setup needs attention';

  @override
  String get adUnavailable => 'Ad unavailable right now';

  @override
  String get activeToday => 'Active today';

  @override
  String get startToday => 'Start today';

  @override
  String get firstSpark => 'First Spark';

  @override
  String get unlockReady => 'Unlock ready';

  @override
  String get vipEpisode => 'VIP episode';

  @override
  String get upgradeToWatch => 'Upgrade to watch this short.';

  @override
  String get goToRewards => 'Go to rewards';

  @override
  String get unlockThisEpisode => 'Unlock this episode';

  @override
  String bonusBalance(Object balance, Object cost) {
    return '$cost bonus · Your balance: $balance';
  }

  @override
  String get earnBonus => 'Earn bonus';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get previewShortiGo => 'Preview ShortiGo';

  @override
  String get shortDramasBeforeSignup => 'Short dramas before you sign up';

  @override
  String get browseCategoriesReady =>
      'Explore short dramas even before you sign in.';

  @override
  String get noPreviewsYet => 'No previews yet';

  @override
  String get checkBackFreshDramas => 'Check back soon for fresh short dramas.';

  @override
  String get vipEpisodeOpen => 'Every VIP episode is open';

  @override
  String get bonusSelectedEpisodes => 'Earn bonus to unlock selected episodes';

  @override
  String get adDiagnostics => 'Ad diagnostics';

  @override
  String get testMode => 'test mode';

  @override
  String get inspector => 'Inspector';

  @override
  String get signInToSyncAccount =>
      'Sign in when you want to sync your list, rewards, and account.';

  @override
  String watchOnShortiGo(Object episode, Object title) {
    return 'Watch $title on ShortiGo · Episode $episode';
  }

  @override
  String get rewardedAdTransaction => 'Rewarded ad';

  @override
  String get purchaseTransaction => 'Purchase';

  @override
  String get episodeUnlockedTransaction => 'Episode unlocked';

  @override
  String get refundTransaction => 'Refund';

  @override
  String get invalidUrlError => 'The server URL is invalid.';

  @override
  String get notConfiguredError => 'The content API server is not configured.';

  @override
  String get timeoutError =>
      'The server took too long to respond. Please try again.';

  @override
  String get networkError => 'Unable to connect to the content server.';

  @override
  String get malformedJsonError => 'The server returned invalid data.';

  @override
  String get invalidSchemaError =>
      'The server returned an invalid data structure.';

  @override
  String get notFoundError => 'The content was not found on the server.';

  @override
  String get sourceLockedError =>
      'This episode does not have a public playback source yet.';

  @override
  String get genericContentApiError =>
      'Unable to load content right now. Please try again.';

  @override
  String get authInvalidEmail => 'Invalid email address.';

  @override
  String get authInvalidCredential => 'Email or password is incorrect.';

  @override
  String get authEmailInUse => 'This email is already registered.';

  @override
  String get authWeakPassword => 'Password is too weak.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authNetwork => 'Unable to connect to the account service.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authUnavailable => 'Account sign-in is not available right now.';

  @override
  String get authUnknown => 'Unable to sign in right now. Please try again.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get unexpectedError =>
      'The app encountered an unexpected problem. Please try again.';

  @override
  String get accountError => 'Account error';

  @override
  String get subscriptionError => 'Subscription error';

  @override
  String get subscriptionPurchaseFailed =>
      'The purchase could not be completed. Please try again.';

  @override
  String get subscriptionRestoreFailed =>
      'Purchases could not be restored. Please try again.';

  @override
  String get subscriptionNotConfigured =>
      'Subscriptions are not configured right now.';

  @override
  String get accountSignInRequired => 'Sign in again to continue.';

  @override
  String get accountRecentLoginRequired =>
      'For your security, sign in again before deleting your account.';

  @override
  String get accountDeletionFailed =>
      'Account deletion failed. Please try again.';

  @override
  String get viewAll => 'View all';

  @override
  String get loadMore => 'Load more';

  @override
  String get sortHot => 'Hot';

  @override
  String get sortNew => 'Newest';

  @override
  String get apiIncompatibleError =>
      'This content API is incompatible. Please update the server.';
}
