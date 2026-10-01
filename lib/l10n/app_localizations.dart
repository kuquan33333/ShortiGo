import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShortiGo'**
  String get appTitle;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @shorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get shorts;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @myList.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get myList;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @contentSource.
  ///
  /// In en, this message translates to:
  /// **'Content source'**
  String get contentSource;

  /// No description provided for @contentSourceSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'No content source configured'**
  String get contentSourceSetupTitle;

  /// No description provided for @contentSourceSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'ShortiGo does not ship with a built-in content source. Add your Content API URL to start watching.'**
  String get contentSourceSetupDescription;

  /// No description provided for @configureContentSource.
  ///
  /// In en, this message translates to:
  /// **'Configure content source'**
  String get configureContentSource;

  /// No description provided for @contentSourceSetupHint.
  ///
  /// In en, this message translates to:
  /// **'You can change the source anytime in Settings.'**
  String get contentSourceSetupHint;

  /// No description provided for @popularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular categories'**
  String get popularCategories;

  /// No description provided for @maybeYouLike.
  ///
  /// In en, this message translates to:
  /// **'You may like'**
  String get maybeYouLike;

  /// No description provided for @contentApiServer.
  ///
  /// In en, this message translates to:
  /// **'Movie API server'**
  String get contentApiServer;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore default'**
  String get restoreDefault;

  /// No description provided for @serverStatus.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get serverStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search short dramas'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @noShorts.
  ///
  /// In en, this message translates to:
  /// **'No shorts yet.'**
  String get noShorts;

  /// No description provided for @seriesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Series not found.'**
  String get seriesNotFound;

  /// No description provided for @noSavedSeries.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any series yet.'**
  String get noSavedSeries;

  /// No description provided for @saveSeriesHint.
  ///
  /// In en, this message translates to:
  /// **'Save a series and it will appear here.'**
  String get saveSeriesHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountOrSignIn.
  ///
  /// In en, this message translates to:
  /// **'Create account or sign in'**
  String get createAccountOrSignIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @guestMessage.
  ///
  /// In en, this message translates to:
  /// **'You are browsing ShortiGo as a guest.'**
  String get guestMessage;

  /// No description provided for @signInToUse.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this feature.'**
  String get signInToUse;

  /// No description provided for @accountServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account services are not configured yet.'**
  String get accountServiceUnavailable;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @sourceLocked.
  ///
  /// In en, this message translates to:
  /// **'This episode does not have a public playback source yet.'**
  String get sourceLocked;

  /// No description provided for @sourceLockedShort.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get sourceLockedShort;

  /// No description provided for @sourceLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'A public playback source is not available for this episode yet.'**
  String get sourceLockedDescription;

  /// No description provided for @sourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get sourceUnavailable;

  /// No description provided for @sourceUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'This episode cannot be played from a public source right now.'**
  String get sourceUnavailableDescription;

  /// No description provided for @episodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String episodeCount(Object count);

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @newUpdates.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newUpdates;

  /// No description provided for @hot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get hot;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @dubbed.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Dubbed'**
  String get dubbed;

  /// No description provided for @vietsub.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Subtitles'**
  String get vietsub;

  /// No description provided for @romance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get romance;

  /// No description provided for @ceo.
  ///
  /// In en, this message translates to:
  /// **'CEO'**
  String get ceo;

  /// No description provided for @revenge.
  ///
  /// In en, this message translates to:
  /// **'Revenge'**
  String get revenge;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @fantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get fantasy;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @rebirth.
  ///
  /// In en, this message translates to:
  /// **'Rebirth / Time Travel'**
  String get rebirth;

  /// No description provided for @adventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get adventure;

  /// No description provided for @scary.
  ///
  /// In en, this message translates to:
  /// **'Scary'**
  String get scary;

  /// No description provided for @anime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get anime;

  /// No description provided for @vip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get vip;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String durationSeconds(Object seconds);

  /// No description provided for @unknownDuration.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unknownDuration;

  /// No description provided for @accountAndSubscription.
  ///
  /// In en, this message translates to:
  /// **'Account & Subscription'**
  String get accountAndSubscription;

  /// No description provided for @subscribeToVip.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to VIP'**
  String get subscribeToVip;

  /// No description provided for @vipMembership.
  ///
  /// In en, this message translates to:
  /// **'VIP Membership'**
  String get vipMembership;

  /// No description provided for @vipBenefits.
  ///
  /// In en, this message translates to:
  /// **'Ad-free, 1080p, and exclusive VIP content.'**
  String get vipBenefits;

  /// No description provided for @noOfferingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No VIP offerings are available right now.'**
  String get noOfferingsAvailable;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @subscriptionRestored.
  ///
  /// In en, this message translates to:
  /// **'VIP purchases restored.'**
  String get subscriptionRestored;

  /// No description provided for @subscriptionPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'VIP is now active.'**
  String get subscriptionPurchaseSuccess;

  /// No description provided for @vipTestModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Test mode — no real payment will be made.'**
  String get vipTestModeNotice;

  /// No description provided for @resetVipTest.
  ///
  /// In en, this message translates to:
  /// **'Reset VIP test'**
  String get resetVipTest;

  /// No description provided for @testVipReset.
  ///
  /// In en, this message translates to:
  /// **'VIP test entitlement was reset.'**
  String get testVipReset;

  /// No description provided for @noActiveVipPurchase.
  ///
  /// In en, this message translates to:
  /// **'No active VIP purchase was found.'**
  String get noActiveVipPurchase;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @vipViewer.
  ///
  /// In en, this message translates to:
  /// **'VIP viewer'**
  String get vipViewer;

  /// No description provided for @freeViewer.
  ///
  /// In en, this message translates to:
  /// **'Free viewer'**
  String get freeViewer;

  /// No description provided for @dailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get dailyCheckIn;

  /// No description provided for @watchAnAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad'**
  String get watchAnAd;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @browseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get browseAsGuest;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @getVip.
  ///
  /// In en, this message translates to:
  /// **'Get VIP'**
  String get getVip;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @deleteAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete your ShortiGo account?'**
  String get deleteAccountPrompt;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile, My List, and viewing activity will be permanently deleted.'**
  String get deleteAccountDescription;

  /// No description provided for @contentServerSlow.
  ///
  /// In en, this message translates to:
  /// **'The content server took too long to respond.'**
  String get contentServerSlow;

  /// No description provided for @contentServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the content server.'**
  String get contentServerUnavailable;

  /// No description provided for @keepStreakAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak alive'**
  String get keepStreakAlive;

  /// No description provided for @enoughToUnlock.
  ///
  /// In en, this message translates to:
  /// **'You have enough to unlock an episode'**
  String get enoughToUnlock;

  /// No description provided for @bonusUntilNext.
  ///
  /// In en, this message translates to:
  /// **'{count} bonus until your next episode unlock'**
  String bonusUntilNext(Object count);

  /// No description provided for @claimedToday.
  ///
  /// In en, this message translates to:
  /// **'Claimed today'**
  String get claimedToday;

  /// No description provided for @bonusFive.
  ///
  /// In en, this message translates to:
  /// **'+5 bonus'**
  String get bonusFive;

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// No description provided for @testAdReady.
  ///
  /// In en, this message translates to:
  /// **'Test ad ready · +12 bonus'**
  String get testAdReady;

  /// No description provided for @bonusTwelve.
  ///
  /// In en, this message translates to:
  /// **'+12 bonus'**
  String get bonusTwelve;

  /// No description provided for @preparingAd.
  ///
  /// In en, this message translates to:
  /// **'Preparing an ad...'**
  String get preparingAd;

  /// No description provided for @adPlaying.
  ///
  /// In en, this message translates to:
  /// **'Ad is playing'**
  String get adPlaying;

  /// No description provided for @confirmingReward.
  ///
  /// In en, this message translates to:
  /// **'Confirming your reward...'**
  String get confirmingReward;

  /// No description provided for @noAdAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ad available yet'**
  String get noAdAvailable;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection'**
  String get checkConnection;

  /// No description provided for @adSetupNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Ad setup needs attention'**
  String get adSetupNeedsAttention;

  /// No description provided for @adUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ad unavailable right now'**
  String get adUnavailable;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get activeToday;

  /// No description provided for @startToday.
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get startToday;

  /// No description provided for @firstSpark.
  ///
  /// In en, this message translates to:
  /// **'First Spark'**
  String get firstSpark;

  /// No description provided for @unlockReady.
  ///
  /// In en, this message translates to:
  /// **'Unlock ready'**
  String get unlockReady;

  /// No description provided for @vipEpisode.
  ///
  /// In en, this message translates to:
  /// **'VIP episode'**
  String get vipEpisode;

  /// No description provided for @upgradeToWatch.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to watch this short.'**
  String get upgradeToWatch;

  /// No description provided for @goToRewards.
  ///
  /// In en, this message translates to:
  /// **'Go to rewards'**
  String get goToRewards;

  /// No description provided for @unlockThisEpisode.
  ///
  /// In en, this message translates to:
  /// **'Unlock this episode'**
  String get unlockThisEpisode;

  /// No description provided for @bonusBalance.
  ///
  /// In en, this message translates to:
  /// **'{cost} bonus · Your balance: {balance}'**
  String bonusBalance(Object balance, Object cost);

  /// No description provided for @earnBonus.
  ///
  /// In en, this message translates to:
  /// **'Earn bonus'**
  String get earnBonus;

  /// No description provided for @tapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// No description provided for @previewShortiGo.
  ///
  /// In en, this message translates to:
  /// **'Preview ShortiGo'**
  String get previewShortiGo;

  /// No description provided for @shortDramasBeforeSignup.
  ///
  /// In en, this message translates to:
  /// **'Short dramas before you sign up'**
  String get shortDramasBeforeSignup;

  /// No description provided for @browseCategoriesReady.
  ///
  /// In en, this message translates to:
  /// **'Explore short dramas even before you sign in.'**
  String get browseCategoriesReady;

  /// No description provided for @noPreviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No previews yet'**
  String get noPreviewsYet;

  /// No description provided for @checkBackFreshDramas.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for fresh short dramas.'**
  String get checkBackFreshDramas;

  /// No description provided for @vipEpisodeOpen.
  ///
  /// In en, this message translates to:
  /// **'Every VIP episode is open'**
  String get vipEpisodeOpen;

  /// No description provided for @bonusSelectedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Earn bonus to unlock selected episodes'**
  String get bonusSelectedEpisodes;

  /// No description provided for @adDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Ad diagnostics'**
  String get adDiagnostics;

  /// No description provided for @testMode.
  ///
  /// In en, this message translates to:
  /// **'test mode'**
  String get testMode;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @signInToSyncAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in when you want to sync your list, rewards, and account.'**
  String get signInToSyncAccount;

  /// No description provided for @watchOnShortiGo.
  ///
  /// In en, this message translates to:
  /// **'Watch {title} on ShortiGo · Episode {episode}'**
  String watchOnShortiGo(Object episode, Object title);

  /// No description provided for @rewardedAdTransaction.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad'**
  String get rewardedAdTransaction;

  /// No description provided for @purchaseTransaction.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchaseTransaction;

  /// No description provided for @episodeUnlockedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Episode unlocked'**
  String get episodeUnlockedTransaction;

  /// No description provided for @refundTransaction.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundTransaction;

  /// No description provided for @invalidUrlError.
  ///
  /// In en, this message translates to:
  /// **'The server URL is invalid.'**
  String get invalidUrlError;

  /// No description provided for @notConfiguredError.
  ///
  /// In en, this message translates to:
  /// **'The content API server is not configured.'**
  String get notConfiguredError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Please try again.'**
  String get timeoutError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the content server.'**
  String get networkError;

  /// No description provided for @malformedJsonError.
  ///
  /// In en, this message translates to:
  /// **'The server returned invalid data.'**
  String get malformedJsonError;

  /// No description provided for @invalidSchemaError.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid data structure.'**
  String get invalidSchemaError;

  /// No description provided for @notFoundError.
  ///
  /// In en, this message translates to:
  /// **'The content was not found on the server.'**
  String get notFoundError;

  /// No description provided for @sourceLockedError.
  ///
  /// In en, this message translates to:
  /// **'This episode does not have a public playback source yet.'**
  String get sourceLockedError;

  /// No description provided for @genericContentApiError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load content right now. Please try again.'**
  String get genericContentApiError;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredential;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authWeakPassword;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authTooManyRequests;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the account service.'**
  String get authNetwork;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is not available right now.'**
  String get authUnavailable;

  /// No description provided for @authUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in right now. Please try again.'**
  String get authUnknown;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'The app encountered an unexpected problem. Please try again.'**
  String get unexpectedError;

  /// No description provided for @accountError.
  ///
  /// In en, this message translates to:
  /// **'Account error'**
  String get accountError;

  /// No description provided for @subscriptionError.
  ///
  /// In en, this message translates to:
  /// **'Subscription error'**
  String get subscriptionError;

  /// No description provided for @subscriptionPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Please try again.'**
  String get subscriptionPurchaseFailed;

  /// No description provided for @subscriptionRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchases could not be restored. Please try again.'**
  String get subscriptionRestoreFailed;

  /// No description provided for @subscriptionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not configured right now.'**
  String get subscriptionNotConfigured;

  /// No description provided for @accountSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue.'**
  String get accountSignInRequired;

  /// No description provided for @accountRecentLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again before deleting your account.'**
  String get accountRecentLoginRequired;

  /// No description provided for @accountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed. Please try again.'**
  String get accountDeletionFailed;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @sortHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get sortHot;

  /// No description provided for @sortNew.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNew;

  /// No description provided for @apiIncompatibleError.
  ///
  /// In en, this message translates to:
  /// **'This content API is incompatible. Please update the server.'**
  String get apiIncompatibleError;

  /// No description provided for @watchAll.
  ///
  /// In en, this message translates to:
  /// **'Watch all'**
  String get watchAll;

  /// No description provided for @chooseEpisode.
  ///
  /// In en, this message translates to:
  /// **'Choose episode'**
  String get chooseEpisode;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get intro;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'End of series'**
  String get ended;

  /// No description provided for @episodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Episode {count}'**
  String episodeLabel(Object count);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String views(Object count);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @hotTab.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get hotTab;

  /// No description provided for @newTab.
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get newTab;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @similarContent.
  ///
  /// In en, this message translates to:
  /// **'More like this'**
  String get similarContent;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @lockedEpisode.
  ///
  /// In en, this message translates to:
  /// **'This episode is locked at the source.'**
  String get lockedEpisode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
