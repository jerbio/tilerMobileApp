// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

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
  String get deadline_anytime => 'Deadline (wanneer dan maar)';

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
  String get tileShareName => 'Naam gedeeld tegeltje';

  @override
  String get tileShare => 'Gedeeld tegeltje';

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
  String get multiShare => 'Meervoudig delen';

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
  String get addTileTimeRestrictionTitle => 'Time restrictions';

  @override
  String get addTileTimeRestrictionHeading => 'When can Tiler schedule this?';

  @override
  String get addTileTimeRestrictionSubtitle =>
      'Set when this tile is allowed to appear on your calendar.';

  @override
  String get addTileRestrictionAnytimeHelper =>
      'Tiler can place this whenever you\'re available.';

  @override
  String get addTileRestrictionWork => 'Work hours';

  @override
  String get addTileRestrictionWorkHelper =>
      'Only schedule during your Work profile.';

  @override
  String get addTileRestrictionPersonal => 'Personal hours';

  @override
  String get addTileRestrictionPersonalHelper =>
      'Only schedule during your Personal profile.';

  @override
  String get addTileRestrictionCustom => 'Custom hours';

  @override
  String get addTileRestrictionCustomHelper =>
      'Choose specific days and times.';

  @override
  String get addTileRestrictionNotSetUp =>
      'Not set up — use the arrow to set hours';

  @override
  String addTileRestrictionEdit(String name) {
    return 'Edit $name';
  }

  @override
  String get addTileRestrictionTip =>
      'Tiler will respect these restrictions when auto-scheduling, re-optimizing, or suggesting times for this tile.';

  @override
  String get addTileRestrictionLoadFailed =>
      'Couldn\'t load your Work and Personal hours.';

  @override
  String addTileRestrictionDayRange(String first, String last) {
    return '$first – $last';
  }

  @override
  String addTileRestrictionWindow(String days, String start, String end) {
    return '$days · $start – $end';
  }

  @override
  String get addTileCustomHoursTitle => 'Custom hours';

  @override
  String get addTileCustomHoursSubtitle =>
      'Select the days and time windows when this tile can be scheduled.';

  @override
  String addTileCustomHoursProfileSubtitle(String name) {
    return 'Select the days and time windows for your $name.';
  }

  @override
  String get addTileCustomHoursPresets => 'Quick presets';

  @override
  String get addTileHoursPresetWeekdays => 'Weekdays';

  @override
  String get addTileHoursPresetEvenings => 'Evenings';

  @override
  String get addTileHoursPresetWeekends => 'Weekends';

  @override
  String addTileHoursPresetWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get addTileHoursEndBeforeStart => 'End cannot be before start';

  @override
  String get addTileRestrictionAllDay => 'All day';

  @override
  String addTileRestrictionAllDayWindow(String days, String label) {
    return '$days · $label';
  }

  @override
  String get addTileCustomHoursFooter =>
      'Disabled days will be excluded from scheduling this tile.';

  @override
  String addTileCustomHoursProfileFooter(String name) {
    return 'Applies to every tile that uses $name.';
  }

  @override
  String addTileHoursCopy(String day) {
    return 'Copy $day\'s hours';
  }

  @override
  String addTileHoursPaste(String day) {
    return 'Paste hours to $day';
  }

  @override
  String get addTileHoursClearCopy => 'Clear copied hours';

  @override
  String addTileHoursStartSemantics(String day, String time) {
    return '$day start, $time';
  }

  @override
  String addTileHoursEndSemantics(String day, String time) {
    return '$day end, $time';
  }

  @override
  String addTileHoursSaveFailed(String name) {
    return 'Couldn\'t save your $name.';
  }

  @override
  String get addTileHoursSaving => 'Saving…';

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
  String get productTourStarting =>
      'Je rondleiding door de app staat op het punt te beginnen.';
}
