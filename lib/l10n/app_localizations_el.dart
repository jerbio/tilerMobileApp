// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Προσθήκη';

  @override
  String get setupCustomRestrictions => 'Ρύθμιση προσαρμοσμένων περιορισμών';

  @override
  String get customRestrictionTitle => 'Προσαρμοσμένοι περιορισμοί';

  @override
  String get customRestrictionHeader => 'Ρύθμιση προσαρμοσμένων περιορισμών';

  @override
  String get customRestrictionHeaderDescription =>
      'Επιλέξτε πότε θέλετε να ολοκληρώσετε αυτό το καθήκον.';

  @override
  String get day => 'Ημέρα';

  @override
  String get hour => 'Ώρα';

  @override
  String get min => 'Λεπτά';

  @override
  String get monday => 'Δευτέρα';

  @override
  String get tuesday => 'Τρίτη';

  @override
  String get wednesday => 'Τετάρτη';

  @override
  String get thursday => 'Πέμπτη';

  @override
  String get friday => 'Παρασκευή';

  @override
  String get saturday => 'Σάββατο';

  @override
  String get sunday => 'Κυριακή';

  @override
  String get duration => 'Διάρκεια';

  @override
  String get durationStar => 'Διάρκεια*';

  @override
  String get addTile => 'Προσθήκη πλακιδίου';

  @override
  String get defer => 'Αναβολή';

  @override
  String get deferAll => 'Αναβολή όλων';

  @override
  String get procrastinating => 'Αναβολή';

  @override
  String get forecast => 'Πρόβλεψη';

  @override
  String get whenQ => 'Πότε;';

  @override
  String get loading => 'Φόρτωση';

  @override
  String get loadingPrediction => 'Φόρτωση πρόβλεψης';

  @override
  String get address => 'Διεύθυνση';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get nickName => 'Ψευδώνυμο';

  @override
  String get deadline_anytime => 'Θεωρητικό (Όποτε)';

  @override
  String get selectADeadline => 'Επιλογή θεώρητου';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get tileName => 'Όνομα πλακιδίου';

  @override
  String get tileNameStar => 'Όνομα πλακιδίου*';

  @override
  String get starAreRequired => ' * τα πεδία είναι υποχρεωτικά';

  @override
  String get howManyTimes => 'Πόσες φορές';

  @override
  String get once => 'Μία φορά';

  @override
  String get weekdaysAndWorkHours => 'Διημερίδες και ώρες εργασίας';

  @override
  String get weekend => 'Σαββατοκύριακο';

  @override
  String get anytime => 'Όποτε';

  @override
  String get repetition => 'Επανάληψη';

  @override
  String get reminder => 'Θέριμψη';

  @override
  String get restriction => 'Περιορισμός';

  @override
  String get username => 'Όνομα χρήστη';

  @override
  String get usernameOrEmail => 'Όνομα χρήστη ή Email';

  @override
  String get password => 'Κωδικός';

  @override
  String get email => 'Email';

  @override
  String get back => 'Πίσω';

  @override
  String get confirmPassword => 'Επιβεβαίωση κωδικού';

  @override
  String get passwordIsRequired => 'Ο κωδικός είναι υποχρεωτικός';

  @override
  String get emailIsRequired => 'Το email είναι υποχρεωτικό';

  @override
  String get fieldIsRequired => 'Το πεδίο είναι υποχρεωτικό';

  @override
  String get signingIn => 'Σύνδεση';

  @override
  String get signInWithEmailCode => 'Σύνδεση με κωδικό email';

  @override
  String get sendAccessCode => 'Αποστολή κωδικού πρόσβασης';

  @override
  String get continueBtn => 'Συνέχεια';

  @override
  String get usePasswordInstead => 'Χρήση κωδικού αντί για αυτόν';

  @override
  String get useAccessCodeInstead => 'Χρήση κωδικού πρόσβασης αντί για αυτόν';

  @override
  String get registeringUser => 'Εγγραφή χρήστη';

  @override
  String get sendVerificationCode => 'Αποστολή κωδικού επαλήθευσης';

  @override
  String get verificationCodeSent =>
      'Το κωδικό επαλήθευσης εστάλη στο email σας.';

  @override
  String get verificationCode => 'Κωδικό επαλήθευσης';

  @override
  String get verifyCode => 'Επαλήθευση κωδικού';

  @override
  String get resendCode => 'Επανεκκίνηση κωδικού';

  @override
  String get verifyingCode => 'Επαλήθευση κωδικού';

  @override
  String get invalidVerificationCode =>
      'Μη έγκυρο ή ληγμένο κωδικό επαλήθευσης.';

  @override
  String get accessCodeRequiresEmail =>
      'Η σύνδεση με κωδικό πρόσβασης απαιτεί διεύθυνση email.';

  @override
  String get emailCodeInstructions =>
      'Εισάγετε το email σας και θα σας στείλουμε ένα κωδικό επαλήθευσης.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Εισάγετε τον κωδικό επαλήθευσης που εστάλη στο $email.';
  }

  @override
  String get confirmPasswordRequired => 'Απαιτείται επιβεβαίωση κωδικού';

  @override
  String get passwordsDontMatch => 'Ο κωδικός και η επιβεβαίωση δεν ταιριάζουν';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'Ο κωδικός πρέπει να έχει τουλάχιστον 7 χαρακτήρες';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'Ο κωδικός πρέπει να περιέχει ένα κεφαλαίο γράμμα';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'Ο κωδικός πρέπει να περιέχει ένα πεζό γράμμα';

  @override
  String get passwordNeedsToHaveNumber =>
      'Ο κωδικός πρέπει να περιέχει ένα ψηφίο';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'Ο κωδικός πρέπει να περιέχει τουλάχιστον 1 ειδικό χαρακτήρα';

  @override
  String get enableLocations => 'Ενεργοποίηση άδειας τοποθεσίας';

  @override
  String get noMatchWasFound => 'Δεν βρέθηκε αντίστοιχο';

  @override
  String get atLeastThreeLettersForLookup =>
      '...Ο Tiler χρειάζεται τρεις χαρακτήρες για αναζήτηση';

  @override
  String get searchSourceBadgeTiler => 'Tiler';

  @override
  String get searchSourceBadgeGoogle => 'Google';

  @override
  String get searchSourceBadgeMicrosoft => 'Microsoft';

  @override
  String searchConnectedAccount(String account) {
    return 'via $account';
  }

  @override
  String get searchPartialFailureWarning =>
      'Some calendars couldn\'t be searched.';

  @override
  String get searchUnavailableMessage =>
      'Search is temporarily unavailable. Please try again.';

  @override
  String get searchRetry => 'Retry';

  @override
  String get noLocationMatchWasFound => 'Δεν βρέθηκε τοποθεσία';

  @override
  String get noLocation => 'Χωρίς τοποθεσία';

  @override
  String get clearedColon => 'Επεξεργασία: ';

  @override
  String get complete => 'Ολοκλήρωση';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get cancel => 'Άκυρο';

  @override
  String get now => 'Τώρα';

  @override
  String get color => 'Χρώμα';

  @override
  String get pickAColor => 'Επιλογή χρώματος';

  @override
  String get pause => 'Παύση';

  @override
  String get resume => 'Συνέχεια';

  @override
  String get play => 'Αναπαραγωγή';

  @override
  String get successfullyPaused => 'Παύση επιτυχής';

  @override
  String get successfullyResumed => 'Συνέχεια επιτυχής';

  @override
  String get successfullyCompleted => 'Ολοκλήρωση επιτυχής';

  @override
  String get completed => 'Ολοκληρώθηκε';

  @override
  String get deleted => 'Διαγράφηκε';

  @override
  String get scheduled => 'Προγραμματίστηκε';

  @override
  String get movedUpToNow => 'Μετακίνηση προς το τώρα';

  @override
  String get pausing => 'Παύση';

  @override
  String get resuming => 'Συνέχεια';

  @override
  String get movingUp => 'Μετακίνηση πλακιδίου';

  @override
  String get completing => 'Ολοκλήρωση';

  @override
  String get deleting => 'Διαγραφή';

  @override
  String get deleteBlockConfirming => 'Διαγραφή αυτού του μπλοκ...';

  @override
  String get deleteTileConfirming => 'Διαγραφή αυτού του πλακιδίου...';

  @override
  String get deleteNow => 'Διαγραφή τώρα';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Αυτό θα τα διαγράψει και από το Google Calendar';

  @override
  String get deleteOutlookWarning =>
      '⚠️ Αυτό θα τα διαγράψει και από το Outlook';

  @override
  String get previously => 'Πρώτα';

  @override
  String get upcoming => 'Επερχόμενα';

  @override
  String get failedToSendRequest => 'Αποτυχία αποστολής αίτησης';

  @override
  String get revise => 'Αναθεώρηση';

  @override
  String get revisingSchedule => 'Αναθεώρηση προγράμματος';

  @override
  String get procrastinateBlockOut => 'Διάλειμμα πλακιδίου';

  @override
  String get lunchBreak => 'Διάλειμμα μεσημεριανού';

  @override
  String get coffeeBreak => 'Διάλειμμα καφέ';

  @override
  String get morningBreak => 'Πρωινό διάλειμμα';

  @override
  String get afternoonBreak => 'Μεσημβρινό διάλειμμα';

  @override
  String get freeTime => 'Ελεύθερος χρόνος';

  @override
  String get freeSlotHeader => 'Ελεύθερος χρόνος';

  @override
  String get freeSlotNow => 'Ελεύθερο τώρα';

  @override
  String get quickBreak => 'Γρήγορο διάλειμμα';

  @override
  String get shortBreak => 'Μικρό διάλειμμα';

  @override
  String get blockedTime => 'Αποκλεισμένος χρόνος';

  @override
  String get start => 'Εναρξη';

  @override
  String get end => 'Λήξη';

  @override
  String get deadline => 'Θεώρητο';

  @override
  String get split => 'Διαίρεση';

  @override
  String get timeBlocks => 'Χρονικά μπλοκ';

  @override
  String get swipeRightToTileIt => 'Σκούρψτε δεξιά για να το πλακιδιώσετε';

  @override
  String get failedToReviseScheduleRequest =>
      'Αποτυχία αιτήματος αναθεώρησης προγράμματος';

  @override
  String get daily => 'Ημερήσια';

  @override
  String get weekly => 'Εβδομαδιαία';

  @override
  String get monthly => 'Μηνιαία';

  @override
  String get yearly => 'Ετήσια';

  @override
  String get none => 'Κανένα';

  @override
  String get noneNotificationCategory => 'Προεπιλογή';

  @override
  String get nextTileNotificationCategory => 'Επόμενο πλακίδιο';

  @override
  String get userSetReminderNotificationCategory => 'Θέριμψη χρήστη';

  @override
  String get depatureTimeNotificationCategory => 'Ώρα αναχώρησης';

  @override
  String get tile => 'Πλακίδιο';

  @override
  String get appointment => 'Μπλοκ';

  @override
  String startingAtTime(String time) {
    return 'Ξεκινά στις $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Τερματίζει στις $time';
  }

  @override
  String get startsInTenMinutes => 'Ξεκινά σε δέκα λεπτά';

  @override
  String get endsInTenMinutes => 'Τερματίζει σε πέντε λεπτά';

  @override
  String startsInDuration(String duration) {
    return 'Ξεκινά σε $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 Το $tileName ολοκληρώνεται σύντομα';
  }

  @override
  String get home => 'Σπίτι';

  @override
  String get work => 'Εργασία';

  @override
  String get googleLogo => 'Λόγκο Google';

  @override
  String get edit => 'Επεξεργασία';

  @override
  String get workProfileHours => 'Ώρες εργασίας';

  @override
  String get personalHours => 'Προσωπικές ώρες';

  @override
  String get setWorkProfileHours => 'Ορισμός ωρών εργασίας';

  @override
  String get setPersonalHours => 'Ορισμός προσωπικών ωρών';

  @override
  String get customHours => 'Προσαρμοσμένες ώρες';

  @override
  String get logout => 'Αποσύνδεση';

  @override
  String get noteEllipsis => 'Σημείωση...';

  @override
  String get tapToCreateNewTile => 'Αγγίξτε για να δημιουργήσετε νέο πλακίδιο';

  @override
  String get emptyDayHeaderLine1 => 'Κανένα σχέδιο ακόμα.';

  @override
  String get emptyDayFooterLine1 => 'Ξεκινήστε σε δευτερόλεπτα';

  @override
  String get emptyDayFooterLine2 =>
      'εισάγετε ημερολόγια ή δημιουργήστε πλακίδια.';

  @override
  String get emptyDayOr => 'ή';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Εισαγωγή Google Calendar';

  @override
  String get suggestions => 'Προτάσεις';

  @override
  String get progress => 'Πρόοδος';

  @override
  String get youNeedToLeaveIn => 'Πρέπει να φύγετε σε';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Πρέπει να φύγετε σε $duration';
  }

  @override
  String durationLate(String duration) {
    return 'Καθυστερεί $duration';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Εκτράπηκε $duration πριν';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Ολοκληρώθηκε $duration πριν';
  }

  @override
  String durationLeft(String duration) {
    return 'Απομένουν $duration';
  }

  @override
  String get issuesConnectingToTiler => 'Προβλήματα σύνδεσης με τον Tiler';

  @override
  String completedCount(String count) {
    return 'Ολοκληρώθηκαν ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Διαγράφηκαν ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Πλακίδια απομένουν ($count)';
  }

  @override
  String countTile(String count) {
    return '$count πλακίδια';
  }

  @override
  String numberOfTilesSelected(String number) {
    return 'Επιλέχθηκαν $number πλακίδια';
  }

  @override
  String get completeTiles => 'Ολοκλήρωση πλακιδίων';

  @override
  String get thisFitsInYourSchedule => 'Τα χωράει στο πρόγραμμα σας.';

  @override
  String get warningColon => 'Προσοχή:';

  @override
  String get oneEventAtRisk => '1 γεγονός σε κίνδυνο';

  @override
  String countEventAtRisk(String number) {
    return '$number γεγονότα σε κίνδυνο';
  }

  @override
  String get oneConflict => '1 Συγκρούση';

  @override
  String countConflict(String number) {
    return '$number Συγκρούσεις';
  }

  @override
  String get create => 'Δημιουργία';

  @override
  String get thisEventWouldCause => 'Αυτό το γεγονός θα προκαλούσε';

  @override
  String errorMessage(String message) {
    return 'Σφάλμα: $message';
  }

  @override
  String get unScheduledTiles => 'Μη προγραμματισμένα πλακίδια';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number μη προγραμματισμένα πλακίδια';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number περισσότεροι';
  }

  @override
  String get unScheduled => 'Μη προγραμματισμένα';

  @override
  String get allScheduled => 'Όλα προγραμματισμένα';

  @override
  String get getOnIt => 'Ξεκινήστε';

  @override
  String get done => 'Ολοκλήρωση';

  @override
  String get late => 'Καθυστέρηση';

  @override
  String get onTime => 'Στις καθορισμένες ώρες';

  @override
  String get todayStatusPlacedTitle => 'Τοποθετήθηκε επιτυχώς';

  @override
  String get todayStatusAttentionTitle => 'Χρειάζεται προσοχή';

  @override
  String get todayStatusLateTitle => 'Καθυστέρηση';

  @override
  String get todayStatusAttentionHelper =>
      'Δεν μπόρεσαν να χωρέσουν στον διαθέσιμο χρόνο σήμερα.';

  @override
  String get todayStatusLateHelper =>
      'Ο χρόνος μετακίνησης ανάμεσα σε αυτά και στα γύρω πλακίδια σημαίνει ότι δεν μπορείτε να φτάσετε εγκαίρως.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count πλακίδια',
      one: '1 πλακίδιο',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Πλακίδια ολοκληρωμένα',
      one: 'Πλακίδιο ολοκληρωμένο',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Χρειάζεται προσοχή';

  @override
  String get todayStatusTilesRunningLate => 'Καθυστέρηση';

  @override
  String get todayStatusEverythingOnTrack => 'Όλα σύμφωνα με το πρόγραμμα';

  @override
  String get todayStatusEverythingElseOnTrack =>
      'Τα υπόλοιπα σύμφωνα με το πρόγραμμα';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Κανένα προγραμματισμένο πλακίδιο δεν καθυστερεί.';

  @override
  String get todayStatusClearDay => 'Η μέρα σας είναι ελεύθερη.';

  @override
  String get todayStatusPreviewCta => 'Προεπισκόπηση βελτιωμένου προγράμματος';

  @override
  String get todayStatusPreviewLoading => 'Προετοιμασία προεπισκόπησης…';

  @override
  String get todayStatusPreviewUnavailable =>
      'Δεν ήταν δυνατή η δημιουργία της προεπισκόπησης. Το πρόγραμμα σας παραμένει χωρίς αλλαγές.';

  @override
  String get todayStatusUntitledTile => 'Πλακίδιο χωρίς τίτλο';

  @override
  String get todayStatusShowAll => 'Εμφάνιση όλων';

  @override
  String todayStatusExpandSection(String section) {
    return 'Ανάπτυξη $section';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return 'Σύμπτυξη $section';
  }

  @override
  String get todayStatusReasonDueToday => 'Πρόθεσμο σήμερα';

  @override
  String get todayStatusReasonNoOpenSlot => 'Δεν υπάρχει ελεύθερη ώρα';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'Η μετακίνηση το καθιστά αδύνατο';

  @override
  String get todayStatusReasonOutsideHours => 'Εκτός των διαθεσίμων ωρών';

  @override
  String get todayStatusReasonDependencyBlocked => 'Αναμονή για άλλο πλακίδιο';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Χρειάζεται $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Χρειάζεται την απόφασή σας';

  @override
  String get todayStatusReasonUnknown => 'Δεν χωρέσει';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count σεάνς',
      one: '1 σεάνς',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Επιλογή πλακιδίων';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Ανάπτυξη των σεάνς του $title';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Σύμπτυξη των σεάνς του $title';
  }

  @override
  String get analysis => 'Ανάλυση';

  @override
  String get noDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα';

  @override
  String get sleep => 'Ύπνος';

  @override
  String get overview => 'Σύνοψη';

  @override
  String get driveTime => 'Χρόνος οδήγησης';

  @override
  String get signUpWithGoogle => 'Σύνδεση με το Google';

  @override
  String get signUpWithApple => 'Σύνδεση με το Apple';

  @override
  String get signUpWithMicrosoft => 'Σύνδεση με το Microsoft';

  @override
  String get signIn => 'Σύνδεση';

  @override
  String get signUp => 'Εγγραφή';

  @override
  String get invalidUsernameOrPassword => 'Μη έγκυρο όνομα χρήστη ή κωδικό';

  @override
  String get noInternetConnection => 'Χωρίς σύνδεση στο διαδίκτυο';

  @override
  String get oneHour => '1 ώρα';

  @override
  String countHours(String count) {
    return '$count ώρες';
  }

  @override
  String get oneMinute => '1 λεπτό';

  @override
  String countMinutes(String count) {
    return '$count λεπτά';
  }

  @override
  String countDays(String count) {
    return '$count ημέρες';
  }

  @override
  String lateDate(String date) {
    return 'Καθυστέρηση ($date)';
  }

  @override
  String get custom => 'Προσαρμογή';

  @override
  String get allowAccessDescription =>
      'Ο Tiler συλλέγει δεδομένα τοποθεσίας για να επιτρέπει αποτελεσματικό προγραμματισμό πλακιδίων και ραντεβού. \nΤα δεδομένα σας παραμένουν ιδιωτικά και χρησιμοποιούνται μόνο για αυτόν τον σκοπό.';

  @override
  String get allowLocationAccessQ => 'Να επιτραπεί η πρόσβαση τοποθεσίας;';

  @override
  String get allow => 'Επιτρέπεται';

  @override
  String get deny => 'Απόρριψη';

  @override
  String get afternoon => 'Μεσημέρι';

  @override
  String get evening => 'Βράδυ';

  @override
  String get night => 'Νύχτα';

  @override
  String get morningAndAfternoon => 'Πρωί & Μεσημέρι';

  @override
  String get afternoonAndEvening => 'Μεσημέρι & Βράδυ';

  @override
  String get lateEvening => 'Αργό βράδυ';

  @override
  String get prediction => 'Πρόβλεψη';

  @override
  String get softDeadline => 'Ελαφρύ όριο';

  @override
  String get location => 'Τοποθεσία';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Διαγραφή Λογαριασμού';

  @override
  String get deleteYourTilerAccountQ => 'Διαγραφή Λογαριασμού;';

  @override
  String get no => 'Όχι';

  @override
  String get dismiss => 'Απόρριψη';

  @override
  String get forgetPassword => 'Ξεχάσατε κωδικό';

  @override
  String get forgotPasswordBtn => 'Ξεχάσατε κωδικό;';

  @override
  String get resetPassword => 'Επαναφορά κωδικού';

  @override
  String get reset => 'Επαναφορά';

  @override
  String lookingUp(String text) {
    return 'Αναζήτηση $text';
  }

  @override
  String get lowPriorityTrunc => 'Χαμηλή';

  @override
  String get mediumPriorityTrunc => 'Μέτρια';

  @override
  String get highPriorityTrunc => 'Υψηλή';

  @override
  String failedToAddGoogleCalendar(String email) {
    return 'Αποτυχία προσθήκης $email';
  }

  @override
  String deletedCalendar(String email) {
    return 'Διαγράφηκε η ατζέντα $email';
  }

  @override
  String get loadingIntegrations => 'Φόρτωση ολοκληρώσεων';

  @override
  String get noThirdPartyIntegtions => 'Κανένας ατζέντα τρίτων';

  @override
  String get addGoogleCalendar => 'Προσθήκη Google Calendar';

  @override
  String get integrations => 'Ολοκληρώσεις';

  @override
  String get integrateOtherCalendars => 'Ολοκλήρωση με ατζέντες τρίτων';

  @override
  String get clear => 'Σβήσιμο';

  @override
  String get next => 'Επόμενο';

  @override
  String get previous => 'Προηγούμενο';

  @override
  String get skip => 'Παράλειψη';

  @override
  String get morningPerson => '🌅 Πρωινός τύπος';

  @override
  String get morning => 'Πρωί';

  @override
  String get middayPerson => '🌞 Τύπος μεσημβρινής ώρας';

  @override
  String get nightPerson => '🌃 Νυχτερινός τύπος';

  @override
  String get enterAddress => 'Εισάγετε τη διεύθυνσή σας';

  @override
  String get primaryLocationQuestion =>
      'Ποια είναι η κύρια τοποθεσία σας για εργασία ή μελέτη;';

  @override
  String get useDeviceLocation => 'Χρήση της τοποθεσίας της συσκευής μου';

  @override
  String get energyLevelDescriptionQuestion =>
      'Πώς θα περιέγραφε τις στάθμες ενέργειάς σας καθ\' όλη τη διάρκεια της ημέρας;';

  @override
  String get incompleteRequest => 'Δεν στάληκε πλήρες αίτημα';

  @override
  String get addContact => 'Προσθήκη επαφής';

  @override
  String get invalidContactFormat => 'Μη έγκυρο email ή αριθμός τηλεφώνου';

  @override
  String deadlineTime(String time) {
    return 'Θεώρητο: $time';
  }

  @override
  String get accept => 'Αποδοχή';

  @override
  String get decline => 'Απόρριψη';

  @override
  String get preview => 'Προεπισκόπηση';

  @override
  String get addTilette => 'Προσθήκη Tilette';

  @override
  String get tileShareName => 'Όνομα κοινοποίησης πλακιδίου';

  @override
  String get tileShare => 'Κοινοποίηση πλακιδίου';

  @override
  String get update => 'Ενημέρωση';

  @override
  String get noDesignatedTiles => 'Κανένα καθορισμένο πλακίδιο';

  @override
  String get noTileCluster => 'Δεν δημιουργήθηκε κοινόχρηστο πλακίδιο';

  @override
  String get errorLoadingTilelist => 'Σφάλμα φόρτωσης λίστας πλακιδίων';

  @override
  String get failedToLoadTileShareCluster =>
      'Αποτυχία φόρτωσης συλλογής κοινοποίησης πλακιδίου';

  @override
  String get missingTileShareCluster => 'Λείπει συλλογή κοινοποίησης πλακιδίου';

  @override
  String get outBound => 'Εξερχόμενο';

  @override
  String get inBound => 'Εισερχόμενο';

  @override
  String get multiShare => 'Πολυκοινοποίηση';

  @override
  String get errorOccurred => 'Παρουσιάστηκε σφάλμα!!\nΠροσπαθήστε ξανά.';

  @override
  String get authenticationIssues => 'Προβλήματα με την πιστοποίηση.';

  @override
  String get userIsNotAuthenticated => 'Ο χρήστης δεν έχει πιστοποιηθεί.';

  @override
  String get responseContentError =>
      'Η απόκριση δεν περιέχει το αναμενόμενο περιεχόμενο.';

  @override
  String get responseHandlingError => 'Αποτυχία επεξεργασίας της απόκρισης.';

  @override
  String get today => 'Σήμερα';

  @override
  String get yesterday => 'Χθες';

  @override
  String get tomorrow => 'Αύριο';

  @override
  String get travel => 'Ταξίδι';

  @override
  String numberOfDayForecast(String number) {
    return 'Πρόβλεψη $number ημερών';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Αποτυχία λήψης προεπισκόπησης';

  @override
  String get noDriving => 'Χωρίς οδήγηση';

  @override
  String get tileShareNoteEllipsis => 'Σημείωση...';

  @override
  String get hi => 'Γεια';

  @override
  String get welcome => 'Καλώς ορίσατε';

  @override
  String get passwordCreationMessagePart1 =>
      'Δημιουργήστε έναν ισχυρό, μοναδικό κωδικό με';

  @override
  String get passwordConditionMinLength => 'τουλάχιστον έξι χαρακτήρες';

  @override
  String get passwordCreationMessageIncluding => ', συμπεριλαμβανομένων';

  @override
  String get passwordConditionUppercaseLetters => 'κεφαλαίων γραμμάτων';

  @override
  String get passwordConditionLowercaseLetters => 'πεζών γραμμάτων';

  @override
  String get passwordConditionNumbers => 'ψηφίων';

  @override
  String get passwordConditionSpecialCharacter => 'ενός ειδικού χαρακτήρα';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', και';

  @override
  String get nonViableTimeSlot => 'Κανένα βιώσιμο χρονικό διάστημα';

  @override
  String numberAm(String number) {
    return '$numberπμ';
  }

  @override
  String numberPm(String number) {
    return '$numberμμ';
  }

  @override
  String get dayCast => 'DayCast';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get selectWeek => 'Επιλογή εβδομάδας';

  @override
  String get selectYear => 'Επιλογή έτους';

  @override
  String get retrievingDataIssue => 'Προβλήμα με την ανάκτηση δεδομένων';

  @override
  String get recurring => 'Επαναλαμβανόμενο';

  @override
  String get nonRecurring => 'Μη επαναλαμβανόμενο';

  @override
  String get dailyReurring => 'Ημερήσιο';

  @override
  String get weeklyReurring => 'Εβδομαδιαίο';

  @override
  String get biweeklyReurring => 'Καθεβδομαδιαίο';

  @override
  String get monthlyReurring => 'Μηνιαίο';

  @override
  String get yearlyReurring => 'Ετήσιο';

  @override
  String get ellipsisEmprtNotes => 'Σημειώσεις...';

  @override
  String get tileShareDelete => 'Διαγραφή';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Πλακίδιο πρόβλεψης';

  @override
  String get previewOthers => 'Άλλοι';

  @override
  String get goodMorning => 'Καλημέρα';

  @override
  String get goodDay => 'Καλή μέρα';

  @override
  String get goodEvening => 'Καλησπέρα';

  @override
  String youHaveXBlocks(String count) {
    return 'Έχετε $count μπλοκ που επέρχονται.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Έχετε $count πλακίδια που επέρχονται.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Έχετε $count κοινόχρηστα πλακίδια που επέρχονται.';
  }

  @override
  String countTileShare(String count) {
    return '$count κοινόχρηστα πλακίδια';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Έχετε $blockCount μπλοκ και $tileCount πλακίδια που επέρχονται.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Έχετε $blockCount μπλοκ και $tileShareCount κοινόχρηστα πλακίδια που επέρχονται.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Έχετε $tileCount πλακίδια και $tileShareCount κοινόχρηστα πλακίδια που επέρχονται.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Έχετε $blockCount μπλοκ, $tileCount πλακίδια και $tileShareCount κοινόχρηστα πλακίδια που επέρχονται.';
  }

  @override
  String get noTilesPreview =>
      'Δεν έχετε τίποτα επερχόμενο για τον υπόλοιπο από σήμερα.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Δημιουργία πλακιδίου';

  @override
  String get previewTileForecast => 'Πρόβλεψη';

  @override
  String get previewTileOptions => 'Επιλογές';

  @override
  String get previewTileMore => 'Περισσότερα';

  @override
  String get previewTileShuffle => 'Ανακάτεμα';

  @override
  String get previewTileRevise => 'Αναθεώρηση';

  @override
  String get previewTileDeferAll => 'Αναβολή όλων';

  @override
  String get previewLocationName => 'Τοποθεσία';

  @override
  String get previewTagName => 'Ετικέτα';

  @override
  String get previewClassificationName => 'Κατηγοριοποίηση';

  @override
  String get previewBlockedOut => 'Αποκλεισμένο';

  @override
  String get accountInfo => 'Πληροφορίες λογαριασμού';

  @override
  String get fistName => 'Όνομα';

  @override
  String get lastName => 'Επίθετο';

  @override
  String get tilePreferences => 'Προτιμήσεις πλακιδίου';

  @override
  String get notificationsPreferences => 'Προτιμήσεις ειδοποιήσεων';

  @override
  String get security => 'Ασφάλεια';

  @override
  String get connections => 'Συνδέσεις';

  @override
  String get myLocations => 'Οι τοποθεσίες μου';

  @override
  String get aboutTiler => 'Σχετικά με το Tiler';

  @override
  String get howToUseTiler => 'Πώς να χρησιμοποιήσετε το Tiler';

  @override
  String get darkMode => 'Σκοτεινή λειτουργία';

  @override
  String get setLocation => 'Ορισμός τοποθεσίας';

  @override
  String get connectCalendars => 'Συνδέστε τις ατζέντες σας';

  @override
  String get configure => 'Ρύθμιση';

  @override
  String get comingSoon => 'Έρχεται σύντομα';

  @override
  String get googleCalendar => 'Google Calendar';

  @override
  String get appleCalendar => 'Apple Calendar';

  @override
  String get googleTasks => 'Google Tasks';

  @override
  String get microsoft => 'Microsoft';

  @override
  String get slack => 'Slack';

  @override
  String get addCalendar => 'Προσθήκη ατζέντας';

  @override
  String get calendarConnected => 'Η ατζέντα συνδέθηκε';

  @override
  String get calendarConnectionDeclined => 'Η σύνδεση με την ατζέντα ακυρώθηκε';

  @override
  String get calendarConnectionError =>
      'Δεν ήταν δυνατή η σύνδεση με την ατζέντα σας';

  @override
  String get sleepDuration => 'Διάρκεια ύπνου';

  @override
  String get transportationMethodQuestion => 'Πώς μετακινείστε;';

  @override
  String get defineYourTimeRestrictions =>
      'Ορισμός των χρονικών σας περιορισμών';

  @override
  String get setWorkHours => 'Ορισμός ωρών εργασίας';

  @override
  String get setYourBlockOutHours => 'Ορισμός των ωρών αποκλεισμού σας';

  @override
  String get travelMediumBiking => 'Ποδήλατο';

  @override
  String get travelMediumTransit => 'Μεταφορά';

  @override
  String get travelMediumDriving => 'Οδήγηση';

  @override
  String get travelMediumTransport => 'Μεταφορά';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio λεπτά';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio ώρες';
  }

  @override
  String get bedTime => 'Ώρα ύπνου';

  @override
  String get sleepTime => 'Ώρα ύπνου';

  @override
  String get scheduleFullness => 'Πλήρωση προγράμματος';

  @override
  String get scheduleFullnessDescription =>
      'Πόσο γεμάτο πρέπει να είναι το πρόγραμμά σας;';

  @override
  String scheduleFullnessValue(int percentage) {
    return 'Στόχος πλήρωσης $percentage%';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Οι στόχοι κυμαίνονται από $minimum% έως $maximum%. Έτσι διατηρείται μια χρήσιμη βάση, ενώ αφήνεται χώρος για αλλαγές και μετακινήσεις.';
  }

  @override
  String get schedulePreferences => 'Προτιμήσεις προγράμματος';

  @override
  String get lighter => 'Πιο ελαφρύ';

  @override
  String get balanced => 'Ισορροπημένο';

  @override
  String get fuller => 'Πιο γεμάτο';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Οι προτιμήσεις πλακιδίου ενημερώθηκαν επιτυχώς.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Οι προτιμήσεις ειδοποιήσεων ενημερώθηκαν επιτυχώς.';

  @override
  String get tileReminders => 'Θηρήματα πλακιδίου';

  @override
  String get appUpdates => 'Ενημερώσεις εφαρμογής';

  @override
  String get marketingUpdates => 'Ενημερώσεις μάρκετινγκ';

  @override
  String get emailNotifications => 'Ειδοποιήσεις email';

  @override
  String get fullName => 'Πλήρες όνομα';

  @override
  String get phoneNumber => 'Αριθμός τηλεφώνου';

  @override
  String get countryCode => 'Κωδικός χώρας';

  @override
  String get dateOfBirth => 'Ημερομηνία γέννησης';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'Οι πληροφορίες λογαριασμού ενημερώθηκαν επιτυχώς.';

  @override
  String get reachingServerIssues =>
      'Προβλήματα με την πρόσβαση στους διακομιστές Tiler';

  @override
  String get deleteAccountConfirmation =>
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε τον λογαριασμό σας; Αυτή η ενέργεια δεν μπορεί να ανακληθεί.';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get integrationsSetLocation => 'Ορισμός τοποθεσίας';

  @override
  String get googleCalender => 'Google Calendar';

  @override
  String get passwordsMustMatch => 'Οι κωδικοί πρέπει να ταιριάζουν';

  @override
  String get parenthesisLate => '(Καθυστέρηση)';

  @override
  String get failedToAddIntegration => 'Αποτυχία προσθήκης ολοκλήρωσης';

  @override
  String get unknownProvider => 'Άγνωστος πάροχος';

  @override
  String get manageCalendars => 'Διαχείριση ατζέντων';

  @override
  String get calendarItems => 'Στοιχεία ατζέντας';

  @override
  String get noCalendarItemsFound => 'Δεν βρέθηκαν στοιχεία ατζέντας';

  @override
  String get calendarItemsWillAppearHere =>
      'Τα στοιχεία της ατζέντας σας θα εμφανιστούν εδώ';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount από $totalCount ατζέντες ενεργές';
  }

  @override
  String get toggleCalendarsToSync =>
      'Εναλλαγή ατζέντων για συγχρονισμό με το Tiler';

  @override
  String get unknownCalendar => 'Άγνωστη ατζέντα';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount από $totalCount ενεργά';
  }

  @override
  String integrationCount(int count) {
    return '$count Ολοκληρώσεις';
  }

  @override
  String get errorLoadingCalendarItems => 'Σφάλμα φόρτωσης στοιχείων ατζέντας';

  @override
  String get integratedCalendars => 'Ατζέντες';

  @override
  String get integrationAdd => 'Προσθήκη';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Μπορούμε να έχουμε πρόσβαση στη θέση σας για να προσφέρουμε προτάσεις\nκαι ειδοποιήσεις βασισμένες στη θέση;';

  @override
  String get recurringTasks => 'Επαναλαμβανόμενες εργασίες';

  @override
  String get yourProfession => 'Ο επάγγελμα σας;';

  @override
  String get yourProfessionQuestion => 'Τι κάνετε για δουλειά;';

  @override
  String get yourProfessionHint => 'Περιγράψτε τι κάνετε για δουλειά';

  @override
  String get medicalProfessional => 'Ιατρικός επαγγελματίας';

  @override
  String get softwareDeveloper => 'Αναπτύκτης λογισμικού';

  @override
  String get student => 'Φοιτητής';

  @override
  String get engineer => 'Μηχανικός';

  @override
  String get fieldSalesProfessional => 'Επαγγελματίας πωλήσεων πεδίου';

  @override
  String get remoteWorker => 'Τηλεργάτης & Ψηφιακός νομάδας';

  @override
  String get stayAtHomeParent => 'Γονέας που μένει στο σπίτι';

  @override
  String get clientAccountManagers => 'Διαχειριστές πελατών/λογαριασμών';

  @override
  String get other => 'Άλλο';

  @override
  String get tileSuggestions => 'Προτάσεις πλακιδίων';

  @override
  String get personalOrWorkQuestion => 'Για τι θα χρησιμοποιείτε το Tiler;';

  @override
  String get enter3chars => 'Εισάγετε τουλάχιστον 3 χαρακτήρες.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Μετακινήστε σε $duration για να φτάσετε εγκαίρως';
  }

  @override
  String get leaveNowToArriveOnTime =>
      'Μετακινήστε τώρα για να φτάσετε εγκαίρως!';

  @override
  String durationDrive(String duration) {
    return 'Οδήγηση $duration';
  }

  @override
  String durationTransit(String duration) {
    return 'Μεταφορά $duration';
  }

  @override
  String durationBike(String duration) {
    return 'Ποδήλατο $duration';
  }

  @override
  String durationWalk(String duration) {
    return 'Περίπατο $duration';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return 'Οδήγηση $duration προς $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return 'Μεταφορά $duration προς $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return 'Ποδήλατο $duration προς $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return 'Περίπατο $duration προς $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Αναχωρήστε μέχρι τις $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Εντοπίστηκε κίνηση - προτείνεται εναλλακτική διαδρομή';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Κίνηση: +$minutes λεπτά καθυστέρηση';
  }

  @override
  String get heavyTrafficExpected => 'Περιμένεται πυκνή κίνηση';

  @override
  String get addWithAI => 'Προσθήκη με AI';

  @override
  String get focusTime => 'Χρόνος εστίασης';

  @override
  String get videoMeeting => 'Video συνάντηση';

  @override
  String get sharedWith => 'Κοινοποίηση με';

  @override
  String durationMinutes(String minutes) {
    return '$minutesλ';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hoursω $minutesλ';
  }

  @override
  String travelDurationMinutes(int minutes) {
    return '$minutes λεπτά';
  }

  @override
  String travelDurationHours(int hours) {
    return '$hours ω';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours ω $minutes λεπτά';
  }

  @override
  String travelViaRoute(String route) {
    return 'μέσω $route';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return ' $travelMode προς ';
  }

  @override
  String get travelModeDriving => 'οδήγηση';

  @override
  String get travelModeWalking => 'περίπατο';

  @override
  String get travelModeBicycling => 'ποδήλατο';

  @override
  String get travelModeTransitLower => 'μεταφορά';

  @override
  String travelDurationCompact(int minutes) {
    return '$minutesλ';
  }

  @override
  String get yourDayIsOptimized => 'Η μέρα σας βελτιστοποιήθηκε.';

  @override
  String get yourDayAtAGlance => 'Η μέρα σας με μια ματιά';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration χρόνου διαδρομής σήμερα.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count πλακίδια προγραμματισμένα για σήμερα.';
  }

  @override
  String get viewRoute => 'Προβολή διαδρομής';

  @override
  String get focusModeChip => 'Λειτουργία εστίασης';

  @override
  String get showRouteChip => 'Εμφάνιση διαδρομής';

  @override
  String get reOptimizeChip => 'Επανα-βελτιστοποίηση';

  @override
  String get todayColon => 'Σήμερα:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount πλακίδια, $blockCount μπλοκ';
  }

  @override
  String get timeSavedColon => 'Χρόνος που εξοικονομήθηκε:';

  @override
  String get travelTimeColon => 'Χρόνος διαδρομής:';

  @override
  String travelTime(String duration) {
    return 'Χρόνος διαδρομής: $duration';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hoursω $minutesλ';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hoursω';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutesλ';
  }

  @override
  String hourAm(int hour) {
    return '$hour πμ';
  }

  @override
  String hourPm(int hour) {
    return '$hour μμ';
  }

  @override
  String get scheduleConflict => 'Συγκρούση προγράμματος';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" και \"$tile2\" είναι προγραμματισμένα την ίδια στιγμή';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return 'Το \"$tile1\" γίνεται κατά το \"$tile2\" ($overlap επικάλυψη)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return 'Το \"$tile1\" επικαλύπτει το \"$tile2\" κατά $overlap';
  }

  @override
  String get fix => 'Διόρθωση';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Συγκρούση: $minutesλ επικάλυψη';
  }

  @override
  String get oneScheduleConflict => '1 Συγκρούση προγράμματος';

  @override
  String countScheduleConflicts(int count) {
    return '$count Συγκρούσεις προγράμματος';
  }

  @override
  String get tapToReviewAndResolve => 'Αγγίξτε για ανασκόπηση και επίλυση';

  @override
  String countConflicts(int count) {
    return '$count συγκρούσεις';
  }

  @override
  String get tapToExpand => 'Αγγίξτε για ανάπτυξη';

  @override
  String conflictingTiles(int count) {
    return '$count Συγκρουόμενα πλακίδια';
  }

  @override
  String totalOverlap(String duration) {
    return 'Συνολική επικάλυψη: $duration';
  }

  @override
  String get autoResolve => 'Αυτόματη επίλυση';

  @override
  String get untitledTile => 'Πλακίδιο χωρίς τίτλο';

  @override
  String get untitledEvent => 'Χωρίς τίτλο';

  @override
  String get extendedEventSingular => '1 Επεκταμένο γεγονός';

  @override
  String extendedEventsPlural(int count) {
    return '$count Επεκταμένα γεγονότα';
  }

  @override
  String get extendedEventsTapToView =>
      'Αγγίξτε για προβολή γεγονότων ολόκληρης ημέρας και μακράς διάρκειας';

  @override
  String get extendedEventsTitle => 'Επεκταμένα γεγονότα';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count γεγονότα πάνω από 16 ώρες',
      one: '1 γεγονός πάνω από 16 ώρες',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Σημερινή διαδρομή';

  @override
  String get noLocationsToday => 'Κανένας τοποθεσία σήμερα';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Προσθέστε τοποθεσίες στα πλακίδια σας για να δείτε τη διαδρομή σας';

  @override
  String countStops(int count) {
    return '$count στάσεις';
  }

  @override
  String get routeOptimized => 'Η διαδρομή βελτιστοποιήθηκε';

  @override
  String savedTravelTime(String duration) {
    return 'Εξοικονομήθηκαν $duration χρόνου διαδρομής';
  }

  @override
  String get firstStop => 'Πρώτη στάση';

  @override
  String get stop => 'Στάση';

  @override
  String arriveBy(String time) {
    return 'Φτάνω μέχρι τις $time';
  }

  @override
  String get fromPreviousStop => 'από την προηγούμενη στάση';

  @override
  String get viewTile => 'Προβολή πλακιδίου';

  @override
  String get editTile => 'Επεξεργασία πλακιδίου';

  @override
  String get startNavigation => 'Έναρξη πλοήγησης';

  @override
  String get noLocationAvailable => 'Κανένας τοποθεσία';

  @override
  String get seeTodaysRoute => 'Δείτε τη σημερινή διαδρομή';

  @override
  String get whatWouldYouLikeToDo => 'Τι θα θέλατε να κάνετε;';

  @override
  String get describeATask =>
      'Περιγράψτε μια εργασία, εμείς θα κάνουμε τη πλακιδιοποίηση.';

  @override
  String get microphonePermissionDenied => 'Η άδεια μικροφώνου απορρίφθηκε.';

  @override
  String failedToStartRecording(String error) {
    return 'Αποτυχία έναρξης καταγραφής: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Αποτυχία διακοπής καταγραφής: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Σφάλμα μετατροπής ήχου: $error';
  }

  @override
  String get audioConversionFailed => 'Η μετατροπή ήχου απέτυχε';

  @override
  String get recordingPathIsEmpty => 'Η διαδρομή καταγραφής είναι κενή';

  @override
  String get noActiveRecording => 'Καμία ενεργή καταγραφή';

  @override
  String get joinMeeting => 'Συμμετοχή στη συνάντηση';

  @override
  String get openLink => 'Άνοιγμα συνδέσμου';

  @override
  String get actions => 'Ενέργειες';

  @override
  String get hideActions => 'Απόκρυψη ενεργειών';

  @override
  String get pendingRsvpSingular => '1 Γεγονότος χρειάζεται απάντηση';

  @override
  String pendingRsvpPlural(int count) {
    return '$count Γεγονότα χρειάζονται απάντηση';
  }

  @override
  String get pendingRsvpHappeningNow =>
      'Σε εξέλιξη τώρα - απαντήστε για να συμμετάσχετε';

  @override
  String get pendingRsvpStartingSoon => 'Ξεκινά σύντομα - απαντήστε τώρα';

  @override
  String get pendingRsvpWithinHour => 'Ξεκινά μέσα σε μία ώρα';

  @override
  String get pendingRsvpUpcoming => 'Επερχόμενο - αγγίξτε για απάντηση';

  @override
  String get pendingRsvpTapToReview => 'Αγγίξτε για ανασκόπηση και απάντηση';

  @override
  String get pendingRsvpTitle => 'Εκκρεμείς απαντήσεις';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count γεγονότα περιμένουν την απάντησή σας',
      one: '1 γεγονός περιμένει την απάντησή σας',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Ξεκινά σύντομα';

  @override
  String get pendingRsvpLater => 'Καθ΄ όλη τη μέρα & επερχόμενα';

  @override
  String get declinedRsvpSingular => '1 Απορριφθέν γεγονός';

  @override
  String declinedRsvpPlural(int count) {
    return '$count Απορριφθέντα γεγονότα';
  }

  @override
  String get declinedRsvp => 'Απορριφθέντα γεγονότα';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 Εκκρεμής, $declinedCount Απορριφθέντα';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount Εκκρεμείς, 1 Απορριφθέν';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount Εκκρεμείς, $declinedCount Απορριφθέντα';
  }

  @override
  String get rsvpNeedsAction => 'Χρειάζεται απάντηση';

  @override
  String get rsvpTentative => 'Προσωρινικό';

  @override
  String get rsvpAccepted => 'Αποδεκτό';

  @override
  String get rsvpDeclined => 'Απορριφθέν';

  @override
  String unableToOpenLinkError(String link) {
    return 'Δεν ήταν δυνατή η άνοιξη του συνδέσμου: $link';
  }

  @override
  String get leaveNow => 'Μετακινηθείτε τώρα!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Μετακινείστε σε $minutes λεπτά';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count ειδοποιήσεις';
  }

  @override
  String get alertChipLeaveNow => 'Μετακινήστε τώρα';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Μετακινήστε $minutesλ';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Συγκρούσεις',
      one: '1 Συγκρούση',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ολόκληρες ημέρες',
      one: '1 Ολόκληρη ημέρα',
    );
    return '$_temp0';
  }

  @override
  String alertChipRsvp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RSVPs',
      one: '1 RSVP',
    );
    return '$_temp0';
  }

  @override
  String get accepted => 'Αποδεκτό';

  @override
  String get declined => 'Απορριφθέν';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Απάντηση στο $calendarSource';
  }

  @override
  String get unknown => 'Πρόσκληση ατζέντας';

  @override
  String get loadingPreviousDays => 'Φόρτωση προηγούμενων ημερών...';

  @override
  String get loadingUpcomingDays => 'Φόρτωση επερχόμενων ημερών...';

  @override
  String get requestTimeout => 'Λήξη χρόνου αιτήματος - ελέγξτε τη σύνδεσή σας';

  @override
  String get failedToPauseTile => 'Αποτυχία παύσης πλακιδίου';

  @override
  String get failedToResumeTile => 'Αποτυχία επαναφοράς πλακιδίου';

  @override
  String get failedToMoveUpTask => 'Αποτυχία μετακίνησης εργασίας';

  @override
  String get failedToUpdateTile => 'Αποτυχία ενημέρωσης πλακιδίου';

  @override
  String get failedToBuzzSchedule => 'Αποτυχία εγγραφής προγράμματος';

  @override
  String get failedToShuffleSchedule => 'Αποτυχία ανακάτεματος προγράμματος';

  @override
  String get failedToProcrastinateTile => 'Αποτυχία αναβολής πλακιδίου';

  @override
  String get tutorialStepYourScheduleTitle => 'Το πρόγραμμα σας';

  @override
  String get tutorialStepYourScheduleBody =>
      'Η μέρα σας οργανώνεται σε Πλακίδια - έξυπνα χρονικά μπλοκ που ο Tiler διατάσσει για εσάς. Κλείστε πάνω και κάτω για να δείτε ολόκληρη τη μέρα σας.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Δημιουργία & Βελτιστοποίηση';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Αγγίξτε εδώ για να δημιουργήσετε μια νέα εργασία. Πείτε στο Tiler τι πρέπει να κάνετε και πόσο καιρό θα χρειαστεί - ο Tiler θα καταλάβει το πότε.';

  @override
  String get tutorialCalloutReOptimize => 'Επανα-βελτιστοποίηση';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'Η ημέρα σας χάλασε; Επαναυπολογίστε από τώρα διατηρώντας το επερχόμενο σχέδιο σχεδόν σταθερό';

  @override
  String get tutorialCalloutTravelTime => 'Χρόνος διαδρομής';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Ο Tiler λαμβάνει υπόψη τη μετακίνηση μεταξύ τοποθεσιών';

  @override
  String get tutorialStepQuickCreateTitle => 'Γρήγορη δημιουργία';

  @override
  String get tutorialStepQuickCreateBody =>
      'Αυτό είναι το φύλλο γρήγορης προσθήκης. Ονομάστε το πλακίδιο σας και ορίστε μια διάρκεια για γρήγορη προσθήκη.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'Αυτό είναι το φύλλο γρήγορης προσθήκης πίσω μου! Ονομάστε το πλακίδιο σας, ορίστε μια διάρκεια και αγγίξτε Προσθήκη - ο Tiler αναλαμβάνει το υπόλοιπο.';

  @override
  String get tutorialCalloutNameYourTile => 'Ονομάστε το πλακίδιο σας';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Περιγράψτε την εργασία που θέλετε να ολοκληρώσετε';

  @override
  String get tutorialCalloutSetDuration => 'Ορισμός διάρκειας';

  @override
  String get tutorialCalloutSetDurationDesc =>
      'Πόσο καιρό θα διαρκέσει αυτή η εργασία;';

  @override
  String get tutorialCalloutMoreOptions => 'Περισσότερες επιλογές';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Προσθέστε τοποθεσία, θεώρητο ή επανάληψη μέσω του πλήρους επεξεργαστή';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Προσθέστε τοποθεσία, θεώρητο ή επανάληψη';

  @override
  String get tutorialStepTilerWorksTitle => 'Ο Tiler δουλεύει για εσάς';

  @override
  String get tutorialStepTilerWorksBody =>
      'Ο Tiler διατάσσει αυτόματα τα πλακίδια σας με βάση τα επίπεδα ενέργειάς σας, τον χρόνο διαδρομής και τα θεωρήματα. Απλά προσθέστε αυτά που πρέπει να κάνετε - ο Tiler θα φροντίσει το πότε.';

  @override
  String get tutorialCalloutForecast => 'Πρόβλεψη';

  @override
  String get tutorialCalloutForecastDesc =>
      'Δείτε πότε θα εισεχθεί ένα πλακίδιο πριν το επιλέξετε';

  @override
  String get tutorialCalloutShuffle => 'Ανακάτεμα';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Ανακάτεμα και πρόταση του τι πρέπει να κάνετε επόμενο';

  @override
  String get tutorialCalloutDeferAll => 'Αναβολή όλων';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Σκληρή μέρα; Μετακινήστε τα πάντα εμπρός';

  @override
  String get tutorialStepControlTilesTitle => 'Ελέγξτε τα πλακίδια σας';

  @override
  String get tutorialStepControlTilesBody =>
      'Κάθε πλακίδιο έχει ελέγχους για τη διαχείριση των εργασιών σας σε πραγματικό χρόνο:';

  @override
  String get tutorialCalloutPlay => 'Αναπαραγωγή';

  @override
  String get tutorialCalloutPlayDesc =>
      'Ξεκινήστε να εργάζεστε σε αυτό το πλακίδιο';

  @override
  String get tutorialCalloutPause => 'Παύση';

  @override
  String get tutorialCalloutPauseDesc =>
      'Πάρετε ένα διάλειμμα - ο Tiler θα επαναπρογραμματίσει τα υπόλοιπα';

  @override
  String get tutorialCalloutComplete => 'Ολοκλήρωση';

  @override
  String get tutorialCalloutCompleteDesc =>
      'Ολοκληρώθηκε! Σημειώστε το ως ολοκληρωμένο';

  @override
  String get tutorialCalloutProcrastinate => 'Αναβολή';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Όχι τώρα - μετακινήστε το αργότερα';

  @override
  String get tutorialStepBigPictureTitle => 'Δείτε το γενικό σύνολο';

  @override
  String get tutorialStepBigPictureBody =>
      'Αγγίξτε το εικονίδιο ατζέντας για να εναλλάξετε τρεις προβολές:';

  @override
  String get tutorialCalloutDaily => 'Ημερήσια';

  @override
  String get tutorialCalloutDailyDesc =>
      'Ώρα-ωρα - το λεπτομερές σας ημερήσιο πρόγραμμα';

  @override
  String get tutorialCalloutWeekly => 'Εβδομαδιαία';

  @override
  String get tutorialCalloutWeeklyDesc =>
      'Δείτε ολόκληρη την εβδομάδα με μια ματιά';

  @override
  String get tutorialCalloutMonthly => 'Μηνιαία';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Σχεδιάστε εκ των προτέρων με μηνιαία σύνοψη';

  @override
  String get tutorialStepToolkitTitle => 'Το εργαλείο σας';

  @override
  String get tutorialStepToolkitBody =>
      'Αυτά τα χρήσιμα εργαλεία είναι πάντα σε απόσταση:';

  @override
  String get tutorialCalloutShare => 'Κοινοποίηση';

  @override
  String get tutorialCalloutShareDesc =>
      'Συνεργασία - κοινοποιήστε πλακίδια με άλλους';

  @override
  String get tutorialCalloutSearch => 'Αναζήτηση';

  @override
  String get tutorialCalloutSearchDesc =>
      'Βρείτε οποιοδήποτε πλακίδιο με όνομα';

  @override
  String get tutorialCalloutSettings => 'Ρυθμίσεις';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Προσαρμόστε την εμπειρία σας, συνδέστε ατζέντες, ορίστε προτιμήσεις';

  @override
  String get tutorialCalloutChat => 'Συνομιλία';

  @override
  String get tutorialCalloutChatDesc =>
      'Αγγίξτε το κουμπί συνομιλίας για να προσθέσετε ή ρυθμίσετε πλακίδια απλά μιλώντας στο Tiler';

  @override
  String get tutorialStepChatTitle => 'Συνομιλία με το Tiler';

  @override
  String get tutorialStepChatBody =>
      'Αγγίξτε το κουμπί συνομιλίας οποιαδήποτε στιγμή για να προσθέσετε ή ρυθμίσετε πλακίδια απλά μιλώντας στο Tiler - χωρίς φόρμες.';

  @override
  String get tutorialNavNext => 'Επόμενο';

  @override
  String get tutorialNavNextArrow => 'Επόμενο →';

  @override
  String get tutorialNavBack => 'Πίσω';

  @override
  String get tutorialNavBackArrow => '← Πίσω';

  @override
  String get tutorialNavSkip => 'Παράλειψη';

  @override
  String get tutorialNavLetsGo => 'Ας πάμε!';

  @override
  String get welcomeExplainerHeadline => 'Πλακίδια vs Μπλοκ';

  @override
  String get welcomeExplainerSubtitle =>
      'Μια γρήγορη ματιά σε πώς το Tiler σχεδιάζει τη μέρα σας.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Τα μπλοκ είναι σταθερά. Γίνονται σε καθορισμένο χρόνο.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Τα πλακίδια είναι ευελιξτικά. Ο Tiler τα ταιριάζει γύρω από τα μπλοκ σας.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'Ο οδοντίατρος μετακινήθηκε στις $time - ο Tiler επαναπρογραμματίζει τα πλακίδια σας γύρω από αυτό.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Μετακινήθηκε';

  @override
  String get welcomeExplainerReplannedBadge => 'Επαναπρογραμματίστηκε';

  @override
  String get welcomeExplainerBlockStandup => 'Ευθυγράμμιση ομάδας';

  @override
  String get welcomeExplainerBlockDentist => 'Οδοντίατρος';

  @override
  String get welcomeExplainerTileWorkout => 'Γυμναστική';

  @override
  String get welcomeExplainerTileReport => 'Σύνταξη εκθέσεως';

  @override
  String get welcomeExplainerTileGroceries => 'Σούπερμάρκετ';

  @override
  String get welcomeExplainerLegendBlock => 'Μπλοκ';

  @override
  String get welcomeExplainerLegendTile => 'Πλακίδιο';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Προτιμήσεις πλακιδίου';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Οι AI προτιμήσεις σας βρίσκονται εδώ - πώς μετακινείστε, οι εργασιακές και προσωπικές σας ώρες, και χρόνος αποκλεισμού.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Πώς μετακινείστε';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Ο Tiler προγραμματίζει χρόνο διαδρομής μεταξύ πλακιδίων με βάση τον τρόπο που συνήθως μετακινείστε.';

  @override
  String get tutorialStepTilePrefsHoursTitle =>
      'Εργασιακές και προσωπικές ώρες';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Πότε ο Tiler μπορεί να προγραμματίσει πλακίδια εργασίας έναντι προσωπικών. Αγγίξτε οποιονδήποτε για να ορίσετε ένα προφίλ.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Ώρες αποκλεισμού';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Ώρα ύπνου και διάρκεια ύπνου - ώρες που ο Tiler δεν προγραμματίζει ποτέ.';

  @override
  String get chat => 'Συνομιλία';

  @override
  String get transcribing => 'Γραφή αντίγραφων';

  @override
  String get newChat => 'Νέα συνομιλία';

  @override
  String get noChatHistory => 'Κανένα ιστορικό συνομιλίας';

  @override
  String get unknownChat => 'Άγνωστη συνομιλία';

  @override
  String get transcriptionFailed => 'Η γραφή αντίγραφων απέτυχε';

  @override
  String get acceptChanges => 'Αποδοχή αλλαγών';

  @override
  String get noRequestToExecute => 'Κανένα αίτημα για εκτέλεση';

  @override
  String get initializingAction => 'Αρχικοποίηση δημιουργίας ενέργειας';

  @override
  String get settingThingsUp => 'Ετοιμασία';

  @override
  String get preparingRequest => 'Ετοιμασία του αιτήματός σας';

  @override
  String get gettingReady => 'Ετοιμασία';

  @override
  String get processingAction => 'Επεξεργασία ενέργειας';

  @override
  String get workingOnIt => 'Εργασία σε εξέλιξη';

  @override
  String get analyzingRequest => 'Ανάλυση του αιτήματός σας';

  @override
  String get thinking => 'Σκέψη';

  @override
  String get actionComplete => 'Η επεξεργασία ενέργειας ολοκληρώθηκε';

  @override
  String get processingDone => 'Η επεξεργασία ολοκληρώθηκε';

  @override
  String get allSet => 'Όλα έτοιμα';

  @override
  String get finishedProcessing => 'Η επεξεργασία ολοκληρώθηκε';

  @override
  String get generatingSummary => 'Δημιουργία σύνοψης';

  @override
  String get summarizingResults => 'Σύνοψη αποτελεσμάτων';

  @override
  String get creatingOverview => 'Δημιουργία περίληψης';

  @override
  String get preparingSummary => 'Ετοιμασία σύνοψης';

  @override
  String get summaryComplete => 'Η δημιουργία σύνοψης ολοκληρώθηκε';

  @override
  String get summaryReady => 'Η σύνοψη είναι έτοιμη';

  @override
  String get overviewComplete => 'Η περίληψη ολοκληρώθηκε';

  @override
  String get doneSummarizing => 'Τέλος συνόψης';

  @override
  String get loadingSchedule => 'Φόρτωση δεδομένων προγράμματος';

  @override
  String get fetchingSchedule => 'Λήψη του προγράμματός σας';

  @override
  String get retrievingCalendar => 'Ανάκτηση ατζέντας';

  @override
  String get loadingTimeline => 'Φόρτωση χρονολόγιου';

  @override
  String get optimizingSchedule => 'Βελτιστοποίηση προγράμματος';

  @override
  String get reorganizingDay => 'Επαναοργάνωση της ημέρας σας';

  @override
  String get findingBestFit => 'Εύρεση του καλύτερου ταιριού';

  @override
  String get adjustingTimeline => 'Ρύθμιση χρονολόγιου';

  @override
  String get scheduleComplete => 'Η βελτιστοποίηση προγράμματος ολοκληρώθηκε';

  @override
  String get scheduleUpdated => 'Το πρόγραμμα ενημερώθηκε';

  @override
  String get timelineOptimized => 'Το χρονολόγιο βελτιστοποιήθηκε';

  @override
  String get allDone => 'Τέλος';

  @override
  String get connectionLost => 'Η σύνδεση χάθηκε. Παρακαλώ ανανέωση';

  @override
  String get sendingRequest => 'Αποστολή αιτήματος';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'Η σύνδεση WebSocket χάθηκε μετά από 5 προσπάθειες';

  @override
  String get webSocketMessageHandlingError =>
      'Σφάλμα κατά την επεξεργασία μηνύματος';

  @override
  String get jsonParseError => 'Σφάλμα ανάλυσης JSON';

  @override
  String get processError => 'Σφάλμα διεργασίας';

  @override
  String get socketConnectionError => 'Σφάλμα σύνδεσης socket';

  @override
  String get keepAliveFailed => 'Η διατήρηση σύνδεσης απέτυχε';

  @override
  String get copy => 'Αντιγραφή';

  @override
  String get entityIdNotFound => 'Δεν βρέθηκε id οντότητας προεπισκόπησης';

  @override
  String get feedback => 'Ανατροφοδότηση';

  @override
  String get feedbackCategory => 'Κατηγορία';

  @override
  String get feedbackCategoryBug => 'Σφάλμα';

  @override
  String get feedbackCategoryFeature => 'Λειτουργία';

  @override
  String get feedbackCategoryEnhancement => 'Βελτίωση';

  @override
  String get feedbackCategoryGeneral => 'Γενική';

  @override
  String get feedbackTitle => 'Τίτλος';

  @override
  String get feedbackTitleHint => 'Σύντομη σύνοψη της ανατροφοδότησής σας';

  @override
  String get feedbackDescription => 'Περιγραφή';

  @override
  String get feedbackDescriptionHint =>
      'Δώστε λεπτομέρειες για την ανατροφοδότησή σας';

  @override
  String get feedbackSubmitted => 'Η ανατροφοδότηση υποβλήθηκε επιτυχώς';

  @override
  String get feedbackError => 'Αποτυχία υποβολής ανατροφοδότησης';

  @override
  String get noPreviewsAvailable =>
      'Δεν υπάρχουν TileCast διαθέσιμα για αυτό το αίτημα';

  @override
  String get previewUnavailable => 'Το επιλεγμένο TileCast δεν είναι διαθέσιμο';

  @override
  String get previewSummaryUnavailable => 'Το TileCast δεν μπόρεσε να φορτωθεί';

  @override
  String get previewGenerating => 'Δημιουργία TileCast…';

  @override
  String get previewTimedOut =>
      'Το TileCast παίρνει περισσότερο χρόνο από το αναμενόμενο. Δοκιμάστε ξανά σε λίγο.';

  @override
  String get previewGenerationFailed =>
      'Δεν μπορέσαμε να δημιουργήσουμε αυτό το TileCast.';

  @override
  String get previewInvalidated =>
      'Αυτό το TileCast δεν είναι πλέον έγκυρο γιατί άλλαξε το πρόγραμμά σας.';

  @override
  String get previewStaleBanner =>
      'Αυτό το TileCast αντανακλά μια προηγούμενη άποψη του προγράμματός σας.';

  @override
  String get previewNonViableLabel => 'Δεν μπόρεσε να προγραμματιστεί';

  @override
  String get reviewChanges => 'Ανασκόπηση αλλαγών';

  @override
  String get previewRetry => 'Νέα απόπειρα';

  @override
  String get previewPreparing => 'Ετοιμασία TileCast…';

  @override
  String get previewReadyToView => 'Αγγίξτε για προβολή TileCast';

  @override
  String get previewActionsOutdated => 'Αρχαίο - στείλτε ένα νέο μήνυμα';

  @override
  String get previewActionsUnavailable => 'TileCast μη διαθέσιμο';

  @override
  String get tileCastStaleNote =>
      'Το πρόγραμμά σας άλλαξε - αυτό το TileCast μπορεί να είναι παλιό';

  @override
  String get tileCastAlsoIncluded => 'Επίσης περιλαμβάνεται';

  @override
  String actionsCount(int count) {
    return '$count ενέργειες';
  }

  @override
  String get ok => 'Εντάξει';

  @override
  String get notesLoading => 'Φόρτωση σημειώσεων…';

  @override
  String get notesSaving => 'Αποθήκευση…';

  @override
  String get notesSaved => 'Αποθηκεύτηκε';

  @override
  String get notesUnsaved => 'Επεξεργασία…';

  @override
  String get notesSaveError => 'Δεν μπόρεσε να αποθηκευτεί';

  @override
  String get notesSaveNow => 'Αποθήκευση τώρα';

  @override
  String get notesShowPreview => 'Προεπισκόπηση';

  @override
  String get notesShowEditor => 'Επεξεργασία';

  @override
  String get notesPreviewEmpty => 'Κανένα για προεπισκόπηση ακόμα.';

  @override
  String get notesLinkPromptTitle => 'Εισαγωγή συνδέσμου';

  @override
  String get notesConflictTitle => 'Κάποιος άλλος ενημέρωσε αυτή τη σημείωση.';

  @override
  String get notesConflictDiscardMine => 'Απόρριψη της δικής μου';

  @override
  String get notesConflictKeepEditing => 'Συνέχεια επεξεργασίας';

  @override
  String get notesToolBold => 'Έντονα';

  @override
  String get notesToolItalic => 'Πλάγια';

  @override
  String get notesToolStrikethrough => 'Διαγραφή';

  @override
  String get notesToolInlineCode => 'Ενσωματωμένος κώδικας';

  @override
  String get notesToolHeading1 => 'Κεφαλίδα 1';

  @override
  String get notesToolHeading2 => 'Κεφαλίδα 2';

  @override
  String get notesToolBulletList => 'Λίστα σημείων';

  @override
  String get notesToolNumberedList => 'Αριθμημένη λίστα';

  @override
  String get notesToolTaskList => 'Λίστα εργασιών';

  @override
  String get notesToolQuote => 'Παράθεση';

  @override
  String get notesToolLink => 'Σύνδεσμος';

  @override
  String get notesTitle => 'Σημειώσεις';

  @override
  String get notesViewerTitle => 'Σημείωση';

  @override
  String get notesTapToAdd => 'Αγγίξτε για να προσθέσετε σημείωση';

  @override
  String get notesTapToEdit =>
      'Αγγίξτε για επεξεργασία · μακρύ πάτημα για ανάγνωση';

  @override
  String get notesDone => 'Ολοκληρώθηκε';

  @override
  String get endOfDay => 'Τέλος ημέρας';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get share => 'Κοινοποίηση';

  @override
  String get openChat => 'Άνοιγμα συνομιλίας';

  @override
  String get goToToday => 'Μετάβαση στο σήμερα';

  @override
  String get switchCalendarView => 'Εναλλαγή προβολής ατζέντας';

  @override
  String get previewSundialGreeting => 'Γεια.';

  @override
  String get previewSundialCountsPrefix => 'Σήμερα έχει';

  @override
  String get previewSundialCountsSuffix => 'σε αναμονή.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count πλακίδια';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count μπλοκ';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count κοινόχρηστα πλακίδια';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours ώρες εργασίας';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins λεπτά διαδρομής';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'η μέρα σας καθαρίζει μέχρι τις $time';
  }

  @override
  String get previewSundialAndSeparator => 'και';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count μέρη';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '$hoursω ύπνο';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '$hoursω ελεύθερο';
  }

  @override
  String get previewSundialFullyBooked => 'Όλα δεσμευμένα';

  @override
  String get previewSundialTier0 => 'Ανοιχτή μέρα';

  @override
  String get previewSundialTier1 => 'Έναρξη';

  @override
  String get previewSundialTier2 => 'Σε εξέλιξη';

  @override
  String get previewSundialTier3 => 'Σταθερή πρόοδος';

  @override
  String get previewSundialTier4 => 'Σχεδόν εκεί';

  @override
  String get previewSundialTodayLabel => 'Σήμερα';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles πλακίδια, $blocks μπλοκ, $nonViable μη προγραμματισμένα';
  }

  @override
  String get timelineClearHeading => 'Το χρονολόγιό σας είναι καθαρό σήμερα';

  @override
  String get timelineClearAddTask => 'Προσθήκη πλακιδίου';

  @override
  String get aiConsentTitle => 'Συναντήστε το Tiler AI';

  @override
  String get aiConsentSubtitle => 'Ο AI βοηθός προγραμματισμού σας';

  @override
  String get aiConsentIntro =>
      'Για να μετατρέψετε τα λόγια σας σε πρόγραμμα, το Tiler AI κοινοποιεί ό,τι στέλνετε σε έμπιστους πάροχους AI.';

  @override
  String get aiConsentDataTitle => 'Τι στέλνουμε';

  @override
  String get aiConsentDataBody =>
      'Τα μηνύματα και ηχογραφήσεις φωνής που στέλνετε, σχετικές λεπτομέρειες από το πρόγραμμά σας.';

  @override
  String get aiConsentProvidersTitle => 'Ποιος το λαμβάνει';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini και OpenAI, οι πάροχοι AI τρίτων μέρους.';

  @override
  String get aiConsentPrivacyLink => 'Διαβάστε την Πολιτική Απορρήτου μας';

  @override
  String get aiConsentContinue => 'Συνέχεια στο Tiler AI';

  @override
  String get aiConsentAgreementNotice =>
      'Με τη συνέχειά σας, συμφωνείτε να κοινοποιήσετε αυτά τα δεδομένα στον πάροχο Τρίτων όπως περιγράφηκε παραπάνω.';

  @override
  String get aiConsentClose => 'Κλείσιμο';

  @override
  String get legalFooterPrefix => 'Με τη συνέχειά σας, συμφωνείτε στο';

  @override
  String get legalFooterTerms => 'Όροι';

  @override
  String get legalFooterAnd => 'και';

  @override
  String get legalFooterPrivacy => 'Απόρρητο';

  @override
  String get aiConsentLinkError => 'Δεν ήταν δυνατή η άνοιξη του συνδέσμου.';

  @override
  String get addTileScreenTitleFlexible => 'Add Tile';

  @override
  String get addTileScreenTitleFixed => 'Add Block';

  @override
  String get addTileTypeFlexible => 'Flexible Tile';

  @override
  String get addTileTypeFixed => 'Fixed Block';

  @override
  String get addTileTypeSelectorLabel => 'Tile type';

  @override
  String addTileExplanationFlexible(String emphasis) {
    return 'Tiler will find the $emphasis for this.';
  }

  @override
  String addTileExplanationFixed(String emphasis) {
    return 'Blocks happen at $emphasis.';
  }

  @override
  String get addTileFindTime => 'Find time';

  @override
  String get addTileSubmitting => 'Submitting';

  @override
  String get addTileNameRequired => 'Name is required';

  @override
  String get addTileTitleRequired => 'Title is required';

  @override
  String get addTileFieldTaskName => 'TASK NAME';

  @override
  String get addTileFieldTitle => 'TITLE';

  @override
  String get addTileFieldDuration => 'DURATION';

  @override
  String get addTileFieldCompleteBy => 'COMPLETE BY';

  @override
  String get addTileFieldPreferredTime => 'PREFERRED TIME';

  @override
  String get addTileFieldDate => 'DATE';

  @override
  String get addTileFieldStarts => 'STARTS';

  @override
  String get addTileFieldEnds => 'ENDS';

  @override
  String get addTileFieldLocation => 'LOCATION';

  @override
  String get addTileTaskNameHint => 'What do you want to do?';

  @override
  String get addTileBlockTitleHint => 'What is this block?';

  @override
  String get addTileValueNotSet => 'Not set';

  @override
  String get addTileAutoCalculated => 'Auto-calculated';

  @override
  String addTileEndsSemantics(String time) {
    return 'Ends at $time, calculated from start and duration';
  }

  @override
  String addTileTodayDate(String date) {
    return 'Today, $date';
  }

  @override
  String get addTileMoreOptions => 'More options';

  @override
  String get addTilePriority => 'Priority';

  @override
  String get addTilePriorityLow => 'Low';

  @override
  String get addTilePriorityMedium => 'Medium';

  @override
  String get addTilePriorityHigh => 'High';

  @override
  String get addTilePriorityLowMeaning => 'Nice to have';

  @override
  String get addTilePriorityMediumMeaning => 'Important';

  @override
  String get addTilePriorityHighMeaning => 'Must get done';

  @override
  String get addTilePriorityHelper =>
      'Priority helps Tiler decide what to protect first.';

  @override
  String get addTileColorAutomatic => 'Automatic';

  @override
  String get addTileColorCustom => 'Custom';

  @override
  String get addTileSplitIntoSessions => 'Split into sessions';

  @override
  String get addTileSplitHelper => 'Break this into separate work sessions.';

  @override
  String addTileSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get addTileFewerSessions => 'Fewer sessions';

  @override
  String get addTileMoreSessions => 'More sessions';

  @override
  String get addTileFlexibleCompletion => 'Flexible completion date';

  @override
  String get addTileFlexibleCompletionHelper =>
      'Tiler may move this date slightly if needed.';

  @override
  String get addTilePreferredTimeCustom => 'Custom';

  @override
  String addTileDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String addTileDurationHours(int hours) {
    return '$hours hr';
  }

  @override
  String addTileDurationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get addTileRepeat => 'Repeat';

  @override
  String get addTileRepeatNever => 'Does not repeat';

  @override
  String get addTileRepeatDays => 'DAYS';

  @override
  String get addTileRepeatsUntil => 'REPEATS UNTIL';

  @override
  String get addTileRepeatHelper =>
      'Repeat helps Tiler schedule recurring tasks.';

  @override
  String get addTileLocationSearchHint => 'Search locations';

  @override
  String get addTileLocationYourPlaces => 'YOUR PLACES';

  @override
  String get addTileLocationSuggestions => 'SUGGESTIONS';

  @override
  String get addTileLocationHelper =>
      'Location helps Tiler optimize travel and timing.';

  @override
  String get addTileLocationNoneSaved => 'No saved places yet';

  @override
  String get addTileLocationNoneSavedHelper =>
      'Search for a place, or type a name like \"bike shop\" to save one.';

  @override
  String get addTileLocationNoResults => 'No places found';

  @override
  String get addTileLocationNoResultsHelper =>
      'You can still save what you typed as the place name.';

  @override
  String get addTileLocationSearchFailed => 'Could not search right now';

  @override
  String get addTileLocationSearchFailedHelper =>
      'Check your connection and try again, or save what you typed as the place name.';

  @override
  String addTileLocationUseTyped(String query) {
    return 'Use \"$query\"';
  }

  @override
  String get addTileLocationUseTypedHelper => 'Give it a name and address';

  @override
  String get addTileLocationFallbackName => 'Location';

  @override
  String get addTilePlaceAdd => 'Add place';

  @override
  String get addTilePlaceEdit => 'Edit place';

  @override
  String get addTilePlaceName => 'NAME';

  @override
  String get addTilePlaceAddress => 'ADDRESS';

  @override
  String get addTilePlaceNameHint => 'e.g. Walmart near work';

  @override
  String get addTilePlaceAddressHint => 'Street, city, state';

  @override
  String get addTilePlaceSave => 'Save place';

  @override
  String get addTilePlaceNameThis => 'Name this place';

  @override
  String get addTilePlaceNameHelper =>
      'A name is how you find this place again. Naming two places the same thing keeps only the newest address.';

  @override
  String addTilePlaceNameTaken(String name, String address) {
    return 'You already have a place called \"$name\" at $address. Saving will move that name to this address.';
  }

  @override
  String addTilePlaceNameTakenNoAddress(String name) {
    return 'You already have a place called \"$name\". Saving will move that name to this address.';
  }

  @override
  String get addTileFieldPriority => 'PRIORITY';

  @override
  String get addTileFieldColor => 'COLOR';

  @override
  String get addTileColorPresets => 'PRESETS';

  @override
  String get addTileColorAutomaticHelper => 'Tiler picks a color for you';

  @override
  String get addTileColorCustomHelper => 'Pick any color';

  @override
  String get addTileColorHelper =>
      'Color only changes how this looks on your schedule.';

  @override
  String get addTileColorShuffle => 'Shuffle a different color';

  @override
  String addTileColorSwatch(int index) {
    return 'Color $index';
  }

  @override
  String get addTileExplanationFlexibleEmphasis => 'best time';

  @override
  String get addTileExplanationFixedEmphasis => 'a fixed time';

  @override
  String get addTileFieldRepeat => 'REPEAT';

  @override
  String get addTileDurationQuick => 'QUICK';

  @override
  String get addTileDurationCustom => 'CUSTOM';

  @override
  String get addTileDurationHourLabel => 'Hour';

  @override
  String get addTileDurationMinuteLabel => 'Min';

  @override
  String addTileDurationEndsFromStart(String start) {
    return 'FROM $start';
  }

  @override
  String addTileDurationEndsNextDay(String time) {
    return '$time, next day';
  }

  @override
  String addTileDurationEndsSemantics(String end, String start) {
    return 'Ends at $end, from a start of $start. Change the end time';
  }

  @override
  String get editTileTitleTile => 'Edit Tile';

  @override
  String get editTileTitleBlock => 'Edit Block';

  @override
  String get editTileSave => 'Save Changes';

  @override
  String get editTileSaving => 'Saving…';

  @override
  String get editTileSectionTiming => 'TIMING';

  @override
  String get editTileReasonNameRequired => 'Give this tile a title to save it';

  @override
  String get editTileReasonSplitRequired => 'Sessions must be at least 1';

  @override
  String get editTileReasonEndNotAfterStart =>
      'The end must be after the start';

  @override
  String get editTileDiscardTitle => 'Discard changes?';

  @override
  String get editTileDiscardBody => 'Your edits to this tile will be lost.';

  @override
  String get editTileDiscard => 'Discard';

  @override
  String get editTileKeepEditing => 'Keep editing';

  @override
  String get editTileLoadFailed => 'Couldn\'t load this tile.';

  @override
  String get editTileSaveFailed =>
      'Could not save right now. Your changes are kept.';

  @override
  String get editTileSectionActions => 'ACTIONS';

  @override
  String get editTileSectionSessions => 'SESSIONS';

  @override
  String get editTileFieldSessions => 'Split into sessions';

  @override
  String get editTileFieldDeadline => 'DEADLINE';

  @override
  String get editTileSectionAdditional => 'ADDITIONAL DETAILS';

  @override
  String get editTileSectionSuggestions => 'SUGGESTIONS';

  @override
  String get editTileCreateAsNewTile => 'Create as new tile';

  @override
  String get editTileSectionProgress => 'PROGRESS';

  @override
  String editTileProgressComplete(int done, int total) {
    return '$done of $total complete';
  }

  @override
  String editTileProgressRemaining(int remaining, int deleted) {
    return '$remaining remaining · $deleted deleted';
  }

  @override
  String get editTileActionComplete => 'Complete';

  @override
  String get editTileActionCompleteCaption => 'Mark as done';

  @override
  String get editTileActionStartNow => 'Start now';

  @override
  String get editTileActionStartNowCaption => 'Move to now';

  @override
  String get editTileActionDefer => 'Defer';

  @override
  String get editTileActionDeferCaption => 'Pick a new time';

  @override
  String get editTileActionDelete => 'Delete';

  @override
  String get editTileActionDeleteCaption => 'Remove';

  @override
  String editTileActionConfirmComplete(String title) {
    return 'Mark \"$title\" as done?';
  }

  @override
  String editTileActionConfirmStartNow(String title) {
    return 'Move \"$title\" to now?';
  }

  @override
  String editTileActionConfirmDefer(String title) {
    return 'Defer \"$title\"?';
  }

  @override
  String editTileActionConfirmDelete(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get editTileActionDeleteBody =>
      'This removes the tile from your schedule.';

  @override
  String get editTileActionDiscardsEdits =>
      'Your unsaved changes will be discarded.';

  @override
  String get editTileActionFailed => 'Could not do that right now.';

  @override
  String editTileActionSemantics(String label, String caption) {
    return '$label, $caption';
  }

  @override
  String get editTileSectionRepetition => 'REPETITION';

  @override
  String get editTileSectionPriority => 'PRIORITY';

  @override
  String get editTileSectionLocation => 'LOCATION';

  @override
  String get editTileLocationRemove => 'Remove location';

  @override
  String get addTileDeadlineClear => 'Remove deadline';

  @override
  String get editTileMenuTileDetails => 'Tile details';

  @override
  String get editTileMoreMenu => 'More';

  @override
  String get editTileRepeatEveryDay => 'Every day';

  @override
  String get editTileRepeatEveryWeek => 'Every week';

  @override
  String editTileRepeatEveryWeekOn(String days) {
    return 'Every week on $days';
  }

  @override
  String get editTileRepeatEveryMonth => 'Every month';

  @override
  String get editTileRepeatEveryYear => 'Every year';

  @override
  String editTileRepeatUntil(String cadence, String date) {
    return '$cadence · until $date';
  }

  @override
  String editTileRepeatUntilDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String editTileRepeatNeverEnds(String cadence) {
    return '$cadence · never ends';
  }

  @override
  String get editTileRepeatCalloutTitle =>
      'This will create multiple instances';

  @override
  String get editTileRepeatCalloutBody =>
      'Tiler will schedule each occurrence based on your preferences and availability.';

  @override
  String get editTileNotesTitle => 'Notes';

  @override
  String get editTileModeReadOnly =>
      'This tile is finished, so it can\'t be edited. You can still delete it.';

  @override
  String get editTileModeProcrastinate =>
      'Blocked-out time. Move it, mark it done, or delete it.';

  @override
  String editTileModeThirdParty(String provider) {
    return 'Managed by $provider. Respond to the invitation or delete it here; edit the event in $provider.';
  }

  @override
  String get editTileProviderGoogle => 'Google Calendar';

  @override
  String get editTileProviderOutlook => 'Outlook';

  @override
  String get editTileRsvpFailed => 'Could not send your response right now.';

  @override
  String get editTileWhatIfChecking => 'Checking what this change affects…';

  @override
  String editTileWhatIfSummary(int late, int overflow) {
    return 'Affects other tiles: $late late, $overflow overflow';
  }

  @override
  String get editTileWhatIfSheetTitle => 'What this change affects';

  @override
  String get editTileWhatIfLate => 'Late';

  @override
  String get editTileWhatIfOverflow => 'Overflow';

  @override
  String get editTileWhatIfClean => 'No other tiles are affected.';

  @override
  String get editTileWhatIfFailed =>
      'Couldn\'t check the effect on your schedule.';

  @override
  String get editTileWhatIfRetry => 'Retry';

  @override
  String get editTileEditTitle => 'Edit title';

  @override
  String get tileDetailTitle => 'Tile details';

  @override
  String get tileDetailLoadFailed => 'Couldn\'t load this tile\'s details.';

  @override
  String get tileDetailSaveFailed =>
      'Could not save right now. Your changes are kept.';

  @override
  String get tileDetailDeleteSeries => 'Delete tile';

  @override
  String tileDetailDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get tileDetailDeleteBody =>
      'Every occurrence of this tile will be removed from your schedule.';

  @override
  String get tileDetailDeleteFailed => 'Could not delete right now.';

  @override
  String get tileDetailSectionOccurrences => 'OCCURRENCES';

  @override
  String get tileDetailOccurrencesEmpty => 'No occurrences scheduled yet.';

  @override
  String get tileDetailOccurrencesFailed => 'Couldn\'t load the occurrences.';

  @override
  String get tileDetailOccurrencesEarlier => 'Show earlier';

  @override
  String get tileDetailOccurrencesLater => 'Show later';

  @override
  String get tileDetailOccurrenceDone => 'Done';

  @override
  String tileDetailOccurrenceSemantics(String day, String span, String done) {
    return '$day, $span$done';
  }

  @override
  String editTileTimeChipSemantics(String field, String value) {
    return '$field time, $value';
  }

  @override
  String editTileDateChipSemantics(String field, String value) {
    return '$field date, $value';
  }

  @override
  String get addTileSubmitFailed =>
      'Could not add this right now. Your details are saved.';

  @override
  String get addTileRetry => 'Retry';

  @override
  String searchResultsForQuery(int count, String query) {
    return '$count results for \"$query\"';
  }

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterTiler => 'Tiler';

  @override
  String get searchFilterGoogle => 'Google';

  @override
  String get searchFilterOutlook => 'Outlook';

  @override
  String get startNow => 'Start now';

  @override
  String dueOnDate(String date) {
    return 'Due $date';
  }

  @override
  String get noResultsForProvider => 'No results from this calendar';

  @override
  String get readOnly => 'Read-only';

  @override
  String get productTourStarting => 'Your product tour is about to begin.';
}
