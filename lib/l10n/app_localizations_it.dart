// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Aggiungi';

  @override
  String get setupCustomRestrictions => 'Configura limitazioni personalizzate';

  @override
  String get customRestrictionTitle => 'Limitazioni personalizzate';

  @override
  String get customRestrictionHeader => 'Configura limitazioni personalizzate';

  @override
  String get customRestrictionHeaderDescription =>
      'Seleziona quando desideri completare questo compito.';

  @override
  String get day => 'Giorno';

  @override
  String get hour => 'Ora';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Lunedì';

  @override
  String get tuesday => 'Martedì';

  @override
  String get wednesday => 'Mercoledì';

  @override
  String get thursday => 'Giovedì';

  @override
  String get friday => 'Venerdì';

  @override
  String get saturday => 'Sabato';

  @override
  String get sunday => 'Domenica';

  @override
  String get duration => 'Durata';

  @override
  String get durationStar => 'Durata*';

  @override
  String get addTile => 'Aggiungi blocco';

  @override
  String get defer => 'Rinvia';

  @override
  String get deferAll => 'Rinvia tutto';

  @override
  String get procrastinating => 'Procrastinazione';

  @override
  String get forecast => 'Previsione';

  @override
  String get whenQ => 'Quando?';

  @override
  String get loading => 'Caricamento';

  @override
  String get loadingPrediction => 'Caricamento previsione';

  @override
  String get address => 'Indirizzo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get nickName => 'Nome di battesimo';

  @override
  String get deadline_anytime => 'Scadenza (Quando vuoi)';

  @override
  String get selectADeadline => 'Seleziona una scadenza';

  @override
  String get close => 'Chiudi';

  @override
  String get tileName => 'Nome blocco';

  @override
  String get tileNameStar => 'Nome blocco*';

  @override
  String get starAreRequired => ' * sono campi obbligatori';

  @override
  String get howManyTimes => 'Quante volte';

  @override
  String get once => 'Una volta';

  @override
  String get weekdaysAndWorkHours => 'Giorni feriali e ore lavorative';

  @override
  String get weekend => 'Fine settimana';

  @override
  String get anytime => 'Quando vuoi';

  @override
  String get repetition => 'Ripetizione';

  @override
  String get reminder => 'Promemoria';

  @override
  String get restriction => 'Limitazione';

  @override
  String get username => 'Nome utente';

  @override
  String get usernameOrEmail => 'Nome utente o Email';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get back => 'Indietro';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get passwordIsRequired => 'La password è obbligatoria';

  @override
  String get emailIsRequired => 'L\'email è obbligatoria';

  @override
  String get fieldIsRequired => 'Il campo è obbligatorio';

  @override
  String get signingIn => 'Accesso in corso';

  @override
  String get signInWithEmailCode => 'Accedi con codice email';

  @override
  String get sendAccessCode => 'Invia codice di accesso';

  @override
  String get continueBtn => 'Continua';

  @override
  String get usePasswordInstead => 'Usa la password invece';

  @override
  String get useAccessCodeInstead => 'Usa il codice di accesso invece';

  @override
  String get registeringUser => 'Registrazione utente';

  @override
  String get sendVerificationCode => 'Invia codice di verifica';

  @override
  String get verificationCodeSent => 'Codice di verifica inviato al tuo email.';

  @override
  String get verificationCode => 'Codice di verifica';

  @override
  String get verifyCode => 'Verifica codice';

  @override
  String get resendCode => 'Invia di nuovo il codice';

  @override
  String get verifyingCode => 'Verifica del codice in corso';

  @override
  String get invalidVerificationCode =>
      'Codice di verifica non valido o scaduto.';

  @override
  String get accessCodeRequiresEmail =>
      'L\'accesso con codice richiede un indirizzo email.';

  @override
  String get emailCodeInstructions =>
      'Inserisci il tuo email e ti invieremo un codice di verifica.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Inserisci il codice di verifica inviato a $email.';
  }

  @override
  String get confirmPasswordRequired =>
      'È richiesta la conferma della password';

  @override
  String get passwordsDontMatch => 'La password e la conferma non coincidono';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'La password deve avere almeno 7 caratteri';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'La password deve contenere una lettera maiuscola';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'La password deve contenere una lettera minuscola';

  @override
  String get passwordNeedsToHaveNumber =>
      'La password deve contenere un numero';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'La password deve contenere almeno 1 carattere speciale';

  @override
  String get enableLocations => 'Attiva l\'autorizzazione alla posizione';

  @override
  String get noMatchWasFound => 'Nessuna corrispondenza trovata';

  @override
  String get atLeastThreeLettersForLookup =>
      '...Tiler ha bisogno di tre caratteri per la ricerca';

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
  String get noLocationMatchWasFound =>
      'Nessuna corrispondenza di posizione trovata';

  @override
  String get noLocation => 'Nessuna posizione';

  @override
  String get clearedColon => 'Cancellato: ';

  @override
  String get complete => 'Completa';

  @override
  String get delete => 'Elimina';

  @override
  String get cancel => 'Annulla';

  @override
  String get now => 'Adesso';

  @override
  String get color => 'Colore';

  @override
  String get pickAColor => 'Scegli un colore';

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Riprendi';

  @override
  String get play => 'Avvia';

  @override
  String get successfullyPaused => 'Pausa riuscita';

  @override
  String get successfullyResumed => 'Ripresa riuscita';

  @override
  String get successfullyCompleted => 'Completato con successo';

  @override
  String get completed => 'Completato';

  @override
  String get deleted => 'Eliminato';

  @override
  String get scheduled => 'Programmato';

  @override
  String get movedUpToNow => 'Spostamento verso adesso';

  @override
  String get pausing => 'Messa in pausa';

  @override
  String get resuming => 'Ripresa in corso';

  @override
  String get movingUp => 'Spostamento in alto del tuo blocco';

  @override
  String get completing => 'Completamento';

  @override
  String get deleting => 'Eliminazione';

  @override
  String get deleteBlockConfirming => 'Eliminazione di questo blocco...';

  @override
  String get deleteTileConfirming => 'Eliminazione di questo blocco...';

  @override
  String get deleteNow => 'Elimina ora';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Verranno eliminati anche da Google Calendar';

  @override
  String get deleteOutlookWarning => '⚠️ Verranno eliminati anche da Outlook';

  @override
  String get previously => 'Precedenti';

  @override
  String get upcoming => 'Imminenti';

  @override
  String get failedToSendRequest => 'Invio della richiesta non riuscito';

  @override
  String get revise => 'Modifica';

  @override
  String get revisingSchedule => 'Modifica pianificazione';

  @override
  String get procrastinateBlockOut => 'Pausa blocco';

  @override
  String get lunchBreak => 'Pausa pranzo';

  @override
  String get coffeeBreak => 'Pausa caffè';

  @override
  String get morningBreak => 'Pausa del mattino';

  @override
  String get afternoonBreak => 'Pausa del pomeriggio';

  @override
  String get freeTime => 'Tempo libero';

  @override
  String get freeSlotHeader => 'Tempo libero';

  @override
  String get freeSlotNow => 'Libero ora';

  @override
  String get quickBreak => 'Pausa veloce';

  @override
  String get shortBreak => 'Pausa breve';

  @override
  String get blockedTime => 'Tempo bloccato';

  @override
  String get start => 'Inizio';

  @override
  String get end => 'Fine';

  @override
  String get deadline => 'Scadenza';

  @override
  String get split => 'Dividi';

  @override
  String get timeBlocks => 'Blocchi di tempo';

  @override
  String get swipeRightToTileIt => 'Scorri a destra per pianificarlo';

  @override
  String get failedToReviseScheduleRequest =>
      'Richiesta di modifica della pianificazione non riuscita';

  @override
  String get daily => 'Quotidiano';

  @override
  String get weekly => 'Settimanale';

  @override
  String get monthly => 'Mensile';

  @override
  String get yearly => 'Annuale';

  @override
  String get none => 'Nessuno';

  @override
  String get noneNotificationCategory => 'Predefinito';

  @override
  String get nextTileNotificationCategory => 'Prossimo blocco';

  @override
  String get userSetReminderNotificationCategory =>
      'Promemoria impostato dall\'utente';

  @override
  String get depatureTimeNotificationCategory => 'Ora di partenza';

  @override
  String get tile => 'Blocco';

  @override
  String get appointment => 'Blocco';

  @override
  String startingAtTime(String time) {
    return 'Inizia alle $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Termina alle $time';
  }

  @override
  String get startsInTenMinutes => 'Inizia tra dieci minuti';

  @override
  String get endsInTenMinutes => 'Termina tra cinque minuti';

  @override
  String startsInDuration(String duration) {
    return 'Inizia tra $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName sta per concludersi';
  }

  @override
  String get home => 'Casa';

  @override
  String get work => 'Lavoro';

  @override
  String get googleLogo => 'Logo Google';

  @override
  String get edit => 'Modifica';

  @override
  String get workProfileHours => 'Orari di lavoro';

  @override
  String get personalHours => 'Orari personali';

  @override
  String get setWorkProfileHours => 'Imposta orari di lavoro';

  @override
  String get setPersonalHours => 'Imposta orari personali';

  @override
  String get customHours => 'Orari personalizzati';

  @override
  String get logout => 'Esci';

  @override
  String get noteEllipsis => 'Nota...';

  @override
  String get tapToCreateNewTile => 'Tocca per creare un nuovo blocco';

  @override
  String get emptyDayHeaderLine1 => 'Nessun piano per ora.';

  @override
  String get emptyDayFooterLine1 => 'Inizia in pochi secondi';

  @override
  String get emptyDayFooterLine2 => 'importa i calendari o crea blocchi.';

  @override
  String get emptyDayOr => 'o';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Importa Google Calendar';

  @override
  String get suggestions => 'Suggerimenti';

  @override
  String get progress => 'Progressi';

  @override
  String get youNeedToLeaveIn => 'Devi partire tra';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Devi partire tra $duration';
  }

  @override
  String durationLate(String duration) {
    return 'In ritardo di $duration';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Trascorso $duration fa';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Completato $duration fa';
  }

  @override
  String durationLeft(String duration) {
    return 'Rimane $duration';
  }

  @override
  String get issuesConnectingToTiler => 'Problemi di connessione a Tiler';

  @override
  String completedCount(String count) {
    return 'Completati ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Eliminati ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Blocchi rimasti ($count)';
  }

  @override
  String countTile(String count) {
    return '$count blocchi';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number blocchi selezionati';
  }

  @override
  String get completeTiles => 'Completa blocchi';

  @override
  String get thisFitsInYourSchedule =>
      'Questa si adatta alla tua pianificazione.';

  @override
  String get warningColon => 'Attenzione: ';

  @override
  String get oneEventAtRisk => '1 evento a rischio';

  @override
  String countEventAtRisk(String number) {
    return '$number eventi a rischio';
  }

  @override
  String get oneConflict => '1 conflitto';

  @override
  String countConflict(String number) {
    return '$number conflitti';
  }

  @override
  String get create => 'Crea';

  @override
  String get thisEventWouldCause => 'Questo evento causerebbe ';

  @override
  String errorMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get unScheduledTiles => 'Blocchi non pianificati';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number blocchi non pianificati';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number altri';
  }

  @override
  String get unScheduled => 'Non pianificato';

  @override
  String get allScheduled => 'Tutto pianificato';

  @override
  String get getOnIt => 'Inizia subito';

  @override
  String get done => 'Fatto';

  @override
  String get late => 'In ritardo';

  @override
  String get onTime => 'In orario';

  @override
  String get todayStatusPlacedTitle => 'Inseriti con successo';

  @override
  String get todayStatusAttentionTitle => 'Richiede attenzione';

  @override
  String get todayStatusLateTitle => 'In ritardo';

  @override
  String get todayStatusAttentionHelper =>
      'Non è stato possibile inserirli nel tempo disponibile di oggi.';

  @override
  String get todayStatusLateHelper =>
      'Il tempo di spostamento tra questi e i blocchi circostanti fa sì che non potrai arrivare in orario.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocchi',
      one: '1 blocco',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Blocchi completati',
      one: 'Blocco completato',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Richiedono attenzione';

  @override
  String get todayStatusTilesRunningLate => 'In ritardo';

  @override
  String get todayStatusEverythingOnTrack => 'Tutto è in carreggiata';

  @override
  String get todayStatusEverythingElseOnTrack =>
      'Tutto il resto è in carreggiata';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Nessun blocco pianificato è in ritardo.';

  @override
  String get todayStatusClearDay => 'La tua giornata è libera.';

  @override
  String get todayStatusPreviewCta => 'Visualizza un piano migliore';

  @override
  String get todayStatusPreviewLoading => 'Preparazione dell\'anteprima…';

  @override
  String get todayStatusPreviewUnavailable =>
      'L\'anteprima non può essere generata. Il tuo piano non è stato modificato.';

  @override
  String get todayStatusUntitledTile => 'Blocco senza titolo';

  @override
  String get todayStatusShowAll => 'Mostra tutto';

  @override
  String todayStatusExpandSection(String section) {
    return 'Espandi $section';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return 'Comprimi $section';
  }

  @override
  String get todayStatusReasonDueToday => 'Scadenza oggi';

  @override
  String get todayStatusReasonNoOpenSlot => 'Nessuno slot libero';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'Lo spostamento lo rende impossibile';

  @override
  String get todayStatusReasonOutsideHours => 'Fuori dalle ore disponibili';

  @override
  String get todayStatusReasonDependencyBlocked =>
      'In attesa di un altro blocco';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Richiede $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Richiede la tua decisione';

  @override
  String get todayStatusReasonUnknown => 'Non ha trovato spazio';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioni',
      one: '1 sessione',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Seleziona blocchi';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Espandi le sessioni di $title';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Comprimi le sessioni di $title';
  }

  @override
  String get analysis => 'Analisi';

  @override
  String get noDataAvailable => 'Nessun dato disponibile';

  @override
  String get sleep => 'Sonno';

  @override
  String get overview => 'Panoramica';

  @override
  String get driveTime => 'Tempo di guida';

  @override
  String get signUpWithGoogle => 'Accedi con Google';

  @override
  String get signUpWithApple => 'Accedi con Apple';

  @override
  String get signUpWithMicrosoft => 'Accedi con Microsoft';

  @override
  String get signIn => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get invalidUsernameOrPassword => 'Nome utente o password non validi';

  @override
  String get noInternetConnection => 'Nessuna connessione Internet';

  @override
  String get oneHour => '1 ora';

  @override
  String countHours(String count) {
    return '$count ore';
  }

  @override
  String get oneMinute => '1 minuto';

  @override
  String countMinutes(String count) {
    return '$count minuti';
  }

  @override
  String countDays(String count) {
    return '$count giorni';
  }

  @override
  String lateDate(String date) {
    return 'In ritardo ($date)';
  }

  @override
  String get custom => 'Personalizzato';

  @override
  String get allowAccessDescription =>
      'Tiler raccoglie dati di posizione per una pianificazione efficiente di blocchi e appuntamenti.\nI tuoi dati restano privati e vengono utilizzati solo per questo scopo.';

  @override
  String get allowLocationAccessQ => 'Consentire l\'accesso alla posizione?';

  @override
  String get allow => 'Consenti';

  @override
  String get deny => 'Nega';

  @override
  String get afternoon => 'Pomeriggio';

  @override
  String get evening => 'Sera';

  @override
  String get night => 'Notte';

  @override
  String get morningAndAfternoon => 'Mattina & Pomeriggio';

  @override
  String get afternoonAndEvening => 'Pomeriggio & Sera';

  @override
  String get lateEvening => 'Sera tardi';

  @override
  String get prediction => 'Previsione';

  @override
  String get softDeadline => 'Scadenza flessibile';

  @override
  String get location => 'Posizione';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteYourTilerAccountQ => 'Eliminare l\'account?';

  @override
  String get no => 'No';

  @override
  String get dismiss => 'Ignora';

  @override
  String get forgetPassword => 'Dimentica password';

  @override
  String get forgotPasswordBtn => 'Password dimenticata?';

  @override
  String get resetPassword => 'Reimposta password';

  @override
  String get reset => 'Reimposta';

  @override
  String lookingUp(String text) {
    return 'Ricerca di $text';
  }

  @override
  String get lowPriorityTrunc => 'Bassa';

  @override
  String get mediumPriorityTrunc => 'Media';

  @override
  String get highPriorityTrunc => 'Alta';

  @override
  String failedToAddGoogleCalendar(String email) {
    return 'Aggiunta di $email non riuscita';
  }

  @override
  String deletedCalendar(String email) {
    return 'Calendario $email eliminato';
  }

  @override
  String get loadingIntegrations => 'Caricamento integrazioni';

  @override
  String get noThirdPartyIntegtions => 'Nessun calendario di terze parti';

  @override
  String get addGoogleCalendar => 'Aggiungi Google Calendar';

  @override
  String get integrations => 'Integrazioni';

  @override
  String get integrateOtherCalendars => 'Integra calendari di terze parti';

  @override
  String get clear => 'Cancella';

  @override
  String get next => 'Avanti';

  @override
  String get previous => 'Indietro';

  @override
  String get skip => 'Salta';

  @override
  String get morningPerson => '🌅 Persona mattutina';

  @override
  String get morning => 'Mattina';

  @override
  String get middayPerson => '🌞 Persona di mezzogiorno';

  @override
  String get nightPerson => '🌃 Persona notturna';

  @override
  String get enterAddress => 'Inserisci il tuo indirizzo';

  @override
  String get primaryLocationQuestion =>
      'Qual è la tua posizione principale per lavoro o studio?';

  @override
  String get useDeviceLocation => 'Usa la posizione del mio dispositivo';

  @override
  String get energyLevelDescriptionQuestion =>
      'Come descriveresti i tuoi livelli di energia nel corso della giornata?';

  @override
  String get incompleteRequest => 'Non è stata inviata una richiesta completa';

  @override
  String get addContact => 'Aggiungi contatto';

  @override
  String get invalidContactFormat => 'Email o numero di telefono non validi';

  @override
  String deadlineTime(String time) {
    return 'Scadenza: $time';
  }

  @override
  String get accept => 'Accetta';

  @override
  String get decline => 'Rifiuta';

  @override
  String get preview => 'Anteprima';

  @override
  String get addTilette => 'Aggiungi Tilette';

  @override
  String get tileShareName => 'Nome del blocco condiviso';

  @override
  String get tileShare => 'Blocco condiviso';

  @override
  String get update => 'Aggiorna';

  @override
  String get noDesignatedTiles => 'Nessun blocco designato';

  @override
  String get noTileCluster => 'Nessun blocco condiviso creato';

  @override
  String get errorLoadingTilelist =>
      'Errore nel caricamento della lista blocchi';

  @override
  String get failedToLoadTileShareCluster =>
      'Caricamento del cluster di blocchi condivisi non riuscito';

  @override
  String get missingTileShareCluster => 'Cluster di blocchi condivisi mancante';

  @override
  String get outBound => 'In uscita';

  @override
  String get inBound => 'In entrata';

  @override
  String get multiShare => 'Condivisione multipla';

  @override
  String get errorOccurred => 'Si è verificato un errore!!\nRiprova.';

  @override
  String get authenticationIssues => 'Problemi di autenticazione.';

  @override
  String get userIsNotAuthenticated => 'L\'utente non è autenticato.';

  @override
  String get responseContentError =>
      'La risposta non contiene il contenuto atteso.';

  @override
  String get responseHandlingError => 'Gestione della risposta non riuscita.';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get tomorrow => 'Domani';

  @override
  String get travel => 'Viaggio';

  @override
  String numberOfDayForecast(String number) {
    return 'Previsione di $number giorni';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Anteprima non riuscita';

  @override
  String get noDriving => 'Nessuna guida';

  @override
  String get tileShareNoteEllipsis => 'Nota...';

  @override
  String get hi => 'Ciao';

  @override
  String get welcome => 'Benvenuto';

  @override
  String get passwordCreationMessagePart1 =>
      'Crea una password forte e univoca con ';

  @override
  String get passwordConditionMinLength => 'almeno sei caratteri';

  @override
  String get passwordCreationMessageIncluding => ', che includa ';

  @override
  String get passwordConditionUppercaseLetters => 'lettere maiuscole';

  @override
  String get passwordConditionLowercaseLetters => 'lettere minuscole';

  @override
  String get passwordConditionNumbers => 'numeri';

  @override
  String get passwordConditionSpecialCharacter => 'un carattere speciale';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', e ';

  @override
  String get nonViableTimeSlot => 'Nessun intervallo di tempo disponibile';

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
  String get save => 'Salva';

  @override
  String get selectWeek => 'Seleziona una settimana';

  @override
  String get selectYear => 'Seleziona anno';

  @override
  String get retrievingDataIssue => 'Problema nel recupero dei dati';

  @override
  String get recurring => 'Ricorrente';

  @override
  String get nonRecurring => 'Non ricorrente';

  @override
  String get dailyReurring => 'Quotidiano';

  @override
  String get weeklyReurring => 'Settimanale';

  @override
  String get biweeklyReurring => 'Bi-settimanale';

  @override
  String get monthlyReurring => 'Mensile';

  @override
  String get yearlyReurring => 'Annuale';

  @override
  String get ellipsisEmprtNotes => 'Note...';

  @override
  String get tileShareDelete => 'Elimina';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Blocco di previsione';

  @override
  String get previewOthers => 'Altri';

  @override
  String get goodMorning => 'Buongiorno';

  @override
  String get goodDay => 'Buona giornata';

  @override
  String get goodEvening => 'Buonasera';

  @override
  String youHaveXBlocks(String count) {
    return 'Hai $count appuntamenti in arrivo.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Hai $count blocchi in arrivo.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Hai $count blocchi condivisi in arrivo.';
  }

  @override
  String countTileShare(String count) {
    return '$count blocchi condivisi';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Hai $blockCount appuntamenti e $tileCount blocchi in arrivo.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Hai $blockCount appuntamenti e $tileShareCount blocchi condivisi in arrivo.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Hai $tileCount blocchi e $tileShareCount blocchi condivisi in arrivo.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Hai $blockCount appuntamenti, $tileCount blocchi e $tileShareCount blocchi condivisi in arrivo.';
  }

  @override
  String get noTilesPreview =>
      'Per il resto del giorno non hai nulla in programma.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Crea blocco';

  @override
  String get previewTileForecast => 'Previsione';

  @override
  String get previewTileOptions => 'Opzioni';

  @override
  String get previewTileMore => 'Altro';

  @override
  String get previewTileShuffle => 'Mescola';

  @override
  String get previewTileRevise => 'Modifica';

  @override
  String get previewTileDeferAll => 'Rinvia tutto';

  @override
  String get previewLocationName => 'Posizione';

  @override
  String get previewTagName => 'Etichetta';

  @override
  String get previewClassificationName => 'Classificazione';

  @override
  String get previewBlockedOut => 'Bloccato';

  @override
  String get accountInfo => 'Info account';

  @override
  String get fistName => 'Nome';

  @override
  String get lastName => 'Cognome';

  @override
  String get tilePreferences => 'Preferenze blocchi';

  @override
  String get notificationsPreferences => 'Preferenze notifiche';

  @override
  String get security => 'Sicurezza';

  @override
  String get connections => 'Connessioni';

  @override
  String get myLocations => 'Le mie posizioni';

  @override
  String get aboutTiler => 'Info su Tiler';

  @override
  String get howToUseTiler => 'Come usare Tiler';

  @override
  String get darkMode => 'Modalità scura';

  @override
  String get setLocation => 'Imposta posizione';

  @override
  String get connectCalendars => 'Collega i tuoi calendari';

  @override
  String get configure => 'Configura';

  @override
  String get comingSoon => 'In arrivo';

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
  String get addCalendar => 'Aggiungi calendario';

  @override
  String get calendarConnected => 'Calendario connesso';

  @override
  String get calendarConnectionDeclined =>
      'La connessione al calendario è stata annullata';

  @override
  String get calendarConnectionError =>
      'Impossibile connettere il tuo calendario';

  @override
  String get sleepDuration => 'Durata del sonno';

  @override
  String get transportationMethodQuestion => 'Come ti sposti?';

  @override
  String get defineYourTimeRestrictions =>
      'Definisci le tue limitazioni di tempo';

  @override
  String get setWorkHours => 'Imposta orari di lavoro';

  @override
  String get setYourBlockOutHours => 'Imposta le ore da bloccare';

  @override
  String get travelMediumBiking => 'In bicicletta';

  @override
  String get travelMediumTransit => 'Trasporto pubblico';

  @override
  String get travelMediumDriving => 'In auto';

  @override
  String get travelMediumTransport => 'Trasporto';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio m';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio h';
  }

  @override
  String get bedTime => 'Ora di andare a letto';

  @override
  String get sleepTime => 'Ora di sonno';

  @override
  String get scheduleFullness => 'Piena della pianificazione';

  @override
  String get scheduleFullnessDescription =>
      'Quanto deve essere piena la tua pianificazione?';

  @override
  String scheduleFullnessValue(int percentage) {
    return 'Piena target del $percentage%';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Gli obiettivi vanno dal $minimum% al $maximum%. Questo mantiene una base utile, lasciando spazio a modifiche e viaggi.';
  }

  @override
  String get schedulePreferences => 'Preferenze della pianificazione';

  @override
  String get lighter => 'Più leggera';

  @override
  String get balanced => 'Equilibrata';

  @override
  String get fuller => 'Più piena';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Preferenze blocchi aggiornate con successo.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Preferenze notifiche aggiornate con successo.';

  @override
  String get tileReminders => 'Promemoria blocchi';

  @override
  String get appUpdates => 'Aggiornamenti app';

  @override
  String get marketingUpdates => 'Aggiornamenti marketing';

  @override
  String get emailNotifications => 'Notifiche email';

  @override
  String get fullName => 'Nome completo';

  @override
  String get phoneNumber => 'Numero di telefono';

  @override
  String get countryCode => 'Prefisso paese';

  @override
  String get dateOfBirth => 'Data di nascita';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'Informazioni account aggiornate con successo.';

  @override
  String get reachingServerIssues =>
      'Problemi nel raggiungimento dei server di Tiler';

  @override
  String get deleteAccountConfirmation =>
      'Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata.';

  @override
  String get disconnect => 'Scollega';

  @override
  String get integrationsSetLocation => 'Imposta posizione';

  @override
  String get googleCalender => 'Google Calendar';

  @override
  String get passwordsMustMatch => 'Le password devono coincidere';

  @override
  String get parenthesisLate => '(In ritardo)';

  @override
  String get failedToAddIntegration => 'Aggiunta integrazione non riuscita';

  @override
  String get unknownProvider => 'Provider sconosciuto';

  @override
  String get manageCalendars => 'Gestisci calendari';

  @override
  String get calendarItems => 'Elementi del calendario';

  @override
  String get noCalendarItemsFound => 'Nessun elemento del calendario trovato';

  @override
  String get calendarItemsWillAppearHere =>
      'I tuoi elementi del calendario appariranno qui';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount di $totalCount calendari attivi';
  }

  @override
  String get toggleCalendarsToSync =>
      'Attiva i calendari da sincronizzare con Tiler';

  @override
  String get unknownCalendar => 'Calendario sconosciuto';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount di $totalCount attivi';
  }

  @override
  String integrationCount(int count) {
    return '$count integrazioni';
  }

  @override
  String get errorLoadingCalendarItems =>
      'Errore nel caricamento degli elementi del calendario';

  @override
  String get integratedCalendars => 'Calendari';

  @override
  String get integrationAdd => 'Aggiungi';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Possiamo accedere alla tua posizione per fornire raccomandazioni\ne notifiche basate sulla posizione?';

  @override
  String get recurringTasks => 'Compiti ricorrenti';

  @override
  String get yourProfession => 'La tua professione?';

  @override
  String get yourProfessionQuestion => 'Che lavoro fai?';

  @override
  String get yourProfessionHint => 'Descrivi cosa fai per lavoro';

  @override
  String get medicalProfessional => 'Professionista sanitario';

  @override
  String get softwareDeveloper => 'Sviluppatore software';

  @override
  String get student => 'Studente';

  @override
  String get engineer => 'Ingegnere';

  @override
  String get fieldSalesProfessional => 'Commerciale in campo';

  @override
  String get remoteWorker => 'Lavoratore da remoto & Nomade digitale';

  @override
  String get stayAtHomeParent => 'Genitore casalingo';

  @override
  String get clientAccountManagers => 'Account manager';

  @override
  String get other => 'Altro';

  @override
  String get tileSuggestions => 'Suggerimenti blocchi';

  @override
  String get personalOrWorkQuestion => 'A cosa userai Tiler?';

  @override
  String get enter3chars => 'Inserisci almeno 3 caratteri.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Parti tra $duration per arrivare in orario';
  }

  @override
  String get leaveNowToArriveOnTime => 'Parti ora per arrivare in orario!';

  @override
  String durationDrive(String duration) {
    return '$duration di guida';
  }

  @override
  String durationTransit(String duration) {
    return '$duration di trasporto pubblico';
  }

  @override
  String durationBike(String duration) {
    return '$duration in bicicletta';
  }

  @override
  String durationWalk(String duration) {
    return '$duration a piedi';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration di guida verso $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration di trasporto pubblico verso $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration in bicicletta verso $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration a piedi verso $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Parti entro le $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Traffico rilevato: suggerito un nuovo percorso';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Traffico: +$minutes min di ritardo';
  }

  @override
  String get heavyTrafficExpected => 'Intenso traffico previsto';

  @override
  String get addWithAI => 'Aggiungi con l\'IA';

  @override
  String get focusTime => 'Tempo di concentrazione';

  @override
  String get videoMeeting => 'Videochiamata';

  @override
  String get sharedWith => 'Condiviso con';

  @override
  String durationMinutes(String minutes) {
    return '${minutes}m';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String travelDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String travelDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String travelViaRoute(String route) {
    return 'via $route';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return ' $travelMode per ';
  }

  @override
  String get travelModeDriving => 'in auto';

  @override
  String get travelModeWalking => 'a piedi';

  @override
  String get travelModeBicycling => 'in bicicletta';

  @override
  String get travelModeTransitLower => 'trasporto pubblico';

  @override
  String travelDurationCompact(int minutes) {
    return '${minutes}m';
  }

  @override
  String get yourDayIsOptimized => 'La tua giornata è ottimizzata.';

  @override
  String get yourDayAtAGlance => 'La tua giornata in un colpo d\'occhio';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration di tempo di viaggio oggi.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count blocchi pianificati per oggi.';
  }

  @override
  String get viewRoute => 'Visualizza percorso';

  @override
  String get focusModeChip => 'Modalità focus';

  @override
  String get showRouteChip => 'Mostra percorso';

  @override
  String get reOptimizeChip => 'Ri-ottimizza';

  @override
  String get todayColon => 'Oggi:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount blocchi, $blockCount appuntamenti';
  }

  @override
  String get timeSavedColon => 'Tempo risparmiato:';

  @override
  String get travelTimeColon => 'Tempo di viaggio:';

  @override
  String travelTime(String duration) {
    return 'Tempo di viaggio: $duration';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationHoursShort(int hours) {
    return '${hours}h';
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
  String get scheduleConflict => 'Conflitto di pianificazione';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" e \"$tile2\" sono pianificati alla stessa ora';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '\"$tile1\" è durante \"$tile2\" (sovrapposizione di $overlap)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '\"$tile1\" sovrappone \"$tile2\" per $overlap';
  }

  @override
  String get fix => 'Correggi';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Conflitto: ${minutes}m di sovrapposizione';
  }

  @override
  String get oneScheduleConflict => '1 conflitto di pianificazione';

  @override
  String countScheduleConflicts(int count) {
    return '$count conflitti di pianificazione';
  }

  @override
  String get tapToReviewAndResolve => 'Tocca per rivedere e risolvere';

  @override
  String countConflicts(int count) {
    return '$count conflitti';
  }

  @override
  String get tapToExpand => 'Tocca per espandere';

  @override
  String conflictingTiles(int count) {
    return '$count blocchi in conflitto';
  }

  @override
  String totalOverlap(String duration) {
    return 'Sovrapposizione totale: $duration';
  }

  @override
  String get autoResolve => 'Risoluzione automatica';

  @override
  String get untitledTile => 'Blocco senza titolo';

  @override
  String get untitledEvent => 'Senza titolo';

  @override
  String get extendedEventSingular => '1 evento esteso';

  @override
  String extendedEventsPlural(int count) {
    return '$count eventi estesi';
  }

  @override
  String get extendedEventsTapToView =>
      'Tocca per vedere eventi di tutto il giorno e di lunga durata';

  @override
  String get extendedEventsTitle => 'Eventi estesi';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventi di oltre 16 ore',
      one: '1 evento di oltre 16 ore',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Percorso di oggi';

  @override
  String get noLocationsToday => 'Nessuna posizione oggi';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Aggiungi posizioni ai tuoi blocchi per vedere il tuo percorso giornaliero';

  @override
  String countStops(int count) {
    return '$count tappe';
  }

  @override
  String get routeOptimized => 'Percorso ottimizzato';

  @override
  String savedTravelTime(String duration) {
    return 'Risparmiati $duration di tempo di viaggio';
  }

  @override
  String get firstStop => 'Prima tappa';

  @override
  String get stop => 'Tappa';

  @override
  String arriveBy(String time) {
    return 'Arriva entro le $time';
  }

  @override
  String get fromPreviousStop => 'dalla tappa precedente';

  @override
  String get viewTile => 'Visualizza blocco';

  @override
  String get editTile => 'Modifica blocco';

  @override
  String get startNavigation => 'Avvia navigazione';

  @override
  String get noLocationAvailable => 'Nessuna posizione';

  @override
  String get seeTodaysRoute => 'Vedi il percorso di oggi';

  @override
  String get whatWouldYouLikeToDo => 'Cosa vorresti fare?';

  @override
  String get describeATask =>
      'Descrivi un compito, ci occupiamo della pianificazione.';

  @override
  String get microphonePermissionDenied =>
      'Autorizzazione al microfono negata.';

  @override
  String failedToStartRecording(String error) {
    return 'Avvio della registrazione non riuscito: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Arresto della registrazione non riuscito: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Errore di conversione audio: $error';
  }

  @override
  String get audioConversionFailed => 'Conversione audio non riuscita';

  @override
  String get recordingPathIsEmpty => 'Il percorso della registrazione è vuoto';

  @override
  String get noActiveRecording => 'Nessuna registrazione attiva';

  @override
  String get joinMeeting => 'Partecipa alla riunione';

  @override
  String get openLink => 'Apri link';

  @override
  String get actions => 'Azioni';

  @override
  String get hideActions => 'Nascondi azioni';

  @override
  String get pendingRsvpSingular => '1 evento richiede una risposta';

  @override
  String pendingRsvpPlural(int count) {
    return '$count eventi richiedono una risposta';
  }

  @override
  String get pendingRsvpHappeningNow =>
      'In corso ora: rispondi per partecipare';

  @override
  String get pendingRsvpStartingSoon => 'Inizia presto: rispondi ora';

  @override
  String get pendingRsvpWithinHour => 'Inizia entro un\'ora';

  @override
  String get pendingRsvpUpcoming => 'In arrivo: tocca per rispondere';

  @override
  String get pendingRsvpTapToReview => 'Tocca per rivedere e rispondere';

  @override
  String get pendingRsvpTitle => 'Risposte in attesa';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventi in attesa della tua risposta',
      one: '1 evento in attesa della tua risposta',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Iniziano presto';

  @override
  String get pendingRsvpLater => 'Più tardi oggi & in arrivo';

  @override
  String get declinedRsvpSingular => '1 evento rifiutato';

  @override
  String declinedRsvpPlural(int count) {
    return '$count eventi rifiutati';
  }

  @override
  String get declinedRsvp => 'Eventi rifiutati';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 in attesa, $declinedCount rifiutati';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount in attesa, 1 rifiutato';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount in attesa, $declinedCount rifiutati';
  }

  @override
  String get rsvpNeedsAction => 'Serve una risposta';

  @override
  String get rsvpTentative => 'Provisionale';

  @override
  String get rsvpAccepted => 'Accettato';

  @override
  String get rsvpDeclined => 'Rifiutato';

  @override
  String unableToOpenLinkError(String link) {
    return 'Impossibile aprire il link: $link';
  }

  @override
  String get leaveNow => 'Parti ora!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Parti tra $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count avvisi';
  }

  @override
  String get alertChipLeaveNow => 'Parti ora';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Parti tra ${minutes}m';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflitti',
      one: '1 conflitto',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tutto il giorno',
      one: '1 tutto il giorno',
    );
    return '$_temp0';
  }

  @override
  String alertChipRsvp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RSVP',
      one: '1 RSVP',
    );
    return '$_temp0';
  }

  @override
  String get accepted => 'Accettato';

  @override
  String get declined => 'Rifiutato';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Rispondi a $calendarSource';
  }

  @override
  String get unknown => 'Invito del calendario';

  @override
  String get loadingPreviousDays => 'Caricamento giorni precedenti...';

  @override
  String get loadingUpcomingDays => 'Caricamento giorni imminenti...';

  @override
  String get requestTimeout =>
      'Timeout della richiesta: controlla la tua connessione';

  @override
  String get failedToPauseTile => 'Messa in pausa del blocco non riuscita';

  @override
  String get failedToResumeTile => 'Ripresa del blocco non riuscita';

  @override
  String get failedToMoveUpTask => 'Spostamento del compito non riuscito';

  @override
  String get failedToUpdateTile => 'Aggiornamento del blocco non riuscito';

  @override
  String get failedToBuzzSchedule => 'Buzz della pianificazione non riuscito';

  @override
  String get failedToShuffleSchedule =>
      'Rimesscolo della pianificazione non riuscito';

  @override
  String get failedToProcrastinateTile =>
      'Procrastinazione del blocco non riuscita';

  @override
  String get tutorialStepYourScheduleTitle => 'La tua pianificazione';

  @override
  String get tutorialStepYourScheduleBody =>
      'La tua giornata è organizzata in Blocchi: blocchi di tempo intelligenti che Tiler dispone per te. Scorri su e giù per vedere la giornata intera.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Crea & Ottimizza';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Tocca qui per creare un nuovo compito. Dì a Tiler cosa devi fare e quanto tempo ci vorrà — Tiler si occupa di quando.';

  @override
  String get tutorialCalloutReOptimize => 'Ri-ottimizza';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'La giornata è deragliata? Ricalcola da ora mantenendo sostanzialmente stabile il piano imminente';

  @override
  String get tutorialCalloutTravelTime => 'Tempo di viaggio';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Tiler tiene conto degli spostamenti tra le posizioni';

  @override
  String get tutorialStepQuickCreateTitle => 'Creazione rapida';

  @override
  String get tutorialStepQuickCreateBody =>
      'Questo è il pannello di aggiunta rapida. Dà un nome al tuo blocco e imposta una durata per un\'aggiunta veloce.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'Questo è il pannello di aggiunta rapida dietro di me! Dà un nome al tuo blocco, imposta una durata e tocca Aggiungi — Tiler si occupa del resto.';

  @override
  String get tutorialCalloutNameYourTile => 'Dai un nome al tuo blocco';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Descrivi il compito che vuoi svolgere';

  @override
  String get tutorialCalloutSetDuration => 'Imposta la durata';

  @override
  String get tutorialCalloutSetDurationDesc => 'Quanto durerà questo compito?';

  @override
  String get tutorialCalloutMoreOptions => 'Altre opzioni';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Aggiungi posizione, scadenza o ripetizione tramite l\'editor completo';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Aggiungi posizione, scadenza o ripetizione';

  @override
  String get tutorialStepTilerWorksTitle => 'Tiler lavora per te';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tiler organizza automaticamente i tuoi blocchi in base ai tuoi livelli di energia, al tempo di viaggio e alle scadenze. Aggiungi semplicemente cosa devi fare — Tiler si occupa di quando.';

  @override
  String get tutorialCalloutForecast => 'Previsione';

  @override
  String get tutorialCalloutForecastDesc =>
      'Vedi quando un blocco verrà inserito prima di selezionarlo';

  @override
  String get tutorialCalloutShuffle => 'Mescola';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Rimischia tutto e suggerisci cosa dovresti fare dopo';

  @override
  String get tutorialCalloutDeferAll => 'Rinvia tutto';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Giornata difficile? Sposta tutto in avanti';

  @override
  String get tutorialStepControlTilesTitle => 'Controlla i tuoi blocchi';

  @override
  String get tutorialStepControlTilesBody =>
      'Ogni blocco ha controlli per gestire i tuoi compiti in tempo reale:';

  @override
  String get tutorialCalloutPlay => 'Avvia';

  @override
  String get tutorialCalloutPlayDesc => 'Inizia a lavorare su questo blocco';

  @override
  String get tutorialCalloutPause => 'Pausa';

  @override
  String get tutorialCalloutPauseDesc =>
      'Fai una pausa — Tiler riorganizzerà il resto';

  @override
  String get tutorialCalloutComplete => 'Completa';

  @override
  String get tutorialCalloutCompleteDesc => 'Fatto! Segnalalo come completato';

  @override
  String get tutorialCalloutProcrastinate => 'Procrastina';

  @override
  String get tutorialCalloutProcrastinateDesc => 'Non ora — spostalo più tardi';

  @override
  String get tutorialStepBigPictureTitle => 'Vedi il quadro generale';

  @override
  String get tutorialStepBigPictureBody =>
      'Tocca l\'icona del calendario per passare tra tre visualizzazioni:';

  @override
  String get tutorialCalloutDaily => 'Giornaliero';

  @override
  String get tutorialCalloutDailyDesc =>
      'Ora per ora — la tua agenda dettagliata';

  @override
  String get tutorialCalloutWeekly => 'Settimanale';

  @override
  String get tutorialCalloutWeeklyDesc =>
      'Vedi tutta la settimana in un colpo d\'occhio';

  @override
  String get tutorialCalloutMonthly => 'Mensile';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Pianifica in anticipo con una panoramica mensile';

  @override
  String get tutorialStepToolkitTitle => 'Il tuo toolkit';

  @override
  String get tutorialStepToolkitBody =>
      'Questi pratici strumenti sono sempre a portata di mano:';

  @override
  String get tutorialCalloutShare => 'Condividi';

  @override
  String get tutorialCalloutShareDesc =>
      'Collabora: condividi blocchi con altri';

  @override
  String get tutorialCalloutSearch => 'Cerca';

  @override
  String get tutorialCalloutSearchDesc => 'Trova qualsiasi blocco per nome';

  @override
  String get tutorialCalloutSettings => 'Impostazioni';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Personalizza la tua esperienza, collega calendari e imposta preferenze';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Tocca il pulsante chat per aggiungere o regolare blocchi parlando con Tiler';

  @override
  String get tutorialStepChatTitle => 'Chat con Tiler';

  @override
  String get tutorialStepChatBody =>
      'Tocca il pulsante chat in qualsiasi momento per aggiungere o regolare blocchi parlando con Tiler: niente moduli.';

  @override
  String get tutorialNavNext => 'Avanti';

  @override
  String get tutorialNavNextArrow => 'Avanti →';

  @override
  String get tutorialNavBack => 'Indietro';

  @override
  String get tutorialNavBackArrow => '← Indietro';

  @override
  String get tutorialNavSkip => 'Salta';

  @override
  String get tutorialNavLetsGo => 'Andiamo!';

  @override
  String get welcomeExplainerHeadline => 'Blocchi vs Appuntamenti';

  @override
  String get welcomeExplainerSubtitle =>
      'Uno sguardo a come Tiler pianifica la tua giornata.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Gli appuntamenti sono fissi. Avvengono a un orario stabilito.';

  @override
  String get welcomeExplainerTilesCaption =>
      'I blocchi sono flessibili. Tiler li dispone attorno ai tuoi appuntamenti.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'Il dentista spostato alle $time — Tiler ripianifica i tuoi blocchi attorno.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Spostato';

  @override
  String get welcomeExplainerReplannedBadge => 'Ripianificato';

  @override
  String get welcomeExplainerBlockStandup => 'Standup di squadra';

  @override
  String get welcomeExplainerBlockDentist => 'Dentista';

  @override
  String get welcomeExplainerTileWorkout => 'Workout';

  @override
  String get welcomeExplainerTileReport => 'Scrivi report';

  @override
  String get welcomeExplainerTileGroceries => 'Spesa';

  @override
  String get welcomeExplainerLegendBlock => 'Appuntamento';

  @override
  String get welcomeExplainerLegendTile => 'Blocco';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Preferenze blocchi';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Le tue preferenze AI vivono qui — come ti sposti, le tue ore lavorative e personali e le ore da bloccare.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Come ti sposti';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tiler stima il tempo di viaggio tra i blocchi in base a come ti sposti di solito.';

  @override
  String get tutorialStepTilePrefsHoursTitle => 'Ore lavorative e personali';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Quando Tiler può pianificare blocchi di lavoro o personali. Tocca uno dei due per impostare un profilo.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Ore da bloccare';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Ora di andare a letto e durata del sonno: ore in cui Tiler non pianifica mai.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'Trascrizione';

  @override
  String get newChat => 'Nuova chat';

  @override
  String get noChatHistory => 'Nessuna cronologia chat';

  @override
  String get unknownChat => 'Chat sconosciuta';

  @override
  String get transcriptionFailed => 'Trascrizione non riuscita';

  @override
  String get acceptChanges => 'Accetta modifiche';

  @override
  String get noRequestToExecute => 'Nessuna richiesta da eseguire';

  @override
  String get initializingAction => 'Inizializzazione generazione azione';

  @override
  String get settingThingsUp => 'Preparazione';

  @override
  String get preparingRequest => 'Preparazione della tua richiesta';

  @override
  String get gettingReady => 'Preparazione in corso';

  @override
  String get processingAction => 'Elaborazione azione';

  @override
  String get workingOnIt => 'Ci sto lavorando';

  @override
  String get analyzingRequest => 'Analisi della tua richiesta';

  @override
  String get thinking => 'Riflessione';

  @override
  String get actionComplete => 'Elaborazione azione completata';

  @override
  String get processingDone => 'Elaborazione completata';

  @override
  String get allSet => 'Tutto pronto';

  @override
  String get finishedProcessing => 'Elaborazione terminata';

  @override
  String get generatingSummary => 'Generazione riepilogo';

  @override
  String get summarizingResults => 'Riepilogo dei risultati';

  @override
  String get creatingOverview => 'Creazione panoramica';

  @override
  String get preparingSummary => 'Preparazione riepilogo';

  @override
  String get summaryComplete => 'Generazione riepilogo completata';

  @override
  String get summaryReady => 'Riepilogo pronto';

  @override
  String get overviewComplete => 'Panoramica completata';

  @override
  String get doneSummarizing => 'Riepilogo completato';

  @override
  String get loadingSchedule => 'Caricamento dati della pianificazione';

  @override
  String get fetchingSchedule => 'Recupero della tua pianificazione';

  @override
  String get retrievingCalendar => 'Recupero calendario';

  @override
  String get loadingTimeline => 'Caricamento linea temporale';

  @override
  String get optimizingSchedule => 'Ottimizzazione della pianificazione';

  @override
  String get reorganizingDay => 'Riorganizzazione della giornata';

  @override
  String get findingBestFit => 'Ricerca del miglior adattamento';

  @override
  String get adjustingTimeline => 'Regolazione linea temporale';

  @override
  String get scheduleComplete =>
      'Ottimizzazione della pianificazione completata';

  @override
  String get scheduleUpdated => 'Pianificazione aggiornata';

  @override
  String get timelineOptimized => 'Linea temporale ottimizzata';

  @override
  String get allDone => 'Tutto fatto';

  @override
  String get connectionLost => 'Connessione persa. Aggiorna';

  @override
  String get sendingRequest => 'Invio della richiesta';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'Connessione WebSocket persa dopo 5 tentativi';

  @override
  String get webSocketMessageHandlingError =>
      'Errore durante la gestione del messaggio';

  @override
  String get jsonParseError => 'Errore di parsing JSON';

  @override
  String get processError => 'Errore di processo';

  @override
  String get socketConnectionError => 'Errore di connessione socket';

  @override
  String get keepAliveFailed => 'Mantenimento della connessione non riuscito';

  @override
  String get copy => 'Copia';

  @override
  String get entityIdNotFound => 'Nessun id entità anteprima trovato';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackCategory => 'Categoria';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategoryFeature => 'Funzionalità';

  @override
  String get feedbackCategoryEnhancement => 'Miglioramento';

  @override
  String get feedbackCategoryGeneral => 'Generale';

  @override
  String get feedbackTitle => 'Titolo';

  @override
  String get feedbackTitleHint => 'Breve sintesi del tuo feedback';

  @override
  String get feedbackDescription => 'Descrizione';

  @override
  String get feedbackDescriptionHint => 'Fornisci i dettagli del tuo feedback';

  @override
  String get feedbackSubmitted => 'Feedback inviato con successo';

  @override
  String get feedbackError => 'Invio del feedback non riuscito';

  @override
  String get noPreviewsAvailable =>
      'Nessun TileCast disponibile per questa richiesta';

  @override
  String get previewUnavailable => 'Il TileCast selezionato non è disponibile';

  @override
  String get previewSummaryUnavailable => 'Impossibile caricare il TileCast';

  @override
  String get previewGenerating => 'Generazione TileCast…';

  @override
  String get previewTimedOut =>
      'Il TileCast sta richiedendo più tempo del previsto. Riprova tra un momento.';

  @override
  String get previewGenerationFailed =>
      'Non siamo riusciti a generare questo TileCast.';

  @override
  String get previewInvalidated =>
      'Questo TileCast non è più valido perché la tua pianificazione è cambiata.';

  @override
  String get previewStaleBanner =>
      'Questo TileCast riflette uno snapshot precedente della tua pianificazione.';

  @override
  String get previewNonViableLabel => 'Non pianificabile';

  @override
  String get reviewChanges => 'Rivedi modifiche';

  @override
  String get previewRetry => 'Riprova';

  @override
  String get previewPreparing => 'Preparazione TileCast…';

  @override
  String get previewReadyToView => 'Tocca per vedere il TileCast';

  @override
  String get previewActionsOutdated =>
      'Non aggiornato — invia un nuovo messaggio';

  @override
  String get previewActionsUnavailable => 'TileCast non disponibile';

  @override
  String get tileCastStaleNote =>
      'La tua pianificazione è cambiata: questo TileCast potrebbe non essere aggiornato';

  @override
  String get tileCastAlsoIncluded => 'Incluso anche';

  @override
  String actionsCount(int count) {
    return '$count azioni';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'Caricamento note…';

  @override
  String get notesSaving => 'Salvataggio…';

  @override
  String get notesSaved => 'Salvato';

  @override
  String get notesUnsaved => 'Modifica in corso…';

  @override
  String get notesSaveError => 'Impossibile salvare';

  @override
  String get notesSaveNow => 'Salva ora';

  @override
  String get notesShowPreview => 'Anteprima';

  @override
  String get notesShowEditor => 'Modifica';

  @override
  String get notesPreviewEmpty => 'Nessuna anteprima disponibile.';

  @override
  String get notesLinkPromptTitle => 'Inserisci link';

  @override
  String get notesConflictTitle => 'Un altro ha aggiornato questa nota.';

  @override
  String get notesConflictDiscardMine => 'Scarta le mie modifiche';

  @override
  String get notesConflictKeepEditing => 'Continua a modificare';

  @override
  String get notesToolBold => 'Grassetto';

  @override
  String get notesToolItalic => 'Corsivo';

  @override
  String get notesToolStrikethrough => 'Barrato';

  @override
  String get notesToolInlineCode => 'Codice inline';

  @override
  String get notesToolHeading1 => 'Intestazione 1';

  @override
  String get notesToolHeading2 => 'Intestazione 2';

  @override
  String get notesToolBulletList => 'Elenco puntato';

  @override
  String get notesToolNumberedList => 'Elenco numerato';

  @override
  String get notesToolTaskList => 'Elenco attività';

  @override
  String get notesToolQuote => 'Citazione';

  @override
  String get notesToolLink => 'Link';

  @override
  String get notesTitle => 'Note';

  @override
  String get notesViewerTitle => 'Nota';

  @override
  String get notesTapToAdd => 'Tocca per aggiungere una nota';

  @override
  String get notesTapToEdit =>
      'Tocca per modificare · pressione prolungata per leggere';

  @override
  String get notesDone => 'Fatto';

  @override
  String get endOfDay => 'Fine della giornata';

  @override
  String get search => 'Cerca';

  @override
  String get share => 'Condividi';

  @override
  String get openChat => 'Apri chat';

  @override
  String get goToToday => 'Vai a oggi';

  @override
  String get switchCalendarView => 'Cambia visualizzazione calendario';

  @override
  String get previewSundialGreeting => 'Ciao.';

  @override
  String get previewSundialCountsPrefix => 'Oggi ci sono';

  @override
  String get previewSundialCountsSuffix => 'in attesa.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count blocchi';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count appuntamenti';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count blocchi condivisi';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours ore di lavoro';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins minuti di spostamenti';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'la tua giornata si libera entro le $time';
  }

  @override
  String get previewSundialAndSeparator => 'e';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count luoghi';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '${hours}h di sonno';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '${hours}h libere';
  }

  @override
  String get previewSundialFullyBooked => 'Tutto pieno';

  @override
  String get previewSundialTier0 => 'Giornata libera';

  @override
  String get previewSundialTier1 => 'Si inizia';

  @override
  String get previewSundialTier2 => 'In corso';

  @override
  String get previewSundialTier3 => 'Ottimo progresso';

  @override
  String get previewSundialTier4 => 'Quasi fatto';

  @override
  String get previewSundialTodayLabel => 'Oggi';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles blocchi, $blocks appuntamenti, $nonViable non pianificati';
  }

  @override
  String get timelineClearHeading => 'La tua linea temporale è libera oggi';

  @override
  String get timelineClearAddTask => 'Aggiungi un blocco';

  @override
  String get aiConsentTitle => 'Incontra Tiler AI';

  @override
  String get aiConsentSubtitle => 'Il tuo assistente di pianificazione AI';

  @override
  String get aiConsentIntro =>
      'Per trasformare le tue parole in una pianificazione, Tiler AI condivide ciò che invii con provider AI di fiducia.';

  @override
  String get aiConsentDataTitle => 'Cosa inviamo';

  @override
  String get aiConsentDataBody =>
      'I messaggi e le registrazioni vocali che invii, oltre ai dettagli rilevanti della tua pianificazione.';

  @override
  String get aiConsentProvidersTitle => 'Chi lo riceve';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini e OpenAI, i nostri provider AI di terze parti.';

  @override
  String get aiConsentPrivacyLink => 'Leggi la nostra Privacy Policy';

  @override
  String get aiConsentContinue => 'Continua con Tiler AI';

  @override
  String get aiConsentAgreementNotice =>
      'Continuando, acconsenti a condividere questi dati con il provider di terze parti come descritto sopra.';

  @override
  String get aiConsentClose => 'Chiudi';

  @override
  String get legalFooterPrefix => 'Continuando, accetti i';

  @override
  String get legalFooterTerms => 'Termini';

  @override
  String get legalFooterAnd => 'e';

  @override
  String get legalFooterPrivacy => 'Privacy';

  @override
  String get aiConsentLinkError => 'Impossibile aprire il link.';

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
}
