// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Hinzufügen';

  @override
  String get setupCustomRestrictions => 'Eigene Einschränkungen einrichten';

  @override
  String get customRestrictionTitle => 'Eigene Einschränkungen';

  @override
  String get customRestrictionHeader => 'Eigene Einschränkungen einrichten';

  @override
  String get customRestrictionHeaderDescription =>
      'Wähle aus, wann du diese Aufgabe abschließen möchtest.';

  @override
  String get day => 'Tag';

  @override
  String get hour => 'Stunde';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String get duration => 'Dauer';

  @override
  String get durationStar => 'Dauer*';

  @override
  String get addTile => 'Kachel hinzufügen';

  @override
  String get defer => 'Aufschieben';

  @override
  String get deferAll => 'Alles aufschieben';

  @override
  String get procrastinating => 'Aufschieberitis';

  @override
  String get forecast => 'Prognose';

  @override
  String get whenQ => 'Wann?';

  @override
  String get loading => 'Wird geladen';

  @override
  String get loadingPrediction => 'Vorhersage wird geladen';

  @override
  String get address => 'Adresse';

  @override
  String get settings => 'Einstellungen';

  @override
  String get nickName => 'Spitzname';

  @override
  String get deadline_anytime => 'Fällig (Jederzeit)';

  @override
  String get selectADeadline => 'Fälligkeit wählen';

  @override
  String get close => 'Schließen';

  @override
  String get tileName => 'Kachelname';

  @override
  String get tileNameStar => 'Kachelname*';

  @override
  String get starAreRequired => '* sind Pflichtfelder';

  @override
  String get howManyTimes => 'Wie oft';

  @override
  String get once => 'Einmal';

  @override
  String get weekdaysAndWorkHours => 'Wochentage und Arbeitszeiten';

  @override
  String get weekend => 'Wochenende';

  @override
  String get anytime => 'Jederzeit';

  @override
  String get repetition => 'Wiederholung';

  @override
  String get reminder => 'Erinnerung';

  @override
  String get restriction => 'Einschränkung';

  @override
  String get username => 'Benutzername';

  @override
  String get usernameOrEmail => 'Benutzername oder E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get email => 'E-Mail';

  @override
  String get back => 'Zurück';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get passwordIsRequired => 'Passwort ist erforderlich';

  @override
  String get emailIsRequired => 'E-Mail ist erforderlich';

  @override
  String get fieldIsRequired => 'Feld ist erforderlich';

  @override
  String get signingIn => 'Anmeldung läuft';

  @override
  String get signInWithEmailCode => 'Mit E-Mail-Code anmelden';

  @override
  String get sendAccessCode => 'Zugangscode senden';

  @override
  String get continueBtn => 'Weiter';

  @override
  String get usePasswordInstead => 'Stattdessen Passwort verwenden';

  @override
  String get useAccessCodeInstead => 'Stattdessen Zugangscode verwenden';

  @override
  String get registeringUser => 'Konto wird erstellt';

  @override
  String get sendVerificationCode => 'Bestätigungscode senden';

  @override
  String get verificationCodeSent =>
      'Bestätigungscode wurde an deine E-Mail gesendet.';

  @override
  String get verificationCode => 'Bestätigungscode';

  @override
  String get verifyCode => 'Code bestätigen';

  @override
  String get resendCode => 'Code neu senden';

  @override
  String get verifyingCode => 'Code wird überprüft';

  @override
  String get invalidVerificationCode =>
      'Ungültiger oder abgelaufener Bestätigungscode.';

  @override
  String get accessCodeRequiresEmail =>
      'Die Anmeldung per Zugangscode erfordert eine E-Mail-Adresse.';

  @override
  String get emailCodeInstructions =>
      'Gib deine E-Mail ein, und wir senden dir einen Bestätigungscode.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Gib den an $email gesendete Bestätigungscode ein.';
  }

  @override
  String get confirmPasswordRequired =>
      'Bestätigungs-Passwort ist erforderlich';

  @override
  String get passwordsDontMatch =>
      'Passwort und Bestätigungs-Passwort stimmen nicht überein';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'Passwort muss mindestens 7 Zeichen lang sein';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'Passwort muss einen Großbuchstaben enthalten';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'Passwort muss einen Kleinbuchstaben enthalten';

  @override
  String get passwordNeedsToHaveNumber => 'Passwort muss eine Zahl enthalten';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'Passwort muss mindestens 1 Sonderzeichen enthalten';

  @override
  String get enableLocations => 'Standortzugriff erlauben';

  @override
  String get noMatchWasFound => 'Kein Treffer gefunden';

  @override
  String get atLeastThreeLettersForLookup =>
      '…Tiler benötigt drei Zeichen für die Suche';

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
  String get noLocationMatchWasFound => 'Kein Standort gefunden';

  @override
  String get noLocation => 'Kein Standort';

  @override
  String get clearedColon => 'Geglättet: ';

  @override
  String get complete => 'Fertigstellen';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get now => 'Jetzt';

  @override
  String get color => 'Farbe';

  @override
  String get pickAColor => 'Farbe wählen';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get play => 'Start';

  @override
  String get successfullyPaused => 'Erfolgreich pausiert';

  @override
  String get successfullyResumed => 'Erfolgreich fortgesetzt';

  @override
  String get successfullyCompleted => 'Erfolgreich abgeschlossen';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get scheduled => 'Geplant';

  @override
  String get movedUpToNow => 'Wird nach vorne verschoben';

  @override
  String get pausing => 'Pausiert';

  @override
  String get resuming => 'Wird fortgesetzt';

  @override
  String get movingUp => 'Deine Kachel wird nach vorne verschoben';

  @override
  String get completing => 'Wird abgeschlossen';

  @override
  String get deleting => 'Wird gelöscht';

  @override
  String get deleteBlockConfirming => 'Dieser Block wird gelöscht…';

  @override
  String get deleteTileConfirming => 'Diese Kachel wird gelöscht…';

  @override
  String get deleteNow => 'Jetzt löschen';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Wird auch aus dem Google Kalender gelöscht';

  @override
  String get deleteOutlookWarning => '⚠️ Wird auch aus Outlook gelöscht';

  @override
  String get previously => 'Früher';

  @override
  String get upcoming => 'Bevorstehend';

  @override
  String get failedToSendRequest => 'Anfrage konnte nicht gesendet werden';

  @override
  String get revise => 'Überarbeiten';

  @override
  String get revisingSchedule => 'Zeitplan wird überarbeitet';

  @override
  String get procrastinateBlockOut => 'Kachelpause';

  @override
  String get lunchBreak => 'Mittagspause';

  @override
  String get coffeeBreak => 'Kaffeepause';

  @override
  String get morningBreak => 'Morgenpause';

  @override
  String get afternoonBreak => 'Nachmittagspause';

  @override
  String get freeTime => 'Freie Zeit';

  @override
  String get freeSlotHeader => 'Freie Zeit';

  @override
  String get freeSlotNow => 'Jetzt frei';

  @override
  String get quickBreak => 'Kurze Pause';

  @override
  String get shortBreak => 'Kurze Pause';

  @override
  String get blockedTime => 'Blockierte Zeit';

  @override
  String get start => 'Start';

  @override
  String get end => 'Ende';

  @override
  String get deadline => 'Fälligkeit';

  @override
  String get split => 'Teilen';

  @override
  String get timeBlocks => 'Zeitblöcke';

  @override
  String get swipeRightToTileIt => 'Nach rechts wischen, um es zu kacheln';

  @override
  String get failedToReviseScheduleRequest =>
      'Zeitplan-Anfrage konnte nicht überarbeitet werden';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String get none => 'Keine';

  @override
  String get noneNotificationCategory => 'Standard';

  @override
  String get nextTileNotificationCategory => 'Nächste Kachel';

  @override
  String get userSetReminderNotificationCategory => 'Benutzer-Erinnerung';

  @override
  String get depatureTimeNotificationCategory => 'Abreisezeit';

  @override
  String get tile => 'Kachel';

  @override
  String get appointment => 'Block';

  @override
  String startingAtTime(String time) {
    return 'Beginnt um $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Endet um $time';
  }

  @override
  String get startsInTenMinutes => 'Beginnt in zehn Minuten';

  @override
  String get endsInTenMinutes => 'Endet in fünf Minuten';

  @override
  String startsInDuration(String duration) {
    return 'Beginnt in $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName endet bald';
  }

  @override
  String get home => 'Zuhause';

  @override
  String get work => 'Arbeit';

  @override
  String get googleLogo => 'Google-Logo';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get workProfileHours => 'Arbeitszeiten';

  @override
  String get personalHours => 'Persönliche Zeiten';

  @override
  String get setWorkProfileHours => 'Arbeitszeiten festlegen';

  @override
  String get setPersonalHours => 'Persönliche Zeiten festlegen';

  @override
  String get customHours => 'Eigene Zeiten';

  @override
  String get logout => 'Abmelden';

  @override
  String get noteEllipsis => 'Notiz…';

  @override
  String get tapToCreateNewTile => 'Tippen, um eine neue Kachel zu erstellen';

  @override
  String get emptyDayHeaderLine1 => 'Noch keine Pläne.';

  @override
  String get emptyDayFooterLine1 => 'In Sekunden starten:';

  @override
  String get emptyDayFooterLine2 =>
      'Kalender importieren oder Kacheln erstellen.';

  @override
  String get emptyDayOr => 'oder';

  @override
  String get emptyDayImportGoogleCalendarButton =>
      'Google Kalender importieren';

  @override
  String get suggestions => 'Vorschläge';

  @override
  String get progress => 'Fortschritt';

  @override
  String get youNeedToLeaveIn => 'Du musst los in';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Du musst los in $duration';
  }

  @override
  String durationLate(String duration) {
    return '$duration zu spät';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Endete vor $duration';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Abgeschlossen vor $duration';
  }

  @override
  String durationLeft(String duration) {
    return 'Noch $duration übrig';
  }

  @override
  String get issuesConnectingToTiler => 'Problem bei der Verbindung zu Tiler';

  @override
  String completedCount(String count) {
    return 'Abgeschlossen ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Gelöscht ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Kacheln übrig ($count)';
  }

  @override
  String countTile(String count) {
    return '$count Kacheln';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number Kacheln ausgewählt';
  }

  @override
  String get completeTiles => 'Kacheln abschließen';

  @override
  String get thisFitsInYourSchedule => 'Das passt in deinen Zeitplan.';

  @override
  String get warningColon => 'Warnung: ';

  @override
  String get oneEventAtRisk => '1 Termin in Gefahr';

  @override
  String countEventAtRisk(String number) {
    return '$number Termine in Gefahr';
  }

  @override
  String get oneConflict => '1 Konflikt';

  @override
  String countConflict(String number) {
    return '$number Konflikte';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get thisEventWouldCause => 'Dieser Termin würde verursachen: ';

  @override
  String errorMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get unScheduledTiles => 'Nicht geplante Kacheln';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number Nicht geplante Kacheln';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number weitere';
  }

  @override
  String get unScheduled => 'Nicht geplant';

  @override
  String get allScheduled => 'Alles geplant';

  @override
  String get getOnIt => 'Los geht\'s';

  @override
  String get done => 'Fertig';

  @override
  String get late => 'Zu spät';

  @override
  String get onTime => 'Pünktlich';

  @override
  String get todayStatusPlacedTitle => 'Erfolgreich platziert';

  @override
  String get todayStatusAttentionTitle => 'Benötigt Aufmerksamkeit';

  @override
  String get todayStatusLateTitle => 'Läuft verspätet';

  @override
  String get todayStatusAttentionHelper =>
      'Diese konnten nicht in die heute verfügbare Zeit eingeplant werden.';

  @override
  String get todayStatusLateHelper =>
      'Die Reisedauer zwischen diesen und deinen umliegenden Kacheln bedeutet, dass du nicht pünktlich dort sein kannst.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kacheln',
      one: '1 Kachel',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kacheln abgeschlossen',
      one: 'Kachel abgeschlossen',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Benötigt Aufmerksamkeit';

  @override
  String get todayStatusTilesRunningLate => 'Läuft verspätet';

  @override
  String get todayStatusEverythingOnTrack => 'Alles ist im Zeitplan';

  @override
  String get todayStatusEverythingElseOnTrack => 'Alles andere ist im Zeitplan';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Keine geplanten Kacheln laufen verspätet.';

  @override
  String get todayStatusClearDay => 'Dein Tag ist frei.';

  @override
  String get todayStatusPreviewCta => 'Besseren Plan in der Vorschau ansehen';

  @override
  String get todayStatusPreviewLoading => 'Vorschau wird vorbereitet…';

  @override
  String get todayStatusPreviewUnavailable =>
      'Vorschau konnte nicht erstellt werden. Dein Plan bleibt unverändert.';

  @override
  String get todayStatusUntitledTile => 'Kachel ohne Titel';

  @override
  String get todayStatusShowAll => 'Alle anzeigen';

  @override
  String todayStatusExpandSection(String section) {
    return '$section aufklappen';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return '$section zuklappen';
  }

  @override
  String get todayStatusReasonDueToday => 'Heute fällig';

  @override
  String get todayStatusReasonNoOpenSlot => 'Kein freier Slot';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'Reisedauer macht dies unmöglich';

  @override
  String get todayStatusReasonOutsideHours =>
      'Außerhalb der verfügbaren Zeiten';

  @override
  String get todayStatusReasonDependencyBlocked =>
      'Wartet auf eine andere Kachel';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Braucht $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Braucht deine Entscheidung';

  @override
  String get todayStatusReasonUnknown => 'Passte nicht';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sessions',
      one: '1 Session',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Kacheln auswählen';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Sessions von $title aufklappen';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Sessions von $title zuklappen';
  }

  @override
  String get analysis => 'Analyse';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get sleep => 'Schlaf';

  @override
  String get overview => 'Übersicht';

  @override
  String get driveTime => 'Fahrzeit';

  @override
  String get signUpWithGoogle => 'Mit Google anmelden';

  @override
  String get signUpWithApple => 'Mit Apple anmelden';

  @override
  String get signUpWithMicrosoft => 'Mit Microsoft anmelden';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get invalidUsernameOrPassword =>
      'Ungültiger Benutzername oder Passwort';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get oneHour => '1 Stunde';

  @override
  String countHours(String count) {
    return '$count Stunden';
  }

  @override
  String get oneMinute => '1 Minute';

  @override
  String countMinutes(String count) {
    return '$count Minuten';
  }

  @override
  String countDays(String count) {
    return '$count Tage';
  }

  @override
  String lateDate(String date) {
    return 'Zu spät ($date)';
  }

  @override
  String get custom => 'Eigene';

  @override
  String get allowAccessDescription =>
      'Tiler erfasst Standortdaten, um Kacheln und Termine effizient zu planen. Deine Daten bleiben privat und werden nur zu diesem Zweck verwendet.';

  @override
  String get allowLocationAccessQ => 'Standortzugriff erlauben?';

  @override
  String get allow => 'Erlauben';

  @override
  String get deny => 'Ablehnen';

  @override
  String get afternoon => 'Nachmittag';

  @override
  String get evening => 'Abend';

  @override
  String get night => 'Nacht';

  @override
  String get morningAndAfternoon => 'Morgen & Nachmittag';

  @override
  String get afternoonAndEvening => 'Nachmittag & Abend';

  @override
  String get lateEvening => 'Spätabend';

  @override
  String get prediction => 'Vorhersage';

  @override
  String get softDeadline => 'Weiche Fälligkeit';

  @override
  String get location => 'Standort';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteYourTilerAccountQ => 'Konto löschen?';

  @override
  String get no => 'Nein';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get forgetPassword => 'Passwort vergessen';

  @override
  String get forgotPasswordBtn => 'Passwort vergessen?';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String lookingUp(String text) {
    return '$text wird gesucht';
  }

  @override
  String get lowPriorityTrunc => 'Niedrig';

  @override
  String get mediumPriorityTrunc => 'Mittel';

  @override
  String get highPriorityTrunc => 'Hoch';

  @override
  String failedToAddGoogleCalendar(String email) {
    return '$email konnte nicht hinzugefügt werden';
  }

  @override
  String deletedCalendar(String email) {
    return 'Kalender $email gelöscht';
  }

  @override
  String get loadingIntegrations => 'Integrationen werden geladen';

  @override
  String get noThirdPartyIntegtions => 'Keine Drittanbieter-Kalender';

  @override
  String get addGoogleCalendar => 'Google Kalender hinzufügen';

  @override
  String get integrations => 'Integrationen';

  @override
  String get integrateOtherCalendars => 'Mit Drittanbieter-Kalendern verbinden';

  @override
  String get clear => 'Leeren';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Zurück';

  @override
  String get skip => 'Überspringen';

  @override
  String get morningPerson => '🌅 Frühaufsteher';

  @override
  String get morning => 'Morgen';

  @override
  String get middayPerson => '🌞 Mittagstyp';

  @override
  String get nightPerson => '🌃 Nachteule';

  @override
  String get enterAddress => 'Gib deine Adresse ein';

  @override
  String get primaryLocationQuestion =>
      'Was ist dein Hauptstandort für Arbeit oder Studium?';

  @override
  String get useDeviceLocation => 'Standort meines Geräts verwenden';

  @override
  String get energyLevelDescriptionQuestion =>
      'Wie beschreibst du deine Energie über den Tag verteilt?';

  @override
  String get incompleteRequest => 'Unvollständige Anfrage gesendet';

  @override
  String get addContact => 'Kontakt hinzufügen';

  @override
  String get invalidContactFormat => 'Keine gültige E-Mail- oder Telefonnummer';

  @override
  String deadlineTime(String time) {
    return 'Fälligkeit: $time';
  }

  @override
  String get accept => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get preview => 'Vorschau';

  @override
  String get addTilette => 'Tilette hinzufügen';

  @override
  String get tileShareName => 'Tile-Share-Name';

  @override
  String get tileShare => 'Tile Share';

  @override
  String get update => 'Aktualisieren';

  @override
  String get noDesignatedTiles => 'Keine zugewiesenen Kacheln';

  @override
  String get noTileCluster => 'Keine Tile Shares erstellt';

  @override
  String get errorLoadingTilelist => 'Fehler beim Laden der Kachelliste';

  @override
  String get failedToLoadTileShareCluster =>
      'Tile-Share-Cluster konnte nicht geladen werden';

  @override
  String get missingTileShareCluster => 'Tile-Share-Cluster fehlt';

  @override
  String get outBound => 'Ausgehend';

  @override
  String get inBound => 'Eingehend';

  @override
  String get multiShare => 'Mehrfach-Share';

  @override
  String get errorOccurred =>
      'Ein Fehler ist aufgetreten!!\nBitte versuche es erneut.';

  @override
  String get authenticationIssues => 'Problem bei der Authentifizierung.';

  @override
  String get userIsNotAuthenticated => 'Benutzer ist nicht authentifiziert.';

  @override
  String get responseContentError =>
      'Antwort enthält nicht den erwarteten Inhalt.';

  @override
  String get responseHandlingError =>
      'Antwort konnte nicht verarbeitet werden.';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get travel => 'Anreise';

  @override
  String numberOfDayForecast(String number) {
    return '$number-Tage-Prognose';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Vorschau konnte nicht geladen werden';

  @override
  String get noDriving => 'Keine Autofahrt';

  @override
  String get tileShareNoteEllipsis => 'Notiz…';

  @override
  String get hi => 'Hallo';

  @override
  String get welcome => 'Willkommen';

  @override
  String get passwordCreationMessagePart1 =>
      'Erstelle ein starkes, eindeutiges Passwort mit ';

  @override
  String get passwordConditionMinLength => 'mindestens sechs Zeichen';

  @override
  String get passwordCreationMessageIncluding => ', einschließlich ';

  @override
  String get passwordConditionUppercaseLetters => 'Großbuchstaben';

  @override
  String get passwordConditionLowercaseLetters => 'Kleinbuchstaben';

  @override
  String get passwordConditionNumbers => 'Zahlen';

  @override
  String get passwordConditionSpecialCharacter => 'einem Sonderzeichen';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ' und ';

  @override
  String get nonViableTimeSlot => 'Kein machbarer Zeitpunkt';

  @override
  String numberAm(String number) {
    return '$number Uhr';
  }

  @override
  String numberPm(String number) {
    return '$number Uhr';
  }

  @override
  String get dayCast => 'DayCast';

  @override
  String get save => 'Speichern';

  @override
  String get selectWeek => 'Woche auswählen';

  @override
  String get selectYear => 'Jahr auswählen';

  @override
  String get retrievingDataIssue => 'Problem beim Abrufen von Daten';

  @override
  String get recurring => 'Wiederkehrend';

  @override
  String get nonRecurring => 'Nicht wiederkehrend';

  @override
  String get dailyReurring => 'Täglich';

  @override
  String get weeklyReurring => 'Wöchentlich';

  @override
  String get biweeklyReurring => '14-tägig';

  @override
  String get monthlyReurring => 'Monatlich';

  @override
  String get yearlyReurring => 'Jährlich';

  @override
  String get ellipsisEmprtNotes => 'Notizen…';

  @override
  String get tileShareDelete => 'Löschen';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Prognose-Kachel';

  @override
  String get previewOthers => 'Andere';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodDay => 'Einen schönen Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String youHaveXBlocks(String count) {
    return 'Du hast $count Blocks vor dir.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Du hast $count Kacheln vor dir.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Du hast $count Tile Shares vor dir.';
  }

  @override
  String countTileShare(String count) {
    return '$count Tile Shares';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Du hast $blockCount Blocks und $tileCount Kacheln vor dir.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Du hast $blockCount Blocks und $tileShareCount Tile Shares vor dir.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Du hast $tileCount Kacheln und $tileShareCount Tile Shares vor dir.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Du hast $blockCount Blocks, $tileCount Kacheln und $tileShareCount Tile Shares vor dir.';
  }

  @override
  String get noTilesPreview =>
      'Für den Rest des Tages ist nichts mehr geplant.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText…';
  }

  @override
  String get createTile => 'Kachel erstellen';

  @override
  String get previewTileForecast => 'Prognose';

  @override
  String get previewTileOptions => 'Optionen';

  @override
  String get previewTileMore => 'Mehr';

  @override
  String get previewTileShuffle => 'Mischen';

  @override
  String get previewTileRevise => 'Überarbeiten';

  @override
  String get previewTileDeferAll => 'Alles aufschieben';

  @override
  String get previewLocationName => 'Standort';

  @override
  String get previewTagName => 'Tag';

  @override
  String get previewClassificationName => 'Kategorie';

  @override
  String get previewBlockedOut => 'Blockiert';

  @override
  String get accountInfo => 'Kontoinformationen';

  @override
  String get fistName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get tilePreferences => 'Kachel-Einstellungen';

  @override
  String get notificationsPreferences => 'Benachrichtigungseinstellungen';

  @override
  String get security => 'Sicherheit';

  @override
  String get connections => 'Verbindungen';

  @override
  String get myLocations => 'Meine Standorte';

  @override
  String get aboutTiler => 'Über Tiler';

  @override
  String get howToUseTiler => 'So verwendest du Tiler';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get setLocation => 'Standort festlegen';

  @override
  String get connectCalendars => 'Verbinde deine Kalender';

  @override
  String get configure => 'Konfigurieren';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get googleCalendar => 'Google Kalender';

  @override
  String get appleCalendar => 'Apple Kalender';

  @override
  String get googleTasks => 'Google Aufgaben';

  @override
  String get microsoft => 'Microsoft';

  @override
  String get slack => 'Slack';

  @override
  String get addCalendar => 'Kalender hinzufügen';

  @override
  String get calendarConnected => 'Kalender verbunden';

  @override
  String get calendarConnectionDeclined =>
      'Kalenderverbindung wurde abgebrochen';

  @override
  String get calendarConnectionError =>
      'Dein Kalender konnte nicht verbunden werden';

  @override
  String get sleepDuration => 'Schafdauer';

  @override
  String get transportationMethodQuestion => 'Wie bewegst du dich fort?';

  @override
  String get defineYourTimeRestrictions =>
      'Lege deine Zeiteinschränkungen fest';

  @override
  String get setWorkHours => 'Arbeitszeiten festlegen';

  @override
  String get setYourBlockOutHours => 'Lege deine Ausschlusszeiten fest';

  @override
  String get travelMediumBiking => 'Fahrradfahren';

  @override
  String get travelMediumTransit => 'Öffentliche Verkehrsmittel';

  @override
  String get travelMediumDriving => 'Auto fahren';

  @override
  String get travelMediumTransport => 'Transport';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio min';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio Std';
  }

  @override
  String get bedTime => 'Bettzeit';

  @override
  String get sleepTime => 'Schlafzeit';

  @override
  String get scheduleFullness => 'Zeitplan-Auslastung';

  @override
  String get scheduleFullnessDescription => 'Wie voll soll dein Zeitplan sein?';

  @override
  String scheduleFullnessValue(int percentage) {
    return '$percentage % Ziel-Auslastung';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Die Zielwerte liegen zwischen $minimum % und $maximum %. So bleibt eine nützliche Grundlinie erhalten und Änderungen sowie Reisezeit finden ihren Platz.';
  }

  @override
  String get schedulePreferences => 'Zeitplan-Einstellungen';

  @override
  String get lighter => 'Leichter';

  @override
  String get balanced => 'Ausgewogen';

  @override
  String get fuller => 'Volller';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Kachel-Einstellungen wurden erfolgreich aktualisiert.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Benachrichtigungseinstellungen wurden erfolgreich aktualisiert.';

  @override
  String get tileReminders => 'Kachelerinnerungen';

  @override
  String get appUpdates => 'App-Updates';

  @override
  String get marketingUpdates => 'Marketing-Updates';

  @override
  String get emailNotifications => 'E-Mail-Benachrichtigungen';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get countryCode => 'Ländervorwahl';

  @override
  String get dateOfBirth => 'Geburtsdatum';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'Kontoinformationen wurden erfolgreich aktualisiert.';

  @override
  String get reachingServerIssues =>
      'Problem bei der Verbindung zu Tiler-Servern';

  @override
  String get deleteAccountConfirmation =>
      'Bist du sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get disconnect => 'Trennen';

  @override
  String get integrationsSetLocation => 'Standort festlegen';

  @override
  String get googleCalender => 'Google Kalender';

  @override
  String get passwordsMustMatch => 'Passwörter müssen übereinstimmen';

  @override
  String get parenthesisLate => '(Zu spät)';

  @override
  String get failedToAddIntegration =>
      'Integration konnte nicht hinzugefügt werden';

  @override
  String get unknownProvider => 'Unbekannter Anbieter';

  @override
  String get manageCalendars => 'Kalender verwalten';

  @override
  String get calendarItems => 'Kalendereinträge';

  @override
  String get noCalendarItemsFound => 'Keine Kalendereinträge gefunden';

  @override
  String get calendarItemsWillAppearHere =>
      'Deine Kalendereinträge erscheinen hier';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount von $totalCount Kalendern aktiv';
  }

  @override
  String get toggleCalendarsToSync =>
      'Kalender auswählen, die mit Tiler synchronisiert werden';

  @override
  String get unknownCalendar => 'Unbekannter Kalender';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount von $totalCount aktiv';
  }

  @override
  String integrationCount(int count) {
    return '$count Integrationen';
  }

  @override
  String get errorLoadingCalendarItems =>
      'Fehler beim Laden der Kalendereinträge';

  @override
  String get integratedCalendars => 'Kalender';

  @override
  String get integrationAdd => 'Hinzufügen';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Darf Tiler auf deinen Standort zugreifen, um standortbasierte Empfehlungen und Benachrichtigungen bereitzustellen?';

  @override
  String get recurringTasks => 'Wiederkehrende Aufgaben';

  @override
  String get yourProfession => 'Dein Beruf?';

  @override
  String get yourProfessionQuestion => 'Was machst du beruflich?';

  @override
  String get yourProfessionHint => 'Beschreibe, was du beruflich machst';

  @override
  String get medicalProfessional => 'Mediziner/in';

  @override
  String get softwareDeveloper => 'Softwareentwickler/in';

  @override
  String get student => 'Student/in';

  @override
  String get engineer => 'Ingenieur/in';

  @override
  String get fieldSalesProfessional => 'Außendienstmitarbeiter/in';

  @override
  String get remoteWorker => 'Remote-Arbeitnehmer & Digital Nomad';

  @override
  String get stayAtHomeParent => 'Zuhause bleibender Elternteil';

  @override
  String get clientAccountManagers => 'Kunden-/Account-Manager';

  @override
  String get other => 'Sonstiges';

  @override
  String get tileSuggestions => 'Kachelvorschläge';

  @override
  String get personalOrWorkQuestion => 'Wofür wirst du Tiler verwenden?';

  @override
  String get enter3chars => 'Gib mindestens 3 Zeichen ein.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Los in $duration, um pünktlich anzukommen';
  }

  @override
  String get leaveNowToArriveOnTime => 'Jetzt los, um pünktlich anzukommen!';

  @override
  String durationDrive(String duration) {
    return '$duration mit dem Auto';
  }

  @override
  String durationTransit(String duration) {
    return '$duration mit ÖPNV';
  }

  @override
  String durationBike(String duration) {
    return '$duration mit dem Rad';
  }

  @override
  String durationWalk(String duration) {
    return '$duration zu Fuß';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration Auto bis $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration ÖPNV bis $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration Rad bis $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration zu Fuß bis $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Los bis $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Verkehr erkannt - Umleitung vorgeschlagen';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Verkehr: +$minutes min Verspätung';
  }

  @override
  String get heavyTrafficExpected => 'Starker Verkehr erwartet';

  @override
  String get addWithAI => 'Mit KI hinzufügen';

  @override
  String get focusTime => 'Fokuszzeit';

  @override
  String get videoMeeting => 'Videocall';

  @override
  String get sharedWith => 'Geteilt mit';

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours Std $minutes min';
  }

  @override
  String travelDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String travelDurationHours(int hours) {
    return '$hours Std';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours Std $minutes min';
  }

  @override
  String travelViaRoute(String route) {
    return 'über $route';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return ' $travelMode nach ';
  }

  @override
  String get travelModeDriving => 'Auto';

  @override
  String get travelModeWalking => 'zu Fuß';

  @override
  String get travelModeBicycling => 'Rad';

  @override
  String get travelModeTransitLower => 'ÖPNV';

  @override
  String travelDurationCompact(int minutes) {
    return '$minutes min';
  }

  @override
  String get yourDayIsOptimized => 'Dein Tag ist optimiert.';

  @override
  String get yourDayAtAGlance => 'Dein Tag auf einen Blick';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration Reisezeit heute.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count Kacheln heute geplant.';
  }

  @override
  String get viewRoute => 'Route anzeigen';

  @override
  String get focusModeChip => 'Fokusmodus';

  @override
  String get showRouteChip => 'Route zeigen';

  @override
  String get reOptimizeChip => 'Neu optimieren';

  @override
  String get todayColon => 'Heute:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount Kacheln, $blockCount Blocks';
  }

  @override
  String get timeSavedColon => 'Gesparte Zeit:';

  @override
  String get travelTimeColon => 'Reisezeit:';

  @override
  String travelTime(String duration) {
    return 'Reisezeit: $duration';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours Std $minutes min';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hours Std';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String hourAm(int hour) {
    return '$hour Uhr';
  }

  @override
  String hourPm(int hour) {
    return '$hour Uhr';
  }

  @override
  String get scheduleConflict => 'Planungskonflikt';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '„$tile1\" und „$tile2\" sind zur gleichen Zeit geplant';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '„$tile1\" liegt innerhalb von „$tile2\" ($overlap Überlappung)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '„$tile1\" überlappt „$tile2\" um $overlap';
  }

  @override
  String get fix => 'Beheben';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Konflikt: $minutes min Überlappung';
  }

  @override
  String get oneScheduleConflict => '1 Planungskonflikt';

  @override
  String countScheduleConflicts(int count) {
    return '$count Planungskonflikte';
  }

  @override
  String get tapToReviewAndResolve => 'Tippen zum Prüfen und Lösen';

  @override
  String countConflicts(int count) {
    return '$count Konflikte';
  }

  @override
  String get tapToExpand => 'Tippen zum Aufklappen';

  @override
  String conflictingTiles(int count) {
    return '$count Kacheln mit Konflikt';
  }

  @override
  String totalOverlap(String duration) {
    return 'Gesamtüberlappung: $duration';
  }

  @override
  String get autoResolve => 'Automatisch lösen';

  @override
  String get untitledTile => 'Kachel ohne Titel';

  @override
  String get untitledEvent => 'Ohne Titel';

  @override
  String get extendedEventSingular => '1 Extended-Event';

  @override
  String extendedEventsPlural(int count) {
    return '$count Extended-Events';
  }

  @override
  String get extendedEventsTapToView =>
      'Tippen für ganztägige und lange Events';

  @override
  String get extendedEventsTitle => 'Extended-Events';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Events über 16 Stunden',
      one: '1 Event über 16 Stunden',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Heutige Route';

  @override
  String get noLocationsToday => 'Heute keine Standorte';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Füge deinen Kacheln Standorte hinzu, um deine Tagesroute zu sehen';

  @override
  String countStops(int count) {
    return '$count Stopps';
  }

  @override
  String get routeOptimized => 'Route optimiert';

  @override
  String savedTravelTime(String duration) {
    return '$duration Reisezeit gespart';
  }

  @override
  String get firstStop => 'Erster Stopp';

  @override
  String get stop => 'Stopp';

  @override
  String arriveBy(String time) {
    return 'Ankunft bis $time';
  }

  @override
  String get fromPreviousStop => 'ab vorherigem Stopp';

  @override
  String get viewTile => 'Kachel ansehen';

  @override
  String get editTile => 'Kachel bearbeiten';

  @override
  String get startNavigation => 'Navigation starten';

  @override
  String get noLocationAvailable => 'Kein Standort';

  @override
  String get seeTodaysRoute => 'Heutige Route ansehen';

  @override
  String get whatWouldYouLikeToDo => 'Was möchtest du tun?';

  @override
  String get describeATask =>
      'Beschreibe eine Aufgabe, wir kümmern uns ums Kacheln.';

  @override
  String get microphonePermissionDenied => 'Mikrofon-Zugriff verweigert.';

  @override
  String failedToStartRecording(String error) {
    return 'Aufnahme konnte nicht gestartet werden: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Aufnahme konnte nicht gestoppt werden: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Audio-Konversionsfehler: $error';
  }

  @override
  String get audioConversionFailed => 'Audio-Konversion fehlgeschlagen';

  @override
  String get recordingPathIsEmpty => 'Aufnahmepfad ist leer';

  @override
  String get noActiveRecording => 'Keine aktive Aufnahme';

  @override
  String get joinMeeting => 'Meeting beitreten';

  @override
  String get openLink => 'Link öffnen';

  @override
  String get actions => 'Aktionen';

  @override
  String get hideActions => 'Aktionen ausblenden';

  @override
  String get pendingRsvpSingular => '1 Event benötigt Antwort';

  @override
  String pendingRsvpPlural(int count) {
    return '$count Events benötigen Antwort';
  }

  @override
  String get pendingRsvpHappeningNow =>
      'Findet gerade statt - antworte, um beizutreten';

  @override
  String get pendingRsvpStartingSoon => 'Beginnt bald - jetzt antworten';

  @override
  String get pendingRsvpWithinHour => 'Beginnt innerhalb einer Stunde';

  @override
  String get pendingRsvpUpcoming => 'Bevorstehend - tippen zum Antworten';

  @override
  String get pendingRsvpTapToReview => 'Tippen zum Prüfen und Antworten';

  @override
  String get pendingRsvpTitle => 'Ausstehende Antworten';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Events warten auf deine Antwort',
      one: '1 Event wartet auf deine Antwort',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Beginnt bald';

  @override
  String get pendingRsvpLater => 'Später heute & bevorstehend';

  @override
  String get declinedRsvpSingular => '1 abgelehntes Event';

  @override
  String declinedRsvpPlural(int count) {
    return '$count abgelehnte Events';
  }

  @override
  String get declinedRsvp => 'Abgelehnte Events';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 ausstehend, $declinedCount abgelehnt';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount ausstehend, 1 abgelehnt';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount ausstehend, $declinedCount abgelehnt';
  }

  @override
  String get rsvpNeedsAction => 'Antwort benötigt';

  @override
  String get rsvpTentative => 'Unbestimmt';

  @override
  String get rsvpAccepted => 'Angenommen';

  @override
  String get rsvpDeclined => 'Abgelehnt';

  @override
  String unableToOpenLinkError(String link) {
    return 'Link konnte nicht geöffnet werden: $link';
  }

  @override
  String get leaveNow => 'Jetzt los!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Los in $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count Warnungen';
  }

  @override
  String get alertChipLeaveNow => 'Jetzt los';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Los in $minutes min';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Konflikte',
      one: '1 Konflikt',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ganztages-Events',
      one: '1 Ganztages-Event',
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
  String get accepted => 'Angenommen';

  @override
  String get declined => 'Abgelehnt';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Auf $calendarSource antworten';
  }

  @override
  String get unknown => 'Kalereinladung';

  @override
  String get loadingPreviousDays => 'Vorherige Tage werden geladen…';

  @override
  String get loadingUpcomingDays => 'Kommende Tage werden geladen…';

  @override
  String get requestTimeout => 'Anfrage-Timeout - bitte Verbindung prüfen';

  @override
  String get failedToPauseTile => 'Kachel konnte nicht pausiert werden';

  @override
  String get failedToResumeTile => 'Kachel konnte nicht fortgesetzt werden';

  @override
  String get failedToMoveUpTask =>
      'Aufgabe konnte nicht nach vorne verschoben werden';

  @override
  String get failedToUpdateTile => 'Kachel konnte nicht aktualisiert werden';

  @override
  String get failedToBuzzSchedule =>
      'Zeitplan konnte nicht neu berechnet werden';

  @override
  String get failedToShuffleSchedule => 'Zeitplan konnte nicht gemischt werden';

  @override
  String get failedToProcrastinateTile =>
      'Kachel konnte nicht verschoben werden';

  @override
  String get tutorialStepYourScheduleTitle => 'Dein Zeitplan';

  @override
  String get tutorialStepYourScheduleBody =>
      'Dein Tag ist in Kacheln organisiert – clevere Zeitblöcke, die Tiler für dich anordnet. Scrolle hoch und runter, um deinen ganzen Tag zu sehen.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Erstellen & Optimieren';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Tippe hier, um eine neue Aufgabe zu erstellen. Sage Tiler, was du tun musst und wie lange es dauert – Tiler überlegt sich den Zeitpunkt.';

  @override
  String get tutorialCalloutReOptimize => 'Neu optimieren';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'Tag gerät aus der Bahn? Ab jetzt neu berechnen, während dein bevorstehender Plan grob stabil bleibt';

  @override
  String get tutorialCalloutTravelTime => 'Reisezeit';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Tiler berücksichtigt die Fahrzeit zwischen Standorten';

  @override
  String get tutorialStepQuickCreateTitle => 'Schnell erstellen';

  @override
  String get tutorialStepQuickCreateBody =>
      'Das ist das Schnellhinzufügen-Panel. Nenne deine Kachel und setze eine Dauer für ein schnelles Hinzufügen.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'Das ist das Schnellhinzufügen-Panel hinter mir! Nenne deine Kachel, setze eine Dauer und tippe Hinzufügen – Tiler übernimmt den Rest.';

  @override
  String get tutorialCalloutNameYourTile => 'Kachel benennen';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Beschreibe die Aufgabe, die du erledigen möchtest';

  @override
  String get tutorialCalloutSetDuration => 'Dauer festlegen';

  @override
  String get tutorialCalloutSetDurationDesc =>
      'Wie lange wird diese Aufgabe dauern?';

  @override
  String get tutorialCalloutMoreOptions => 'Weitere Optionen';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Standort, Fälligkeit oder Wiederholung über den Voll-Editor hinzufügen';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Standort, Fälligkeit oder Wiederholung hinzufügen';

  @override
  String get tutorialStepTilerWorksTitle => 'Tiler arbeitet für dich';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tiler ordnet deine Kacheln automatisch nach deinen Energieniveaus, der Reisezeit und den Fälligkeiten. Füge einfach hinzu, was du tun musst – Tiler überlegt sich den Zeitpunkt.';

  @override
  String get tutorialCalloutForecast => 'Prognose';

  @override
  String get tutorialCalloutForecastDesc =>
      'Sieh, wann eine Kachel eingefügt wird, bevor du sie auswählst';

  @override
  String get tutorialCalloutShuffle => 'Mischen';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Verändere die Reihenfolge und erhalte einen Vorschlag für deinen nächsten Schritt';

  @override
  String get tutorialCalloutDeferAll => 'Alles aufschieben';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Schwieriger Tag? Schiebe alles nach hinten';

  @override
  String get tutorialStepControlTilesTitle => 'Kacheln steuern';

  @override
  String get tutorialStepControlTilesBody =>
      'Jede Kachel hat Steuerungen, um deine Aufgaben in Echtzeit zu verwalten:';

  @override
  String get tutorialCalloutPlay => 'Start';

  @override
  String get tutorialCalloutPlayDesc => 'Beginne, an dieser Kachel zu arbeiten';

  @override
  String get tutorialCalloutPause => 'Pause';

  @override
  String get tutorialCalloutPauseDesc =>
      'Mach eine Pause – Tiler plant den Rest neu';

  @override
  String get tutorialCalloutComplete => 'Fertigstellen';

  @override
  String get tutorialCalloutCompleteDesc => 'Geschafft! Als erledigt markieren';

  @override
  String get tutorialCalloutProcrastinate => 'Aufschieben';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Nicht jetzt – auf später verschieben';

  @override
  String get tutorialStepBigPictureTitle => 'Das große Bild';

  @override
  String get tutorialStepBigPictureBody =>
      'Tippe auf das Kalendersymbol, um zwischen drei Ansichten zu wechseln:';

  @override
  String get tutorialCalloutDaily => 'Täglich';

  @override
  String get tutorialCalloutDailyDesc =>
      'Stunde für Stunde – deine detaillierte Agenda';

  @override
  String get tutorialCalloutWeekly => 'Wöchentlich';

  @override
  String get tutorialCalloutWeeklyDesc => 'Die ganze Woche auf einen Blick';

  @override
  String get tutorialCalloutMonthly => 'Monatlich';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Mit einer Monatsübersicht vorausplanen';

  @override
  String get tutorialStepToolkitTitle => 'Dein Werkzeugkasten';

  @override
  String get tutorialStepToolkitBody =>
      'Diese praktischen Werkzeuge sind immer griffbereit:';

  @override
  String get tutorialCalloutShare => 'Teilen';

  @override
  String get tutorialCalloutShareDesc =>
      'Zusammenarbeiten – Kacheln mit anderen teilen';

  @override
  String get tutorialCalloutSearch => 'Suchen';

  @override
  String get tutorialCalloutSearchDesc => 'Jede Kachel nach Namen finden';

  @override
  String get tutorialCalloutSettings => 'Einstellungen';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Erlebnis anpassen, Kalender verbinden, Einstellungen festlegen';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Tippe auf die Chat-Schaltfläche, um Kacheln hinzuzufügen oder anzupassen, indem du einfach mit Tiler sprichst';

  @override
  String get tutorialStepChatTitle => 'Mit Tiler chatten';

  @override
  String get tutorialStepChatBody =>
      'Tippe jederzeit auf die Chat-Schaltfläche, um Kacheln einfach per Gespräch hinzuzufügen oder anzupassen – keine Formulare nötig.';

  @override
  String get tutorialNavNext => 'Weiter';

  @override
  String get tutorialNavNextArrow => 'Weiter →';

  @override
  String get tutorialNavBack => 'Zurück';

  @override
  String get tutorialNavBackArrow => '← Zurück';

  @override
  String get tutorialNavSkip => 'Überspringen';

  @override
  String get tutorialNavLetsGo => 'Los geht\'s!';

  @override
  String get welcomeExplainerHeadline => 'Kacheln vs. Blocks';

  @override
  String get welcomeExplainerSubtitle =>
      'Ein kurzer Blick darauf, wie Tiler deinen Tag plant.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Blocks sind fest. Sie finden zu einer festen Zeit statt.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Kacheln sind flexibel. Tiler passt sie an deine Blocks an.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'Zahnarzttermin verschoben auf $time – Tiler plant deine Kacheln darum neu.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Verschoben';

  @override
  String get welcomeExplainerReplannedBadge => 'Neu geplant';

  @override
  String get welcomeExplainerBlockStandup => 'Team-Standup';

  @override
  String get welcomeExplainerBlockDentist => 'Zahnarzt';

  @override
  String get welcomeExplainerTileWorkout => 'Training';

  @override
  String get welcomeExplainerTileReport => 'Bericht schreiben';

  @override
  String get welcomeExplainerTileGroceries => 'Einkaufen';

  @override
  String get welcomeExplainerLegendBlock => 'Block';

  @override
  String get welcomeExplainerLegendTile => 'Kachel';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Kachel-Einstellungen';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Deine KI-Einstellungen findest du hier – wie du reist, deine Arbeits- und persönlichen Zeiten und Ausschlusszeiten.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Wie du unterwegs bist';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tiler berücksichtigt die Reisezeit zwischen Kacheln anhand deiner bevorzugten Fortbewegungsart.';

  @override
  String get tutorialStepTilePrefsHoursTitle =>
      'Arbeits- und persönliche Zeiten';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Wann Tiler Arbeits- oder persönliche Kacheln planen darf. Tippe auf eines, um ein Profil einzurichten.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Ausschlusszeiten';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Bettzeit und Schafdauer – Zeiten, in die Tiler nichts plant.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'Wird transkribiert';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get noChatHistory => 'Kein Chatverlauf';

  @override
  String get unknownChat => 'Unbekannter Chat';

  @override
  String get transcriptionFailed => 'Transkription fehlgeschlagen';

  @override
  String get acceptChanges => 'Änderungen akzeptieren';

  @override
  String get noRequestToExecute => 'Keine Anfrage auszuführen';

  @override
  String get initializingAction => 'Aktionsgenerierung wird initialisiert';

  @override
  String get settingThingsUp => 'Alles wird vorbereitet';

  @override
  String get preparingRequest => 'Deine Anfrage wird vorbereitet';

  @override
  String get gettingReady => 'Vorbereiten';

  @override
  String get processingAction => 'Aktion wird verarbeitet';

  @override
  String get workingOnIt => 'Wird bearbeitet';

  @override
  String get analyzingRequest => 'Deine Anfrage wird analysiert';

  @override
  String get thinking => 'Denkt nach';

  @override
  String get actionComplete => 'Aktionsverarbeitung abgeschlossen';

  @override
  String get processingDone => 'Verarbeitung abgeschlossen';

  @override
  String get allSet => 'Alles erledigt';

  @override
  String get finishedProcessing => 'Verarbeitung abgeschlossen';

  @override
  String get generatingSummary => 'Zusammenfassung wird erstellt';

  @override
  String get summarizingResults => 'Ergebnisse werden zusammengefasst';

  @override
  String get creatingOverview => 'Übersicht wird erstellt';

  @override
  String get preparingSummary => 'Zusammenfassung wird vorbereitet';

  @override
  String get summaryComplete => 'Zusammenfassungsgenerierung abgeschlossen';

  @override
  String get summaryReady => 'Zusammenfassung bereit';

  @override
  String get overviewComplete => 'Übersicht abgeschlossen';

  @override
  String get doneSummarizing => 'Zusammenfassen abgeschlossen';

  @override
  String get loadingSchedule => 'Zeitplandaten werden geladen';

  @override
  String get fetchingSchedule => 'Dein Zeitplan wird abgerufen';

  @override
  String get retrievingCalendar => 'Kalender wird abgerufen';

  @override
  String get loadingTimeline => 'Zeitleiste wird geladen';

  @override
  String get optimizingSchedule => 'Zeitplan wird optimiert';

  @override
  String get reorganizingDay => 'Dein Tag wird umorganisiert';

  @override
  String get findingBestFit => 'Bester Passform wird gesucht';

  @override
  String get adjustingTimeline => 'Zeitleiste wird angepasst';

  @override
  String get scheduleComplete => 'Zeitplanoptimierung abgeschlossen';

  @override
  String get scheduleUpdated => 'Zeitplan aktualisiert';

  @override
  String get timelineOptimized => 'Zeitleiste optimiert';

  @override
  String get allDone => 'Alles erledigt';

  @override
  String get connectionLost => 'Verbindung verloren. Bitte aktualisieren';

  @override
  String get sendingRequest => 'Anfrage wird gesendet';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'WebSocket-Verbindung nach 5 Versuchen verloren';

  @override
  String get webSocketMessageHandlingError =>
      'Fehler bei der Nachrichtenverarbeitung';

  @override
  String get jsonParseError => 'JSON-Parsefehler';

  @override
  String get processError => 'Prozessfehler';

  @override
  String get socketConnectionError => 'Socket-Verbindungsfehler';

  @override
  String get keepAliveFailed =>
      'Verbindung konnte nicht aufrechterhalten werden';

  @override
  String get copy => 'Kopieren';

  @override
  String get entityIdNotFound => 'Keine Preview-Entitäts-ID gefunden';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackCategory => 'Kategorie';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategoryFeature => 'Funktion';

  @override
  String get feedbackCategoryEnhancement => 'Verbesserung';

  @override
  String get feedbackCategoryGeneral => 'Allgemein';

  @override
  String get feedbackTitle => 'Titel';

  @override
  String get feedbackTitleHint => 'Kurze Zusammenfassung deines Feedbacks';

  @override
  String get feedbackDescription => 'Beschreibung';

  @override
  String get feedbackDescriptionHint => 'Gib Details zu deinem Feedback an';

  @override
  String get feedbackSubmitted => 'Feedback erfolgreich gesendet';

  @override
  String get feedbackError => 'Feedback konnte nicht gesendet werden';

  @override
  String get noPreviewsAvailable =>
      'Für diese Anfrage sind keine TileCasts verfügbar';

  @override
  String get previewUnavailable =>
      'Der ausgewählte TileCast ist nicht verfügbar';

  @override
  String get previewSummaryUnavailable =>
      'TileCast konnte nicht geladen werden';

  @override
  String get previewGenerating => 'TileCast wird erstellt…';

  @override
  String get previewTimedOut =>
      'Der TileCast dauert länger als erwartet. Versuche es in einem Moment erneut.';

  @override
  String get previewGenerationFailed =>
      'Diesen TileCast konnten wir nicht erstellen.';

  @override
  String get previewInvalidated =>
      'Dieser TileCast ist nicht mehr gültig, da sich dein Zeitplan geändert hat.';

  @override
  String get previewStaleBanner =>
      'Dieser TileCast zeigt einen früheren Stand deines Zeitplans.';

  @override
  String get previewNonViableLabel => 'Konnte nicht geplant werden';

  @override
  String get reviewChanges => 'Änderungen prüfen';

  @override
  String get previewRetry => 'Erneut versuchen';

  @override
  String get previewPreparing => 'TileCast wird vorbereitet…';

  @override
  String get previewReadyToView => 'Tippen, um TileCast anzuzeigen';

  @override
  String get previewActionsOutdated => 'Veraltet – sende eine neue Nachricht';

  @override
  String get previewActionsUnavailable => 'TileCast nicht verfügbar';

  @override
  String get tileCastStaleNote =>
      'Dein Zeitplan hat sich geändert – dieser TileCast ist möglicherweise veraltet';

  @override
  String get tileCastAlsoIncluded => 'Ebenfalls enthalten';

  @override
  String actionsCount(int count) {
    return '$count Aktionen';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'Notizen werden geladen…';

  @override
  String get notesSaving => 'Wird gespeichert…';

  @override
  String get notesSaved => 'Gespeichert';

  @override
  String get notesUnsaved => 'Wird bearbeitet…';

  @override
  String get notesSaveError => 'Konnte nicht gespeichert werden';

  @override
  String get notesSaveNow => 'Jetzt speichern';

  @override
  String get notesShowPreview => 'Vorschau';

  @override
  String get notesShowEditor => 'Bearbeiten';

  @override
  String get notesPreviewEmpty => 'Noch nichts zur Vorschau.';

  @override
  String get notesLinkPromptTitle => 'Link einfügen';

  @override
  String get notesConflictTitle =>
      'Jemand anderes hat diese Notiz aktualisiert.';

  @override
  String get notesConflictDiscardMine => 'Meine verwerfen';

  @override
  String get notesConflictKeepEditing => 'Weiterbearbeiten';

  @override
  String get notesToolBold => 'Fett';

  @override
  String get notesToolItalic => 'Kursiv';

  @override
  String get notesToolStrikethrough => 'Durchstreichen';

  @override
  String get notesToolInlineCode => 'Inline-Code';

  @override
  String get notesToolHeading1 => 'Überschrift 1';

  @override
  String get notesToolHeading2 => 'Überschrift 2';

  @override
  String get notesToolBulletList => 'Aufzählungsliste';

  @override
  String get notesToolNumberedList => 'Nummerierte Liste';

  @override
  String get notesToolTaskList => 'Aufgabenliste';

  @override
  String get notesToolQuote => 'Zitat';

  @override
  String get notesToolLink => 'Link';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get notesViewerTitle => 'Notiz';

  @override
  String get notesTapToAdd => 'Tippen, um eine Notiz hinzuzufügen';

  @override
  String get notesTapToEdit =>
      'Tippen zum Bearbeiten · lange drücken zum Lesen';

  @override
  String get notesDone => 'Fertig';

  @override
  String get endOfDay => 'Tagesende';

  @override
  String get search => 'Suchen';

  @override
  String get share => 'Teilen';

  @override
  String get openChat => 'Chat öffnen';

  @override
  String get goToToday => 'Zu heute springen';

  @override
  String get switchCalendarView => 'Kalenderansicht wechseln';

  @override
  String get previewSundialGreeting => 'Hallo.';

  @override
  String get previewSundialCountsPrefix => 'Heute stehen an';

  @override
  String get previewSundialCountsSuffix => 'warten.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count Kacheln';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count Blocks';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count Tile Shares';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours Std. Arbeit';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins min Anfahrtszeit';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'dein Tag ist bis $time frei';
  }

  @override
  String get previewSundialAndSeparator => 'und';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count Orte';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '$hours Std. Schlaf';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '$hours Std. frei';
  }

  @override
  String get previewSundialFullyBooked => 'Alles vergeben';

  @override
  String get previewSundialTier0 => 'Freier Tag';

  @override
  String get previewSundialTier1 => 'Erst der Anfang';

  @override
  String get previewSundialTier2 => 'Unterwegs';

  @override
  String get previewSundialTier3 => 'Guter Fortschritt';

  @override
  String get previewSundialTier4 => 'Fast geschafft';

  @override
  String get previewSundialTodayLabel => 'Heute';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles Kacheln, $blocks Blocks, $nonViable nicht geplant';
  }

  @override
  String get timelineClearHeading => 'Deine Zeitleiste ist heute frei';

  @override
  String get timelineClearAddTask => 'Kachel hinzufügen';

  @override
  String get aiConsentTitle => 'Lerne Tiler AI kennen';

  @override
  String get aiConsentSubtitle => 'Dein KI-Planungsassistent';

  @override
  String get aiConsentIntro =>
      'Um deine Worte in einen Zeitplan zu verwandeln, teilt Tiler AI das, was du sendest, mit vertrauenswürdigen KI-Anbietern.';

  @override
  String get aiConsentDataTitle => 'Was wir senden';

  @override
  String get aiConsentDataBody =>
      'Die Nachrichten und Sprachaufnahmen, die du sendest, plus relevante Details aus deinem Zeitplan.';

  @override
  String get aiConsentProvidersTitle => 'Wer es erhält';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini und OpenAI, unsere externen KI-Anbieter.';

  @override
  String get aiConsentPrivacyLink => 'Unsere Datenschutzrichtlinie lesen';

  @override
  String get aiConsentContinue => 'Zu Tiler AI weiter';

  @override
  String get aiConsentAgreementNotice =>
      'Mit dem Weiterfahren stimmst du zu, diese Daten mit dem externen Anbieter wie oben beschrieben zu teilen.';

  @override
  String get aiConsentClose => 'Schließen';

  @override
  String get legalFooterPrefix => 'Mit dem Weiterfahren stimmst du den ';

  @override
  String get legalFooterTerms => 'Bedingungen';

  @override
  String get legalFooterAnd => ' und der ';

  @override
  String get legalFooterPrivacy => 'Datenschutzrichtlinie';

  @override
  String get aiConsentLinkError => 'Der Link konnte nicht geöffnet werden.';

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
