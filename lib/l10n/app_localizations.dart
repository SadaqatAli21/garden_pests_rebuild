import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('pt'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Pest Identifire'**
  String get appTitle;

  /// No description provided for @scanNow.
  ///
  /// In en, this message translates to:
  /// **'Tap to Scan'**
  String get scanNow;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @scansToday.
  ///
  /// In en, this message translates to:
  /// **'Scans Today'**
  String get scansToday;

  /// No description provided for @keepHealthy.
  ///
  /// In en, this message translates to:
  /// **'Keep your garden healthy!'**
  String get keepHealthy;

  /// No description provided for @aiScanner.
  ///
  /// In en, this message translates to:
  /// **'AI Pest Scanner'**
  String get aiScanner;

  /// No description provided for @detectInsects.
  ///
  /// In en, this message translates to:
  /// **'Detect insects & Identify severity'**
  String get detectInsects;

  /// No description provided for @treatmentGuide.
  ///
  /// In en, this message translates to:
  /// **'Treatment Guide'**
  String get treatmentGuide;

  /// No description provided for @organicChemical.
  ///
  /// In en, this message translates to:
  /// **'Organic & Chemical'**
  String get organicChemical;

  /// No description provided for @savedScans.
  ///
  /// In en, this message translates to:
  /// **'Saved\nScans'**
  String get savedScans;

  /// No description provided for @historyLogs.
  ///
  /// In en, this message translates to:
  /// **'History & Logs'**
  String get historyLogs;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @helloGardener.
  ///
  /// In en, this message translates to:
  /// **'Hello, Gardener! 🌿'**
  String get helloGardener;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning ☀️'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon 🌤️'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening 🌙'**
  String get goodEvening;

  /// No description provided for @appModules.
  ///
  /// In en, this message translates to:
  /// **'App Modules'**
  String get appModules;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @alignPlant.
  ///
  /// In en, this message translates to:
  /// **'Align plant within frame'**
  String get alignPlant;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @noPestDetected.
  ///
  /// In en, this message translates to:
  /// **'No Pest Detected'**
  String get noPestDetected;

  /// No description provided for @pestDetected.
  ///
  /// In en, this message translates to:
  /// **'Pest Detected!'**
  String get pestDetected;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @affectedArea.
  ///
  /// In en, this message translates to:
  /// **'Affected Area'**
  String get affectedArea;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @chemical.
  ///
  /// In en, this message translates to:
  /// **'Chemical'**
  String get chemical;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @dailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit'**
  String get dailyLimit;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @unlockUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited scans and premium features'**
  String get unlockUnlimited;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning...'**
  String get cleaning;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @autoCleaner.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleaner'**
  String get autoCleaner;

  /// No description provided for @manualCleaner.
  ///
  /// In en, this message translates to:
  /// **'Manual Cleaner'**
  String get manualCleaner;

  /// No description provided for @waterDetection.
  ///
  /// In en, this message translates to:
  /// **'Water Detection'**
  String get waterDetection;

  /// No description provided for @dustCleaner.
  ///
  /// In en, this message translates to:
  /// **'Dust Cleaner'**
  String get dustCleaner;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @aboutPest.
  ///
  /// In en, this message translates to:
  /// **'About this Pest'**
  String get aboutPest;

  /// No description provided for @identificationCues.
  ///
  /// In en, this message translates to:
  /// **'Identification Cues'**
  String get identificationCues;

  /// No description provided for @biologicalDamage.
  ///
  /// In en, this message translates to:
  /// **'Biological Damage Analysis'**
  String get biologicalDamage;

  /// No description provided for @commonHostPlants.
  ///
  /// In en, this message translates to:
  /// **'Common Host Plants'**
  String get commonHostPlants;

  /// No description provided for @pestLifeCycle.
  ///
  /// In en, this message translates to:
  /// **'Pest Life Cycle'**
  String get pestLifeCycle;

  /// No description provided for @environmentalTriggers.
  ///
  /// In en, this message translates to:
  /// **'Environmental Triggers'**
  String get environmentalTriggers;

  /// No description provided for @economicImpact.
  ///
  /// In en, this message translates to:
  /// **'Economic Impact Insight'**
  String get economicImpact;

  /// No description provided for @multiSeasonStrategy.
  ///
  /// In en, this message translates to:
  /// **'Multi-Season Strategy'**
  String get multiSeasonStrategy;

  /// No description provided for @treatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan'**
  String get treatmentPlan;

  /// No description provided for @retryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'RETRY ANALYSIS'**
  String get retryAnalysis;

  /// No description provided for @cancelAndGoBack.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Go Back'**
  String get cancelAndGoBack;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get analysisFailed;

  /// No description provided for @analyzingPlant.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Plant...'**
  String get analyzingPlant;

  /// No description provided for @identifyingPests.
  ///
  /// In en, this message translates to:
  /// **'Identifying potential pests and diseases'**
  String get identifyingPests;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History Log'**
  String get historyTitle;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No History Yet'**
  String get noHistory;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your pest scan history will appear here.\nStart scanning to identify pests!'**
  String get historyEmpty;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected?'**
  String get deleteSelected;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} items from your history?'**
  String deleteConfirm(Object count);

  /// No description provided for @itemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Items deleted successfully'**
  String get itemsDeleted;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @pestGuide.
  ///
  /// In en, this message translates to:
  /// **'Pest Guide 📚'**
  String get pestGuide;

  /// No description provided for @pestGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find treatments for common pests'**
  String get pestGuideSubtitle;

  /// No description provided for @searchPests.
  ///
  /// In en, this message translates to:
  /// **'Search pests...'**
  String get searchPests;

  /// No description provided for @noPestsFound.
  ///
  /// In en, this message translates to:
  /// **'No pests found'**
  String get noPestsFound;

  /// No description provided for @adjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustSearch;

  /// No description provided for @readGuide.
  ///
  /// In en, this message translates to:
  /// **'Read Guide'**
  String get readGuide;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @saveToHistory.
  ///
  /// In en, this message translates to:
  /// **'Save to History'**
  String get saveToHistory;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @languageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Language selection coming soon!'**
  String get languageComingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon!'**
  String get featureComingSoon;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent! Check your status bar.'**
  String get notificationSent;

  /// No description provided for @proMember.
  ///
  /// In en, this message translates to:
  /// **'PRO MEMBER'**
  String get proMember;

  /// No description provided for @pestIdentifierPro.
  ///
  /// In en, this message translates to:
  /// **'AI Pest Identifire Pro'**
  String get pestIdentifierPro;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take your gardening to the next level'**
  String get proSubtitle;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Pest Analysis'**
  String get aiAnalysis;

  /// No description provided for @treatmentGuides.
  ///
  /// In en, this message translates to:
  /// **'Treatment Guides'**
  String get treatmentGuides;

  /// No description provided for @expertSupport.
  ///
  /// In en, this message translates to:
  /// **'Expert Support'**
  String get expertSupport;

  /// No description provided for @adFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get adFree;

  /// No description provided for @advancedInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced Insights'**
  String get advancedInsights;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get limited;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @chat247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Chat'**
  String get chat247;

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

  /// No description provided for @startTrial.
  ///
  /// In en, this message translates to:
  /// **'START 7-DAY FREE TRIAL'**
  String get startTrial;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Then just \$4.99/month. Cancel anytime.'**
  String get subscriptionDetails;

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'Identify Pests Instantly'**
  String get introTitle1;

  /// No description provided for @introDesc1.
  ///
  /// In en, this message translates to:
  /// **'Take a photo to instantly identify pests and diseases affecting your plants.'**
  String get introDesc1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Get Expert Solutions'**
  String get introTitle2;

  /// No description provided for @introDesc2.
  ///
  /// In en, this message translates to:
  /// **'Receive detailed treatment plans and expert advice to save your garden.'**
  String get introDesc2;

  /// No description provided for @introTitle3.
  ///
  /// In en, this message translates to:
  /// **'Track Your Garden'**
  String get introTitle3;

  /// No description provided for @introDesc3.
  ///
  /// In en, this message translates to:
  /// **'Keep a history of your scans and monitor the health of your plants over time.'**
  String get introDesc3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @removeSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Selected?'**
  String get removeSelectedTitle;

  /// No description provided for @removeSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {count} items from your saved scans?'**
  String removeSelectedMessage(Object count);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @itemsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Items removed successfully'**
  String get itemsRemoved;

  /// No description provided for @savedScansTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Scans'**
  String get savedScansTitle;

  /// No description provided for @noSavedScans.
  ///
  /// In en, this message translates to:
  /// **'No Saved Scans'**
  String get noSavedScans;

  /// No description provided for @savedScansEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bookmarked scans will appear here.\nSave results to find them later!'**
  String get savedScansEmpty;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AI Pest Identifire'**
  String get appName;

  /// No description provided for @pestAphidName.
  ///
  /// In en, this message translates to:
  /// **'Aphid (Plant Lice)'**
  String get pestAphidName;

  /// No description provided for @pestAphidDesc.
  ///
  /// In en, this message translates to:
  /// **'Aphids, technically known as Aphidoidea, are small, soft-bodied insects that are among the most destructive and widespread pests. Often called \"plant lice,\" they suck sap and reproduce asexually, leading to explosive population growth.'**
  String get pestAphidDesc;

  /// No description provided for @pestAphidSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Visual Identification:** Dense clusters on undersides of leaves.\n• **Leaf Distortion:** Leaves curl, crinkle, or cup downwards.\n• **Yellowing:** Spots or entire leaves turn yellow.\n• **Honeydew:** Sticky residue and Sooty Mold fungus.\n• **Ant Activity:** Ants farming aphids for honeydew.'**
  String get pestAphidSymptoms;

  /// No description provided for @pestAphidTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Water Blast:** Strong stream of water to dislodge them.\n• **Insecticidal Soap:** Dissolves their outer shell.\n• **Neem Oil:** Repellent and growth regulator.\n• **Horticultural Oils:** Smother overwintering eggs.\n• **Diatomaceous Earth:** Dehydrates them.'**
  String get pestAphidTreatment;

  /// No description provided for @pestAphidPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Beneficial Insects:** Ladybugs and lacewings.\n• **Companion Planting:** Garlic, chives, onions, and mint.\n• **Nitrogen Management:** Avoid over-fertilizing.\n• **Reflective Mulch:** Confuses winged aphids.'**
  String get pestAphidPrevention;

  /// No description provided for @pestSpiderMiteName.
  ///
  /// In en, this message translates to:
  /// **'Spider Mite'**
  String get pestSpiderMiteName;

  /// No description provided for @pestSpiderMiteSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Stippling:** Tiny, pale yellow dots on leaves.\n• **Bronzing:** Leaves turn bronze or silvery-gray.\n• **Webbing:** Fine silken webbing between leaves (severe).\n• **Defoliation:** Leaves shrivel and fall off.'**
  String get pestSpiderMiteSymptoms;

  /// No description provided for @pestSpiderMiteTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Humidity:** Increase humidity to deter them.\n• **Predatory Mites:** *Phytoseiulus persimilis* feed on them.\n• **Neem Oil:** Smothers mites and eggs.\n• **Alcohol Spray:** 1 part alcohol to 3 parts water.'**
  String get pestSpiderMiteTreatment;

  /// No description provided for @pestSpiderMitePrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Quarantine:** Isolate new plants.\n• **Dust Management:** Wash foliage regularly.\n• **Water Management:** Keep plants watered.\n• **Weed Control:** Remove overwintering hosts.'**
  String get pestSpiderMitePrevention;

  /// No description provided for @pestWhiteflyName.
  ///
  /// In en, this message translates to:
  /// **'Whitefly'**
  String get pestWhiteflyName;

  /// No description provided for @pestWhiteflySymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Yellowing:** Leaves turn pale or mottled.\n• **Sticky Honeydew:** Massive amounts of residue.\n• **Sooty Mold:** Black fungus grows on honeydew.\n• **Wilting:** Plants lose turgor and growth stunts.'**
  String get pestWhiteflySymptoms;

  /// No description provided for @pestWhiteflyTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Yellow Sticky Traps:** Attract and trap adults.\n• **Vacuuming:** Suck adults off leaves in the morning.\n• **Insecticidal Soap:** Kills soft-bodied nymphs.\n• **Parasitic Wasps:** *Encarsia formosa* for greenhouses.'**
  String get pestWhiteflyTreatment;

  /// No description provided for @pestWhiteflyPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Inspection:** Check new plants carefully.\n• **Weed Removal:** Eliminate alternate hosts.\n• **Nitrogen Control:** Avoid excess nitrogen.\n• **Worm Castings:** Reptellent effect.'**
  String get pestWhiteflyPrevention;

  /// No description provided for @pestCaterpillarName.
  ///
  /// In en, this message translates to:
  /// **'Caterpillar'**
  String get pestCaterpillarName;

  /// No description provided for @pestCaterpillarSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Holes:** Irregular chewing marks or skeletonizing.\n• **Frass:** Black or green pellets (droppings).\n• **Rolled Leaves:** Silk ties leaves together.\n• **Cut Stems:** Seedlings cut at soil line.'**
  String get pestCaterpillarSymptoms;

  /// No description provided for @pestCaterpillarTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Hand Picking:** Pick off by hand.\n• **Bt (Bacillus thuringiensis):** Bacteria toxic only to caterpillars.\n• **Spinosad:** Effective organic spray.\n• **Row Covers:** Biological barrier.'**
  String get pestCaterpillarTreatment;

  /// No description provided for @pestCaterpillarPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Fall Cleanup:** Remove debris.\n• **Interplanting:** Dill and cilantro attract predators.\n• **Moth Deterrents:** Sage and thyme.\n• **Cardboard Collars:** Protect seedlings from cutworms.'**
  String get pestCaterpillarPrevention;

  /// No description provided for @pestThripsName.
  ///
  /// In en, this message translates to:
  /// **'Thrips'**
  String get pestThripsName;

  /// No description provided for @pestThripsSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Silver Scars:** Silvery sheen on leaves.\n• **Black Specks:** Tiny black dots of excrement.\n• **Flower Damage:** Brown edges on petals.\n• **Distorted Tips:** New growth is twisted.'**
  String get pestThripsSymptoms;

  /// No description provided for @pestThripsTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Blue Sticky Traps:** Attract and trap adults.\n• **Spinosad:** Gold standard for organic control.\n• **Neem Oil:** Contact killer.\n• **Predatory Mites:** *Amblyseius* species.'**
  String get pestThripsTreatment;

  /// No description provided for @pestThripsPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Reflective Mulch:** Confuses them.\n• **Weed Control:** Remove breeding grounds.\n• **Screening:** Ultra-fine mesh for greenhouses.'**
  String get pestThripsPrevention;

  /// No description provided for @pestMealybugName.
  ///
  /// In en, this message translates to:
  /// **'Mealybug'**
  String get pestMealybugName;

  /// No description provided for @pestMealybugSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Cottony Masses:** White fluff in leaf joints.\n• **Sticky Honeydew:** Makes plants sticky.\n• **Yellowing:** Leaves drop.\n• **Root Damage:** White fungal look on roots.'**
  String get pestMealybugSymptoms;

  /// No description provided for @pestMealybugTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Alcohol Swab:** Kill individual bugs with alcohol.\n• **Alcohol Spray:** Diluted alcohol spray for whole plants.\n• **Insecticidal Soap:** Penetrates waxy layer.\n• **Systemic Granules:** For ornamentals.'**
  String get pestMealybugTreatment;

  /// No description provided for @pestMealybugPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Inspection:** Check protected areas of new plants.\n• **Lower Temperature:** Slows reproduction.\n• **Pruning:** Remove heavily infested branches.'**
  String get pestMealybugPrevention;

  /// No description provided for @pestLeafBeetleName.
  ///
  /// In en, this message translates to:
  /// **'Leaf Beetle'**
  String get pestLeafBeetleName;

  /// No description provided for @pestLeafBeetleSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Skeletonizing:** Tissue between veins eaten.\n• **Shot Holes:** Tiny round holes.\n• **Notched Leaves:** Edges chewed.\n• **Grub Damage:** Lawns dying in patches.'**
  String get pestLeafBeetleSymptoms;

  /// No description provided for @pestLeafBeetleTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Hand Picking:** Drop into soapy water.\n• **Neem Oil:** Anti-feedant.\n• **Kaolin Clay:** Irritating barrier film.\n• **Beneficial Nematodes:** Kill grubs in soil.'**
  String get pestLeafBeetleTreatment;

  /// No description provided for @pestLeafBeetlePrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Row Covers:** Prevent adults landing.\n• **Trap Crops:** Lure beetles away.\n• **Milky Spore:** Long-term grub control.\n• **Fall Cleanup:** Remove overwintering sites.'**
  String get pestLeafBeetlePrevention;

  /// No description provided for @pestSlugName.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get pestSlugName;

  /// No description provided for @pestSlugSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Irregular Holes:** Smooth edges in leaves.\n• **Slime Trails:** Silvery mucus tracks.\n• **Fruit Damage:** Holes in strawberries/tomatoes.\n• **Nocturnal:** Damage appears overnight.'**
  String get pestSlugSymptoms;

  /// No description provided for @pestSlugTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Iron Phosphate Bait:** Safe organic bait.\n• **Beer Traps:** Drown them.\n• **Copper Barrier:** Shocks them.\n• **Hand Picking:** Effective at night.'**
  String get pestSlugTreatment;

  /// No description provided for @pestSlugPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Morning Watering:** Let soil dry by night.\n• **Remove Shelter:** Clean up debris and boards.\n• **Rough Mulch:** Eggshells or bark.'**
  String get pestSlugPrevention;

  /// No description provided for @pestSnailName.
  ///
  /// In en, this message translates to:
  /// **'Snail'**
  String get pestSnailName;

  /// No description provided for @pestSnailSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Slime Trails:** Silvery tracks.\n• **Large Holes:** Chewing damage.\n• **Bark Damage:** Feeding on young trees.\n• **Grouping:** Hiding in clusters during day.'**
  String get pestSnailSymptoms;

  /// No description provided for @pestSnailTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Hand Picking:** Easy to grab by shell.\n• **Iron Phosphate Bait:** Effective control.\n• **Decoy Traps:** Damp boards or citrus rinds.\n• **Predatory Snails:** Eat garden snails.'**
  String get pestSnailTreatment;

  /// No description provided for @pestSnailPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Drip Irrigation:** Reduce surface moisture.\n• **Barriers:** Copper or ash.\n• **Eliminate Breeding:** Remove ivy/ground cover.'**
  String get pestSnailPrevention;

  /// No description provided for @pestGrasshopperName.
  ///
  /// In en, this message translates to:
  /// **'Grasshopper'**
  String get pestGrasshopperName;

  /// No description provided for @pestGrasshopperSymptoms.
  ///
  /// In en, this message translates to:
  /// **'• **Ragged Margins:** Large chunks missing.\n• **Defoliation:** Can strip plants bare.\n• **Fruit Damage:** Chewing on peppers/corn.\n• **Visibility:** Easily seen jumping/flying.'**
  String get pestGrasshopperSymptoms;

  /// No description provided for @pestGrasshopperTreatment.
  ///
  /// In en, this message translates to:
  /// **'• **Nolo Bait:** Biological control for nymphs.\n• **Garlic Spray:** Repellent.\n• **Neem Oil:** Growth regulator.\n• **Kaolin Clay:** Barrier.'**
  String get pestGrasshopperTreatment;

  /// No description provided for @pestGrasshopperPrevention.
  ///
  /// In en, this message translates to:
  /// **'• **Tilling:** Expose eggs in fall/spring.\n• **Weed Buffer:** Manage surrounding vegetation.\n• **Row Covers:** Physical barrier.\n• **Birds:** Encourage natural predators.'**
  String get pestGrasshopperPrevention;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @identificationAndSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Identification & Symptoms'**
  String get identificationAndSymptoms;

  /// No description provided for @treatmentAndControl.
  ///
  /// In en, this message translates to:
  /// **'Treatment & Control'**
  String get treatmentAndControl;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @analysisResult.
  ///
  /// In en, this message translates to:
  /// **'Analysis Result'**
  String get analysisResult;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions:'**
  String get instructions;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency:'**
  String get frequency;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage:'**
  String get dosage;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety:'**
  String get safety;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @savedToScans.
  ///
  /// In en, this message translates to:
  /// **'Saved to Scans'**
  String get savedToScans;

  /// No description provided for @saveScan.
  ///
  /// In en, this message translates to:
  /// **'Save Scan'**
  String get saveScan;

  /// No description provided for @scanSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Scan added to your Saved Scans!'**
  String get scanSavedSuccess;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// No description provided for @scanAutoSaved.
  ///
  /// In en, this message translates to:
  /// **'Scan automatically saved to history'**
  String get scanAutoSaved;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save scan. Please try again.'**
  String get failedToSave;

  /// No description provided for @noOrganicTreatments.
  ///
  /// In en, this message translates to:
  /// **'No organic treatments suggested.'**
  String get noOrganicTreatments;

  /// No description provided for @noChemicalTreatments.
  ///
  /// In en, this message translates to:
  /// **'No chemical treatments suggested.'**
  String get noChemicalTreatments;

  /// No description provided for @noPreventionTips.
  ///
  /// In en, this message translates to:
  /// **'No prevention tips available.'**
  String get noPreventionTips;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get exitAppMessage;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications?'**
  String get notificationsTitle;

  /// No description provided for @notificationsContent.
  ///
  /// In en, this message translates to:
  /// **'Get reminders to check your plants and keep your garden healthy with daily notifications.'**
  String get notificationsContent;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get cameraTitle;

  /// No description provided for @cameraContent.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your camera to take photos of plants and identify pests using AI.'**
  String get cameraContent;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery Permission'**
  String get galleryTitle;

  /// No description provided for @galleryContent.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your gallery to select photos of plants for AI analysis.'**
  String get galleryContent;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'To use this feature, please enable the required permission in your device settings.'**
  String get permissionDenied;

  /// No description provided for @failedToProcessImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to process image'**
  String get failedToProcessImage;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImage;

  /// No description provided for @macLibrary.
  ///
  /// In en, this message translates to:
  /// **'Mac Library'**
  String get macLibrary;

  /// No description provided for @macLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a plant photo from your Mac\nfor AI pest analysis'**
  String get macLibraryDesc;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful! Enjoy your Pro features.'**
  String get purchaseSuccessful;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase Error: {error}'**
  String purchaseError(Object error);

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed'**
  String get transactionFailed;

  /// No description provided for @alreadyPremium.
  ///
  /// In en, this message translates to:
  /// **'You are already a premium user!'**
  String get alreadyPremium;

  /// No description provided for @shareFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share Your Feedback'**
  String get shareFeedback;

  /// No description provided for @helpImproveExperience.
  ///
  /// In en, this message translates to:
  /// **'Help us improve your experience'**
  String get helpImproveExperience;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @catBug.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get catBug;

  /// No description provided for @catIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea/Improvement'**
  String get catIdea;

  /// No description provided for @catQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get catQuestion;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
  String get yourMessage;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think — bug, idea, or anything...'**
  String get feedbackHint;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get opening;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @rateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate {appName}'**
  String rateAppTitle(Object appName);

  /// No description provided for @reviewMeansLot.
  ///
  /// In en, this message translates to:
  /// **'Your review means a lot to us ❤️'**
  String get reviewMeansLot;

  /// No description provided for @howRateApp.
  ///
  /// In en, this message translates to:
  /// **'How would you rate our app?'**
  String get howRateApp;

  /// No description provided for @starTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible 😤'**
  String get starTerrible;

  /// No description provided for @starPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor 😕'**
  String get starPoor;

  /// No description provided for @starOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay 😐'**
  String get starOkay;

  /// No description provided for @starGood.
  ///
  /// In en, this message translates to:
  /// **'Good 😊'**
  String get starGood;

  /// No description provided for @starExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! 🤩'**
  String get starExcellent;

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get rateNow;

  /// No description provided for @shareAppSub.
  ///
  /// In en, this message translates to:
  /// **'Spread the word with your friends!'**
  String get shareAppSub;

  /// No description provided for @shareMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Share this message'**
  String get shareMessageLabel;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @copiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedText;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @shareBody.
  ///
  /// In en, this message translates to:
  /// **'🌿 Try {appName} — the smartest way to detect garden pests & diseases instantly!\n\n📲 Download now: {url}'**
  String shareBody(Object appName, Object url);

  /// No description provided for @reportAI.
  ///
  /// In en, this message translates to:
  /// **'Report AI'**
  String get reportAI;

  /// No description provided for @reportAIResult.
  ///
  /// In en, this message translates to:
  /// **'Report AI Result'**
  String get reportAIResult;

  /// No description provided for @whatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong with this result?'**
  String get whatsWrong;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted!'**
  String get reportSubmitted;

  /// No description provided for @thanksImprove.
  ///
  /// In en, this message translates to:
  /// **'Thanks for helping us improve 🙏'**
  String get thanksImprove;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe {plan}'**
  String subscribe(Object plan);

  /// No description provided for @goProUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Go PRO & Unlock\nFull Power'**
  String get goProUpgrade;

  /// No description provided for @healthyPlantsDesc.
  ///
  /// In en, this message translates to:
  /// **'Everything you need for healthy plants,\nunlimited and ad-free.'**
  String get healthyPlantsDesc;

  /// No description provided for @pestInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced Pest Insights'**
  String get pestInsights;

  /// No description provided for @unlimitedScans.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Scans'**
  String get unlimitedScans;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get perYear;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'one-time'**
  String get oneTime;

  /// No description provided for @legalNoticeLifetime.
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your iTunes account at confirmation of purchase. This is a one-time purchase that unlocks all Pro features forever. No monthly or yearly renewals required.'**
  String get legalNoticeLifetime;

  /// No description provided for @legalNoticeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your iTunes account at confirmation of purchase. Your subscription will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage your subscription and turn off auto-renewal by going to your App Store Account Settings after purchase.'**
  String get legalNoticeSubscription;

  /// No description provided for @wrongPest.
  ///
  /// In en, this message translates to:
  /// **'Wrong Pest Identified'**
  String get wrongPest;

  /// No description provided for @wrongPestSub.
  ///
  /// In en, this message translates to:
  /// **'The AI detected the wrong species'**
  String get wrongPestSub;

  /// No description provided for @lowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low Confidence Result'**
  String get lowConfidence;

  /// No description provided for @lowConfidenceSub.
  ///
  /// In en, this message translates to:
  /// **'The result seems uncertain or inaccurate'**
  String get lowConfidenceSub;

  /// No description provided for @wrongTreatment.
  ///
  /// In en, this message translates to:
  /// **'Wrong Treatment Info'**
  String get wrongTreatment;

  /// No description provided for @wrongTreatmentSub.
  ///
  /// In en, this message translates to:
  /// **'Treatment suggestions are irrelevant or incorrect'**
  String get wrongTreatmentSub;

  /// No description provided for @poorImage.
  ///
  /// In en, this message translates to:
  /// **'Poor Image Analysis'**
  String get poorImage;

  /// No description provided for @poorImageSub.
  ///
  /// In en, this message translates to:
  /// **'AI misread the image or plant details'**
  String get poorImageSub;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @pestSpiderMiteDesc.
  ///
  /// In en, this message translates to:
  /// **'Spider mites are tiny, eight-legged arachnids that feed on the sap of plants. They thrive in hot, dry conditions and can cause significant damage if left unchecked.'**
  String get pestSpiderMiteDesc;

  /// No description provided for @pestWhiteflyDesc.
  ///
  /// In en, this message translates to:
  /// **'Whiteflies are small, winged insects that suck sap from the undersides of leaves. They excrete sticky honeydew, which can lead to sooty mold.'**
  String get pestWhiteflyDesc;

  /// No description provided for @pestCaterpillarDesc.
  ///
  /// In en, this message translates to:
  /// **'Caterpillars are the larval stage of moths and butterflies. They are voracious eaters that can quickly skeletonize leaves and damage plants.'**
  String get pestCaterpillarDesc;

  /// No description provided for @pestThripsDesc.
  ///
  /// In en, this message translates to:
  /// **'Thrips are tiny, slender insects with fringed wings. They puncture plant cells and suck out the contents, causing stippling and discolored patches on leaves.'**
  String get pestThripsDesc;

  /// No description provided for @pestMealybugDesc.
  ///
  /// In en, this message translates to:
  /// **'Mealybugs are soft-bodied insects that secrete a powdery white wax. They cluster along veins and stems, sucking plant sap and stunting growth.'**
  String get pestMealybugDesc;

  /// No description provided for @pestLeafBeetleDesc.
  ///
  /// In en, this message translates to:
  /// **'Leaf beetles are a diverse group of beetles that feed on plant foliage. Both the adults and larvae can chew holes in leaves, sometimes completely defoliating plants.'**
  String get pestLeafBeetleDesc;

  /// No description provided for @pestSlugDesc.
  ///
  /// In en, this message translates to:
  /// **'Slugs are soft-bodied mollusks that feed on plant stems, leaves, and seedlings, particularly in damp conditions. They leave a characteristic silvery slime trail.'**
  String get pestSlugDesc;

  /// No description provided for @pestSnailDesc.
  ///
  /// In en, this message translates to:
  /// **'Snails share many characteristics with slugs but carry a coiled shell. They are nocturnal feeders that chew irregular holes in leaves and thrive in moist environments.'**
  String get pestSnailDesc;

  /// No description provided for @pestGrasshopperDesc.
  ///
  /// In en, this message translates to:
  /// **'Grasshoppers are highly mobile insects that chew large sections of leaves, stems, and fruits. In high numbers, they can devastate garden plants.'**
  String get pestGrasshopperDesc;

  /// No description provided for @analyzingLeafStructure.
  ///
  /// In en, this message translates to:
  /// **'Analyzing leaf structure...'**
  String get analyzingLeafStructure;

  /// No description provided for @scanningForPests.
  ///
  /// In en, this message translates to:
  /// **'Scanning for pests...'**
  String get scanningForPests;

  /// No description provided for @identifyingInsects.
  ///
  /// In en, this message translates to:
  /// **'Identifying insects...'**
  String get identifyingInsects;

  /// No description provided for @checkingPlantHealth.
  ///
  /// In en, this message translates to:
  /// **'Checking plant health...'**
  String get checkingPlantHealth;

  /// No description provided for @comparingWithDatabase.
  ///
  /// In en, this message translates to:
  /// **'Comparing with database...'**
  String get comparingWithDatabase;

  /// No description provided for @finalizingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Finalizing analysis...'**
  String get finalizingAnalysis;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Plants Smartly'**
  String get appTagline;

  /// No description provided for @scanTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for Better Results'**
  String get scanTipsTitle;

  /// No description provided for @scanTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow these guidelines before scanning'**
  String get scanTipsSubtitle;

  /// No description provided for @scanTipLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Good Lighting'**
  String get scanTipLightTitle;

  /// No description provided for @scanTipLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Shoot in bright, natural light. Avoid direct harsh sunlight or dim indoor light.'**
  String get scanTipLightDesc;

  /// No description provided for @scanTipBlurTitle.
  ///
  /// In en, this message translates to:
  /// **'No Blur'**
  String get scanTipBlurTitle;

  /// No description provided for @scanTipBlurDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone steady. Tap the screen to focus before taking the photo.'**
  String get scanTipBlurDesc;

  /// No description provided for @scanTipPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Only'**
  String get scanTipPlantTitle;

  /// No description provided for @scanTipPlantDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill the frame with the affected plant part — leaf, stem, or fruit. Avoid cluttered backgrounds.'**
  String get scanTipPlantDesc;

  /// No description provided for @scanTipDistTitle.
  ///
  /// In en, this message translates to:
  /// **'Proper Distance'**
  String get scanTipDistTitle;

  /// No description provided for @scanTipDistDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay 10–20 cm away so the pest or damage is clearly visible and in focus.'**
  String get scanTipDistDesc;

  /// No description provided for @scanTipAngleTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Angles'**
  String get scanTipAngleTitle;

  /// No description provided for @scanTipAngleDesc.
  ///
  /// In en, this message translates to:
  /// **'If unsure, try a top-down view and a close-up side view for best accuracy.'**
  String get scanTipAngleDesc;

  /// No description provided for @scanTipBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Plain Background'**
  String get scanTipBgTitle;

  /// No description provided for @scanTipBgDesc.
  ///
  /// In en, this message translates to:
  /// **'A simple background helps the AI focus on the plant and pest without distraction.'**
  String get scanTipBgDesc;

  /// No description provided for @scanTipGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it, Ready to Scan!'**
  String get scanTipGotIt;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get noInternetMessage;

  /// No description provided for @noInternetSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get noInternetSettings;

  /// No description provided for @plantName.
  ///
  /// In en, this message translates to:
  /// **'Plant Name'**
  String get plantName;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @useCase.
  ///
  /// In en, this message translates to:
  /// **'Use Case'**
  String get useCase;

  /// No description provided for @expectedPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected Price'**
  String get expectedPrice;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @plantInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Identification & Details'**
  String get plantInfoTitle;

  /// No description provided for @identify.
  ///
  /// In en, this message translates to:
  /// **'Identify'**
  String get identify;

  /// No description provided for @recognizeAnyPlant.
  ///
  /// In en, this message translates to:
  /// **'Recognize any plant'**
  String get recognizeAnyPlant;

  /// No description provided for @diagnose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get diagnose;

  /// No description provided for @checkPlantHealth.
  ///
  /// In en, this message translates to:
  /// **'Check your plant\'s health'**
  String get checkPlantHealth;

  /// No description provided for @waterReminders.
  ///
  /// In en, this message translates to:
  /// **'Water Reminders'**
  String get waterReminders;

  /// No description provided for @scheduleAlerts.
  ///
  /// In en, this message translates to:
  /// **'Schedule alerts for your garden'**
  String get scheduleAlerts;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get startScan;

  /// No description provided for @careGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Care Guide'**
  String get careGuideTitle;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No Reminders Yet'**
  String get noRemindersYet;

  /// No description provided for @noRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set daily alerts to never forget watering your plants again!'**
  String get noRemindersSubtitle;

  /// No description provided for @addFirstPlant.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Plant'**
  String get addFirstPlant;

  /// No description provided for @timesDaily.
  ///
  /// In en, this message translates to:
  /// **'{count} times daily'**
  String timesDaily(Object count);

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder?'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the schedule for {plantName}?'**
  String deleteReminderConfirm(Object plantName);

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @setNewAlert.
  ///
  /// In en, this message translates to:
  /// **'Set New Alert'**
  String get setNewAlert;

  /// No description provided for @plantNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Money Plant, Rose...'**
  String get plantNameHint;

  /// No description provided for @scheduledTimes.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Times'**
  String get scheduledTimes;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @timeAlreadySelected.
  ///
  /// In en, this message translates to:
  /// **'Time already selected!'**
  String get timeAlreadySelected;

  /// No description provided for @maxRemindersReached.
  ///
  /// In en, this message translates to:
  /// **'Max 3 reminders per plant!'**
  String get maxRemindersReached;

  /// No description provided for @pleaseEnterPlantName.
  ///
  /// In en, this message translates to:
  /// **'Please enter plant name!'**
  String get pleaseEnterPlantName;

  /// No description provided for @reminderSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved successfully!'**
  String get reminderSavedSuccess;

  /// No description provided for @dailyNotificationInfo.
  ///
  /// In en, this message translates to:
  /// **'You will get daily notifications at these times for {plantName}.'**
  String dailyNotificationInfo(Object plantName);

  /// No description provided for @healthCareDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Health Care Diagnosis'**
  String get healthCareDiagnosis;

  /// No description provided for @overallStatus.
  ///
  /// In en, this message translates to:
  /// **'Overall Status'**
  String get overallStatus;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @careRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Care Recommendations'**
  String get careRecommendations;

  /// No description provided for @plantNotIdentified.
  ///
  /// In en, this message translates to:
  /// **'Plant Not Identified'**
  String get plantNotIdentified;

  /// No description provided for @healthReport.
  ///
  /// In en, this message translates to:
  /// **'Health Report'**
  String get healthReport;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'hi', 'id', 'pt', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'id': return AppLocalizationsId();
    case 'pt': return AppLocalizationsPt();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
          'an issue with the localizations generation tool. Please file an issue '
          'on GitHub with a reproducible sample app and the gen-l10n configuration '
          'that was used.'
  );
}
