// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get scheduleReadFailedTitle => 'Couldn\'t load your events.';

  @override
  String get scheduleReadFailedBody => 'Try again in a moment.';

  @override
  String get scheduleReadRefreshFailed => 'Couldn\'t refresh your events.';

  @override
  String get scheduleReadRetained => 'Showing your last loaded schedule.';

  @override
  String get scheduleReadRetrying => 'Trying again...';

  @override
  String get scheduleReadSignIn => 'Sign in to load your events.';

  @override
  String get scheduleSummaryUnavailable => 'Summary unavailable';

  @override
  String get notesLoadFailed =>
      'Je notities konden niet worden geladen. Open de notitie-editor opnieuw.';

  @override
  String get onboardingSubmitFailed =>
      'Je instellingen konden niet worden opgeslagen. Je keuzes blijven bewaard. Probeer het opnieuw of sla deze stap voorlopig over.';

  @override
  String operationFailed(String operation) {
    return '$operation is mislukt. Probeer het opnieuw.';
  }

  @override
  String get scheduleLoadFailed =>
      'Je planning kon niet worden geladen. Vernieuw om het opnieuw te proberen.';

  @override
  String get chatConnectionFailed =>
      'Er kon geen verbinding met de chat worden gemaakt. Open de chat opnieuw.';

  @override
  String get chatHistoryFailed =>
      'Je chatgeschiedenis kon niet worden geladen. Open het gesprek opnieuw.';

  @override
  String get chatSendFailed =>
      'Je bericht kon niet worden verzonden. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get chatRecordingFailed =>
      'De spraakopname kon niet worden gestart. Controleer de microfoontoegang en probeer het opnieuw.';

  @override
  String get chatCancelRecordingFailed =>
      'De spraakopname kon niet worden geannuleerd. Probeer de opname opnieuw te stoppen.';

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Toevoegen';

  @override
  String get setupCustomRestrictions => 'Aangepaste restricties instellen';

  @override
  String get day => 'Dag';

  @override
  String get hour => 'Uur';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Maandag';

  @override
  String get tuesday => 'Dinsdag';

  @override
  String get wednesday => 'Woensdag';

  @override
  String get thursday => 'Donderdag';

  @override
  String get friday => 'Vrijdag';

  @override
  String get saturday => 'Zaterdag';

  @override
  String get sunday => 'Zondag';

  @override
  String get duration => 'Duur';

  @override
  String get durationStar => 'Duur*';

  @override
  String get addTile => 'Tegeltje toevoegen';

  @override
  String get defer => 'Uitstellen';

  @override
  String get deferAll => 'Alles uitstellen';

  @override
  String get procrastinating => 'Uitstellen';

  @override
  String get forecast => 'Voorspelling';

  @override
  String get whenQ => 'Wanneer?';

  @override
  String get loading => 'Laden';

  @override
  String get loadingPrediction => 'Voorspelling laden';

  @override
  String get address => 'Adres';

  @override
  String get settings => 'Instellingen';

  @override
  String get nickName => 'Bijnaam';

  @override
  String get selectADeadline => 'Kies een deadline';

  @override
  String get close => 'Sluiten';

  @override
  String get tileName => 'Naam tegeltje';

  @override
  String get tileNameStar => 'Naam tegeltje*';

  @override
  String get starAreRequired => '* zijn vereiste velden';

  @override
  String get howManyTimes => 'Hoe vaak';

  @override
  String get once => 'Eén keer';

  @override
  String get weekdaysAndWorkHours => 'Werkdagen en werktijden';

  @override
  String get weekend => 'Weekend';

  @override
  String get anytime => 'Wanneer dan maar';

  @override
  String get repetition => 'Herhaling';

  @override
  String get reminder => 'Herinnering';

  @override
  String get restriction => 'Restrictie';

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get usernameOrEmail => 'Gebruikersnaam of e-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String get email => 'E-mail';

  @override
  String get back => 'Terug';

  @override
  String get confirmPassword => 'Wachtwoord bevestigen';

  @override
  String get passwordIsRequired => 'Wachtwoord is vereist';

  @override
  String get emailIsRequired => 'E-mail is vereist';

  @override
  String get fieldIsRequired => 'Veld is vereist';

  @override
  String get signingIn => 'Aanmelden';

  @override
  String get signInWithEmailCode => 'Aanmelden met e-mailcode';

  @override
  String get sendAccessCode => 'Toegangscode verzenden';

  @override
  String get continueBtn => 'Doorgaan';

  @override
  String get usePasswordInstead => 'Gebruik in plaats daarvan een wachtwoord';

  @override
  String get useAccessCodeInstead =>
      'Gebruik in plaats daarvan een toegangscode';

  @override
  String get registeringUser => 'Gebruiker registreren';

  @override
  String get sendVerificationCode => 'Verificatiecode verzenden';

  @override
  String get verificationCodeSent =>
      'Verificatiecode verzonden naar uw e-mail.';

  @override
  String get verificationCode => 'Verificatiecode';

  @override
  String get verifyCode => 'Code verifiëren';

  @override
  String get resendCode => 'Code opnieuw verzenden';

  @override
  String get verifyingCode => 'Code verifiëren';

  @override
  String get invalidVerificationCode =>
      'Ongeldige of verlopen verificatiecode.';

  @override
  String get accessCodeRequiresEmail =>
      'Aanmelden met toegangscode vereist een e-mailadres.';

  @override
  String get emailCodeInstructions =>
      'Voer uw e-mail in en wij sturen u een verificatiecode.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Voer de verificatiecode in die is verzonden naar $email.';
  }

  @override
  String get confirmPasswordRequired => 'Bevestigingswachtwoord is vereist';

  @override
  String get passwordsDontMatch =>
      'Wachtwoord en bevestigingswachtwoord komen niet overeen';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'Wachtwoord moet minstens 7 tekens bevatten';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'Wachtwoord moet een hoofdletter bevatten';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'Wachtwoord moet een kleine letter bevatten';

  @override
  String get passwordNeedsToHaveNumber => 'Wachtwoord moet een cijfer bevatten';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'Wachtwoord moet minstens 1 speciaal teken bevatten';

  @override
  String get enableLocations => 'Schakel locatiemachtigingen in';

  @override
  String get noMatchWasFound => 'Geen overeenkomst gevonden';

  @override
  String get atLeastThreeLettersForLookup =>
      '...Tiler heeft drie tekens nodig voor een zoekopdracht';

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
      'In sommige agenda\'s kon niet gezocht worden.';

  @override
  String get searchUnavailableMessage =>
      'Zoeken is tijdelijk niet beschikbaar. Probeer het opnieuw.';

  @override
  String get searchRetry => 'Opnieuw proberen';

  @override
  String get noLocationMatchWasFound => 'Geen locatie-overeenkomst gevonden';

  @override
  String get noLocation => 'Geen locatie';

  @override
  String get clearedColon => 'Gewist: ';

  @override
  String get complete => 'Voltooien';

  @override
  String get delete => 'Verwijderen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get now => 'Nu';

  @override
  String get color => 'Kleur';

  @override
  String get pickAColor => 'Kies een kleur';

  @override
  String get pause => 'Pauzeren';

  @override
  String get resume => 'Hervatten';

  @override
  String get play => 'Afspelen';

  @override
  String get successfullyPaused => 'Met succes gepauzeerd';

  @override
  String get successfullyResumed => 'Met succes hervat';

  @override
  String get successfullyCompleted => 'Met succes voltooid';

  @override
  String get completed => 'Voltooid';

  @override
  String get deleted => 'Verwijderd';

  @override
  String get scheduled => 'Ingepland';

  @override
  String get movedUpToNow => 'Verplaatsen naar nu';

  @override
  String get pausing => 'Pauzeren';

  @override
  String get resuming => 'Hervatten';

  @override
  String get movingUp => 'Tegeltje naar voren verplaatsen';

  @override
  String get completing => 'Voltooien';

  @override
  String get deleting => 'Verwijderen';

  @override
  String get deleteBlockConfirming => 'Dit blok wordt verwijderd...';

  @override
  String get deleteTileConfirming => 'Dit tegeltje wordt verwijderd...';

  @override
  String get deleteNow => 'Nu verwijderen';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Dit wordt ook verwijderd van Google Agenda';

  @override
  String get deleteOutlookWarning => '⚠️ Dit wordt ook verwijderd van Outlook';

  @override
  String get previously => 'Vroeger';

  @override
  String get upcoming => 'Voorkomend';

  @override
  String get failedToSendRequest => 'Verzoek verzenden mislukt';

  @override
  String get revise => 'Wijzigen';

  @override
  String get revisingSchedule => 'Rooster aanpassen';

  @override
  String get procrastinateBlockOut => 'Tegeltje-pauze';

  @override
  String get lunchBreak => 'Lunchpauze';

  @override
  String get coffeeBreak => 'Koffiepauze';

  @override
  String get morningBreak => 'Ochtendpauze';

  @override
  String get afternoonBreak => 'Middagpauze';

  @override
  String get freeTime => 'Vrije tijd';

  @override
  String get freeSlotHeader => 'Vrije tijd';

  @override
  String get freeSlotNow => 'Nu vrij';

  @override
  String get quickBreak => 'Snelle pauze';

  @override
  String get shortBreak => 'Korte pauze';

  @override
  String get blockedTime => 'Geblokte tijd';

  @override
  String get start => 'Start';

  @override
  String get end => 'Einde';

  @override
  String get deadline => 'Deadline';

  @override
  String get split => 'Splitsen';

  @override
  String get timeBlocks => 'Tijdblokken';

  @override
  String get swipeRightToTileIt => 'Veeg naar rechts om te telen';

  @override
  String get failedToReviseScheduleRequest =>
      'Aanvraag voor roosterwijziging mislukt';

  @override
  String get daily => 'Dagelijks';

  @override
  String get weekly => 'Wekelijks';

  @override
  String get monthly => 'Maandelijks';

  @override
  String get yearly => 'Jaarlijks';

  @override
  String get none => 'Geen';

  @override
  String get noneNotificationCategory => 'Standaard';

  @override
  String get nextTileNotificationCategory => 'Volgend tegeltje';

  @override
  String get userSetReminderNotificationCategory =>
      'Door gebruiker ingestelde herinnering';

  @override
  String get depatureTimeNotificationCategory => 'Vertrektijd';

  @override
  String get tile => 'Tegeltje';

  @override
  String get appointment => 'Blok';

  @override
  String startingAtTime(String time) {
    return 'Start om $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Eindigt om $time';
  }

  @override
  String get startsInTenMinutes => 'Start over tien minuten';

  @override
  String get endsInTenMinutes => 'Eindigt over vijf minuten';

  @override
  String startsInDuration(String duration) {
    return 'Start over $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName eindigt binnenkort';
  }

  @override
  String get home => 'Thuis';

  @override
  String get work => 'Werk';

  @override
  String get googleLogo => 'Google-logo';

  @override
  String get edit => 'Bewerken';

  @override
  String get workProfileHours => 'Werktijden';

  @override
  String get personalHours => 'Persoonlijke uren';

  @override
  String get setWorkProfileHours => 'Werktijden instellen';

  @override
  String get setPersonalHours => 'Persoonlijke uren instellen';

  @override
  String get customHours => 'Aangepaste uren';

  @override
  String get logout => 'Uitloggen';

  @override
  String get noteEllipsis => 'Notitie...';

  @override
  String get tapToCreateNewTile => 'Tik om een nieuw tegeltje te maken';

  @override
  String get emptyDayHeaderLine1 => 'Nog geen plannen.';

  @override
  String get emptyDayFooterLine1 => 'Begin in enkele seconden';

  @override
  String get emptyDayFooterLine2 => 'importeer agenda\'s of maak tegeltjes.';

  @override
  String get emptyDayOr => 'of';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Google Agenda importeren';

  @override
  String get suggestions => 'Suggesties';

  @override
  String get progress => 'Voortgang';

  @override
  String get youNeedToLeaveIn => 'U moet vertrekken over';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'U moet vertrekken over $duration';
  }

  @override
  String durationLate(String duration) {
    return '$duration te laat';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Verstreken $duration geleden';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Voltooid $duration geleden';
  }

  @override
  String durationLeft(String duration) {
    return '$duration resterend';
  }

  @override
  String get issuesConnectingToTiler => 'Problemen met het verbinden met Tiler';

  @override
  String completedCount(String count) {
    return 'Voltooid ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Verwijderd ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Tegeltjes over ($count)';
  }

  @override
  String countTile(String count) {
    return '$count tegeltjes';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number tegeltjes geselecteerd';
  }

  @override
  String get completeTiles => 'Tegeltjes voltooien';

  @override
  String get thisFitsInYourSchedule => 'Dit past in uw rooster.';

  @override
  String get warningColon => 'Waarschuwing: ';

  @override
  String get oneEventAtRisk => '1 gebeurtenis in gevaar';

  @override
  String countEventAtRisk(String number) {
    return '$number gebeurtenissen in gevaar';
  }

  @override
  String get oneConflict => '1 conflict';

  @override
  String countConflict(String number) {
    return '$number conflicten';
  }

  @override
  String get create => 'Aanmaken';

  @override
  String get thisEventWouldCause => 'Deze gebeurtenis zou veroorzaken ';

  @override
  String errorMessage(String message) {
    return 'Fout: $message';
  }

  @override
  String get unScheduledTiles => 'Niet-geplande tegeltjes';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number niet-geplande tegeltjes';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number meer';
  }

  @override
  String get unScheduled => 'Niet-gepland';

  @override
  String get allScheduled => 'Alles gepland';

  @override
  String get getOnIt => 'Aan de slag';

  @override
  String get done => 'Klaar';

  @override
  String get late => 'Te laat';

  @override
  String get onTime => 'Op tijd';

  @override
  String get todayStatusPlacedTitle => 'Met succes geplaatst';

  @override
  String get todayStatusAttentionTitle => 'Vereist aandacht';

  @override
  String get todayStatusLateTitle => 'Te laat';

  @override
  String get todayStatusAttentionHelper =>
      'Deze pasten niet in de beschikbare tijd van vandaag.';

  @override
  String get todayStatusLateHelper =>
      'De reistijd tussen deze en uw andere tegeltjes betekent dat u niet op tijd kunt komen.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegeltjes',
      one: '1 tegeltje',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tegeltjes voltooid',
      one: 'Tegeltje voltooid',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Vereist aandacht';

  @override
  String get todayStatusTilesRunningLate => 'Te laat';

  @override
  String get todayStatusEverythingOnTrack => 'Alles loopt op schema';

  @override
  String get todayStatusEverythingElseOnTrack => 'De rest loopt op schema';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Geen geplande tegeltjes lopen achter.';

  @override
  String get todayStatusClearDay => 'Uw dag is vrij.';

  @override
  String get todayStatusClearDayHeadline => 'Rustige dag, geen urgente zaken.';

  @override
  String get todayStatusClearDaySubtext => 'Laat Tiler voor je werken.';

  @override
  String get todayStatusPreviewCta => 'Bekijk een beter plan';

  @override
  String get todayStatusPreviewLoading => 'Voorvertoning voorbereiden…';

  @override
  String get todayStatusPreviewUnavailable =>
      'De voorvertoning kon niet worden gegenereerd. Uw plan blijft ongewijzigd.';

  @override
  String get todayStatusUntitledTile => 'Tegeltje zonder titel';

  @override
  String get todayStatusShowAll => 'Alles tonen';

  @override
  String todayStatusExpandSection(String section) {
    return '$section uitvouwen';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return '$section inklappen';
  }

  @override
  String get todayStatusReasonDueToday => 'Vervalt vandaag';

  @override
  String get todayStatusReasonNoOpenSlot => 'Geen vrij slot';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'Reistijd maakt dit onmogelijk';

  @override
  String get todayStatusReasonOutsideHours => 'Buiten de beschikbare uren';

  @override
  String get todayStatusReasonDependencyBlocked =>
      'Wacht op een ander tegeltje';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Vereist $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Vereist uw beslissing';

  @override
  String get todayStatusReasonUnknown => 'Kon niet worden ingepast';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessies',
      one: '1 sessie',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Tegeltjes selecteren';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Sessies van $title uitvouwen';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Sessies van $title inklappen';
  }

  @override
  String get analysis => 'Analyse';

  @override
  String get noDataAvailable => 'Geen gegevens beschikbaar';

  @override
  String get sleep => 'Slaap';

  @override
  String get overview => 'Overzicht';

  @override
  String get driveTime => 'Rijtijd';

  @override
  String get signUpWithGoogle => 'Aanmelden met Google';

  @override
  String get signUpWithApple => 'Aanmelden met Apple';

  @override
  String get signUpWithMicrosoft => 'Aanmelden met Microsoft';

  @override
  String get signIn => 'Aanmelden';

  @override
  String get signUp => 'Registreren';

  @override
  String get invalidUsernameOrPassword =>
      'Ongeldige gebruikersnaam of wachtwoord';

  @override
  String get noInternetConnection => 'Geen internetverbinding';

  @override
  String get oneHour => '1 uur';

  @override
  String countHours(String count) {
    return '$count uur';
  }

  @override
  String get oneMinute => '1 minuut';

  @override
  String countMinutes(String count) {
    return '$count minuten';
  }

  @override
  String countDays(String count) {
    return '$count dagen';
  }

  @override
  String lateDate(String date) {
    return 'Te laat ($date)';
  }

  @override
  String get custom => 'Aangepast';

  @override
  String get allowAccessDescription =>
      'Tiler verzamelt locatiegegevens om tegeltjes en afspraken efficiënt in te plannen.\nUw gegevens blijven privé en worden alleen voor dit doel gebruikt.';

  @override
  String get allowLocationAccessQ => 'Locatietoeval toestaan?';

  @override
  String get allow => 'Toestaan';

  @override
  String get deny => 'Weigeren';

  @override
  String get afternoon => 'Middag';

  @override
  String get evening => 'Avond';

  @override
  String get night => 'Nacht';

  @override
  String get morningAndAfternoon => 'Ochtend & middag';

  @override
  String get afternoonAndEvening => 'Middag & avond';

  @override
  String get lateEvening => 'Late avond';

  @override
  String get prediction => 'Voorspelling';

  @override
  String get softDeadline => 'Soepele deadline';

  @override
  String get location => 'Locatie';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deleteYourTilerAccountQ => 'Account verwijderen?';

  @override
  String get no => 'Nee';

  @override
  String get dismiss => 'Wegwerpen';

  @override
  String get forgetPassword => 'Wachtwoord vergeten';

  @override
  String get forgotPasswordBtn => 'Wachtwoord vergeten?';

  @override
  String get resetPassword => 'Wachtwoord opnieuw instellen';

  @override
  String get reset => 'Opnieuw instellen';

  @override
  String lookingUp(String text) {
    return '$text opzoeken';
  }

  @override
  String get lowPriorityTrunc => 'Laag';

  @override
  String get mediumPriorityTrunc => 'Middel';

  @override
  String get highPriorityTrunc => 'Hoog';

  @override
  String failedToAddGoogleCalendar(String email) {
    return '$email toevoegen mislukt';
  }

  @override
  String deletedCalendar(String email) {
    return 'Agenda van $email verwijderd';
  }

  @override
  String get loadingIntegrations => 'Integraties laden';

  @override
  String get noThirdPartyIntegtions => 'Geen agenda\'s van derden';

  @override
  String get addGoogleCalendar => 'Google Agenda toevoegen';

  @override
  String get integrations => 'Integraties';

  @override
  String get integrateOtherCalendars => 'Koppelen met agenda\'s van derden';

  @override
  String get clear => 'Wissen';

  @override
  String get next => 'Volgende';

  @override
  String get previous => 'Vorige';

  @override
  String get skip => 'Overslaan';

  @override
  String get morningPerson => '🌅 Ochtendmens';

  @override
  String get morning => 'Ochtend';

  @override
  String get middayPerson => '🌞 Middagmens';

  @override
  String get nightPerson => '🌃 Nachtmens';

  @override
  String get enterAddress => 'Voer uw adres in';

  @override
  String get primaryLocationQuestion =>
      'Wat is uw voornaamste locatie voor werk of studie?';

  @override
  String get useDeviceLocation => 'Gebruik de locatie van mijn apparaat';

  @override
  String get energyLevelDescriptionQuestion =>
      'Hoe zou u uw energieniveau gedurende de dag beschrijven?';

  @override
  String get incompleteRequest => 'Onvolledige aanvraag verzonden';

  @override
  String get addContact => 'Contact toevoegen';

  @override
  String get invalidContactFormat =>
      'Geen geldig e-mailadres of telefoonnummer';

  @override
  String deadlineTime(String time) {
    return 'Deadline: $time';
  }

  @override
  String get accept => 'Accepteren';

  @override
  String get decline => 'Weigeren';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get addTilette => 'Gedeeld tegeltje toevoegen';

  @override
  String get tileShare => 'Gedeeld tegeltje';

  @override
  String get tileShareActivityInvitationUnknown =>
      'Uitkomst van de uitnodiging onbekend';

  @override
  String get tileShareActivityExplicitResend =>
      'De uitnodiging is mogelijk al verzonden. Verstuur deze expliciet opnieuw indien nodig.';

  @override
  String get tileShareActivityEmail => 'E-mail';

  @override
  String get tileShareActivitySms => 'SMS';

  @override
  String get tileShareActivityPush => 'Pushmelding';

  @override
  String get tileShareActivityTitle => 'Activiteiten';

  @override
  String get tileShareActivityRefresh => 'Vernieuwen';

  @override
  String get tileShareActivityRetry => 'Opnieuw proberen';

  @override
  String get tileShareActivityEmpty => 'Nog geen activiteiten.';

  @override
  String get tileShareActivityFailed =>
      'Activiteiten konden niet worden geladen. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get tileShareActivityAccess =>
      'Deze activiteit is niet meer voor je beschikbaar.';

  @override
  String get tileShareActivityUnknown => 'Activiteit bijgewerkt';

  @override
  String get tileShareActivityUnavailable => 'Item niet meer beschikbaar';

  @override
  String get tileShareActivityMore => 'Meer laden';

  @override
  String get tileShareActivityClusterCreated => 'TileShare aangemaakt';

  @override
  String get tileShareActivityClusterDeleted => 'TileShare verwijderd';

  @override
  String get tileShareActivityTiletteAdded => 'Tegeltje toegevoegd';

  @override
  String get tileShareActivityTiletteEdited => 'Tegeltje bijgewerkt';

  @override
  String get tileShareActivityTiletteDeleted => 'Tegeltje verwijderd';

  @override
  String get tileShareActivityTiletteRestored => 'Tegeltje hersteld';

  @override
  String get tileShareActivityRecipientAdded => 'Deelnemer toegevoegd';

  @override
  String get tileShareActivityRecipientRemoved => 'Deelnemer verwijderd';

  @override
  String get tileShareActivityRecipientRestored => 'Deelnemer hersteld';

  @override
  String get tileShareActivityAccepted => 'Toewijzing geaccepteerd';

  @override
  String get tileShareActivityDeclined => 'Toewijzing afgewezen';

  @override
  String get tileShareActivityInvitationSent => 'Uitnodiging verzonden';

  @override
  String get tileShareActivityInvitationFailed =>
      'Uitnodiging kon niet worden verzonden';

  @override
  String get update => 'Bijwerken';

  @override
  String get noDesignatedTiles => 'Geen toegewezen tegeltjes';

  @override
  String get noTileCluster => 'Geen gedeelde tegeltjes aangemaakt';

  @override
  String get errorLoadingTilelist => 'Fout bij het laden van de tegeltjeslijst';

  @override
  String get failedToLoadTileShareCluster =>
      'Laden van de gedeelde-tegeltjesset mislukt';

  @override
  String get missingTileShareCluster => 'Ontbrekende gedeelde-tegeltjesset';

  @override
  String get outBound => 'Uitgaand';

  @override
  String get inBound => 'Inkomend';

  @override
  String get errorOccurred =>
      'Er is een fout opgetreden!!\nProbeer het opnieuw.';

  @override
  String get authenticationIssues => 'Problemen met de verificatie.';

  @override
  String get userIsNotAuthenticated => 'Gebruiker is niet geauthenticeerd.';

  @override
  String get responseContentError =>
      'De respons bevat niet de verwachte inhoud.';

  @override
  String get responseHandlingError => 'Verwerken van de respons mislukt.';

  @override
  String get today => 'Vandaag';

  @override
  String get yesterday => 'Gisteren';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get travel => 'Reizen';

  @override
  String numberOfDayForecast(String number) {
    return '$number-daagse voorspelling';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Voorbeeld ophalen mislukt';

  @override
  String get noDriving => 'Geen rijafstand';

  @override
  String get tileShareNoteEllipsis => 'Notitie...';

  @override
  String get hi => 'Hoi';

  @override
  String get welcome => 'Welkom';

  @override
  String get passwordCreationMessagePart1 =>
      'Maak een sterk, uniek wachtwoord met ';

  @override
  String get passwordConditionMinLength => 'minstens zes tekens';

  @override
  String get passwordCreationMessageIncluding => ', waaronder ';

  @override
  String get passwordConditionUppercaseLetters => 'hoofdletters';

  @override
  String get passwordConditionLowercaseLetters => 'kleine letters';

  @override
  String get passwordConditionNumbers => 'cijfers';

  @override
  String get passwordConditionSpecialCharacter => 'een speciaal teken';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', en ';

  @override
  String get nonViableTimeSlot => 'Geen haalbaar tijdstip';

  @override
  String numberAm(String number) {
    return '${number}AM';
  }

  @override
  String numberPm(String number) {
    return '${number}PM';
  }

  @override
  String get dayCast => 'DayCast';

  @override
  String get save => 'Opslaan';

  @override
  String get selectWeek => 'Kies een week';

  @override
  String get selectYear => 'Kies jaar';

  @override
  String get retrievingDataIssue => 'Probleem bij het ophalen van gegevens';

  @override
  String get recurring => 'Herhalend';

  @override
  String get nonRecurring => 'Niet-herhalend';

  @override
  String get dailyReurring => 'Dagelijks';

  @override
  String get weeklyReurring => 'Wekelijks';

  @override
  String get biweeklyReurring => 'In de twee weken';

  @override
  String get monthlyReurring => 'Maandelijks';

  @override
  String get yearlyReurring => 'Jaarlijks';

  @override
  String get ellipsisEmprtNotes => 'Notities...';

  @override
  String get tileShareDelete => 'Verwijderen';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Voorspellingstegeltje';

  @override
  String get previewOthers => 'Anderen';

  @override
  String get goodMorning => 'Goede ochtend';

  @override
  String get goodDay => 'Goede dag';

  @override
  String get goodEvening => 'Goedenavond';

  @override
  String youHaveXBlocks(String count) {
    return 'U heeft $count blokken voor u.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'U heeft $count tegeltjes voor u.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'U heeft $count gedeelde tegeltjes voor u.';
  }

  @override
  String countTileShare(String count) {
    return '$count gedeelde tegeltjes';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'U heeft $blockCount blokken en $tileCount tegeltjes voor u.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'U heeft $blockCount blokken en $tileShareCount gedeelde tegeltjes voor u.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'U heeft $tileCount tegeltjes en $tileShareCount gedeelde tegeltjes voor u.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'U heeft $blockCount blokken, $tileCount tegeltjes en $tileShareCount gedeelde tegeltjes voor u.';
  }

  @override
  String get noTilesPreview =>
      'U heeft vandaag de rest van de dag niets te doen.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Tegeltje maken';

  @override
  String get previewTileForecast => 'Voorspelling';

  @override
  String get previewTileOptions => 'Opties';

  @override
  String get previewTileMore => 'Meer';

  @override
  String get previewTileShuffle => 'Wisselen';

  @override
  String get previewTileRevise => 'Wijzigen';

  @override
  String get previewTileDeferAll => 'Alles uitstellen';

  @override
  String get previewLocationName => 'Locatie';

  @override
  String get previewTagName => 'Label';

  @override
  String get previewClassificationName => 'Classificatie';

  @override
  String get previewBlockedOut => 'Geblokkeerd';

  @override
  String get accountInfo => 'Accountgegevens';

  @override
  String get fistName => 'Voornaam';

  @override
  String get lastName => 'Achternaam';

  @override
  String get tilePreferences => 'Tegeltjesvoorkeuren';

  @override
  String get notificationsPreferences => 'Meldingsvoorkeuren';

  @override
  String get security => 'Beveiliging';

  @override
  String get connections => 'Verbindingen';

  @override
  String get myLocations => 'Mijn locaties';

  @override
  String get aboutTiler => 'Over Tiler';

  @override
  String get howToUseTiler => 'Hoe Tiler te gebruiken';

  @override
  String get darkMode => 'Donkere modus';

  @override
  String get setLocation => 'Locatie instellen';

  @override
  String get connectCalendars => 'Koppel uw agenda\'s';

  @override
  String get configure => 'Configureren';

  @override
  String get comingSoon => 'Binnenkort beschikbaar';

  @override
  String get googleCalendar => 'Google Agenda';

  @override
  String get appleCalendar => 'Apple Agenda';

  @override
  String get googleTasks => 'Google Taken';

  @override
  String get microsoft => 'Microsoft';

  @override
  String get slack => 'Slack';

  @override
  String get addCalendar => 'Agenda toevoegen';

  @override
  String get calendarConnected => 'Agenda verbonden';

  @override
  String get calendarConnectionDeclined =>
      'Verbinding met de agenda werd geannuleerd';

  @override
  String get calendarConnectionError => 'Uw agenda kon niet worden verbonden';

  @override
  String get sleepDuration => 'Slaaptijd';

  @override
  String get transportationMethodQuestion => 'Hoe verplaatst u zich?';

  @override
  String get defineYourTimeRestrictions => 'Bepaal uw tijdsrestricties';

  @override
  String get setWorkHours => 'Werktijden instellen';

  @override
  String get setYourBlockOutHours => 'Stel uw blokkade-uren in';

  @override
  String get travelMediumBiking => 'Fietsen';

  @override
  String get travelMediumTransit => 'Openbaar vervoer';

  @override
  String get travelMediumDriving => 'Rijden';

  @override
  String get travelMediumTransport => 'Vervoer';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio min';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio uur';
  }

  @override
  String get bedTime => 'Bedtijd';

  @override
  String get sleepTime => 'Slaaptijd';

  @override
  String get scheduleFullness => 'Volledigheid van het rooster';

  @override
  String get scheduleFullnessDescription => 'Hoe vol moet uw rooster zijn?';

  @override
  String scheduleFullnessValue(int percentage) {
    return 'Doelvolledigheid $percentage %';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Doelwaarden variëren van $minimum % tot $maximum %. Dit behoudt een nuttig uitgangspunt en biedt ruimte voor wijzigingen en reistijd.';
  }

  @override
  String get schedulePreferences => 'Roostervoorkeuren';

  @override
  String get lighter => 'Lichter';

  @override
  String get balanced => 'Gebalanceerd';

  @override
  String get fuller => 'Voller';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Tegeltjesvoorkeuren zijn succesvol bijgewerkt.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Meldingsvoorkeuren zijn succesvol bijgewerkt.';

  @override
  String get tileReminders => 'Tegeltje-herinneringen';

  @override
  String get appUpdates => 'App-updates';

  @override
  String get marketingUpdates => 'Marketingupdates';

  @override
  String get emailNotifications => 'E-mailmeldingen';

  @override
  String get fullName => 'Volledige naam';

  @override
  String get phoneNumber => 'Telefoonnummer';

  @override
  String get countryCode => 'Landcode';

  @override
  String get dateOfBirth => 'Geboortedatum';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'Accountgegevens zijn succesvol bijgewerkt.';

  @override
  String get reachingServerIssues =>
      'Problemen met het bereiken van de Tiler-servers';

  @override
  String get deleteAccountConfirmation =>
      'Weet u zeker dat u uw account wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get disconnect => 'Koppeling verbreken';

  @override
  String get integrationsSetLocation => 'Locatie instellen';

  @override
  String get googleCalender => 'Google Agenda';

  @override
  String get passwordsMustMatch => 'Wachtwoorden moeten overeenkomen';

  @override
  String get parenthesisLate => '(te laat)';

  @override
  String get failedToAddIntegration => 'Integratie toevoegen mislukt';

  @override
  String get unknownProvider => 'Onbekende aanbieder';

  @override
  String get manageCalendars => 'Agenda\'s beheren';

  @override
  String get calendarItems => 'Agenda-items';

  @override
  String get noCalendarItemsFound => 'Geen agenda-items gevonden';

  @override
  String get calendarItemsWillAppearHere => 'Uw agenda-items verschijnen hier';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount van $totalCount agenda\'s actief';
  }

  @override
  String get toggleCalendarsToSync =>
      'Schakel agenda\'s in of uit om te synchroniseren met Tiler';

  @override
  String get unknownCalendar => 'Onbekende agenda';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount van $totalCount actief';
  }

  @override
  String integrationCount(int count) {
    return '$count integraties';
  }

  @override
  String get errorLoadingCalendarItems => 'Fout bij het laden van agenda-items';

  @override
  String get integratedCalendars => 'Agenda\'s';

  @override
  String get integrationAdd => 'Toevoegen';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Mogen we uw locatie gebruiken om\nlocatiegebaseerde aanbevelingen en meldingen te leveren?';

  @override
  String get recurringTasks => 'Herhalende taken';

  @override
  String get yourProfession => 'Uw beroep?';

  @override
  String get yourProfessionQuestion => 'Wat doet u?';

  @override
  String get yourProfessionHint => 'Beschrijf wat u voor werk doet';

  @override
  String get medicalProfessional => 'Medisch professional';

  @override
  String get softwareDeveloper => 'Softwareontwikkelaar';

  @override
  String get student => 'Student';

  @override
  String get engineer => 'Ingenieur';

  @override
  String get fieldSalesProfessional => 'Veldverkoop';

  @override
  String get remoteWorker => 'Werker op afstand & digital nomad';

  @override
  String get stayAtHomeParent => 'Thuisblijvende ouder';

  @override
  String get clientAccountManagers => 'Klant-/accountmanagers';

  @override
  String get other => 'Ander';

  @override
  String get tileSuggestions => 'Tegeltjesuggesties';

  @override
  String get personalOrWorkQuestion => 'Waar gaat u Tiler voor gebruiken?';

  @override
  String get enter3chars => 'Voer minstens 3 tekens in.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Vertrek over $duration om op tijd te arriveren';
  }

  @override
  String get leaveNowToArriveOnTime => 'Vertrek nu om op tijd te arriveren!';

  @override
  String durationDrive(String duration) {
    return '$duration rijden';
  }

  @override
  String durationTransit(String duration) {
    return '$duration openbaar vervoer';
  }

  @override
  String durationBike(String duration) {
    return '$duration fietsen';
  }

  @override
  String durationWalk(String duration) {
    return '$duration lopen';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration rijden naar $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration openbaar vervoer naar $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration fietsen naar $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration lopen naar $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Vertrek vóór $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Verkeer gedetecteerd - omleiding voorgesteld';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Verkeer: +$minutes min vertraging';
  }

  @override
  String get heavyTrafficExpected => 'Zwaar verkeersdrukte verwacht';

  @override
  String get addWithAI => 'Toevoegen met AI';

  @override
  String get focusTime => 'Focustijd';

  @override
  String get videoMeeting => 'Videogesprek';

  @override
  String get sharedWith => 'Gedeeld met';

  @override
  String durationMinutes(String minutes) {
    return '${minutes}m';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '${hours}u ${minutes}m';
  }

  @override
  String travelDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String travelDurationHours(int hours) {
    return '$hours uur';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours uur $minutes min';
  }

  @override
  String travelViaRoute(String route) {
    return 'via $route';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return ' $travelMode naar ';
  }

  @override
  String get travelModeDriving => 'rijden';

  @override
  String get travelModeWalking => 'lopen';

  @override
  String get travelModeBicycling => 'fietsen';

  @override
  String get travelModeTransitLower => 'openbaar vervoer';

  @override
  String travelDurationCompact(int minutes) {
    return '${minutes}m';
  }

  @override
  String get yourDayIsOptimized => 'Uw dag is geoptimaliseerd.';

  @override
  String get yourDayAtAGlance => 'Uw dag in een oogopslag';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration reistijd vandaag.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count tegeltjes ingepland voor vandaag.';
  }

  @override
  String get viewRoute => 'Route bekijken';

  @override
  String get focusModeChip => 'Focustijdmodus';

  @override
  String get showRouteChip => 'Route tonen';

  @override
  String get reOptimizeChip => 'Opnieuw optimaliseren';

  @override
  String get dayFilterAll => 'Alles';

  @override
  String get dayFilterBlocks => 'Blokken';

  @override
  String get dayFilterTiles => 'Tegels';

  @override
  String get dayFilterTooltip =>
      'Alles, alleen blokken of alleen tegels weergeven';

  @override
  String dayFilterShowingBlocks(int shown, int total) {
    return 'Alleen blokken weergeven · $shown van $total';
  }

  @override
  String dayFilterShowingTiles(int shown, int total) {
    return 'Alleen tegels weergeven · $shown van $total';
  }

  @override
  String dayFilterEmptyBlocks(String day) {
    return 'Geen blokken op $day';
  }

  @override
  String dayFilterEmptyTiles(String day) {
    return 'Geen tegels op $day';
  }

  @override
  String get dayFilterShowAll => 'Alles weergeven';

  @override
  String get dayFilterAutoCleared => 'Alles wordt weergegeven — filter gewist';

  @override
  String get todayColon => 'Vandaag:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount tegeltjes, $blockCount blokken';
  }

  @override
  String get timeSavedColon => 'Bespaarde tijd:';

  @override
  String get travelTimeColon => 'Reistijd:';

  @override
  String travelTime(String duration) {
    return 'Reistijd: $duration';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '${hours}u ${minutes}m';
  }

  @override
  String durationDaysHoursShort(int days, int hours) {
    return '${days}d ${hours}u';
  }

  @override
  String durationDaysShort(int days) {
    return '${days}d';
  }

  @override
  String durationHoursShort(int hours) {
    return '${hours}u';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String hourAm(int hour) {
    return '$hour AM';
  }

  @override
  String hourPm(int hour) {
    return '$hour PM';
  }

  @override
  String get scheduleConflict => 'Roosterconflict';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" en \"$tile2\" staan ingepland op hetzelfde tijdstip';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '\"$tile1\" valt in \"$tile2\" (overlap $overlap)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '\"$tile1\" overlapt \"$tile2\" met $overlap';
  }

  @override
  String get fix => 'Oplossen';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Conflict: ${minutes}m overlap';
  }

  @override
  String get oneScheduleConflict => '1 roosterconflict';

  @override
  String countScheduleConflicts(int count) {
    return '$count roosterconflicten';
  }

  @override
  String get tapToReviewAndResolve => 'Tik om te bekijken en op te lossen';

  @override
  String countConflicts(int count) {
    return '$count conflicten';
  }

  @override
  String get tapToExpand => 'Tik om uit te vouwen';

  @override
  String conflictingTiles(int count) {
    return '$count conflicterende tegeltjes';
  }

  @override
  String totalOverlap(String duration) {
    return 'Totale overlap: $duration';
  }

  @override
  String get autoResolve => 'Automatisch oplossen';

  @override
  String get untitledTile => 'Naamloos tegeltje';

  @override
  String get untitledEvent => 'Naamloos';

  @override
  String get extendedEventSingular => '1 uitgebreide gebeurtenis';

  @override
  String extendedEventsPlural(int count) {
    return '$count uitgebreide gebeurtenissen';
  }

  @override
  String get extendedEventsTapToView =>
      'Tik om hele-dag- en lange gebeurtenissen te bekijken';

  @override
  String get extendedEventsTitle => 'Uitgebreide gebeurtenissen';

  @override
  String get dayGridAllDay => 'De hele dag';

  @override
  String get dayGridHeaderAllClear => 'Alles in orde';

  @override
  String dayGridHeaderConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicten',
      one: '1 conflict',
    );
    return '$_temp0';
  }

  @override
  String dayGridHeaderNeedAttention(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$summary vragen aandacht',
      one: '$summary vraagt aandacht',
    );
    return '$_temp0';
  }

  @override
  String get dayGridHeaderReview => 'Controleren';

  @override
  String get dayGridDaySummary => 'Overzicht van de dag';

  @override
  String get bottomNavToday => 'Vandaag';

  @override
  String get bottomNavTiler => 'Tiler';

  @override
  String get dayGridHeaderRespond => 'Reageren';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebeurtenissen langer dan 16 uur',
      one: '1 gebeurtenis langer dan 16 uur',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Route van vandaag';

  @override
  String get noLocationsToday => 'Geen locaties vandaag';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Voeg locaties toe aan uw tegeltjes om uw dagelijkse route te zien';

  @override
  String countStops(int count) {
    return '$count stops';
  }

  @override
  String get routeOptimized => 'Route geoptimaliseerd';

  @override
  String savedTravelTime(String duration) {
    return '$duration reistijd bespaard';
  }

  @override
  String get firstStop => 'Eerste stop';

  @override
  String get stop => 'Stop';

  @override
  String arriveBy(String time) {
    return 'Arriveer vóór $time';
  }

  @override
  String get fromPreviousStop => 'van de vorige stop';

  @override
  String get viewTile => 'Tegeltje bekijken';

  @override
  String get editTile => 'Tegeltje bewerken';

  @override
  String get startNavigation => 'Navigatie starten';

  @override
  String get noLocationAvailable => 'Geen locatie';

  @override
  String get seeTodaysRoute => 'Bekijk de route van vandaag';

  @override
  String get whatWouldYouLikeToDo => 'Wat zou u willen doen?';

  @override
  String get describeATask => 'Beschrijf een taak, wij verzorgen het telen.';

  @override
  String get microphonePermissionDenied => 'Microfoontoegang geweigerd.';

  @override
  String failedToStartRecording(String error) {
    return 'Opname starten mislukt: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Opname stoppen mislukt: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Audio-conversiefout: $error';
  }

  @override
  String get audioConversionFailed => 'Audioconversie mislukt';

  @override
  String get recordingPathIsEmpty => 'Opnamepad is leeg';

  @override
  String get noActiveRecording => 'Geen actieve opname';

  @override
  String get joinMeeting => 'Aan meeting deelnemen';

  @override
  String get openLink => 'Link openen';

  @override
  String get actions => 'Acties';

  @override
  String get hideActions => 'Acties verbergen';

  @override
  String get pendingRsvpSingular => '1 evenement heeft een reactie nodig';

  @override
  String pendingRsvpPlural(int count) {
    return '$count evenementen hebben een reactie nodig';
  }

  @override
  String get pendingRsvpHappeningNow => 'Nu gaande - reageer om deel te nemen';

  @override
  String get pendingRsvpStartingSoon => 'Start binnenkort - reageer nu';

  @override
  String get pendingRsvpWithinHour => 'Start binnen een uur';

  @override
  String get pendingRsvpUpcoming => 'Voorkomend - tik om te reageren';

  @override
  String get pendingRsvpTapToReview => 'Tik om te bekijken en te reageren';

  @override
  String get pendingRsvpTitle => 'Achterblijvende reacties';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count evenementen wachten op uw reactie',
      one: '1 evenement wacht op uw reactie',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Binnenkort startend';

  @override
  String get pendingRsvpLater => 'Later vandaag & voorkomend';

  @override
  String get declinedRsvpSingular => '1 geweigerd evenement';

  @override
  String declinedRsvpPlural(int count) {
    return '$count geweigerde evenementen';
  }

  @override
  String get declinedRsvp => 'Geweigerde evenementen';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 openstaand, $declinedCount geweigerd';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount openstaand, 1 geweigerd';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount openstaand, $declinedCount geweigerd';
  }

  @override
  String get rsvpNeedsAction => 'Heeft een reactie nodig';

  @override
  String get rsvpTentative => 'Voorlopig';

  @override
  String get rsvpAccepted => 'Geaccepteerd';

  @override
  String get rsvpDeclined => 'Geweigerd';

  @override
  String unableToOpenLinkError(String link) {
    return 'Link kan niet worden geopend: $link';
  }

  @override
  String get leaveNow => 'Vertrek nu!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Vertrek over $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count meldingen';
  }

  @override
  String get alertChipLeaveNow => 'Vertrek nu';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Vertrek ${minutes}m';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicten',
      one: '1 conflict',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hele dag',
      one: '1 hele dag',
    );
    return '$_temp0';
  }

  @override
  String alertChipRsvp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RSVP\'s',
      one: '1 RSVP',
    );
    return '$_temp0';
  }

  @override
  String get accepted => 'Geaccepteerd';

  @override
  String get declined => 'Geweigerd';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Reageer op $calendarSource';
  }

  @override
  String get unknown => 'Agendauitnodiging';

  @override
  String get loadingPreviousDays => 'Vorige dagen laden...';

  @override
  String get loadingUpcomingDays => 'Voorkomende dagen laden...';

  @override
  String get requestTimeout =>
      'Tijdslimiet verstreken - controleer uw verbinding';

  @override
  String get failedToPauseTile => 'Tegeltje pauzeren mislukt';

  @override
  String get failedToResumeTile => 'Tegeltje hervatten mislukt';

  @override
  String get failedToMoveUpTask => 'Taak naar voren verplaatsen mislukt';

  @override
  String get failedToUpdateTile => 'Tegeltje bijwerken mislukt';

  @override
  String get failedToBuzzSchedule => 'Rooster aanpakken mislukt';

  @override
  String get failedToShuffleSchedule => 'Rooster wisselen mislukt';

  @override
  String get failedToProcrastinateTile => 'Tegeltje uitstellen mislukt';

  @override
  String get tutorialStepYourScheduleTitle => 'Uw rooster';

  @override
  String get tutorialStepYourScheduleBody =>
      'Uw dag is ingedeeld in tegeltjes — slimme tijdblokken die Tiler voor u rangschikt. Scroll omhoog en omlaag om uw hele dag te zien.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Maken & optimaliseren';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Tik hier om een nieuwe taak te maken. Vertel Tiler wat u moet doen en hoe lang het duurt — Tiler bedenkt de wanneer.';

  @override
  String get tutorialCalloutReOptimize => 'Opnieuw optimaliseren';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'Is uw dag ontspoord? Bereken opnieuw vanaf nu en houd uw komende planning grof in stand';

  @override
  String get tutorialCalloutTravelTime => 'Reistijd';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Tiler houdt rekening met de reis tussen locaties';

  @override
  String get tutorialStepQuickCreateTitle => 'Snel maken';

  @override
  String get tutorialStepQuickCreateBody =>
      'Dit is het snel-toevoegen-scherm. Geef uw tegeltje een naam en stel een duur in voor een snelle toevoeging.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'Dit is het snel-toevoegen-scherm achter mij! Geef uw tegeltje een naam, stel een duur in en tik Toevoegen — Tiler verzorgt de rest.';

  @override
  String get tutorialCalloutNameYourTile => 'Geef uw tegeltje een naam';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Beschrijf de taak die u wilt uitvoeren';

  @override
  String get tutorialCalloutSetDuration => 'Duur instellen';

  @override
  String get tutorialCalloutSetDurationDesc => 'Hoe lang duurt deze taak?';

  @override
  String get tutorialCalloutMoreOptions => 'Meer opties';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Voeg locatie, deadline of herhaling toe via de volledige editor';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Voeg locatie, deadline of herhaling toe';

  @override
  String get tutorialStepTilerWorksTitle => 'Tiler werkt voor u';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tiler rangschikt automatisch uw tegeltjes op basis van uw energieniveaus, reistijd en deadlines. Voeg gewoon toe wat u moet doen — Tiler bedenkt de wanneer.';

  @override
  String get tutorialCalloutForecast => 'Voorspelling';

  @override
  String get tutorialCalloutForecastDesc =>
      'Bekijk wanneer een tegeltje wordt ingevoegd voordat u het selecteert';

  @override
  String get tutorialCalloutShuffle => 'Wisselen';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Wissel dingen rond en stel voor wat u als volgende zou moeten doen';

  @override
  String get tutorialCalloutDeferAll => 'Alles uitstellen';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Heeft u een rommelige dag? Duw alles naar voren';

  @override
  String get tutorialStepControlTilesTitle => 'Beheer uw tegeltjes';

  @override
  String get tutorialStepControlTilesBody =>
      'Elk tegeltje heeft besturingselementen om uw taken in realtime te beheren:';

  @override
  String get tutorialCalloutPlay => 'Afspelen';

  @override
  String get tutorialCalloutPlayDesc => 'Begin met dit tegeltje te werken';

  @override
  String get tutorialCalloutPause => 'Pauzeren';

  @override
  String get tutorialCalloutPauseDesc =>
      'Neem een pauze — Tiler plant de rest opnieuw in';

  @override
  String get tutorialCalloutComplete => 'Voltooien';

  @override
  String get tutorialCalloutCompleteDesc => 'Klaar! Markeer het als afgerond';

  @override
  String get tutorialCalloutProcrastinate => 'Uitstellen';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Nu niet — schuif het naar later';

  @override
  String get tutorialStepBigPictureTitle => 'Krijg het grote geheel te zien';

  @override
  String get tutorialStepBigPictureBody =>
      'Tik op het agendapictogram om te wisselen tussen drie weergaven:';

  @override
  String get tutorialCalloutDaily => 'Dagelijks';

  @override
  String get tutorialCalloutDailyDesc =>
      'Uur voor uur — uw gedetailleerde agenda';

  @override
  String get tutorialCalloutWeekly => 'Wekelijks';

  @override
  String get tutorialCalloutWeeklyDesc =>
      'Bekijk de hele week in een oogopslag';

  @override
  String get tutorialCalloutMonthly => 'Maandelijks';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Plan vooruit met een maandelijks overzicht';

  @override
  String get tutorialStepToolkitTitle => 'Uw gereedschapskist';

  @override
  String get tutorialStepToolkitBody =>
      'Deze handige tools zijn altijd binnen handbereik:';

  @override
  String get tutorialCalloutShare => 'Delen';

  @override
  String get tutorialCalloutShareDesc =>
      'Werk samen — deel tegeltjes met anderen';

  @override
  String get tutorialCalloutSearch => 'Zoeken';

  @override
  String get tutorialCalloutSearchDesc => 'Vind elk tegeltje op naam';

  @override
  String get tutorialCalloutSettings => 'Instellingen';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Pas uw ervaring aan, koppel agenda\'s, stel voorkeuren in';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Tik op de chatknop om tegeltjes toe te voegen of aan te passen door alleen met Tiler te praten';

  @override
  String get tutorialStepChatTitle => 'Chat met Tiler';

  @override
  String get tutorialStepChatBody =>
      'Tik op de chatknop wanneer u wilt om tegeltjes toe te voegen of aan te passen door alleen met Tiler te praten — geen formulieren nodig.';

  @override
  String get tutorialNavNext => 'Volgende';

  @override
  String get tutorialNavNextArrow => 'Volgende →';

  @override
  String get tutorialNavBack => 'Terug';

  @override
  String get tutorialNavBackArrow => '← Terug';

  @override
  String get tutorialNavSkip => 'Overslaan';

  @override
  String get tutorialNavLetsGo => 'Laten we gaan!';

  @override
  String get welcomeExplainerHeadline => 'Tegeltjes vs blokken';

  @override
  String get welcomeExplainerSubtitle =>
      'Een snelle blik op hoe Tiler uw dag plant.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Blokken zijn vast. Ze vinden op een vast tijdstip plaats.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Tegeltjes zijn flexibel. Tiler past ze aan rond uw blokken.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'Tandarts verplaatst naar $time — Tiler plant uw tegeltjes opnieuw rondom in.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Verplaatst';

  @override
  String get welcomeExplainerReplannedBadge => 'Hergepland';

  @override
  String get welcomeExplainerBlockStandup => 'Teamstandup';

  @override
  String get welcomeExplainerBlockDentist => 'Tandarts';

  @override
  String get welcomeExplainerTileWorkout => 'Training';

  @override
  String get welcomeExplainerTileReport => 'Rapport schrijven';

  @override
  String get welcomeExplainerTileGroceries => 'Boodschappen';

  @override
  String get welcomeExplainerLegendBlock => 'Blok';

  @override
  String get welcomeExplainerLegendTile => 'Tegeltje';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Tegeltjesvoorkeuren';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Uw AI-voorkeuren staan hier — hoe u reist, uw werk- en persoonlijke uren, en blokkadetijd.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Hoe u zich verplaatst';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tiler houdt reistijd tussen tegeltjes in rekening op basis van hoe u meestal reist.';

  @override
  String get tutorialStepTilePrefsHoursTitle => 'Werk- en persoonlijke uren';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Wanneer Tiler werk- en persoonlijke tegeltjes mag inplannen. Tik erop om een profiel in te stellen.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Blokkade-uren';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Bedtijd en slaaptijd — uren waarin Tiler nooit inplant.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'Transcriptie maken';

  @override
  String get newChat => 'Nieuwe chat';

  @override
  String get noChatHistory => 'Geen chatgeschiedenis';

  @override
  String get unknownChat => 'Onbekende chat';

  @override
  String get transcriptionFailed => 'Transcriptie mislukt';

  @override
  String get acceptChanges => 'Wijzigingen accepteren';

  @override
  String get noRequestToExecute => 'Geen aanvraag om uit te voeren';

  @override
  String get initializingAction => 'Actiegeneratie inicialiseren';

  @override
  String get settingThingsUp => 'Dingen inrichten';

  @override
  String get preparingRequest => 'Uw aanvraag voorbereiden';

  @override
  String get gettingReady => 'Voorbereiden';

  @override
  String get processingAction => 'Actie verwerken';

  @override
  String get workingOnIt => 'Er mee bezig';

  @override
  String get analyzingRequest => 'Uw aanvraag analyseren';

  @override
  String get thinking => 'Nadenken';

  @override
  String get actionComplete => 'Actieverwerking voltooid';

  @override
  String get processingDone => 'Verwerking voltooid';

  @override
  String get allSet => 'Alles gereed';

  @override
  String get finishedProcessing => 'Verwerking beëindigd';

  @override
  String get generatingSummary => 'Samenvatting genereren';

  @override
  String get summarizingResults => 'Resultaten samenvatten';

  @override
  String get creatingOverview => 'Overzicht aanmaken';

  @override
  String get preparingSummary => 'Samenvatting voorbereiden';

  @override
  String get summaryComplete => 'Samenvattinggeneratie voltooid';

  @override
  String get summaryReady => 'Samenvatting gereed';

  @override
  String get overviewComplete => 'Overzicht voltooid';

  @override
  String get doneSummarizing => 'Samenvatten voltooid';

  @override
  String get loadingSchedule => 'Roostergegevens laden';

  @override
  String get fetchingSchedule => 'Uw rooster ophalen';

  @override
  String get retrievingCalendar => 'Agenda ophalen';

  @override
  String get loadingTimeline => 'Tijdlijn laden';

  @override
  String get optimizingSchedule => 'Rooster optimaliseren';

  @override
  String get reorganizingDay => 'Uw dag herorganiseren';

  @override
  String get findingBestFit => 'Beste passing zoeken';

  @override
  String get adjustingTimeline => 'Tijdlijn aanpassen';

  @override
  String get scheduleComplete => 'Roosteroptimalisatie voltooid';

  @override
  String get scheduleUpdated => 'Rooster bijgewerkt';

  @override
  String get timelineOptimized => 'Tijdlijn geoptimaliseerd';

  @override
  String get allDone => 'Alles klaar';

  @override
  String get connectionLost => 'Verbinding verbroken. Vernieuw alstublieft';

  @override
  String get sendingRequest => 'Aanvraag verzenden';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'WebSocket-verbinding verbroken na 5 pogingen';

  @override
  String get webSocketMessageHandlingError =>
      'Fout bij het verwerken van een bericht';

  @override
  String get jsonParseError => 'JSON-parseerfout';

  @override
  String get processError => 'Procesfout';

  @override
  String get socketConnectionError => 'Socketverbindingsfout';

  @override
  String get keepAliveFailed => 'Verbinding in stand houden mislukt';

  @override
  String get copy => 'Kopiëren';

  @override
  String get entityIdNotFound => 'Geen voorbeeld-entiteits-id gevonden';

  @override
  String get feedback => 'Terugkoppeling';

  @override
  String get feedbackCategory => 'Categorie';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategoryFeature => 'Functie';

  @override
  String get feedbackCategoryEnhancement => 'Uitbreiding';

  @override
  String get feedbackCategoryGeneral => 'Algemeen';

  @override
  String get feedbackTitle => 'Titel';

  @override
  String get feedbackTitleHint => 'Kort overzicht van uw feedback';

  @override
  String get feedbackDescription => 'Omschrijving';

  @override
  String get feedbackDescriptionHint => 'Geef details over uw feedback';

  @override
  String get feedbackSubmitted => 'Feedback succesvol verzonden';

  @override
  String get feedbackError => 'Feedback verzenden mislukt';

  @override
  String get noPreviewsAvailable =>
      'Geen TileCasts beschikbaar voor dit verzoek';

  @override
  String get previewUnavailable =>
      'De geselecteerde TileCast is niet beschikbaar';

  @override
  String get previewSummaryUnavailable => 'TileCast kon niet worden geladen';

  @override
  String get previewGenerating => 'TileCast genereren…';

  @override
  String get previewTimedOut =>
      'De TileCast duurt langer dan verwacht. Probeer het over een moment opnieuw.';

  @override
  String get previewGenerationFailed =>
      'We konden deze TileCast niet genereren.';

  @override
  String get previewInvalidated =>
      'Deze TileCast is niet meer geldig omdat uw rooster is gewijzigd.';

  @override
  String get previewStaleBanner =>
      'Deze TileCast toont een eerdere momentopname van uw rooster.';

  @override
  String get previewNonViableLabel => 'Kon niet worden ingepland';

  @override
  String get reviewChanges => 'Wijzigingen bekijken';

  @override
  String get previewRetry => 'Opnieuw proberen';

  @override
  String get previewPreparing => 'TileCast voorbereiden…';

  @override
  String get previewReadyToView => 'Tik om TileCast te bekijken';

  @override
  String get previewActionsOutdated => 'Verouderd — verstuur een nieuw bericht';

  @override
  String get previewActionsUnavailable => 'TileCast niet beschikbaar';

  @override
  String get tileCastStaleNote =>
      'Uw rooster is gewijzigd — deze TileCast is mogelijk verouderd';

  @override
  String get tileCastAlsoIncluded => 'Ook opgenomen';

  @override
  String actionsCount(int count) {
    return '$count acties';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'Notities laden…';

  @override
  String get notesSaving => 'Opslaan…';

  @override
  String get notesSaved => 'Opgeslagen';

  @override
  String get notesUnsaved => 'Bewerken…';

  @override
  String get notesSaveError => 'Kon niet worden opgeslagen';

  @override
  String get notesSaveNow => 'Nu opslaan';

  @override
  String get notesShowPreview => 'Voorbeeld';

  @override
  String get notesShowEditor => 'Bewerken';

  @override
  String get notesPreviewEmpty => 'Nog niets om voor te bekijken.';

  @override
  String get notesLinkPromptTitle => 'Link invoegen';

  @override
  String get notesConflictTitle =>
      'Iemand anders heeft deze notitie bijgewerkt.';

  @override
  String get notesConflictDiscardMine => 'De mijne wegwerpen';

  @override
  String get notesConflictKeepEditing => 'Doorgaan met bewerken';

  @override
  String get notesToolBold => 'Vette tekst';

  @override
  String get notesToolItalic => 'Cursief';

  @override
  String get notesToolStrikethrough => 'Doorhalen';

  @override
  String get notesToolInlineCode => 'Inlijn-code';

  @override
  String get notesToolHeading1 => 'Koptekst 1';

  @override
  String get notesToolHeading2 => 'Koptekst 2';

  @override
  String get notesToolBulletList => 'Opsomming';

  @override
  String get notesToolNumberedList => 'Genummerde lijst';

  @override
  String get notesToolTaskList => 'Takenlijst';

  @override
  String get notesToolQuote => 'Citaat';

  @override
  String get notesToolLink => 'Link';

  @override
  String get notesTitle => 'Notities';

  @override
  String get notesViewerTitle => 'Notitie';

  @override
  String get notesTapToAdd => 'Tik om een notitie toe te voegen';

  @override
  String get notesTapToEdit => 'Tik om te bewerken · lange druk om te lezen';

  @override
  String get notesDone => 'Klaar';

  @override
  String get endOfDay => 'Einde van de dag';

  @override
  String get search => 'Zoeken';

  @override
  String get share => 'Delen';

  @override
  String get openChat => 'Chat openen';

  @override
  String get goToToday => 'Naar vandaag gaan';

  @override
  String get switchCalendarView => 'Agendaweergave wisselen';

  @override
  String get switchDayGridLayout => 'Daglayout wisselen';

  @override
  String get openDayRibbon => 'Dagen bekijken';

  @override
  String get previewSundialGreeting => 'Hallo.';

  @override
  String get previewSundialCountsPrefix => 'Vandaag heeft';

  @override
  String get previewSundialCountsSuffix => 'in afwachting.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count tegeltjes';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count blokken';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count gedeelde tegeltjes';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours uur werk';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins min vervoer';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'uw dag is vrij vanaf $time';
  }

  @override
  String get previewSundialAndSeparator => 'en';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count locaties';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '${hours}u slaap';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '${hours}u vrij';
  }

  @override
  String get previewSundialFullyBooked => 'Volledig ingepland';

  @override
  String get previewSundialTier0 => 'Vrije dag';

  @override
  String get previewSundialTier1 => 'Opstarten';

  @override
  String get previewSundialTier2 => 'Onderweg';

  @override
  String get previewSundialTier3 => 'Stevige vooruitgang';

  @override
  String get previewSundialTier4 => 'Bijna er';

  @override
  String get previewSundialTodayLabel => 'Vandaag';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles tegeltjes, $blocks blokken, $nonViable niet-gepland';
  }

  @override
  String get timelineClearHeading => 'Uw tijdlijn is vandaag vrij';

  @override
  String get timelineClearAddTask => 'Voeg een tegeltje toe';

  @override
  String get aiConsentTitle => 'Maak kennis met Tiler AI';

  @override
  String get aiConsentSubtitle => 'Uw AI-planninghulp';

  @override
  String get aiConsentIntro =>
      'Om uw woorden om te zetten in een rooster, deelt Tiler AI wat u verstuurt met betrouwbare AI-aanbieders.';

  @override
  String get aiConsentDataTitle => 'Wat we verzenden';

  @override
  String get aiConsentDataBody =>
      'De berichten en spraakopnames die u verstuurt, plus relevante details uit uw rooster.';

  @override
  String get aiConsentProvidersTitle => 'Wie het ontvangt';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini en OpenAI, onze AI-aanbieders van derden.';

  @override
  String get aiConsentPrivacyLink => 'Lees ons privacybeleid';

  @override
  String get aiConsentContinue => 'Doorgaan naar Tiler AI';

  @override
  String get aiConsentAgreementNotice =>
      'Door verder te gaan, gaat u akkoord met het delen van deze gegevens met de aanbieder van derden zoals hierboven beschreven.';

  @override
  String get aiConsentClose => 'Sluiten';

  @override
  String get legalFooterPrefix =>
      'Door verder te gaan, gaat u akkoord met de voorwaarden van Tiler';

  @override
  String get legalFooterTerms => 'Voorwaarden';

  @override
  String get legalFooterAnd => 'en';

  @override
  String get legalFooterPrivacy => 'Privacy';

  @override
  String get aiConsentLinkError => 'De link kon niet worden geopend.';

  @override
  String get addTileScreenTitleFlexible => 'Tegeltje toevoegen';

  @override
  String get addTileScreenTitleFixed => 'Blok toevoegen';

  @override
  String get addTileTypeFlexible => 'Flexibele tegel';

  @override
  String get addTileTypeFixed => 'Vast blok';

  @override
  String get addTileTypeSelectorLabel => 'Type tegel';

  @override
  String addTileExplanationFlexible(String emphasis) {
    return 'Tiler vindt het $emphasis voor deze taak.';
  }

  @override
  String addTileExplanationFixed(String emphasis) {
    return 'Blokken vinden plaats op $emphasis.';
  }

  @override
  String get addTileFindTime => 'Tijd zoeken';

  @override
  String get addTileSubmitting => 'Versturen';

  @override
  String get addTileNameRequired => 'Naam is verplicht';

  @override
  String get addTileTitleRequired => 'Titel is verplicht';

  @override
  String get addTileFieldTaskName => 'TAAKNAAM';

  @override
  String get addTileFieldTitle => 'TITEL';

  @override
  String get addTileFieldDuration => 'DUUR';

  @override
  String get addTileFieldCompleteBy => 'AFRONDEN VOOR';

  @override
  String get addTileFieldPreferredTime => 'PREFEREERDE TIJD';

  @override
  String get addTileFieldDate => 'DATUM';

  @override
  String get addTileFieldStarts => 'BEGINT';

  @override
  String get addTileFieldEnds => 'EINDIGT';

  @override
  String get addTileFieldLocation => 'LOCATIE';

  @override
  String get addTileTaskNameHint => 'Wat wil je doen?';

  @override
  String get addTileBlockTitleHint => 'Wat is dit blok?';

  @override
  String get addTileValueNotSet => 'Niet ingesteld';

  @override
  String get addTileAutoCalculated => 'Automatisch berekend';

  @override
  String addTileEndsSemantics(String time) {
    return 'Eindigt om $time, berekend uit start en duur';
  }

  @override
  String addTileTodayDate(String date) {
    return 'Vandaag, $date';
  }

  @override
  String get addTileMoreOptions => 'Meer opties';

  @override
  String get addTilePriority => 'Prioriteit';

  @override
  String get addTilePriorityLow => 'Laag';

  @override
  String get addTilePriorityMedium => 'Middel';

  @override
  String get addTilePriorityHigh => 'Hoog';

  @override
  String get addTilePriorityLowMeaning => 'Leuk als het kan';

  @override
  String get addTilePriorityMediumMeaning => 'Belangrijk';

  @override
  String get addTilePriorityHighMeaning => 'Moet gebeuren';

  @override
  String get addTilePriorityHelper =>
      'Prioriteit helpt Tiler te beslissen wat eerst beschermd wordt.';

  @override
  String get addTileColorAutomatic => 'Automatisch';

  @override
  String get addTileColorCustom => 'Aangepast';

  @override
  String get addTileSplitIntoSessions => 'Opsplitsen in sessies';

  @override
  String get addTileSplitHelper => 'Splits dit in aparte werkuren.';

  @override
  String addTileSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessies',
      one: '1 sessie',
    );
    return '$_temp0';
  }

  @override
  String get addTileFewerSessions => 'Minder sessies';

  @override
  String get addTileMoreSessions => 'Meer sessies';

  @override
  String get addTileFlexibleCompletion => 'Flexibele einddatum';

  @override
  String get addTileFlexibleCompletionHelper =>
      'Tiler kan deze datum bij nodigheid iets verschuiven.';

  @override
  String get addTilePreferredTimeCustom => 'Aangepast';

  @override
  String addTileDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String addTileDurationHours(int hours) {
    return '$hours u';
  }

  @override
  String addTileDurationHoursMinutes(int hours, int minutes) {
    return '$hours u $minutes min';
  }

  @override
  String get addTileRepeat => 'Herhaal';

  @override
  String get addTileRepeatNever => 'Wordt niet herhaald';

  @override
  String get addTileRepeatDays => 'DAGEN';

  @override
  String get addTileRepeatsUntil => 'HERHAALT TOT';

  @override
  String get addTileRepeatHelper =>
      'Herhalen helpt Tiler terugkerende taken in te plannen.';

  @override
  String get addTileLocationSearchHint => 'Zoek locaties';

  @override
  String get addTileLocationYourPlaces => 'JOUW LOCATIES';

  @override
  String get addTileLocationSuggestions => 'VOORSTELLEN';

  @override
  String get addTileLocationHelper =>
      'De locatie helpt Tiler reistijden en tijden optimaliseren.';

  @override
  String get addTileLocationNoneSaved => 'Nog geen locaties opgeslagen';

  @override
  String get addTileLocationNoneSavedHelper =>
      'Zoek een locatie of typ een naam zoals \"fietswinkel\" om deze op te slaan.';

  @override
  String get addTileLocationNoResults => 'Geen locaties gevonden';

  @override
  String get addTileLocationNoResultsHelper =>
      'Je kunt wat je typt toch als locatienaam opslaan.';

  @override
  String get addTileLocationSearchFailed => 'Zoeken is momenteel niet mogelijk';

  @override
  String get addTileLocationSearchFailedHelper =>
      'Controleer je verbinding en probeer opnieuw, of sla wat je typt op als locatienaam.';

  @override
  String addTileLocationUseTyped(String query) {
    return 'Gebruik \"$query\"';
  }

  @override
  String get addTileLocationUseTypedHelper => 'Geef hem een naam en adres';

  @override
  String get addTileLocationFallbackName => 'Locatie';

  @override
  String get addTilePlaceAdd => 'Locatie toevoegen';

  @override
  String get addTilePlaceEdit => 'Locatie bewerken';

  @override
  String get addTilePlaceName => 'NAAM';

  @override
  String get addTilePlaceAddress => 'ADRES';

  @override
  String get addTilePlaceNameHint => 'bijv. Walmart bij het werk';

  @override
  String get addTilePlaceAddressHint => 'Straat, stad, provincie';

  @override
  String get addTilePlaceSave => 'Locatie opslaan';

  @override
  String get addTilePlaceNameThis => 'Geef deze locatie een naam';

  @override
  String get addTilePlaceNameHelper =>
      'De naam is hoe je deze locatie terugvindt. Als twee locaties dezelfde naam hebben, blijft alleen het nieuwste adres over.';

  @override
  String addTilePlaceNameTaken(String name, String address) {
    return 'Je hebt al een locatie \"$name\" op $address. Bij opslaan wordt deze naam verplaatst naar dit adres.';
  }

  @override
  String addTilePlaceNameTakenNoAddress(String name) {
    return 'Je hebt al een locatie \"$name\". Bij opslaan wordt deze naam verplaatst naar dit adres.';
  }

  @override
  String get addTileFieldPriority => 'PRIORITEIT';

  @override
  String get addTileFieldColor => 'KLEUR';

  @override
  String get addTileColorPresets => 'VOORAFGESTELD';

  @override
  String get addTileColorAutomaticHelper => 'Tiler kiest een kleur voor je';

  @override
  String get addTileColorCustomHelper => 'Kies welke kleur je wilt';

  @override
  String get addTileColorHelper =>
      'Kleur verandert alleen de weergave in je schema.';

  @override
  String get addTileColorShuffle => 'Shuffel een andere kleur';

  @override
  String addTileColorSwatch(int index) {
    return 'Kleur $index';
  }

  @override
  String get addTileExplanationFlexibleEmphasis => 'beste tijdstip';

  @override
  String get addTileExplanationFixedEmphasis => 'een vast tijdstip';

  @override
  String get addTileFieldRepeat => 'HERHALING';

  @override
  String get addTileDurationQuick => 'SNEL';

  @override
  String get addTileDurationCustom => 'AANGEPAST';

  @override
  String get addTileDurationHourLabel => 'Uur';

  @override
  String get addTileDurationMinuteLabel => 'Min';

  @override
  String addTileDurationEndsFromStart(String start) {
    return 'VANAF $start';
  }

  @override
  String addTileDurationEndsNextDay(String time) {
    return '$time, volgende dag';
  }

  @override
  String addTileDurationEndsSemantics(String end, String start) {
    return 'Eindigt om $end, vanaf start om $start. Eindtijd wijzigen';
  }

  @override
  String get editTileTitleTile => 'Tegel bewerken';

  @override
  String get editTileTitleBlock => 'Blok bewerken';

  @override
  String get editTileSave => 'Wijzigingen opslaan';

  @override
  String get editTileSaving => 'Opslaan…';

  @override
  String get editTileSectionTiming => 'TIJDPLANNING';

  @override
  String get editTileReasonNameRequired =>
      'Geef deze tegel een titel om hem op te slaan';

  @override
  String get editTileReasonSplitRequired => 'Sessies moeten minstens 1 zijn';

  @override
  String get editTileReasonEndNotAfterStart =>
      'Het einde moet na de start liggen';

  @override
  String get editTileDiscardTitle => 'Wijzigingen verwerpen?';

  @override
  String get editTileDiscardBody =>
      'Je wijzigingen van deze tegel gaan verloren.';

  @override
  String get editTileDiscard => 'Verwerpen';

  @override
  String get editTileKeepEditing => 'Doorgaan met bewerken';

  @override
  String get editTileLoadFailed => 'Deze tegel kon niet worden geladen.';

  @override
  String get editTileSaveFailed =>
      'Opslaan is momenteel niet mogelijk. Je wijzigingen blijven bewaard.';

  @override
  String get editTileSectionActions => 'ACTIES';

  @override
  String get editTileSectionSessions => 'SESSIES';

  @override
  String get editTileFieldSessions => 'Opsplitsen in sessies';

  @override
  String get editTileFieldDeadline => 'EINDETERMIJN';

  @override
  String get editTileSectionAdditional => 'Bijkomende details';

  @override
  String get editTileSectionSuggestions => 'VOORSTELLEN';

  @override
  String get editTileCreateAsNewTile => 'Maak als nieuwe tegel';

  @override
  String get editTileSectionProgress => 'VOORTGANG';

  @override
  String editTileProgressComplete(int done, int total) {
    return '$done van $total voltooid';
  }

  @override
  String editTileProgressRemaining(int remaining, int deleted) {
    return '$remaining over · $deleted verwijderd';
  }

  @override
  String get editTileActionComplete => 'Voltooi';

  @override
  String get editTileActionCompleteCaption => 'Markeer als gedaan';

  @override
  String get editTileActionStartNow => 'Nu starten';

  @override
  String get editTileActionStartNowCaption => 'Verplaats naar nu';

  @override
  String get editTileActionDefer => 'Uitstellen';

  @override
  String get editTileActionDeferCaption => 'Kies een ander tijdstip';

  @override
  String get editTileActionDelete => 'Verwijder';

  @override
  String get editTileActionDeleteCaption => 'Weghalen';

  @override
  String editTileActionConfirmComplete(String title) {
    return '„$title\" markeren als gedaan?';
  }

  @override
  String editTileActionConfirmStartNow(String title) {
    return '„$title\" verplaatsen naar nu?';
  }

  @override
  String editTileActionConfirmDefer(String title) {
    return '„$title\" uitstellen?';
  }

  @override
  String editTileActionConfirmDelete(String title) {
    return '„$title\" verwijderen?';
  }

  @override
  String get editTileActionDeleteBody => 'Dit haalt de tegel uit je schema.';

  @override
  String get editTileActionDiscardsEdits =>
      'Je niet-opgeslagen wijzigingen worden verworpen.';

  @override
  String get editTileActionFailed => 'Actie is momenteel niet mogelijk.';

  @override
  String editTileActionSemantics(String label, String caption) {
    return '$label, $caption';
  }

  @override
  String get editTileSectionRepetition => 'HERHALING';

  @override
  String get editTileSectionPriority => 'PRIORITEIT';

  @override
  String get editTileSectionLocation => 'LOCATIE';

  @override
  String get editTileLocationRemove => 'Locatie verwijderen';

  @override
  String get addTileDeadlineClear => 'Einddatum verwijderen';

  @override
  String get editTileMenuTileDetails => 'Tegeldetails';

  @override
  String get editTileMoreMenu => 'Meer';

  @override
  String get editTileRepeatEveryDay => 'Elke dag';

  @override
  String get editTileRepeatEveryWeek => 'Elke week';

  @override
  String editTileRepeatEveryWeekOn(String days) {
    return 'Elke week op $days';
  }

  @override
  String get editTileRepeatEveryMonth => 'Elke maand';

  @override
  String get editTileRepeatEveryYear => 'Elk jaar';

  @override
  String editTileRepeatUntil(String cadence, String date) {
    return '$cadence · tot $date';
  }

  @override
  String editTileRepeatUntilDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String editTileRepeatNeverEnds(String cadence) {
    return '$cadence · eindigt nooit';
  }

  @override
  String get editTileRepeatCalloutTitle => 'Dit maakt meerdere instanties aan';

  @override
  String get editTileRepeatCalloutBody =>
      'Tiler plant elke keer in op basis van je voorkeuren en beschikbaarheid.';

  @override
  String get editTileNotesTitle => 'Notities';

  @override
  String get editTileModeReadOnly =>
      'Deze tegel is voltooid en kan niet worden bewerkt. Je kunt hem nog wel verwijderen.';

  @override
  String get editTileModeProcrastinate =>
      'Geblokkeerde tijd. Verplaats hem, markeer hem voltooid of verwijder hem.';

  @override
  String editTileModeThirdParty(String provider) {
    return 'Beheerd door $provider. Beantwoord de uitnodiging of verwijder hem hier; bewerk het evenement in $provider.';
  }

  @override
  String get editTileProviderGoogle => 'Google Agenda';

  @override
  String get editTileProviderOutlook => 'Outlook';

  @override
  String get editTileRsvpFailed =>
      'Je reactie kon momenteel niet worden verzonden.';

  @override
  String get editTileWhatIfChecking =>
      'Controleren wat deze wijziging beïnvloedt…';

  @override
  String editTileWhatIfSummary(int late, int overflow) {
    return 'Beïnvloedt andere tegels: $late laat, $overflow overflow';
  }

  @override
  String get editTileWhatIfSheetTitle => 'Wat deze wijziging beïnvloedt';

  @override
  String get editTileWhatIfLate => 'Laat';

  @override
  String get editTileWhatIfOverflow => 'Overflow';

  @override
  String get editTileWhatIfClean => 'Geen andere tegels worden beïnvloed.';

  @override
  String get editTileWhatIfFailed =>
      'Kon niet controleren wat dit met je schema doet.';

  @override
  String get editTileWhatIfRetry => 'Opnieuw proberen';

  @override
  String editTileWhatIfMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nog $count dagen beïnvloed',
      one: 'nog 1 dag beïnvloed',
    );
    return '$_temp0';
  }

  @override
  String get editTileWhatIfUnplaced => 'Niet geplaatst';

  @override
  String editTileWhatIfAffectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beïnvloede tegeltjes',
      one: '1 beïnvloed tegeltje',
    );
    return '$_temp0';
  }

  @override
  String get editTileEditTitle => 'Titel bewerken';

  @override
  String get tileDetailTitle => 'Tegeldetails';

  @override
  String get tileDetailLoadFailed =>
      'De details van deze tegel konden niet worden geladen.';

  @override
  String get tileDetailSaveFailed =>
      'Opslaan is momenteel niet mogelijk. Je wijzigingen blijven bewaard.';

  @override
  String get tileDetailDeleteSeries => 'Tegel verwijderen';

  @override
  String tileDetailDeleteConfirm(String title) {
    return '„$title\" verwijderen?';
  }

  @override
  String get tileDetailDeleteBody =>
      'Elk voorkomen van deze tegel wordt uit je schema verwijderd.';

  @override
  String get tileDetailDeleteFailed =>
      'Verwijderen is momenteel niet mogelijk.';

  @override
  String get tileDetailSectionOccurrences => 'VOORKEUREN';

  @override
  String get tileDetailOccurrencesEmpty => 'Nog geen voorkomens ingepland.';

  @override
  String get tileDetailOccurrencesFailed =>
      'De voorkomens konden niet worden geladen.';

  @override
  String get tileDetailOccurrencesEarlier => 'Vroegere tonen';

  @override
  String get tileDetailOccurrencesLater => 'Latere tonen';

  @override
  String get tileDetailOccurrenceDone => 'Gedaan';

  @override
  String tileDetailOccurrenceSemantics(String day, String span, String done) {
    return '$day, $span$done';
  }

  @override
  String editTileTimeChipSemantics(String field, String value) {
    return '$field-tijd, $value';
  }

  @override
  String editTileDateChipSemantics(String field, String value) {
    return '$field-datum, $value';
  }

  @override
  String get addTileSubmitFailed =>
      'Kon momenteel niet worden toegevoegd. Je details zijn opgeslagen.';

  @override
  String get addTileRetry => 'Opnieuw proberen';

  @override
  String get addTileTimeRestrictionTitle => 'Tijdsbeperkingen';

  @override
  String get addTileTimeRestrictionHeading => 'Wanneer mag Tiler dit plannen?';

  @override
  String get addTileTimeRestrictionSubtitle =>
      'Stel in wanneer deze tegel in je agenda mag verschijnen.';

  @override
  String get addTileRestrictionAnytimeHelper =>
      'Tiler kan dit overal plaatsen wanneer je beschikbaar bent.';

  @override
  String get addTileRestrictionWork => 'Werkuren';

  @override
  String get addTileRestrictionWorkHelper =>
      'Alleen plannen tijdens je profiel Werk.';

  @override
  String get addTileRestrictionPersonal => 'Persoonlijke uren';

  @override
  String get addTileRestrictionPersonalHelper =>
      'Alleen plannen tijdens je persoonlijke profiel.';

  @override
  String get addTileRestrictionCustom => 'Aangepaste uren';

  @override
  String get addTileRestrictionCustomHelper =>
      'Kies specifieke dagen en tijden.';

  @override
  String get addTileRestrictionNotSetUp =>
      'Niet ingesteld — gebruik de pijl om uren in te stellen';

  @override
  String addTileRestrictionEdit(String name) {
    return '$name bewerken';
  }

  @override
  String get addTileRestrictionTip =>
      'Tiler houdt zich aan deze beperkingen bij automatisch plannen, opnieuw optimaliseren of tijden voorstellen voor deze tegel.';

  @override
  String get addTileRestrictionLoadFailed =>
      'Je werk- en persoonlijke uren konden niet worden geladen.';

  @override
  String addTileRestrictionDayRange(String first, String last) {
    return '$first – $last';
  }

  @override
  String addTileRestrictionWindow(String days, String start, String end) {
    return '$days · $start – $end';
  }

  @override
  String get addTileCustomHoursTitle => 'Aangepaste uren';

  @override
  String get addTileCustomHoursSubtitle =>
      'Selecteer de dagen en tijdvensters waarin deze tegel gepland kan worden.';

  @override
  String addTileCustomHoursProfileSubtitle(String name) {
    return 'Selecteer de dagen en tijdvensters voor $name.';
  }

  @override
  String get addTileCustomHoursPresets => 'Snelinstellingen';

  @override
  String get addTileHoursPresetWeekdays => 'Doordeweeks';

  @override
  String get addTileHoursPresetEvenings => 'Avonden';

  @override
  String get addTileHoursPresetWeekends => 'Weekenden';

  @override
  String addTileHoursPresetWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String addTileHoursEndsNextDay(String day, String time) {
    return 'Eindigt $day om $time';
  }

  @override
  String addTileRestrictionWindowNextDay(
      String days, String start, String end) {
    return '$days · $start – $end (volgende dag)';
  }

  @override
  String get addTileRestrictionAllDay => 'De hele dag';

  @override
  String addTileRestrictionAllDayWindow(String days, String label) {
    return '$days · $label';
  }

  @override
  String get addTileCustomHoursFooter =>
      'Uitgeschakelde dagen worden uitgesloten bij het plannen van deze tegel.';

  @override
  String addTileCustomHoursProfileFooter(String name) {
    return 'Geldt voor elke tegel die $name gebruikt.';
  }

  @override
  String addTileHoursCopy(String day) {
    return 'Uren van $day kopiëren';
  }

  @override
  String addTileHoursPaste(String day) {
    return 'Uren plakken in $day';
  }

  @override
  String get addTileHoursClearCopy => 'Gekopieerde uren wissen';

  @override
  String addTileHoursStartSemantics(String day, String time) {
    return '$day start, $time';
  }

  @override
  String addTileHoursEndSemantics(String day, String time) {
    return '$day eind, $time';
  }

  @override
  String addTileHoursSaveFailed(String name) {
    return '$name kon niet worden opgeslagen.';
  }

  @override
  String get addTileHoursSaving => 'Opslaan…';

  @override
  String searchResultsForQuery(int count, String query) {
    return '$count resultaten voor \"$query\"';
  }

  @override
  String get searchFilterAll => 'Alles';

  @override
  String get searchFilterTiler => 'Tiler';

  @override
  String get searchFilterGoogle => 'Google';

  @override
  String get searchFilterOutlook => 'Outlook';

  @override
  String get startNow => 'Nu starten';

  @override
  String dueOnDate(String date) {
    return 'Verloopt op $date';
  }

  @override
  String get noResultsForProvider => 'Geen resultaten uit deze agenda';

  @override
  String get readOnly => 'Alleen-lezen';

  @override
  String commentsCount(int count) {
    return '$count reacties';
  }

  @override
  String get commentsEmpty => 'Nog geen reacties';

  @override
  String get commentsTitle => 'Opmerkingen';

  @override
  String get commentsLoading => 'Laden…';

  @override
  String get commentsLoadEarlier => 'Oudere reacties laden';

  @override
  String get commentsLoadEarlierReplies => 'Oudere antwoorden laden';

  @override
  String get commentsRetry => 'Opnieuw proberen';

  @override
  String get commentsLoadError =>
      'Reacties konden niet worden geladen. Probeer het opnieuw.';

  @override
  String get commentsCreateError => 'Je reactie kon niet worden gepost.';

  @override
  String get commentsEditError => 'Je wijziging kon niet worden opgeslagen.';

  @override
  String get commentsDeleteError => 'De reactie kon niet worden verwijderd.';

  @override
  String get commentsCreateReplyError => 'Je antwoord kon niet worden gepost.';

  @override
  String get commentsPlaceholder => 'Schrijf een reactie…';

  @override
  String get commentsReplyPlaceholder => 'Schrijf een antwoord…';

  @override
  String get commentsSend => 'Verstuur';

  @override
  String get commentsSending => 'Versturen…';

  @override
  String get commentsEdit => 'Bewerken';

  @override
  String get commentsSave => 'Opslaan';

  @override
  String get commentsCancel => 'Annuleren';

  @override
  String get commentsDelete => 'Verwijderen';

  @override
  String get commentsEdited => 'bewerkt';

  @override
  String get commentsDeletedPlaceholder => 'Deze reactie is verwijderd.';

  @override
  String get commentsDeletedAuthor => 'Verwijderde gebruiker';

  @override
  String get commentsReply => 'Antwoorden';

  @override
  String commentsReplies(int count) {
    return '$count antwoorden';
  }

  @override
  String get commentsShowReplies => 'Antwoorden weergeven';

  @override
  String get commentsHideReplies => 'Antwoorden verbergen';

  @override
  String get commentsYou => '(jij)';

  @override
  String get commentsMentionSuggestions => 'Personen die je kunt vermelden';

  @override
  String get commentsAttach => 'Bestand bijvoegen';

  @override
  String get commentsAttachmentProcessing => 'Bestand wordt gecontroleerd…';

  @override
  String get commentsAttachmentUploaded => 'Geüpload';

  @override
  String get commentsAttachmentQueued => 'In wachtrij';

  @override
  String commentsAttachmentUploadingSummary(int count) {
    return 'Bestanden worden geüpload ($count resterend). Houd deze pagina open.';
  }

  @override
  String get commentsAttachmentUploadFailed => 'Upload mislukt';

  @override
  String get commentsAttachmentPickFailed =>
      'Het bestand kon niet worden bijgevoegd. Probeer het opnieuw.';

  @override
  String commentsAttachmentRemove(String name) {
    return '$name verwijderen';
  }

  @override
  String get commentsAttachmentDownload => 'Downloaden';

  @override
  String get commentsAttachmentDownloadError =>
      'Het bestand kon niet worden gedownload.';

  @override
  String get commentsAttachmentDownloading => 'Downloaden…';

  @override
  String commentsAttachmentSaved(String name) {
    return 'Opgeslagen: $name';
  }

  @override
  String get commentsAttachmentOpen => 'Openen';

  @override
  String get commentsAttachmentOpenFailed => 'Kon het bestand niet openen.';

  @override
  String get commentsAttachmentInvalidType =>
      'Alleen PDF-, DOCX-, PNG- en JPEG-bestanden kunnen worden bijgevoegd.';

  @override
  String get commentsAttachmentTooLarge =>
      'Bestanden moeten 10 MB of kleiner zijn.';

  @override
  String get commentsAttachmentEmpty => 'Dit bestand is leeg.';

  @override
  String commentsAttachmentLimit(int count) {
    return 'Je kunt tot $count bestanden bijvoegen.';
  }

  @override
  String get productTourStarting =>
      'Je rondleiding door de app staat op het punt te beginnen.';

  @override
  String get attentionTabTitle => 'Aandacht';

  @override
  String get attentionFilterAll => 'Alles';

  @override
  String get attentionFilterInvitations => 'Uitnodigingen';

  @override
  String get attentionFilterChanges => 'Wijzigingen';

  @override
  String get attentionFilterAtRisk => 'In gevaar';

  @override
  String get attentionFilterResponses => 'Reacties';

  @override
  String get attentionPillInvitation => 'Uitnodiging';

  @override
  String get attentionPillChanged => 'Gewijzigd';

  @override
  String get attentionPillAtRisk => 'In gevaar';

  @override
  String get attentionPillDeclined => 'Afgewezen';

  @override
  String get attentionPillCompleted => 'Voltooid';

  @override
  String get attentionPillNotSent => 'Niet verzonden';

  @override
  String get attentionSomeone => 'Iemand';

  @override
  String attentionReasonInvited(String inviter) {
    return '$inviter heeft je uitgenodigd';
  }

  @override
  String attentionReasonInvitedMany(String inviter, int count) {
    return '$inviter heeft je uitgenodigd voor $count tegeltjes';
  }

  @override
  String attentionReasonAtRiskOne(String task) {
    return '‘$task’ past niet meer in je planning';
  }

  @override
  String get attentionReasonAtRiskUntitled =>
      'Een tegeltje past niet meer in je planning';

  @override
  String attentionReasonAtRiskMany(int count) {
    return '$count tegeltjes passen niet meer in je planning';
  }

  @override
  String attentionReasonDeadlineMoved(String actor, String from, String to) {
    return '$actor heeft de deadline verplaatst van $from naar $to';
  }

  @override
  String attentionReasonDeadlineChanged(String actor) {
    return '$actor heeft de deadline gewijzigd';
  }

  @override
  String attentionReasonRenamed(String actor) {
    return '$actor heeft een tegeltje hernoemd';
  }

  @override
  String attentionReasonNotesUpdated(String actor) {
    return '$actor heeft de notities bijgewerkt';
  }

  @override
  String attentionReasonUpdated(String actor) {
    return '$actor heeft een tegeltje bijgewerkt';
  }

  @override
  String attentionReasonManyChanges(String actor, int count) {
    return '$actor heeft $count wijzigingen aangebracht';
  }

  @override
  String attentionReasonDeclined(String actor) {
    return '$actor heeft afgewezen';
  }

  @override
  String attentionReasonDeclinedMany(int count) {
    return '$count personen hebben afgewezen';
  }

  @override
  String get attentionReasonNotSent =>
      'Een uitnodiging kon niet worden verzonden';

  @override
  String attentionReasonNotSentMany(int count) {
    return '$count uitnodigingen konden niet worden verzonden';
  }

  @override
  String get attentionReasonSendUnknown =>
      'Een uitnodiging is mogelijk niet verzonden — verstuur deze zo nodig opnieuw';

  @override
  String attentionReasonCompleted(String actor, String task) {
    return '$actor heeft $task voltooid';
  }

  @override
  String attentionReasonCompletedUntitled(String actor) {
    return '$actor heeft een tegeltje voltooid';
  }

  @override
  String attentionReasonCompletedMany(int count) {
    return '$count tegeltjes voltooid';
  }

  @override
  String attentionMetaTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegeltjes',
      one: '1 tegeltje',
    );
    return '$_temp0';
  }

  @override
  String attentionMetaDue(String date) {
    return 'Deadline: $date';
  }

  @override
  String get attentionCtaReview => 'Bekijken';

  @override
  String get attentionCtaReviewChanges => 'Wijzigingen bekijken';

  @override
  String get attentionCtaReviewPlan => 'Plan bekijken';

  @override
  String get attentionCtaView => 'Weergeven';

  @override
  String get attentionMenuTooltip => 'Meer';

  @override
  String get attentionDismiss => 'Verbergen';

  @override
  String get attentionDismissed => 'Verborgen';

  @override
  String get attentionUndo => 'Ongedaan maken';

  @override
  String get attentionDismissFailed =>
      'Kon niet worden verborgen. Probeer het opnieuw.';

  @override
  String get attentionUndoFailed =>
      'Kon niet worden hersteld. Probeer het opnieuw.';

  @override
  String get attentionEmptyTitle => 'Je bent helemaal bij';

  @override
  String get attentionEmptyBody =>
      'Er is op dit moment niets dat je aandacht nodig heeft.';

  @override
  String get attentionEmptyFiltered => 'Hier is niets te tonen';

  @override
  String get attentionLoadFailed =>
      'Sommige updates konden niet worden geladen';

  @override
  String get attentionLoadFailedAll => 'Aandacht kon niet worden geladen';

  @override
  String get attentionRetry => 'Opnieuw proberen';

  @override
  String get tileShareModeBroadcast => 'Uitzending';

  @override
  String get tileShareModeProject => 'Project';

  @override
  String get tileShareModeClass => 'Klas';

  @override
  String get attentionAccept => 'Accepteren';

  @override
  String get attentionDecline => 'Afwijzen';

  @override
  String get attentionAcceptAll => 'Alles accepteren';

  @override
  String get attentionDeclineAll => 'Alles afwijzen';

  @override
  String get attentionAcceptDone => 'Geaccepteerd';

  @override
  String attentionAcceptDoneMany(int count) {
    return '$count tegeltjes geaccepteerd';
  }

  @override
  String get attentionDeclineDone => 'Afgewezen';

  @override
  String attentionDeclineDoneMany(int count) {
    return '$count tegeltjes afgewezen';
  }

  @override
  String get attentionAcceptFailed =>
      'Kon niet worden geaccepteerd. Probeer het opnieuw.';

  @override
  String get attentionDeclineFailed =>
      'Kon niet worden afgewezen. Probeer het opnieuw.';

  @override
  String get attentionScheduleRefreshFailed =>
      'Geaccepteerd, maar je planning kon nog niet worden vernieuwd.';

  @override
  String get clusterTitleFallback => 'Gedeeld werk zonder titel';

  @override
  String get clusterRoleMine => 'Door jou gemaakt';

  @override
  String clusterRoleFrom(String name) {
    return 'Van $name';
  }

  @override
  String get clusterRoleShared => 'Met jou gedeeld';

  @override
  String clusterRsvpAccepted(int accepted, int total) {
    return '$accepted van $total geaccepteerd';
  }

  @override
  String clusterRsvpPeople(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total personen hebben geaccepteerd',
      one: '1 persoon heeft geaccepteerd',
    );
    return '$accepted van $_temp0';
  }

  @override
  String clusterRsvpTasks(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tegeltjes geaccepteerd',
      one: '1 tegeltje geaccepteerd',
    );
    return '$accepted van $_temp0';
  }

  @override
  String get clusterRsvpUnavailable => 'Reacties niet beschikbaar';

  @override
  String get clusterMineAccepted => 'Je hebt geaccepteerd';

  @override
  String get clusterMineDeclined => 'Je hebt afgewezen';

  @override
  String get clusterMinePending => 'Je antwoord is nodig';

  @override
  String get clusterMineMixed => 'Gedeeltelijk beantwoord';

  @override
  String clusterProjectNeedsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegeltjes hebben je antwoord nodig',
      one: '1 tegeltje heeft je antwoord nodig',
    );
    return '$_temp0';
  }

  @override
  String get clusterOverdue => 'Te laat';

  @override
  String get clusterMenuTooltip => 'Meer acties';

  @override
  String get clusterDelete => 'Verwijderen';

  @override
  String get clusterDeleteTitle => 'Dit gedeelde werk verwijderen?';

  @override
  String clusterDeleteBody(String name) {
    return '‘$name’ wordt verwijderd. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String clusterDeleteFailed(String name) {
    return '‘$name’ kon niet worden verwijderd. Het staat weer in je lijst.';
  }

  @override
  String get clusterFilterAll => 'Alles';

  @override
  String get clusterFilterShared => 'Met mij gedeeld';

  @override
  String get clusterFilterCreated => 'Door mij gemaakt';

  @override
  String get clusterEmptyAllTitle => 'Nog niets gedeeld';

  @override
  String get clusterEmptyAllBody =>
      'Deel een tegel met iemand en deze verschijnt hier.';

  @override
  String get clusterEmptySharedTitle => 'Niets met je gedeeld';

  @override
  String get clusterEmptySharedBody =>
      'Wanneer iemand een tegel met je deelt, verschijnt deze hier.';

  @override
  String get clusterEmptyCreatedTitle => 'Je hebt nog niets gedeeld';

  @override
  String get clusterEmptyCreatedBody =>
      'Deel een tegel om te zien wie deze heeft geaccepteerd.';

  @override
  String get clusterEmptyAction => 'Een tegel delen';

  @override
  String get clusterLoadFailed =>
      'Sommige gedeelde items konden niet worden geladen';

  @override
  String get clusterLoadFailedAll =>
      'Gedeelde items konden niet worden geladen';

  @override
  String get clusterLoadMore => 'Meer laden';

  @override
  String get clusterLoadMoreFailed => 'Meer kon niet worden geladen';

  @override
  String get clustersTabTitle => 'Gedeeld werk';

  @override
  String get previewTitleFallback => 'Planning bekijken';

  @override
  String get previewRegenerate => 'Nieuw voorbeeld maken';

  @override
  String get previewSuggested => 'Voorgestelde planning';

  @override
  String get previewSelected => 'Geselecteerde planning';

  @override
  String previewMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verplaatst $count flexibele tegels',
      one: 'Verplaatst 1 flexibele tegel',
    );
    return '$_temp0';
  }

  @override
  String get previewAccept => 'Accepteren';

  @override
  String get previewAcceptAndLock => 'Accepteren en vastzetten';

  @override
  String get previewAcceptHint => 'Tiler kan flexibel werk later verplaatsen.';

  @override
  String previewLockHint(String when) {
    return 'Zet $when vast. Andere sessies blijven flexibel.';
  }

  @override
  String get previewDecline => 'Afwijzen';

  @override
  String get previewCannotFit => 'Dit past niet meer vóór de deadline.';

  @override
  String previewOutsideWindow(String when) {
    return 'Gepland buiten de getoonde dagen: $when';
  }

  @override
  String get previewNothingThisDay => 'Niets gepland op deze dag';

  @override
  String get previewPrevDay => 'Vorige dag';

  @override
  String get previewNextDay => 'Volgende dag';

  @override
  String get previewStale => 'Dit voorbeeld is verouderd.';

  @override
  String get previewRefresh => 'Voorbeeld vernieuwen';

  @override
  String get previewSessionInvalid =>
      'Deze tijd kan niet meer worden vastgezet. Je kunt nog steeds accepteren.';

  @override
  String get previewLoading => 'Je planning wordt gecontroleerd…';

  @override
  String get previewLoadFailed => 'Het voorbeeld kon niet worden gemaakt.';

  @override
  String get previewGone => 'Deze uitnodiging is niet meer beschikbaar.';

  @override
  String get previewSwitchedOff =>
      'Voorbeelden zijn momenteel niet beschikbaar.';

  @override
  String get previewSignIn => 'Log opnieuw in om het voorbeeld te zien.';

  @override
  String get previewInvalid =>
      'Dat verzoek is niet geaccepteerd. Probeer het opnieuw.';

  @override
  String get previewUnsupportedAccepted => 'Je hebt dit al geaccepteerd.';

  @override
  String get previewUnsupportedDeadline => 'De deadline is verstreken.';

  @override
  String get previewUnsupportedConstraints =>
      'Dit tegeltje herhaalt zich, heeft een locatie of beperkingen die een voorbeeld nog niet kan tonen. Je kunt nog steeds antwoorden vanuit de lijst.';

  @override
  String get previewUnsupportedOther =>
      'Van dit tegeltje kan geen voorbeeld worden getoond.';

  @override
  String get previewAdding => 'Wordt aan je agenda toegevoegd…';

  @override
  String get previewAdded => 'Aan je agenda toegevoegd';

  @override
  String get previewNeedsReview =>
      'Toegevoegd, maar de tijd kon niet worden bevestigd.';

  @override
  String get previewNotAdded => 'Niet toegevoegd';

  @override
  String get previewReasonScheduleChanged =>
      'Je planning is veranderd sinds dit voorbeeld.';

  @override
  String get previewReasonAnswered =>
      'Er is elders al geantwoord of iets gewijzigd.';

  @override
  String get previewReasonExpired => 'Het voorbeeld is verlopen.';

  @override
  String get previewReasonOther =>
      'Kon niet worden gepland zoals in het voorbeeld.';

  @override
  String get previewReviewAgain => 'Opnieuw bekijken';

  @override
  String get previewUnconfirmed => 'Je antwoord kon niet worden bevestigd.';

  @override
  String get previewTryAgain => 'Opnieuw proberen';

  @override
  String get previewCheckStatus => 'Status controleren';

  @override
  String get previewStillAdding => 'Wordt nog toegevoegd…';

  @override
  String get previewDeclined => 'Afgewezen';

  @override
  String get previewDeclineFailed =>
      'Kon niet worden afgewezen. Probeer het opnieuw.';

  @override
  String get previewDone => 'Klaar';

  @override
  String get previewCheckFit => 'Beschikbaarheid controleren';

  @override
  String get previewDetails => 'Details';

  @override
  String get previewOtherTimes => 'Andere tijden';

  @override
  String get previewOriginalSuggestion => 'Oorspronkelijk voorstel';

  @override
  String get previewFindAnotherTime => 'Een andere tijd zoeken';

  @override
  String get previewFindingTimes => 'Andere tijden worden gezocht…';

  @override
  String get previewNoDifferentTime => 'Geen andere tijd gevonden';

  @override
  String get previewOptionsFailed =>
      'Andere tijden konden niet worden geladen.';

  @override
  String get previewSelectFailed => 'Kon niet naar die tijd worden verplaatst.';

  @override
  String get previewNoMoves => 'Verplaatst niets anders';

  @override
  String get previewSessions => 'Sessies';

  @override
  String previewSessionN(int n) {
    return 'Sessie $n';
  }

  @override
  String get previewSessionUnplaced => 'Kon niet worden ingepland';

  @override
  String get previewSessionOutside => 'Buiten de getoonde dagen';

  @override
  String previewIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count planningsproblemen',
      one: '1 planningsprobleem',
    );
    return '$_temp0';
  }

  @override
  String get previewIssueUnscheduled => 'Kon niet worden gepland';

  @override
  String get previewIssueConflict => 'Overlapt met ander werk';

  @override
  String previewIssueWindow(String from, String to) {
    return 'Mogelijk van $from tot $to';
  }

  @override
  String get previewViewInCalendar => 'In agenda bekijken';

  @override
  String get detailLoadFailed => 'Dit gedeelde werk kon niet worden geladen.';

  @override
  String get detailNotFound => 'Dit gedeelde werk is niet meer beschikbaar.';

  @override
  String get detailRefreshFailed =>
      'Kon niet worden vernieuwd. Eerder geladen gegevens worden getoond.';

  @override
  String get detailTasksFailed => 'De tegeltjes konden niet worden geladen.';

  @override
  String get detailTasks => 'Tegeltjes';

  @override
  String get forecastDeadlinePassed => 'Deadline verstreken';

  @override
  String get broadcastParticipants => 'Deelnemers';

  @override
  String broadcastViewAll(int count) {
    return 'Alles bekijken ($count)';
  }

  @override
  String get broadcastNoParticipants =>
      'Nog niemand. Voeg hierboven iemand toe.';

  @override
  String get projectNoParticipants =>
      'Nog niemand. Wijs op het tabblad Tegeltjes een tegeltje toe aan iemand.';

  @override
  String broadcastDeliveryIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitnodigingen zijn mogelijk niet aangekomen',
      one: '1 uitnodiging is mogelijk niet aangekomen',
    );
    return '$_temp0';
  }

  @override
  String get participantInvited => 'Uitgenodigd';

  @override
  String get participantAdding => 'Wordt toegevoegd…';

  @override
  String get participantAddFailed => 'Kon niet worden toegevoegd.';

  @override
  String get participantRemoveFailed => 'Kon niet worden verwijderd.';

  @override
  String participantAlreadyInvited(String who) {
    return '$who is al uitgenodigd.';
  }

  @override
  String get participantRemove => 'Verwijderen';

  @override
  String participantRemoveTitle(String who) {
    return '$who verwijderen?';
  }

  @override
  String get participantRemoveBody =>
      'Deze persoon heeft dit tegeltje dan niet meer.';

  @override
  String deliverySent(String channel) {
    return 'Verzonden via $channel';
  }

  @override
  String get deliverySentPlain => 'Uitnodiging verzonden';

  @override
  String deliveryFailed(String channel) {
    return 'Kon niet worden verzonden via $channel';
  }

  @override
  String get deliveryFailedPlain => 'Uitnodiging kon niet worden verzonden';

  @override
  String get deliveryUnknown => 'Bezorging onbekend';

  @override
  String get channelEmail => 'e-mail';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelPush => 'melding';

  @override
  String classPeopleIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personen ontbreken bij sommige tegeltjes',
      one: '1 persoon ontbreekt bij sommige tegeltjes',
    );
    return '$_temp0';
  }

  @override
  String classMissingTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Niet bij $count tegeltjes',
      one: 'Niet bij 1 tegeltje',
    );
    return '$_temp0';
  }

  @override
  String get classAddToAll => 'Aan alle tegeltjes toevoegen';

  @override
  String get classRemoveBody =>
      'Deze persoon wordt van alle tegeltjes verwijderd.';

  @override
  String get classTaskNotAdded => 'Niet toegevoegd';

  @override
  String get classAddFailed => 'Kon niet aan alle tegeltjes worden toegevoegd.';

  @override
  String get projectUnassigned => 'Niemand toegewezen';

  @override
  String projectTasksUnassigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegeltjes zijn aan niemand toegewezen',
      one: '1 tegeltje is aan niemand toegewezen',
    );
    return '$_temp0';
  }

  @override
  String get projectAssign => 'Toewijzen';

  @override
  String get projectReassign => 'Opnieuw toewijzen';

  @override
  String get projectReassigning => 'Wordt opnieuw toegewezen…';

  @override
  String get projectReassignFailed => 'Kon niet opnieuw worden toegewezen.';

  @override
  String projectAssignTitle(String task) {
    return '$task toewijzen';
  }

  @override
  String projectOwnsTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verantwoordelijk voor $count tegeltjes',
      one: 'Verantwoordelijk voor 1 tegeltje',
    );
    return '$_temp0';
  }

  @override
  String get projectAlreadyIn => 'Al in dit project';

  @override
  String get projectRemoveBody =>
      'De tegeltjes van deze persoon zijn dan aan niemand toegewezen.';

  @override
  String get tileShareActivityCommentAdded => 'Reactie toegevoegd';

  @override
  String get tileShareActivityCommentReplied =>
      'Antwoord op reactie toegevoegd';

  @override
  String get tileShareActivityCommentEdited => 'Reactie bewerkt';

  @override
  String get tileShareActivityCommentDeleted => 'Reactie verwijderd';

  @override
  String get commitmentYourTasks => 'Je tegeltjes';

  @override
  String get commitmentYourTask => 'Je tegeltje';

  @override
  String commitmentPartialAnswered(int done, int total) {
    return '$done van $total beantwoord; de rest wacht nog op antwoord.';
  }

  @override
  String get commitmentOpenTile => 'Tegel openen';

  @override
  String get detailEditShare => 'Gedeeld werk bewerken';

  @override
  String get detailEditTask => 'Tegeltje bewerken';

  @override
  String get detailAddTask => 'Tegeltje toevoegen';

  @override
  String get detailDeleteTask => 'Tegeltje verwijderen';

  @override
  String detailDeleteTaskTitle(String name) {
    return '‘$name’ verwijderen?';
  }

  @override
  String get detailDeleteTaskBody =>
      'Het wordt uit de planning van alle deelnemers verwijderd.';

  @override
  String get detailEditFailed =>
      'Je wijziging kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get detailTaskLengthFixed =>
      'De duur van een tegeltje kan na het delen niet veranderen.';

  @override
  String get taskSheetAssignee => 'TOEGEWEZEN AAN';

  @override
  String get taskSheetEveryone => 'Iedereen in deze klas heeft dit tegeltje.';

  @override
  String taskSheetAfterShareDeadline(String when) {
    return 'Dit is na de deadline van het gedeelde werk ($when).';
  }

  @override
  String get taskSheetNameTooShort => 'Gebruik minstens 3 tekens';

  @override
  String get taskSheetPeopleHintClass =>
      'Iedereen die je hier toevoegt, krijgt elk tegeltje in deze klas. Wijzigingen in deelnemers worden bij het opslaan verzonden.';

  @override
  String get taskSheetPeopleHintProject =>
      'De nieuwe toewijzing wordt bij het opslaan verzonden.';

  @override
  String get tiletteNameLabel => 'NAAM VAN HET TEGELTJE';

  @override
  String get detailEditDetails => 'Details bewerken';

  @override
  String get detailDeleteShare => 'Gedeeld werk verwijderen';

  @override
  String get detailDeleteShareBody =>
      'De tegeltjes worden uit ieders planning verwijderd.';

  @override
  String get detailDeleteShareFailed =>
      'Het gedeelde werk kon niet worden verwijderd. Probeer het opnieuw.';

  @override
  String get shareNameLabel => 'NAAM VAN HET GEDEELDE WERK';

  @override
  String get shareModeLabel => 'MODUS';

  @override
  String get shareEditModeFixed => 'De modus kan na het delen niet veranderen.';

  @override
  String get shareEditEffort => 'TOTALE INSPANNING';

  @override
  String get shareEditEffortHelper => 'De som van de duur van alle tegeltjes.';

  @override
  String get shareEditDiscardBody =>
      'Je wijzigingen in dit gedeelde werk gaan verloren.';

  @override
  String shareEditTilettesPulledIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count geaccepteerde tegeltjes worden naar deze deadline verplaatst.',
      one: '1 geaccepteerd tegeltje wordt naar deze deadline verplaatst.',
    );
    return '$_temp0';
  }

  @override
  String shareEditTilettesKeep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count tegeltjes die niemand heeft geaccepteerd, behouden hun latere deadlines.',
      one:
          '1 tegeltje dat niemand heeft geaccepteerd, behoudt de latere deadline.',
    );
    return '$_temp0';
  }

  @override
  String taskSheetMoveShareDeadline(String when) {
    return 'Verplaats ook de deadline van het gedeelde werk naar $when';
  }

  @override
  String get createChooserTitle => 'Werk delen';

  @override
  String get createChooserSubtitle => 'Hoe moeten mensen deelnemen?';

  @override
  String get createModeBroadcastBody =>
      'Iedereen krijgt een eigen kopie van één tegeltje';

  @override
  String get createModeClassBody =>
      'Iedereen krijgt een eigen kopie van een reeks tegeltjes';

  @override
  String get createModeProjectBody =>
      'Iedereen werkt aan één gedeelde reeks tegeltjes';

  @override
  String get createComingSoon => 'Binnenkort beschikbaar';

  @override
  String get createBroadcastTitle => 'Nieuwe uitzending';

  @override
  String get createBroadcastPeopleHint =>
      'Iedereen krijgt een eigen kopie en wordt gevraagd deze te accepteren.';

  @override
  String get createSend => 'Verzenden';

  @override
  String createSendTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Naar $count personen verzenden',
      one: 'Naar 1 persoon verzenden',
    );
    return '$_temp0';
  }

  @override
  String get createSending => 'Wordt verzonden…';

  @override
  String get createNeedsPerson => 'Voeg minstens één persoon toe';

  @override
  String get createFailed =>
      'Kan nu niet worden verzonden. Je gegevens blijven bewaard.';

  @override
  String get createDiscardTitle => 'Dit gedeelde werk verwerpen?';

  @override
  String get createDiscardBody => 'Wat je hebt ingevuld, wordt niet verzonden.';

  @override
  String get createClassTitle => 'Nieuwe klas';

  @override
  String get createNeedsTask => 'Voeg minstens één tegeltje toe';

  @override
  String get createClassPeopleHint =>
      'Iedereen krijgt een eigen kopie van elk tegeltje en wordt gevraagd deze te accepteren.';

  @override
  String get createTilettesLabel => 'TEGELTJES';

  @override
  String createTiletteWithShare(String length) {
    return '$length · deadline van het gedeelde werk';
  }

  @override
  String createTiletteDue(String length, String when) {
    return '$length · deadline: $when';
  }

  @override
  String createClassSummary(int count, String effort, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegeltjes',
      one: '1 tegeltje',
    );
    return '$_temp0 · $effort · deadline: $when';
  }

  @override
  String createStepOf(int step, int total) {
    return 'Stap $step van $total';
  }

  @override
  String get createNextPeople => 'Volgende: personen';

  @override
  String get createProjectTitle => 'Nieuw project';

  @override
  String get createProjectSend => 'Project maken';

  @override
  String get createCreating => 'Wordt gemaakt…';

  @override
  String get createProjectHint =>
      'Wijs na het maken via het bord tegeltjes toe aan anderen, of houd ze voor jezelf.';

  @override
  String get detailLoading => 'Gedeeld werk wordt geladen…';

  @override
  String get taskSheetPeopleLabel => 'PERSONEN';

  @override
  String get taskSheetAddPerson => 'PERSOON TOEVOEGEN';

  @override
  String get taskSheetWillBeAdded => 'Wordt toegevoegd';

  @override
  String get taskSheetWillBeRemoved => 'Wordt verwijderd';

  @override
  String get taskSheetWillBeAssigned => 'Wordt bij het opslaan toegewezen';

  @override
  String get taskSheetPeopleFailed =>
      'Sommige wijzigingen in deelnemers konden niet worden opgeslagen. Probeer het hieronder opnieuw.';

  @override
  String get tileShareSaveChanges => 'Wijzigingen opslaan';

  @override
  String get scheduleChangeRefresh => 'Planning vernieuwen';

  @override
  String get scheduleChangeUncertainBody =>
      'Je wijziging heeft de server mogelijk bereikt. Vernieuw om te controleren of de planning is bijgewerkt. Deze blokkering eindigt automatisch.';

  @override
  String get scheduleChangeRefreshing => 'Je tijdlijn wordt bijgewerkt…';

  @override
  String get scheduleChangeShuffling => 'Een nieuwe indeling proberen…';

  @override
  String get scheduleChangeShuffleCommand => 'Husselen';

  @override
  String get scheduleChangeBuildingTimeline =>
      'Je eerste tijdlijn wordt gemaakt…';

  @override
  String get scheduleChangeSetupCommand => 'Eerste tijdlijn';

  @override
  String get scheduleChangeUncertain => 'Bevestiging niet beschikbaar';

  @override
  String scheduleChangeAcknowledged(String change) {
    return '$change: Je tijdlijn is bijgewerkt. Bekijk de wijzigingen.';
  }

  @override
  String scheduleChangeWentThrough(String change) {
    return '$change is gelukt.';
  }

  @override
  String scheduleChangeFailedLate(String change) {
    return '$change is mislukt.';
  }

  @override
  String scheduleChangeUnconfirmed(String change) {
    return '$change kon niet worden bevestigd. Controleer je planning.';
  }

  @override
  String scheduleChangeNotSent(String change) {
    return 'Tiler was niet bereikbaar, dus $change is niet verzonden. Probeer het opnieuw.';
  }

  @override
  String get scheduleChangeUnconfirmedGeneric =>
      'Je laatste wijziging van de planning kon niet worden bevestigd. Controleer je planning.';

  @override
  String get scheduleChangeReattemptTitle => 'Opnieuw verzenden?';

  @override
  String scheduleChangeReattemptBody(String change) {
    return '$change is mogelijk al gelukt. Opnieuw verzenden?';
  }

  @override
  String get scheduleChangeReattemptConfirm => 'Opnieuw verzenden';

  @override
  String scheduleChangeReattemptDeclined(String change) {
    return '$change is niet opnieuw verzonden.';
  }

  @override
  String get scheduleChangeAdding => 'Afspraak toevoegen';

  @override
  String get scheduleChangeSettings => 'Planningsinstellingen bijwerken';

  @override
  String get scheduleChangeAccepting => 'Wijzigingen accepteren';

  @override
  String get scheduleChangeTargetSchedule => 'Je planning';

  @override
  String get scheduleChangeTargetEvent => 'Afspraak';

  @override
  String get scheduleChangeAllEvents => 'Alle afspraken';

  @override
  String scheduleChangeEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count afspraken',
      one: '1 afspraak',
    );
    return '$_temp0';
  }

  @override
  String get scheduleChangesBlocked =>
      'Rond de huidige wijziging van de planning af voordat je een nieuwe begint.';

  @override
  String scheduleChangesBlockedBy(String change) {
    return 'Rond de huidige wijziging van de planning ($change) af voordat je een nieuwe begint.';
  }

  @override
  String get scheduleChangeFailed => 'Wijziging van de planning mislukt';

  @override
  String get scheduleUpdates => 'Planningupdates';

  @override
  String get scheduleUpdatesDescription =>
      'Hoe je dag beweegt wanneer je planning verandert.';

  @override
  String get scheduleUpdatesDetailed => 'Gedetailleerd';

  @override
  String get scheduleUpdatesDetailedDescription =>
      'Toont elke wijziging stap voor stap.';

  @override
  String get scheduleUpdatesMinimal => 'Minimaal';

  @override
  String get scheduleUpdatesMinimalDescription =>
      'Schuift tegeltjes naar hun nieuwe tijden.';

  @override
  String get scheduleUpdatesOff => 'Uit';

  @override
  String get scheduleUpdatesOffDescription =>
      'Direct bijwerken, zonder animatie.';

  @override
  String get scheduleChangePlanUpdated => 'Planning bijgewerkt';

  @override
  String get scheduleChangeDayCleared => 'Dag vrijgemaakt';

  @override
  String scheduleChangeTilesMoved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes verplaatst',
      one: '1 tegeltje verplaatst',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesMovedToOtherDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes naar andere dagen verplaatst',
      one: '1 tegeltje naar een andere dag verplaatst',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes toegevoegd',
      one: '1 tegeltje toegevoegd',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesRemoved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes verwijderd',
      one: '1 tegeltje verwijderd',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTravelUpdated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString reistijden bijgewerkt',
      one: '1 reistijd bijgewerkt',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeFreeGained(String duration) {
    return '+$duration vrij';
  }

  @override
  String get scheduleChangeSeeChanges => 'Wijzigingen bekijken';

  @override
  String get scheduleChangeWhatChanged => 'Wat er is veranderd';

  @override
  String scheduleChangeAdded(String time) {
    return 'Toegevoegd · $time';
  }

  @override
  String get scheduleChangeRemoved => 'Verwijderd';

  @override
  String scheduleChangeTravelTo(String name) {
    return 'Reis naar $name';
  }

  @override
  String get scheduleChangeFreeTime => 'Vrije tijd';

  @override
  String scheduleChangeMovedFrom(String time) {
    return 'Verplaatst van $time';
  }

  @override
  String scheduleChangeMovedTo(String time) {
    return 'Verplaatst naar $time';
  }

  @override
  String scheduleChangeTileMovedTo(String name, String when) {
    return '$name verplaatst naar $when';
  }

  @override
  String scheduleChangeTilesMovedTo(int count, String when) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes verplaatst naar $when',
      one: '1 tegeltje verplaatst naar $when',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesMovedLater(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes later gezet',
      one: '1 tegeltje later gezet',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesMovedEarlier(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes eerder gezet',
      one: '1 tegeltje eerder gezet',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeTilesMoving(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tegeltjes worden verplaatst',
      one: '1 tegeltje wordt verplaatst',
    );
    return '$_temp0';
  }

  @override
  String get scheduleChangeTabChanges => 'Wijzigingen';

  @override
  String get scheduleChangeTabBeforeAfter => 'Voor & na';

  @override
  String get scheduleChangeBefore => 'Voor';

  @override
  String get scheduleChangeAfter => 'Na';

  @override
  String get vibeChatExecutionMode => 'Chat execution';

  @override
  String get vibeConfirmFirst => 'Confirm first';

  @override
  String get vibeAutoAct => 'Auto act';

  @override
  String get vibeAutoActNote =>
      'Run supported chat actions automatically. Bulk and destructive changes still need review.';

  @override
  String get vibeConfirmNote => 'Review chat changes before they run.';

  @override
  String get vibeConfirmCreation => 'Confirm creation';

  @override
  String get vibeCheckStatus => 'Check status';

  @override
  String get vibeCreationUnknown =>
      'Creation could not be confirmed. Check status before trying again.';

  @override
  String get vibeReviewAgain =>
      'Review the current proposal before confirming again.';

  @override
  String get vibeTileShareCreated => 'TileShare created.';

  @override
  String get vibeCreationReview => 'Review TileShare creation';

  @override
  String get vibeCreationNote =>
      'Nothing is created until you confirm. Recipients still choose whether to accept; notifications are not sent by this action.';

  @override
  String get vibeCreateProject => 'Create project';

  @override
  String get vibeAddTilette => 'Add tilette';

  @override
  String get vibeReviewProject => 'Project';

  @override
  String get vibeReviewStarts => 'Starts';

  @override
  String get vibeReviewDeadline => 'Deadline';

  @override
  String get vibeReviewMinutes => 'minutes';

  @override
  String get vibeOpenTileShare => 'Open TileShare';

  @override
  String get vibeProjectRenamed => 'Project renamed.';

  @override
  String get vibeRenameReview => 'Review project rename';

  @override
  String get vibeRenameProject => 'Rename project';

  @override
  String get vibePreviousName => 'Current name';

  @override
  String get vibeRenameNote =>
      'Only the project name changes after confirmation.';

  @override
  String get vibeConfirmRename => 'Confirm rename';

  @override
  String get vibeRenameUnknown =>
      'Rename could not be confirmed. Check status before trying again.';

  @override
  String get vibeTiletteRenamed => 'Tilette renamed.';

  @override
  String get vibeTiletteRenameReview => 'Review tilette rename';

  @override
  String get vibeRenameTilette => 'Rename tilette';

  @override
  String get vibeTiletteRenameNote =>
      'Only the shared tilette name changes. Personal calendar titles stay as they are.';

  @override
  String get vibeNotesUpdated => 'Tilette notes updated.';

  @override
  String get vibeNotesReview => 'Review tilette notes';

  @override
  String get vibeEditNotes => 'Update tilette notes';

  @override
  String get vibePreviousNotes => 'Current notes';

  @override
  String get vibeProposedNotes => 'Proposed notes';

  @override
  String get vibeEmptyNotes => 'No notes';

  @override
  String get vibeClearNotes => 'Clear notes';

  @override
  String get vibeNotesNote =>
      'The proposed text replaces the complete tilette notes after confirmation.';

  @override
  String get vibeConfirmNotes => 'Confirm notes';

  @override
  String get vibeNotesUnknown =>
      'Notes update could not be confirmed. Check status before trying again.';

  @override
  String get vibeTiletteDeleted => 'Tilette deleted.';

  @override
  String get vibeDeleteReview => 'Review tilette deletion';

  @override
  String get vibeDeleteTilette => 'Delete tilette';

  @override
  String get vibeAssignmentCount => 'Assignments';

  @override
  String get vibeLinkedCalendarCount => 'Linked calendar items';

  @override
  String get vibeDeleteNote =>
      'This disables the tilette and linked calendar work. The project and other tilettes stay available. Assignment history is retained; undo is not provided here.';

  @override
  String get vibeConfirmDeletion => 'Confirm deletion';

  @override
  String get vibeDeleteUnknown =>
      'Deletion could not be confirmed. Check status before trying again.';

  @override
  String get vibeOpenProject => 'Open project';

  @override
  String get vibeTiletteUpdated => 'Tilette updated.';

  @override
  String get vibeUpdateReview => 'Review tilette update';

  @override
  String get vibeUpdateTilette => 'Update tilette';

  @override
  String get vibeUpdateNote =>
      'All displayed changes are saved together after confirmation. Supplied notes replace the complete note.';

  @override
  String get vibeConfirmUpdate => 'Confirm update';

  @override
  String get vibeUpdateRejected =>
      'No changes were applied. Review the response and request a revised update.';

  @override
  String get vibeUpdateUnknown =>
      'Update could not be confirmed. Check status before trying again.';

  @override
  String get vibeScheduleUpdatePending =>
      'Calculating accepted-work schedules. No changes have been saved yet.';

  @override
  String get vibeScheduleNoFit =>
      'No changes were applied. The remaining work could not fit around protected sessions. Adjust the duration or deadline and request a revised update.';

  @override
  String get vibeScheduleUpdateFailed =>
      'No changes were applied. The schedule changed or calculation could not complete. Request a revised update.';

  @override
  String get vibeUpdateProject => 'Update project';

  @override
  String get vibeProjectUpdateReview => 'Review project update';

  @override
  String get vibeProjectUpdated => 'Project updated.';

  @override
  String get vibeManageAccess => 'Manage project access';

  @override
  String get vibeManageRecipients => 'Manage recipients';

  @override
  String get vibeManagementUpdated => 'Recipient or access changes saved.';

  @override
  String get vibeManagementNote =>
      'Review the recipient and access effects above. Calendar access cleanup and restoration run in the background.';

  @override
  String get vibeAccessReconciliation =>
      'Access is saved. Calendar cleanup or restoration runs in the background.';

  @override
  String get vibePlanTargetPending => 'Waiting for combined calculation';

  @override
  String get vibePlanTargetNotApplied => 'Not applied';

  @override
  String get vibePlanReview => 'Review shared-work plan';

  @override
  String get vibePlanUpdated => 'Reviewed changes saved together.';

  @override
  String get vibePlanNote =>
      'All displayed targets are saved together after confirmation. If any target changes or access is lost, review a new proposal.';
}
