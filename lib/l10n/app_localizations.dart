import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// No description provided for @whiteSpace.
  ///
  /// In en, this message translates to:
  /// **' '**
  String get whiteSpace;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @setupCustomRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Set up Custom restrictions'**
  String get setupCustomRestrictions;

  /// No description provided for @customRestrictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom restrictions'**
  String get customRestrictionTitle;

  /// No description provided for @customRestrictionHeader.
  ///
  /// In en, this message translates to:
  /// **'Set up Custom restrictions'**
  String get customRestrictionHeader;

  /// No description provided for @customRestrictionHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Select when you would like to complete this task.'**
  String get customRestrictionHeaderDescription;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationStar.
  ///
  /// In en, this message translates to:
  /// **'Duration*'**
  String get durationStar;

  /// No description provided for @addTile.
  ///
  /// In en, this message translates to:
  /// **'Add Tile'**
  String get addTile;

  /// No description provided for @defer.
  ///
  /// In en, this message translates to:
  /// **'Defer'**
  String get defer;

  /// No description provided for @deferAll.
  ///
  /// In en, this message translates to:
  /// **'Defer All'**
  String get deferAll;

  /// No description provided for @procrastinating.
  ///
  /// In en, this message translates to:
  /// **'Procrastinating'**
  String get procrastinating;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @whenQ.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get whenQ;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @nickName.
  ///
  /// In en, this message translates to:
  /// **'Nick Name'**
  String get nickName;

  /// No description provided for @deadline_anytime.
  ///
  /// In en, this message translates to:
  /// **'Deadline(Anytime)'**
  String get deadline_anytime;

  /// No description provided for @selectADeadline.
  ///
  /// In en, this message translates to:
  /// **'Select a deadline'**
  String get selectADeadline;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tileName.
  ///
  /// In en, this message translates to:
  /// **'Tile Name'**
  String get tileName;

  /// No description provided for @tileNameStar.
  ///
  /// In en, this message translates to:
  /// **'Tile Name*'**
  String get tileNameStar;

  /// No description provided for @starAreRequired.
  ///
  /// In en, this message translates to:
  /// **'* are required fields'**
  String get starAreRequired;

  /// No description provided for @howManyTimes.
  ///
  /// In en, this message translates to:
  /// **'How many times'**
  String get howManyTimes;

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @weekdaysAndWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Weekdays and work hours'**
  String get weekdaysAndWorkHours;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weekend;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @repetition.
  ///
  /// In en, this message translates to:
  /// **'Repetition'**
  String get repetition;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @restriction.
  ///
  /// In en, this message translates to:
  /// **'Restriction'**
  String get restriction;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get fieldIsRequired;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing In'**
  String get signingIn;

  /// No description provided for @registeringUser.
  ///
  /// In en, this message translates to:
  /// **'Registering User'**
  String get registeringUser;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirmation password is required'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Password and confirmation password don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordNeedToBeAtLeastSevenCharacters.
  ///
  /// In en, this message translates to:
  /// **'Password needs to be at least 7 characters'**
  String get passwordNeedToBeAtLeastSevenCharacters;

  /// No description provided for @passwordNeedsToHaveUpperCaseChracters.
  ///
  /// In en, this message translates to:
  /// **'Password needs to have an upper case characters'**
  String get passwordNeedsToHaveUpperCaseChracters;

  /// No description provided for @passwordNeedsToHaveLowerCaseChracters.
  ///
  /// In en, this message translates to:
  /// **'Password needs to have an lower case characters'**
  String get passwordNeedsToHaveLowerCaseChracters;

  /// No description provided for @passwordNeedsToHaveNumber.
  ///
  /// In en, this message translates to:
  /// **'Password needs to have a number'**
  String get passwordNeedsToHaveNumber;

  /// No description provided for @passwordNeedsToHaveASpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Password needs to have at least 1 special character'**
  String get passwordNeedsToHaveASpecialCharacter;

  /// No description provided for @enableLocations.
  ///
  /// In en, this message translates to:
  /// **'Enable location permissions'**
  String get enableLocations;

  /// No description provided for @noMatchWasFound.
  ///
  /// In en, this message translates to:
  /// **'No match was found'**
  String get noMatchWasFound;

  /// No description provided for @atLeastThreeLettersForLookup.
  ///
  /// In en, this message translates to:
  /// **'...Tiler needs three characters for a lookup'**
  String get atLeastThreeLettersForLookup;

  /// No description provided for @noLocationMatchWasFound.
  ///
  /// In en, this message translates to:
  /// **'No location match was found'**
  String get noLocationMatchWasFound;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocation;

  /// No description provided for @clearedColon.
  ///
  /// In en, this message translates to:
  /// **'Cleared: '**
  String get clearedColon;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick A Color'**
  String get pickAColor;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @successfullyPaused.
  ///
  /// In en, this message translates to:
  /// **'Successfully Paused'**
  String get successfullyPaused;

  /// No description provided for @successfullyResumed.
  ///
  /// In en, this message translates to:
  /// **'Successfully Resumed'**
  String get successfullyResumed;

  /// No description provided for @successfullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Successfully Completed'**
  String get successfullyCompleted;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @movedUpToNow.
  ///
  /// In en, this message translates to:
  /// **'Moving up to now'**
  String get movedUpToNow;

  /// No description provided for @pausing.
  ///
  /// In en, this message translates to:
  /// **'Pausing'**
  String get pausing;

  /// No description provided for @resuming.
  ///
  /// In en, this message translates to:
  /// **'Resuming'**
  String get resuming;

  /// No description provided for @movingUp.
  ///
  /// In en, this message translates to:
  /// **'Moving Up your tile'**
  String get movingUp;

  /// No description provided for @completing.
  ///
  /// In en, this message translates to:
  /// **'Completing'**
  String get completing;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get deleting;

  /// No description provided for @previously.
  ///
  /// In en, this message translates to:
  /// **'Previously'**
  String get previously;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @failedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get failedToSendRequest;

  /// No description provided for @revise.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get revise;

  /// No description provided for @revisingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Revising Schedule'**
  String get revisingSchedule;

  /// No description provided for @procrastinateBlockOut.
  ///
  /// In en, this message translates to:
  /// **'Tile Break'**
  String get procrastinateBlockOut;

  /// No description provided for @lunchBreak.
  ///
  /// In en, this message translates to:
  /// **'Lunch Break'**
  String get lunchBreak;

  /// No description provided for @coffeeBreak.
  ///
  /// In en, this message translates to:
  /// **'Coffee Break'**
  String get coffeeBreak;

  /// No description provided for @morningBreak.
  ///
  /// In en, this message translates to:
  /// **'Morning Break'**
  String get morningBreak;

  /// No description provided for @afternoonBreak.
  ///
  /// In en, this message translates to:
  /// **'Afternoon Break'**
  String get afternoonBreak;

  /// No description provided for @freeTime.
  ///
  /// In en, this message translates to:
  /// **'Free Time'**
  String get freeTime;

  /// No description provided for @quickBreak.
  ///
  /// In en, this message translates to:
  /// **'Quick Break'**
  String get quickBreak;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @blockedTime.
  ///
  /// In en, this message translates to:
  /// **'Blocked Time'**
  String get blockedTime;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @timeBlocks.
  ///
  /// In en, this message translates to:
  /// **'Time blocks'**
  String get timeBlocks;

  /// No description provided for @swipeRightToTileIt.
  ///
  /// In en, this message translates to:
  /// **'Swipe Right to tile it'**
  String get swipeRightToTileIt;

  /// No description provided for @failedToReviseScheduleRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to revise schedule request'**
  String get failedToReviseScheduleRequest;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

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

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @noneNotificationCategory.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get noneNotificationCategory;

  /// No description provided for @nextTileNotificationCategory.
  ///
  /// In en, this message translates to:
  /// **'Next Tile'**
  String get nextTileNotificationCategory;

  /// No description provided for @userSetReminderNotificationCategory.
  ///
  /// In en, this message translates to:
  /// **'User Set Reminder'**
  String get userSetReminderNotificationCategory;

  /// No description provided for @depatureTimeNotificationCategory.
  ///
  /// In en, this message translates to:
  /// **'Depature time'**
  String get depatureTimeNotificationCategory;

  /// No description provided for @tile.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get tile;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get appointment;

  /// Starts at time
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String startingAtTime(String time);

  /// Ends at time
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String endsAtTime(String time);

  /// No description provided for @startsInTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in ten minutes'**
  String get startsInTenMinutes;

  /// No description provided for @endsInTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Ends in five minutes'**
  String get endsInTenMinutes;

  /// Description of time till start
  ///
  /// In en, this message translates to:
  /// **'Starts in {duration}'**
  String startsInDuration(String duration);

  /// Description of time of conclusion
  ///
  /// In en, this message translates to:
  /// **'🏁 {tileName} concludes soon'**
  String concludesAtTime(String tileName);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @googleLogo.
  ///
  /// In en, this message translates to:
  /// **'Google Logo'**
  String get googleLogo;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @workProfileHours.
  ///
  /// In en, this message translates to:
  /// **'Work Hours'**
  String get workProfileHours;

  /// No description provided for @personalHours.
  ///
  /// In en, this message translates to:
  /// **'Personal Hours'**
  String get personalHours;

  /// No description provided for @setWorkProfileHours.
  ///
  /// In en, this message translates to:
  /// **'Set Work Hours'**
  String get setWorkProfileHours;

  /// No description provided for @setPersonalHours.
  ///
  /// In en, this message translates to:
  /// **'Set Personal Hours'**
  String get setPersonalHours;

  /// No description provided for @customHours.
  ///
  /// In en, this message translates to:
  /// **'Custom Hours'**
  String get customHours;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @noteEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Note...'**
  String get noteEllipsis;

  /// No description provided for @tapToCreateNewTile.
  ///
  /// In en, this message translates to:
  /// **'Tap to create a new tile'**
  String get tapToCreateNewTile;

  /// No description provided for @emptyDayHeaderLine1.
  ///
  /// In en, this message translates to:
  /// **'No plans yet.'**
  String get emptyDayHeaderLine1;

  /// No description provided for @emptyDayFooterLine1.
  ///
  /// In en, this message translates to:
  /// **'Get started in seconds—'**
  String get emptyDayFooterLine1;

  /// No description provided for @emptyDayFooterLine2.
  ///
  /// In en, this message translates to:
  /// **'import calendars or create tiles.'**
  String get emptyDayFooterLine2;

  /// No description provided for @emptyDayOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get emptyDayOr;

  /// No description provided for @emptyDayImportGoogleCalendarButton.
  ///
  /// In en, this message translates to:
  /// **'Import Google Calendar'**
  String get emptyDayImportGoogleCalendarButton;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @youNeedToLeaveIn.
  ///
  /// In en, this message translates to:
  /// **'You need to leave in'**
  String get youNeedToLeaveIn;

  /// Description of time to depart
  ///
  /// In en, this message translates to:
  /// **'You need to leave in {duration}'**
  String youNeedToLeaveInDuration(String duration);

  /// Description of departure tardiness
  ///
  /// In en, this message translates to:
  /// **'{duration} Late'**
  String durationLate(String duration);

  /// Description of duration ago
  ///
  /// In en, this message translates to:
  /// **'Elapsed {duration} ago'**
  String elapsedDurationAgo(String duration);

  /// Description of duration ago
  ///
  /// In en, this message translates to:
  /// **'Completed {duration} ago'**
  String completedDurationAgo(String duration);

  /// Description of duration remaining
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String durationLeft(String duration);

  /// No description provided for @issuesConnectingToTiler.
  ///
  /// In en, this message translates to:
  /// **'Issues connecting to Tiler'**
  String get issuesConnectingToTiler;

  /// Completed tile count
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completedCount(String count);

  /// Deleted tile count
  ///
  /// In en, this message translates to:
  /// **'Deleted ({count})'**
  String deletedCount(String count);

  /// Tiles left count
  ///
  /// In en, this message translates to:
  /// **'Tiles left ({count})'**
  String tiledCount(String count);

  /// Tile count
  ///
  /// In en, this message translates to:
  /// **'{count} Tiles'**
  String countTile(String count);

  /// Number of Tiles selected
  ///
  /// In en, this message translates to:
  /// **'{number} Tiles selected'**
  String numberOfTilesSelected(String number);

  /// No description provided for @completeTiles.
  ///
  /// In en, this message translates to:
  /// **'Complete Tiles'**
  String get completeTiles;

  /// No description provided for @thisFitsInYourSchedule.
  ///
  /// In en, this message translates to:
  /// **'This fits in your schedule.'**
  String get thisFitsInYourSchedule;

  /// No description provided for @warningColon.
  ///
  /// In en, this message translates to:
  /// **'Warning: '**
  String get warningColon;

  /// No description provided for @oneEventAtRisk.
  ///
  /// In en, this message translates to:
  /// **'1 event at risk'**
  String get oneEventAtRisk;

  /// Number of event at risk
  ///
  /// In en, this message translates to:
  /// **'{number} events at risk'**
  String countEventAtRisk(String number);

  /// No description provided for @oneConflict.
  ///
  /// In en, this message translates to:
  /// **'1 Conflict'**
  String get oneConflict;

  /// Number of conflict
  ///
  /// In en, this message translates to:
  /// **'{number} Conflicts'**
  String countConflict(String number);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @thisEventWouldCause.
  ///
  /// In en, this message translates to:
  /// **'This event would cause '**
  String get thisEventWouldCause;

  /// Error message string
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @unScheduledTiles.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled Tiles'**
  String get unScheduledTiles;

  /// Number of Unscheduled Tiles
  ///
  /// In en, this message translates to:
  /// **'{number} Unscheduled Tiles'**
  String numberOfUnScheduledTiles(String number);

  /// Number of more users
  ///
  /// In en, this message translates to:
  /// **'+{number} more'**
  String numberOfMoreUsers(String number);

  /// No description provided for @unScheduled.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled'**
  String get unScheduled;

  /// No description provided for @allScheduled.
  ///
  /// In en, this message translates to:
  /// **'All Scheduled'**
  String get allScheduled;

  /// No description provided for @getOnIt.
  ///
  /// In en, this message translates to:
  /// **'Get on it'**
  String get getOnIt;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get onTime;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @driveTime.
  ///
  /// In en, this message translates to:
  /// **'Drive Time'**
  String get driveTime;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signUpWithGoogle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @invalidUsernameOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidUsernameOrPassword;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// X hours
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String countHours(String count);

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get oneMinute;

  /// X minutes
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String countMinutes(String count);

  /// X days
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String countDays(String count);

  /// Late (date)
  ///
  /// In en, this message translates to:
  /// **'Late ({date})'**
  String lateDate(String date);

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @allowAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Tiler collects location data to enable efficient scheduling of tiles and appointments. \nYour data remains private and is only used for this purpose.'**
  String get allowAccessDescription;

  /// No description provided for @allowLocationAccessQ.
  ///
  /// In en, this message translates to:
  /// **'Allow location access?'**
  String get allowLocationAccessQ;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @morningAndAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Morning & Afternoon'**
  String get morningAndAfternoon;

  /// No description provided for @afternoonAndEvening.
  ///
  /// In en, this message translates to:
  /// **'Afternoon & Evening'**
  String get afternoonAndEvening;

  /// No description provided for @lateEvening.
  ///
  /// In en, this message translates to:
  /// **'Late Evening'**
  String get lateEvening;

  /// No description provided for @prediction.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get prediction;

  /// No description provided for @softDeadline.
  ///
  /// In en, this message translates to:
  /// **'Soft Deadline'**
  String get softDeadline;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @dashEmptyString.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get dashEmptyString;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteYourTilerAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteYourTilerAccountQ;

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

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget Password'**
  String get forgetPassword;

  /// No description provided for @forgotPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordBtn;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Looking up
  ///
  /// In en, this message translates to:
  /// **'Looking up {text}'**
  String lookingUp(String text);

  /// No description provided for @lowPriorityTrunc.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowPriorityTrunc;

  /// No description provided for @mediumPriorityTrunc.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get mediumPriorityTrunc;

  /// No description provided for @highPriorityTrunc.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highPriorityTrunc;

  /// Email address
  ///
  /// In en, this message translates to:
  /// **'Failed to add {email}'**
  String failedToAddGoogleCalendar(String email);

  /// Email address
  ///
  /// In en, this message translates to:
  /// **'Deleted {email} calendar'**
  String deletedCalendar(String email);

  /// No description provided for @loadingIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Loading Integrations'**
  String get loadingIntegrations;

  /// No description provided for @noThirdPartyIntegtions.
  ///
  /// In en, this message translates to:
  /// **'No Thirdparty calendars'**
  String get noThirdPartyIntegtions;

  /// No description provided for @addGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add Google Calendar'**
  String get addGoogleCalendar;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @integrateOtherCalendars.
  ///
  /// In en, this message translates to:
  /// **'Integrate with third party calendars'**
  String get integrateOtherCalendars;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @morningPerson.
  ///
  /// In en, this message translates to:
  /// **'🌅 Morning person'**
  String get morningPerson;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @middayPerson.
  ///
  /// In en, this message translates to:
  /// **'🌞 Midday person'**
  String get middayPerson;

  /// No description provided for @nightPerson.
  ///
  /// In en, this message translates to:
  /// **'🌃 Night person'**
  String get nightPerson;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterAddress;

  /// No description provided for @wakeUpTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What time do you usually wake up in the morning?'**
  String get wakeUpTimeQuestion;

  /// No description provided for @workdayStartQuestion.
  ///
  /// In en, this message translates to:
  /// **'What time do you typically start your workday?'**
  String get workdayStartQuestion;

  /// No description provided for @primaryLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your primary location for work or study?'**
  String get primaryLocationQuestion;

  /// No description provided for @energyLevelDescriptionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your energy levels throughout the day?'**
  String get energyLevelDescriptionQuestion;

  /// No description provided for @incompleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Did not send complete request'**
  String get incompleteRequest;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// Deadline: time
  ///
  /// In en, this message translates to:
  /// **'Deadline: {time}'**
  String deadlineTime(String time);

  /// Accept button label for RSVP
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Decline button label for RSVP
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @addTilette.
  ///
  /// In en, this message translates to:
  /// **'Add Tilette'**
  String get addTilette;

  /// No description provided for @tileShareName.
  ///
  /// In en, this message translates to:
  /// **'Tile Share Name'**
  String get tileShareName;

  /// No description provided for @tileShare.
  ///
  /// In en, this message translates to:
  /// **'Tile Share'**
  String get tileShare;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @noDesignatedTiles.
  ///
  /// In en, this message translates to:
  /// **'No designated tiles'**
  String get noDesignatedTiles;

  /// No description provided for @noTileCluster.
  ///
  /// In en, this message translates to:
  /// **'No Tile Shares Created'**
  String get noTileCluster;

  /// No description provided for @errorLoadingTilelist.
  ///
  /// In en, this message translates to:
  /// **'Error loading tilelist'**
  String get errorLoadingTilelist;

  /// No description provided for @failedToLoadTileShareCluster.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tile share cluster'**
  String get failedToLoadTileShareCluster;

  /// No description provided for @missingTileShareCluster.
  ///
  /// In en, this message translates to:
  /// **'Missing TileShare cluster'**
  String get missingTileShareCluster;

  /// No description provided for @outBound.
  ///
  /// In en, this message translates to:
  /// **'OutBound'**
  String get outBound;

  /// No description provided for @inBound.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get inBound;

  /// No description provided for @multiShare.
  ///
  /// In en, this message translates to:
  /// **'Multi Share'**
  String get multiShare;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred!!\nPlease try again.'**
  String get errorOccurred;

  /// No description provided for @authenticationIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues with authentication.'**
  String get authenticationIssues;

  /// No description provided for @userIsNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User is not authenticated.'**
  String get userIsNotAuthenticated;

  /// No description provided for @responseContentError.
  ///
  /// In en, this message translates to:
  /// **'Response does not contain expected Content.'**
  String get responseContentError;

  /// No description provided for @responseHandlingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to handle the response.'**
  String get responseHandlingError;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// Number-day Forecast
  ///
  /// In en, this message translates to:
  /// **'{number}-day Forecast'**
  String numberOfDayForecast(String number);

  /// No description provided for @knotDuration.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get knotDuration;

  /// No description provided for @failedToGetPreview.
  ///
  /// In en, this message translates to:
  /// **'Failed to get preview'**
  String get failedToGetPreview;

  /// No description provided for @noDriving.
  ///
  /// In en, this message translates to:
  /// **'No driving'**
  String get noDriving;

  /// No description provided for @tileShareNoteEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Note...'**
  String get tileShareNoteEllipsis;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @passwordCreationMessagePart1.
  ///
  /// In en, this message translates to:
  /// **'Create a strong, unique password with '**
  String get passwordCreationMessagePart1;

  /// No description provided for @passwordConditionMinLength.
  ///
  /// In en, this message translates to:
  /// **'at least six characters'**
  String get passwordConditionMinLength;

  /// No description provided for @passwordCreationMessageIncluding.
  ///
  /// In en, this message translates to:
  /// **', including '**
  String get passwordCreationMessageIncluding;

  /// No description provided for @passwordConditionUppercaseLetters.
  ///
  /// In en, this message translates to:
  /// **'uppercase letters'**
  String get passwordConditionUppercaseLetters;

  /// No description provided for @passwordConditionLowercaseLetters.
  ///
  /// In en, this message translates to:
  /// **'lowercase letters'**
  String get passwordConditionLowercaseLetters;

  /// No description provided for @passwordConditionNumbers.
  ///
  /// In en, this message translates to:
  /// **'numbers'**
  String get passwordConditionNumbers;

  /// No description provided for @passwordConditionSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'a special character'**
  String get passwordConditionSpecialCharacter;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @listFinalSeparator.
  ///
  /// In en, this message translates to:
  /// **', and '**
  String get listFinalSeparator;

  /// No description provided for @nonViableTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'No viable timeslot'**
  String get nonViableTimeSlot;

  /// Time in AM
  ///
  /// In en, this message translates to:
  /// **'{number}AM'**
  String numberAm(String number);

  /// Time in PM
  ///
  /// In en, this message translates to:
  /// **'{number}PM'**
  String numberPm(String number);

  /// No description provided for @dayCast.
  ///
  /// In en, this message translates to:
  /// **'DayCast'**
  String get dayCast;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectWeek.
  ///
  /// In en, this message translates to:
  /// **'Select a Week'**
  String get selectWeek;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @retrievingDataIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue with retrieving data'**
  String get retrievingDataIssue;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @nonRecurring.
  ///
  /// In en, this message translates to:
  /// **'Non-Recurring'**
  String get nonRecurring;

  /// No description provided for @dailyReurring.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyReurring;

  /// No description provided for @weeklyReurring.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyReurring;

  /// No description provided for @biweeklyReurring.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly'**
  String get biweeklyReurring;

  /// No description provided for @monthlyReurring.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyReurring;

  /// No description provided for @yearlyReurring.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyReurring;

  /// No description provided for @ellipsisEmprtNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes...'**
  String get ellipsisEmprtNotes;

  /// No description provided for @tileShareDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tileShareDelete;

  /// No description provided for @commaDelimiter.
  ///
  /// In en, this message translates to:
  /// **','**
  String get commaDelimiter;

  /// No description provided for @foreCastTile.
  ///
  /// In en, this message translates to:
  /// **'Forecast Tile'**
  String get foreCastTile;

  /// No description provided for @previewOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get previewOthers;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'GOod Morning'**
  String get goodMorning;

  /// No description provided for @goodDay.
  ///
  /// In en, this message translates to:
  /// **'Good Day'**
  String get goodDay;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Number of Blocks
  ///
  /// In en, this message translates to:
  /// **'You have {count} blocks coming up.'**
  String youHaveXBlocks(String count);

  /// Number of tiles
  ///
  /// In en, this message translates to:
  /// **'You have {count} tiles coming up.'**
  String youHaveXTiles(String count);

  /// Number of tileshares
  ///
  /// In en, this message translates to:
  /// **'You have {count} tileshares coming up.'**
  String youHaveXTileShares(String count);

  /// Number of tileshares
  ///
  /// In en, this message translates to:
  /// **'{count} tileshares'**
  String countTileShare(String count);

  /// Number of blocks
  ///
  /// In en, this message translates to:
  /// **'You have {blockCount} blocks and {tileCount} tiles coming up.'**
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount);

  /// Number of blocks
  ///
  /// In en, this message translates to:
  /// **'You have {blockCount} blocks and {tileShareCount} tileshares coming up.'**
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount);

  /// Number of blocks
  ///
  /// In en, this message translates to:
  /// **'You have {tileCount} tiles and {tileShareCount} tileshares coming up.'**
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount);

  /// Number of blocks
  ///
  /// In en, this message translates to:
  /// **'You have {blockCount} blocks, {tileCount} tiles and {tileShareCount} tileshares coming up.'**
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount);

  /// No description provided for @noTilesPreview.
  ///
  /// In en, this message translates to:
  /// **'You have nothing coming up for the rest of today.'**
  String get noTilesPreview;

  /// Shortened text
  ///
  /// In en, this message translates to:
  /// **'{shortenedText}...'**
  String previewEllipsisText(String shortenedText);

  /// No description provided for @createTile.
  ///
  /// In en, this message translates to:
  /// **'Create Tile'**
  String get createTile;

  /// No description provided for @previewTileForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get previewTileForecast;

  /// No description provided for @previewTileOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get previewTileOptions;

  /// No description provided for @previewTileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get previewTileMore;

  /// No description provided for @previewTileShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get previewTileShuffle;

  /// No description provided for @previewTileRevise.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get previewTileRevise;

  /// No description provided for @previewTileDeferAll.
  ///
  /// In en, this message translates to:
  /// **'Defer All'**
  String get previewTileDeferAll;

  /// No description provided for @previewLocationName.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get previewLocationName;

  /// No description provided for @previewTagName.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get previewTagName;

  /// No description provided for @previewClassificationName.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get previewClassificationName;

  /// No description provided for @previewBlockedOut.
  ///
  /// In en, this message translates to:
  /// **'Blocked Out'**
  String get previewBlockedOut;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account info'**
  String get accountInfo;

  /// No description provided for @fistName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get fistName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @tilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Tile Preferences'**
  String get tilePreferences;

  /// No description provided for @notificationsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notifications Preferences'**
  String get notificationsPreferences;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @myLocations.
  ///
  /// In en, this message translates to:
  /// **'My Locations'**
  String get myLocations;

  /// No description provided for @aboutTiler.
  ///
  /// In en, this message translates to:
  /// **'About Tiler'**
  String get aboutTiler;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get setLocation;

  /// No description provided for @connectCalendars.
  ///
  /// In en, this message translates to:
  /// **'Connect your calendars'**
  String get connectCalendars;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @googleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// No description provided for @appleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Apple Calendar'**
  String get appleCalendar;

  /// No description provided for @googleTasks.
  ///
  /// In en, this message translates to:
  /// **'Google Tasks'**
  String get googleTasks;

  /// No description provided for @microsoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get microsoft;

  /// No description provided for @slack.
  ///
  /// In en, this message translates to:
  /// **'Slack'**
  String get slack;

  /// No description provided for @sleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep Duration'**
  String get sleepDuration;

  /// No description provided for @transportationMethodQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you move around?'**
  String get transportationMethodQuestion;

  /// No description provided for @defineYourTimeRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Define Your Time Restrictions'**
  String get defineYourTimeRestrictions;

  /// No description provided for @setWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Set Work Hours'**
  String get setWorkHours;

  /// No description provided for @setYourBlockOutHours.
  ///
  /// In en, this message translates to:
  /// **'Set Your Block Out Hours'**
  String get setYourBlockOutHours;

  /// No description provided for @travelMediumBiking.
  ///
  /// In en, this message translates to:
  /// **'Biking'**
  String get travelMediumBiking;

  /// No description provided for @travelMediumTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get travelMediumTransit;

  /// No description provided for @travelMediumDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get travelMediumDriving;

  /// No description provided for @travelMediumTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get travelMediumTransport;

  /// Ratio time in minutes
  ///
  /// In en, this message translates to:
  /// **'{ratio} m'**
  String previewRatioTimeMinutes(String ratio);

  /// Ratio time in hours
  ///
  /// In en, this message translates to:
  /// **'{ratio} hrs'**
  String previewRatioTimeHours(String ratio);

  /// No description provided for @bedTime.
  ///
  /// In en, this message translates to:
  /// **'Bed Time'**
  String get bedTime;

  /// No description provided for @sleepTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep Time'**
  String get sleepTime;

  /// No description provided for @tilePreferencesUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tile Preferences have been updated successfully.'**
  String get tilePreferencesUpdatedSuccessfully;

  /// No description provided for @notificationsPreferencesUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Notifications Preferences have been updated successfully.'**
  String get notificationsPreferencesUpdatedSuccessfully;

  /// No description provided for @tileReminders.
  ///
  /// In en, this message translates to:
  /// **'Tile Reminders'**
  String get tileReminders;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get appUpdates;

  /// No description provided for @marketingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Marketing Updates'**
  String get marketingUpdates;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get emailNotifications;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date Of Birth'**
  String get dateOfBirth;

  /// No description provided for @accountInfoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account Information have been updated successfully.'**
  String get accountInfoUpdatedSuccessfully;

  /// No description provided for @reachingServerIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues with reaching Tiler servers'**
  String get reachingServerIssues;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @integrationsSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get integrationsSetLocation;

  /// No description provided for @googleCalender.
  ///
  /// In en, this message translates to:
  /// **'Google Calender'**
  String get googleCalender;

  /// No description provided for @passwordsMustMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords must match'**
  String get passwordsMustMatch;

  /// No description provided for @parenthesisLate.
  ///
  /// In en, this message translates to:
  /// **'(Late)'**
  String get parenthesisLate;

  /// No description provided for @failedToAddIntegration.
  ///
  /// In en, this message translates to:
  /// **'Failed to add integration'**
  String get failedToAddIntegration;

  /// No description provided for @unknownProvider.
  ///
  /// In en, this message translates to:
  /// **'Unknown Provider'**
  String get unknownProvider;

  /// No description provided for @manageCalendars.
  ///
  /// In en, this message translates to:
  /// **'Manage calendars'**
  String get manageCalendars;

  /// No description provided for @calendarItems.
  ///
  /// In en, this message translates to:
  /// **'Calendar Items'**
  String get calendarItems;

  /// No description provided for @noCalendarItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No calendar items found'**
  String get noCalendarItemsFound;

  /// No description provided for @calendarItemsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your calendar items will appear here'**
  String get calendarItemsWillAppearHere;

  /// Shows count of active calendars
  ///
  /// In en, this message translates to:
  /// **'{selectedCount} of {totalCount} calendars active'**
  String calendarsActive(int selectedCount, int totalCount);

  /// No description provided for @toggleCalendarsToSync.
  ///
  /// In en, this message translates to:
  /// **'Toggle calendars to sync with Tiler'**
  String get toggleCalendarsToSync;

  /// No description provided for @unknownCalendar.
  ///
  /// In en, this message translates to:
  /// **'Unknown Calendar'**
  String get unknownCalendar;

  /// Status badge showing active count
  ///
  /// In en, this message translates to:
  /// **'{selectedCount} of {totalCount} active'**
  String activeStatusBadge(int selectedCount, int totalCount);

  /// Shows count of integrations
  ///
  /// In en, this message translates to:
  /// **'{count} Integrations'**
  String integrationCount(int count);

  /// No description provided for @errorLoadingCalendarItems.
  ///
  /// In en, this message translates to:
  /// **'Error loading calendar items'**
  String get errorLoadingCalendarItems;

  /// No description provided for @integratedCalendars.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get integratedCalendars;

  /// No description provided for @integrationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get integrationAdd;

  /// No description provided for @timeAndLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time & Location'**
  String get timeAndLocationTitle;

  /// No description provided for @timeAndLocationSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you right now?\nWhat is the time over there?'**
  String get timeAndLocationSubTitle;

  /// No description provided for @timeAndLocationSecondarySubTitle.
  ///
  /// In en, this message translates to:
  /// **'Can we access your location to provide location-\nbased recommendations and notifications?'**
  String get timeAndLocationSecondarySubTitle;

  /// No description provided for @workProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your typical daily routine like, set your work hours'**
  String get workProfileQuestion;

  /// No description provided for @personalProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your ‘me time’ during the week'**
  String get personalProfileQuestion;

  /// No description provided for @grabACoffee.
  ///
  /// In en, this message translates to:
  /// **'Grab a coffee'**
  String get grabACoffee;

  /// No description provided for @recurringTasks.
  ///
  /// In en, this message translates to:
  /// **'Recurring Tasks'**
  String get recurringTasks;

  /// No description provided for @recurringTasksQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are there any specific recurring tasks or activities you want to schedule in Tiler?'**
  String get recurringTasksQuestion;

  /// No description provided for @yourProfession.
  ///
  /// In en, this message translates to:
  /// **'Your Profession?'**
  String get yourProfession;

  /// No description provided for @yourProfessionQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you do?'**
  String get yourProfessionQuestion;

  /// No description provided for @yourProfessionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you do for work'**
  String get yourProfessionHint;

  /// No description provided for @medicalProfessional.
  ///
  /// In en, this message translates to:
  /// **'Medical Professional'**
  String get medicalProfessional;

  /// No description provided for @softwareDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Software Developer'**
  String get softwareDeveloper;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @engineer.
  ///
  /// In en, this message translates to:
  /// **'Engineer'**
  String get engineer;

  /// No description provided for @fieldSalesProfessional.
  ///
  /// In en, this message translates to:
  /// **'Field Sales Professional'**
  String get fieldSalesProfessional;

  /// No description provided for @remoteWorker.
  ///
  /// In en, this message translates to:
  /// **'emote Worker & Digital Nomad'**
  String get remoteWorker;

  /// No description provided for @stayAtHomeParent.
  ///
  /// In en, this message translates to:
  /// **'Stay At Home Parent'**
  String get stayAtHomeParent;

  /// No description provided for @clientAccountManagers.
  ///
  /// In en, this message translates to:
  /// **'Client/Account Managers'**
  String get clientAccountManagers;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @tileSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Tile Suggestions'**
  String get tileSuggestions;

  /// No description provided for @tileSuggestionsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Select tiles that match your routine and let Tiler optimize your schedule'**
  String get tileSuggestionsQuestion;

  /// No description provided for @tileProfiling.
  ///
  /// In en, this message translates to:
  /// **'Tiler is profiling you based on your preferences..'**
  String get tileProfiling;

  /// No description provided for @addPlus.
  ///
  /// In en, this message translates to:
  /// **'Add +'**
  String get addPlus;

  /// No description provided for @personalScheduling.
  ///
  /// In en, this message translates to:
  /// **'Personal scheduling'**
  String get personalScheduling;

  /// No description provided for @workPlanning.
  ///
  /// In en, this message translates to:
  /// **'Work planning'**
  String get workPlanning;

  /// No description provided for @teamCoordination.
  ///
  /// In en, this message translates to:
  /// **'Team coordination'**
  String get teamCoordination;

  /// No description provided for @fieldBaseCoordination.
  ///
  /// In en, this message translates to:
  /// **'Field-base coordination'**
  String get fieldBaseCoordination;

  /// No description provided for @academicScheduling.
  ///
  /// In en, this message translates to:
  /// **'Academic scheduling'**
  String get academicScheduling;

  /// No description provided for @clientManagement.
  ///
  /// In en, this message translates to:
  /// **'Client management'**
  String get clientManagement;

  /// No description provided for @personalOrWork.
  ///
  /// In en, this message translates to:
  /// **'Personal or Work??'**
  String get personalOrWork;

  /// No description provided for @personalOrWorkQuestion.
  ///
  /// In en, this message translates to:
  /// **'What will you be using Tiler for?'**
  String get personalOrWorkQuestion;

  /// No description provided for @enter3chars.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters.'**
  String get enter3chars;

  /// No description provided for @tilesVsBlocks.
  ///
  /// In en, this message translates to:
  /// **'Tiles vs Blocks'**
  String get tilesVsBlocks;

  /// No description provided for @vsTilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Get auto-generated Tiles for your, workouts,\ndeadlines and block out times events that aren\'t\nflexible.'**
  String get vsTilesDescription;

  /// No description provided for @vsBlocksDescription.
  ///
  /// In en, this message translates to:
  /// **'Blocks are fixed time periods reserved for important tiles that must happen at a specific time and date.'**
  String get vsBlocksDescription;

  /// No description provided for @swipeRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe Right>>'**
  String get swipeRight;

  /// No description provided for @swipeRightDescription.
  ///
  /// In en, this message translates to:
  /// **'No more planning from scratch—just swipe\nright, and Tiler fits everything into your\nschedule seamlessly.'**
  String get swipeRightDescription;

  /// No description provided for @googleCalendarAndMore.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar +\nmore calendars'**
  String get googleCalendarAndMore;

  /// No description provided for @googleCalendarAndMoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync your calendars, and let Tiler pull\neverything into one smart timeline.\nNo double booking, no stress'**
  String get googleCalendarAndMoreDescription;

  /// No description provided for @selectSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Select suggestions'**
  String get selectSuggestions;

  /// No description provided for @typeSomething.
  ///
  /// In en, this message translates to:
  /// **'Type something here'**
  String get typeSomething;

  /// Proactive alert for departure time
  ///
  /// In en, this message translates to:
  /// **'Leave in {duration} to arrive on time'**
  String leaveInDurationToArriveOnTime(String duration);

  /// No description provided for @leaveNowToArriveOnTime.
  ///
  /// In en, this message translates to:
  /// **'Leave now to arrive on time!'**
  String get leaveNowToArriveOnTime;

  /// Travel time by driving
  ///
  /// In en, this message translates to:
  /// **'{duration} drive'**
  String durationDrive(String duration);

  /// Travel time by transit
  ///
  /// In en, this message translates to:
  /// **'{duration} transit'**
  String durationTransit(String duration);

  /// Travel time by bike
  ///
  /// In en, this message translates to:
  /// **'{duration} bike'**
  String durationBike(String duration);

  /// Travel time by walking
  ///
  /// In en, this message translates to:
  /// **'{duration} walk'**
  String durationWalk(String duration);

  /// Drive time to destination
  ///
  /// In en, this message translates to:
  /// **'{duration} drive to {destination}'**
  String driveToDestination(String duration, String destination);

  /// Transit time to destination
  ///
  /// In en, this message translates to:
  /// **'{duration} transit to {destination}'**
  String transitToDestination(String duration, String destination);

  /// Bike time to destination
  ///
  /// In en, this message translates to:
  /// **'{duration} bike to {destination}'**
  String bikeToDestination(String duration, String destination);

  /// Walk time to destination
  ///
  /// In en, this message translates to:
  /// **'{duration} walk to {destination}'**
  String walkToDestination(String duration, String destination);

  /// Time to leave by
  ///
  /// In en, this message translates to:
  /// **'Leave by {time}'**
  String leaveByTime(String time);

  /// No description provided for @trafficDetectedReroutingSuggested.
  ///
  /// In en, this message translates to:
  /// **'Traffic detected - rerouting suggested'**
  String get trafficDetectedReroutingSuggested;

  /// Traffic delay in minutes
  ///
  /// In en, this message translates to:
  /// **'Traffic: +{minutes} min delay'**
  String trafficDelayMinutes(String minutes);

  /// No description provided for @heavyTrafficExpected.
  ///
  /// In en, this message translates to:
  /// **'Heavy traffic expected'**
  String get heavyTrafficExpected;

  /// No description provided for @addWithAI.
  ///
  /// In en, this message translates to:
  /// **'Add with AI'**
  String get addWithAI;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// No description provided for @videoMeeting.
  ///
  /// In en, this message translates to:
  /// **'Video Meeting'**
  String get videoMeeting;

  /// No description provided for @sharedWith.
  ///
  /// In en, this message translates to:
  /// **'Shared with'**
  String get sharedWith;

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(String minutes);

  /// Duration in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(String hours, String minutes);

  /// Travel duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String travelDurationMinutes(int minutes);

  /// Travel duration in hours
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String travelDurationHours(int hours);

  /// Travel duration in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String travelDurationHoursMinutes(int hours, int minutes);

  /// Via route name
  ///
  /// In en, this message translates to:
  /// **'via {route}'**
  String travelViaRoute(String route);

  /// Travel mode to destination
  ///
  /// In en, this message translates to:
  /// **' {travelMode} to '**
  String travelModeToDestination(String travelMode);

  /// No description provided for @travelModeDriving.
  ///
  /// In en, this message translates to:
  /// **'drive'**
  String get travelModeDriving;

  /// No description provided for @travelModeWalking.
  ///
  /// In en, this message translates to:
  /// **'walk'**
  String get travelModeWalking;

  /// No description provided for @travelModeBicycling.
  ///
  /// In en, this message translates to:
  /// **'bike'**
  String get travelModeBicycling;

  /// No description provided for @travelModeTransitLower.
  ///
  /// In en, this message translates to:
  /// **'transit'**
  String get travelModeTransitLower;

  /// Compact travel duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String travelDurationCompact(int minutes);

  /// No description provided for @yourDayIsOptimized.
  ///
  /// In en, this message translates to:
  /// **'Your day is optimized.'**
  String get yourDayIsOptimized;

  /// No description provided for @yourDayAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance'**
  String get yourDayAtAGlance;

  /// Total travel time for the day
  ///
  /// In en, this message translates to:
  /// **'{duration} of travel time today.'**
  String totalTravelTimeToday(String duration);

  /// Number of tiles scheduled
  ///
  /// In en, this message translates to:
  /// **'{count} tiles scheduled for today.'**
  String tilesScheduledForToday(int count);

  /// No description provided for @viewRoute.
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get viewRoute;

  /// No description provided for @focusModeChip.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusModeChip;

  /// No description provided for @showRouteChip.
  ///
  /// In en, this message translates to:
  /// **'Show Route'**
  String get showRouteChip;

  /// No description provided for @reOptimizeChip.
  ///
  /// In en, this message translates to:
  /// **'Re-optimize'**
  String get reOptimizeChip;

  /// No description provided for @todayColon.
  ///
  /// In en, this message translates to:
  /// **'Today:'**
  String get todayColon;

  /// Count of tiles and blocks
  ///
  /// In en, this message translates to:
  /// **'{tileCount} tiles, {blockCount} blocks'**
  String tilesBlocksCount(int tileCount, int blockCount);

  /// No description provided for @timeSavedColon.
  ///
  /// In en, this message translates to:
  /// **'Time saved:'**
  String get timeSavedColon;

  /// No description provided for @travelTimeColon.
  ///
  /// In en, this message translates to:
  /// **'Travel time:'**
  String get travelTimeColon;

  /// Travel time with duration
  ///
  /// In en, this message translates to:
  /// **'Travel time: {duration}'**
  String travelTime(String duration);

  /// Duration in short format
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutesShort(int hours, int minutes);

  /// Duration in hours short format
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHoursShort(int hours);

  /// Duration in minutes short format
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutesShort(int minutes);

  /// Hour in AM format
  ///
  /// In en, this message translates to:
  /// **'{hour} AM'**
  String hourAm(int hour);

  /// Hour in PM format
  ///
  /// In en, this message translates to:
  /// **'{hour} PM'**
  String hourPm(int hour);

  /// No description provided for @scheduleConflict.
  ///
  /// In en, this message translates to:
  /// **'Schedule Conflict'**
  String get scheduleConflict;

  /// No description provided for @conflictSameTime.
  ///
  /// In en, this message translates to:
  /// **'\"{tile1}\" and \"{tile2}\" are scheduled at the same time'**
  String conflictSameTime(String tile1, String tile2);

  /// No description provided for @conflictDuring.
  ///
  /// In en, this message translates to:
  /// **'\"{tile1}\" is during \"{tile2}\" ({overlap} overlap)'**
  String conflictDuring(String tile1, String tile2, String overlap);

  /// No description provided for @conflictOverlaps.
  ///
  /// In en, this message translates to:
  /// **'\"{tile1}\" overlaps with \"{tile2}\" by {overlap}'**
  String conflictOverlaps(String tile1, String tile2, String overlap);

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @conflictOverlapMinutes.
  ///
  /// In en, this message translates to:
  /// **'Conflict: {minutes}m overlap'**
  String conflictOverlapMinutes(int minutes);

  /// No description provided for @oneScheduleConflict.
  ///
  /// In en, this message translates to:
  /// **'1 Schedule Conflict'**
  String get oneScheduleConflict;

  /// No description provided for @countScheduleConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count} Schedule Conflicts'**
  String countScheduleConflicts(int count);

  /// No description provided for @tapToReviewAndResolve.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and resolve'**
  String get tapToReviewAndResolve;

  /// No description provided for @countConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts'**
  String countConflicts(int count);

  /// No description provided for @tapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get tapToExpand;

  /// No description provided for @conflictingTiles.
  ///
  /// In en, this message translates to:
  /// **'{count} Conflicting Tiles'**
  String conflictingTiles(int count);

  /// No description provided for @totalOverlap.
  ///
  /// In en, this message translates to:
  /// **'Total overlap: {duration}'**
  String totalOverlap(String duration);

  /// No description provided for @autoResolve.
  ///
  /// In en, this message translates to:
  /// **'Auto-resolve'**
  String get autoResolve;

  /// No description provided for @untitledTile.
  ///
  /// In en, this message translates to:
  /// **'Untitled Tile'**
  String get untitledTile;

  /// No description provided for @untitledEvent.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledEvent;

  /// No description provided for @extendedEventSingular.
  ///
  /// In en, this message translates to:
  /// **'1 Extended Event'**
  String get extendedEventSingular;

  /// No description provided for @extendedEventsPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} Extended Events'**
  String extendedEventsPlural(int count);

  /// No description provided for @extendedEventsTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view all-day and long events'**
  String get extendedEventsTapToView;

  /// No description provided for @extendedEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Extended Events'**
  String get extendedEventsTitle;

  /// No description provided for @extendedEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event over 16 hours} other{{count} events over 16 hours}}'**
  String extendedEventsSubtitle(int count);

  /// No description provided for @todaysRoute.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Route'**
  String get todaysRoute;

  /// No description provided for @noLocationsToday.
  ///
  /// In en, this message translates to:
  /// **'No locations today'**
  String get noLocationsToday;

  /// No description provided for @addLocationsToSeeTodaysRoute.
  ///
  /// In en, this message translates to:
  /// **'Add locations to your tiles to see your daily route'**
  String get addLocationsToSeeTodaysRoute;

  /// No description provided for @countStops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String countStops(int count);

  /// No description provided for @routeOptimized.
  ///
  /// In en, this message translates to:
  /// **'Route optimized'**
  String get routeOptimized;

  /// No description provided for @savedTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Saved {duration} of travel time'**
  String savedTravelTime(String duration);

  /// No description provided for @firstStop.
  ///
  /// In en, this message translates to:
  /// **'First Stop'**
  String get firstStop;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @arriveBy.
  ///
  /// In en, this message translates to:
  /// **'Arrive by {time}'**
  String arriveBy(String time);

  /// No description provided for @fromPreviousStop.
  ///
  /// In en, this message translates to:
  /// **'from previous stop'**
  String get fromPreviousStop;

  /// No description provided for @viewTile.
  ///
  /// In en, this message translates to:
  /// **'View Tile'**
  String get viewTile;

  /// No description provided for @editTile.
  ///
  /// In en, this message translates to:
  /// **'Edit Tile'**
  String get editTile;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// No description provided for @noLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocationAvailable;

  /// No description provided for @seeTodaysRoute.
  ///
  /// In en, this message translates to:
  /// **'See Today\'s Route'**
  String get seeTodaysRoute;

  /// No description provided for @joinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get joinMeeting;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @hideActions.
  ///
  /// In en, this message translates to:
  /// **'Hide actions'**
  String get hideActions;

  /// No description provided for @pendingRsvpSingular.
  ///
  /// In en, this message translates to:
  /// **'1 Event Needs Response'**
  String get pendingRsvpSingular;

  /// No description provided for @pendingRsvpPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} Events Need Response'**
  String pendingRsvpPlural(int count);

  /// No description provided for @pendingRsvpHappeningNow.
  ///
  /// In en, this message translates to:
  /// **'Happening now - respond to join'**
  String get pendingRsvpHappeningNow;

  /// No description provided for @pendingRsvpStartingSoon.
  ///
  /// In en, this message translates to:
  /// **'Starting soon - respond now'**
  String get pendingRsvpStartingSoon;

  /// No description provided for @pendingRsvpWithinHour.
  ///
  /// In en, this message translates to:
  /// **'Starting within an hour'**
  String get pendingRsvpWithinHour;

  /// No description provided for @pendingRsvpUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming - tap to respond'**
  String get pendingRsvpUpcoming;

  /// No description provided for @pendingRsvpTapToReview.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and respond'**
  String get pendingRsvpTapToReview;

  /// No description provided for @pendingRsvpTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Responses'**
  String get pendingRsvpTitle;

  /// No description provided for @pendingRsvpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event awaiting your response} other{{count} events awaiting your response}}'**
  String pendingRsvpSubtitle(int count);

  /// No description provided for @pendingRsvpUrgent.
  ///
  /// In en, this message translates to:
  /// **'Starting Soon'**
  String get pendingRsvpUrgent;

  /// No description provided for @pendingRsvpLater.
  ///
  /// In en, this message translates to:
  /// **'Later Today & Upcoming'**
  String get pendingRsvpLater;

  /// No description provided for @declinedRsvpSingular.
  ///
  /// In en, this message translates to:
  /// **'1 Declined Event'**
  String get declinedRsvpSingular;

  /// No description provided for @declinedRsvpPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} Declined Events'**
  String declinedRsvpPlural(int count);

  /// No description provided for @declinedRsvp.
  ///
  /// In en, this message translates to:
  /// **'Declined Events'**
  String get declinedRsvp;

  /// No description provided for @rsvpMixedOnePending.
  ///
  /// In en, this message translates to:
  /// **'1 Pending, {declinedCount} Declined'**
  String rsvpMixedOnePending(int declinedCount);

  /// No description provided for @rsvpMixedOneDeclined.
  ///
  /// In en, this message translates to:
  /// **'{pendingCount} Pending, 1 Declined'**
  String rsvpMixedOneDeclined(int pendingCount);

  /// No description provided for @rsvpMixed.
  ///
  /// In en, this message translates to:
  /// **'{pendingCount} Pending, {declinedCount} Declined'**
  String rsvpMixed(int pendingCount, int declinedCount);

  /// No description provided for @rsvpNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs Response'**
  String get rsvpNeedsAction;

  /// No description provided for @rsvpTentative.
  ///
  /// In en, this message translates to:
  /// **'Tentative'**
  String get rsvpTentative;

  /// No description provided for @rsvpAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get rsvpAccepted;

  /// No description provided for @rsvpDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get rsvpDeclined;

  /// No description provided for @unableToOpenLinkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link: {link}'**
  String unableToOpenLinkError(String link);

  /// No description provided for @leaveNow.
  ///
  /// In en, this message translates to:
  /// **'Leave now!'**
  String get leaveNow;

  /// Short label for departure alert
  ///
  /// In en, this message translates to:
  /// **'Leave in {minutes} min'**
  String leaveInMinutes(int minutes);

  /// Title when multiple alerts are active
  ///
  /// In en, this message translates to:
  /// **'{count} alerts'**
  String multipleAlertsTitle(int count);

  /// No description provided for @alertChipLeaveNow.
  ///
  /// In en, this message translates to:
  /// **'Leave Now'**
  String get alertChipLeaveNow;

  /// Chip label for travel alert with minutes
  ///
  /// In en, this message translates to:
  /// **'Leave {minutes}m'**
  String alertChipLeaveIn(int minutes);

  /// Chip label for schedule conflicts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Conflict} other{{count} Conflicts}}'**
  String alertChipConflicts(int count);

  /// Chip label for extended/all-day events
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 All-Day} other{{count} All-Day}}'**
  String alertChipAllDay(int count);

  /// Chip label for pending RSVP responses
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 RSVP} other{{count} RSVPs}}'**
  String alertChipRsvp(int count);

  /// Status when event is accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Status when event is declined
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// Prompt to respond to calendar event
  ///
  /// In en, this message translates to:
  /// **'Respond to {calendarSource}'**
  String respondToCalendar(String calendarSource);

  /// Default label for unknown calendar source
  ///
  /// In en, this message translates to:
  /// **'Calendar invite'**
  String get unknown;

  /// Message shown when loading schedule for previous days
  ///
  /// In en, this message translates to:
  /// **'Loading previous days...'**
  String get loadingPreviousDays;

  /// Message shown when loading schedule for upcoming days
  ///
  /// In en, this message translates to:
  /// **'Loading upcoming days...'**
  String get loadingUpcomingDays;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
