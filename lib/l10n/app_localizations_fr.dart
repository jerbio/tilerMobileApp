// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Ajouter';

  @override
  String get setupCustomRestrictions =>
      'Configurer des restrictions personnalisées';

  @override
  String get customRestrictionTitle => 'Restrictions personnalisées';

  @override
  String get customRestrictionHeader =>
      'Configurer des restrictions personnalisées';

  @override
  String get customRestrictionHeaderDescription =>
      'Sélectionnez les moments où vous souhaitez effectuer cette tâche.';

  @override
  String get day => 'Jour';

  @override
  String get hour => 'Heure';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get duration => 'Durée';

  @override
  String get durationStar => 'Durée*';

  @override
  String get addTile => 'Ajouter une tuile';

  @override
  String get defer => 'Différer';

  @override
  String get deferAll => 'Tout différer';

  @override
  String get procrastinating => 'Procrastination';

  @override
  String get forecast => 'Prévision';

  @override
  String get whenQ => 'Quand ?';

  @override
  String get loading => 'Chargement';

  @override
  String get loadingPrediction => 'Chargement de la prévision';

  @override
  String get address => 'Adresse';

  @override
  String get settings => 'Paramètres';

  @override
  String get nickName => 'Nom d\'utilisateur';

  @override
  String get deadline_anytime => 'Échéance (N\'importe quand)';

  @override
  String get selectADeadline => 'Sélectionner une échéance';

  @override
  String get close => 'Fermer';

  @override
  String get tileName => 'Nom de la tuile';

  @override
  String get tileNameStar => 'Nom de la tuile*';

  @override
  String get starAreRequired => '* sont des champs obligatoires';

  @override
  String get howManyTimes => 'Combien de fois';

  @override
  String get once => 'Une fois';

  @override
  String get weekdaysAndWorkHours => 'Jours de semaine et heures de travail';

  @override
  String get weekend => 'Week-end';

  @override
  String get anytime => 'N\'importe quand';

  @override
  String get repetition => 'Répétition';

  @override
  String get reminder => 'Rappel';

  @override
  String get restriction => 'Restriction';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameOrEmail => 'Nom d\'utilisateur ou e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get email => 'E-mail';

  @override
  String get back => 'Retour';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordIsRequired => 'Le mot de passe est requis';

  @override
  String get emailIsRequired => 'L\'adresse e-mail est requise';

  @override
  String get fieldIsRequired => 'Ce champ est requis';

  @override
  String get signingIn => 'Connexion en cours';

  @override
  String get signInWithEmailCode => 'Se connecter avec un code e-mail';

  @override
  String get sendAccessCode => 'Envoyer le code d\'accès';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get usePasswordInstead => 'Utiliser un mot de passe à la place';

  @override
  String get useAccessCodeInstead => 'Utiliser un code d\'accès à la place';

  @override
  String get registeringUser => 'Inscription de l\'utilisateur';

  @override
  String get sendVerificationCode => 'Envoyer le code de vérification';

  @override
  String get verificationCodeSent =>
      'Code de vérification envoyé à votre adresse e-mail.';

  @override
  String get verificationCode => 'Code de vérification';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get verifyingCode => 'Vérification du code';

  @override
  String get invalidVerificationCode =>
      'Code de vérification invalide ou expiré.';

  @override
  String get accessCodeRequiresEmail =>
      'La connexion par code d\'accès nécessite une adresse e-mail.';

  @override
  String get emailCodeInstructions =>
      'Saisissez votre e-mail et nous vous enverrons un code de vérification.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Saisissez le code de vérification envoyé à $email.';
  }

  @override
  String get confirmPasswordRequired =>
      'Le mot de passe de confirmation est requis';

  @override
  String get passwordsDontMatch =>
      'Le mot de passe et la confirmation ne correspondent pas';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'Le mot de passe doit contenir au moins 7 caractères';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'Le mot de passe doit contenir au moins une majuscule';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'Le mot de passe doit contenir au moins une minuscule';

  @override
  String get passwordNeedsToHaveNumber =>
      'Le mot de passe doit contenir au moins un chiffre';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'Le mot de passe doit contenir au moins 1 caractère spécial';

  @override
  String get enableLocations => 'Activer les autorisations de localisation';

  @override
  String get noMatchWasFound => 'Aucune correspondance trouvée';

  @override
  String get atLeastThreeLettersForLookup =>
      '...Tiler a besoin de trois caractères pour la recherche';

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
      'Aucune localisation correspondante trouvée';

  @override
  String get noLocation => 'Aucune localisation';

  @override
  String get clearedColon => 'Libéré : ';

  @override
  String get complete => 'Terminer';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get now => 'Maintenant';

  @override
  String get color => 'Couleur';

  @override
  String get pickAColor => 'Choisir une couleur';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get play => 'Lecture';

  @override
  String get successfullyPaused => 'Mise en pause réussie';

  @override
  String get successfullyResumed => 'Reprise réussie';

  @override
  String get successfullyCompleted => 'Terminé avec succès';

  @override
  String get completed => 'Terminé';

  @override
  String get deleted => 'Supprimé';

  @override
  String get scheduled => 'Planifié';

  @override
  String get movedUpToNow => 'Avancé jusqu\'à maintenant';

  @override
  String get pausing => 'Mise en pause';

  @override
  String get resuming => 'Reprise';

  @override
  String get movingUp => 'Avancement de votre tuile';

  @override
  String get completing => 'Terminaison';

  @override
  String get deleting => 'Suppression';

  @override
  String get deleteBlockConfirming => 'Suppression de ce bloc...';

  @override
  String get deleteTileConfirming => 'Suppression de cette tuile...';

  @override
  String get deleteNow => 'Supprimer maintenant';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Cela supprimera également depuis Google Agenda';

  @override
  String get deleteOutlookWarning =>
      '⚠️ Cela supprimera également depuis Outlook';

  @override
  String get previously => 'Précédemment';

  @override
  String get upcoming => 'À venir';

  @override
  String get failedToSendRequest => 'Échec de l\'envoi de la requête';

  @override
  String get revise => 'Réviser';

  @override
  String get revisingSchedule => 'Révision de l\'emploi du temps';

  @override
  String get procrastinateBlockOut => 'Pause tuile';

  @override
  String get lunchBreak => 'Pause déjeuner';

  @override
  String get coffeeBreak => 'Pause café';

  @override
  String get morningBreak => 'Pause matinale';

  @override
  String get afternoonBreak => 'Pause de l\'après-midi';

  @override
  String get freeTime => 'Temps libre';

  @override
  String get freeSlotHeader => 'Temps libre';

  @override
  String get freeSlotNow => 'Libre maintenant';

  @override
  String get quickBreak => 'Petite pause';

  @override
  String get shortBreak => 'Courte pause';

  @override
  String get blockedTime => 'Temps bloqué';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get deadline => 'Échéance';

  @override
  String get split => 'Diviser';

  @override
  String get timeBlocks => 'Blocs horaires';

  @override
  String get swipeRightToTileIt => 'Balayez vers la droite pour planifier';

  @override
  String get failedToReviseScheduleRequest =>
      'Échec de la requête de révision de l\'emploi du temps';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String get none => 'Aucun';

  @override
  String get noneNotificationCategory => 'Par défaut';

  @override
  String get nextTileNotificationCategory => 'Prochaine tuile';

  @override
  String get userSetReminderNotificationCategory =>
      'Rappel défini par l\'utilisateur';

  @override
  String get depatureTimeNotificationCategory => 'Heure de départ';

  @override
  String get tile => 'Tuile';

  @override
  String get appointment => 'Bloc';

  @override
  String startingAtTime(String time) {
    return 'Commence à $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Se termine à $time';
  }

  @override
  String get startsInTenMinutes => 'Commence dans dix minutes';

  @override
  String get endsInTenMinutes => 'Se termine dans cinq minutes';

  @override
  String startsInDuration(String duration) {
    return 'Commence dans $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName se termine bientôt';
  }

  @override
  String get home => 'Domicile';

  @override
  String get work => 'Travail';

  @override
  String get googleLogo => 'Logo Google';

  @override
  String get edit => 'Modifier';

  @override
  String get workProfileHours => 'Heures de travail';

  @override
  String get personalHours => 'Heures personnelles';

  @override
  String get setWorkProfileHours => 'Définir les heures de travail';

  @override
  String get setPersonalHours => 'Définir les heures personnelles';

  @override
  String get customHours => 'Heures personnalisées';

  @override
  String get logout => 'Déconnexion';

  @override
  String get noteEllipsis => 'Note...';

  @override
  String get tapToCreateNewTile => 'Touchez pour créer une nouvelle tuile';

  @override
  String get emptyDayHeaderLine1 => 'Aucun plan pour l\'instant.';

  @override
  String get emptyDayFooterLine1 => 'Commencez en quelques secondes';

  @override
  String get emptyDayFooterLine2 =>
      'importez vos calendriers ou créez des tuiles.';

  @override
  String get emptyDayOr => 'ou';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Importer Google Agenda';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get progress => 'Progression';

  @override
  String get youNeedToLeaveIn => 'Vous devez partir dans';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Vous devez partir dans $duration';
  }

  @override
  String durationLate(String duration) {
    return '$duration de retard';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Écoulé il y a $duration';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Terminé il y a $duration';
  }

  @override
  String durationLeft(String duration) {
    return '$duration restant';
  }

  @override
  String get issuesConnectingToTiler => 'Problème de connexion à Tiler';

  @override
  String completedCount(String count) {
    return 'Terminé ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Supprimé ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Tuiles restantes ($count)';
  }

  @override
  String countTile(String count) {
    return '$count tuiles';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number tuiles sélectionnées';
  }

  @override
  String get completeTiles => 'Terminer les tuiles';

  @override
  String get thisFitsInYourSchedule =>
      'Cela rentre dans votre emploi du temps.';

  @override
  String get warningColon => 'Avertissement : ';

  @override
  String get oneEventAtRisk => '1 événement à risque';

  @override
  String countEventAtRisk(String number) {
    return '$number événements à risque';
  }

  @override
  String get oneConflict => '1 conflit';

  @override
  String countConflict(String number) {
    return '$number conflits';
  }

  @override
  String get create => 'Créer';

  @override
  String get thisEventWouldCause => 'Cet événement provoquerait ';

  @override
  String errorMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get unScheduledTiles => 'Tuiles non planifiées';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number tuiles non planifiées';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number autres';
  }

  @override
  String get unScheduled => 'Non planifié';

  @override
  String get allScheduled => 'Tout planifié';

  @override
  String get getOnIt => 'À la tâche';

  @override
  String get done => 'Terminé';

  @override
  String get late => 'En retard';

  @override
  String get onTime => 'À l\'heure';

  @override
  String get todayStatusPlacedTitle => 'Placement réussi';

  @override
  String get todayStatusAttentionTitle => 'Nécessite votre attention';

  @override
  String get todayStatusLateTitle => 'En retard';

  @override
  String get todayStatusAttentionHelper =>
      'Ces tuiles ne pouvaient pas être placées dans le temps disponible aujourd\'hui.';

  @override
  String get todayStatusLateHelper =>
      'Les temps de trajet entre ces tuiles et les autres vous empêchent d\'arriver à l\'heure.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tuiles',
      one: '1 tuile',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tuiles terminées',
      one: 'Tuile terminée',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Nécessite votre attention';

  @override
  String get todayStatusTilesRunningLate => 'En retard';

  @override
  String get todayStatusEverythingOnTrack => 'Tout est dans les temps';

  @override
  String get todayStatusEverythingElseOnTrack =>
      'Tout le reste est dans les temps';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Aucune tuile planifiée n\'est en retard.';

  @override
  String get todayStatusClearDay => 'Votre journée est libre.';

  @override
  String get todayStatusPreviewCta => 'Apercevoir un meilleur plan';

  @override
  String get todayStatusPreviewLoading => 'Préparation de l\'aperçu…';

  @override
  String get todayStatusPreviewUnavailable =>
      'Impossible de générer l\'aperçu. Votre plan est inchangé.';

  @override
  String get todayStatusUntitledTile => 'Tuile sans titre';

  @override
  String get todayStatusShowAll => 'Afficher tout';

  @override
  String todayStatusExpandSection(String section) {
    return 'Ouvrir $section';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return 'Réduire $section';
  }

  @override
  String get todayStatusReasonDueToday => 'Échue aujourd\'hui';

  @override
  String get todayStatusReasonNoOpenSlot => 'Aucun créneau disponible';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'Le trajet rend cela impossible';

  @override
  String get todayStatusReasonOutsideHours => 'Hors des horaires disponibles';

  @override
  String get todayStatusReasonDependencyBlocked =>
      'En attente d\'une autre tuile';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Nécessite $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Nécessite votre décision';

  @override
  String get todayStatusReasonUnknown => 'Incalable';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Sélectionner des tuiles';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Ouvrir les sessions de $title';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Réduire les sessions de $title';
  }

  @override
  String get analysis => 'Analyse';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get sleep => 'Sommeil';

  @override
  String get overview => 'Aperçu';

  @override
  String get driveTime => 'Temps de trajet';

  @override
  String get signUpWithGoogle => 'Se connecter avec Google';

  @override
  String get signUpWithApple => 'Se connecter avec Apple';

  @override
  String get signUpWithMicrosoft => 'Se connecter avec Microsoft';

  @override
  String get signIn => 'Connexion';

  @override
  String get signUp => 'Inscription';

  @override
  String get invalidUsernameOrPassword =>
      'Nom d\'utilisateur ou mot de passe invalide';

  @override
  String get noInternetConnection => 'Aucune connexion Internet';

  @override
  String get oneHour => '1 heure';

  @override
  String countHours(String count) {
    return '$count heures';
  }

  @override
  String get oneMinute => '1 minute';

  @override
  String countMinutes(String count) {
    return '$count minutes';
  }

  @override
  String countDays(String count) {
    return '$count jours';
  }

  @override
  String lateDate(String date) {
    return 'En retard ($date)';
  }

  @override
  String get custom => 'Personnalisé';

  @override
  String get allowAccessDescription =>
      'Tiler collecte des données de localisation pour planifier efficacement vos tuiles et rendez-vous. Vos données restent privées et ne sont utilisées que dans ce but.';

  @override
  String get allowLocationAccessQ => 'Autoriser l\'accès à la localisation ?';

  @override
  String get allow => 'Autoriser';

  @override
  String get deny => 'Refuser';

  @override
  String get afternoon => 'Après-midi';

  @override
  String get evening => 'Soir';

  @override
  String get night => 'Nuit';

  @override
  String get morningAndAfternoon => 'Matin & Après-midi';

  @override
  String get afternoonAndEvening => 'Après-midi & Soir';

  @override
  String get lateEvening => 'Fin de soirée';

  @override
  String get prediction => 'Prédiction';

  @override
  String get softDeadline => 'Échéance souple';

  @override
  String get location => 'Localisation';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteYourTilerAccountQ => 'Supprimer le compte ?';

  @override
  String get no => 'Non';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get forgetPassword => 'Mot de passe oublié';

  @override
  String get forgotPasswordBtn => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get reset => 'Réinitialiser';

  @override
  String lookingUp(String text) {
    return 'Recherche de $text';
  }

  @override
  String get lowPriorityTrunc => 'Faible';

  @override
  String get mediumPriorityTrunc => 'Moyen';

  @override
  String get highPriorityTrunc => 'Élevé';

  @override
  String failedToAddGoogleCalendar(String email) {
    return 'Échec de l\'ajout de $email';
  }

  @override
  String deletedCalendar(String email) {
    return 'Agenda $email supprimé';
  }

  @override
  String get loadingIntegrations => 'Chargement des intégrations';

  @override
  String get noThirdPartyIntegtions => 'Aucun agenda tiers';

  @override
  String get addGoogleCalendar => 'Ajouter Google Agenda';

  @override
  String get integrations => 'Intégrations';

  @override
  String get integrateOtherCalendars => 'Intégrer des agendas tiers';

  @override
  String get clear => 'Effacer';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get skip => 'Passer';

  @override
  String get morningPerson => '🌅 Personne matinale';

  @override
  String get morning => 'Matin';

  @override
  String get middayPerson => '🌞 Personne de la mi-journée';

  @override
  String get nightPerson => '🌃 Personne de nuit';

  @override
  String get enterAddress => 'Saisissez votre adresse';

  @override
  String get primaryLocationQuestion =>
      'Quelle est votre localisation principale pour le travail ou les études ?';

  @override
  String get useDeviceLocation => 'Utiliser la localisation de mon appareil';

  @override
  String get energyLevelDescriptionQuestion =>
      'Comment décririez-vous votre niveau d\'énergie au cours de la journée ?';

  @override
  String get incompleteRequest => 'Requête incomplète non envoyée';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get invalidContactFormat => 'E-mail ou numéro de téléphone invalide';

  @override
  String deadlineTime(String time) {
    return 'Échéance : $time';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get preview => 'Aperçu';

  @override
  String get addTilette => 'Ajouter une Tilette';

  @override
  String get tileShareName => 'Nom du partage de tuile';

  @override
  String get tileShare => 'Partage de tuile';

  @override
  String get update => 'Mettre à jour';

  @override
  String get noDesignatedTiles => 'Aucune tuile désignée';

  @override
  String get noTileCluster => 'Aucun partage de tuile créé';

  @override
  String get errorLoadingTilelist =>
      'Erreur lors du chargement de la liste des tuiles';

  @override
  String get failedToLoadTileShareCluster =>
      'Échec du chargement du cluster de partage de tuiles';

  @override
  String get missingTileShareCluster => 'Cluster de TileShare manquant';

  @override
  String get outBound => 'En partance';

  @override
  String get inBound => 'En arrivée';

  @override
  String get multiShare => 'Partage multiple';

  @override
  String get errorOccurred =>
      'Une erreur s\'est produite !\nVeuillez réessayer.';

  @override
  String get authenticationIssues => 'Problème d\'authentification.';

  @override
  String get userIsNotAuthenticated => 'L\'utilisateur n\'est pas authentifié.';

  @override
  String get responseContentError =>
      'La réponse ne contient pas le contenu attendu.';

  @override
  String get responseHandlingError => 'Échec du traitement de la réponse.';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get tomorrow => 'Demain';

  @override
  String get travel => 'Trajet';

  @override
  String numberOfDayForecast(String number) {
    return 'Prévision à $number jours';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Échec de l\'obtention de l\'aperçu';

  @override
  String get noDriving => 'Aucun trajet en voiture';

  @override
  String get tileShareNoteEllipsis => 'Note...';

  @override
  String get hi => 'Salut';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get passwordCreationMessagePart1 =>
      'Créez un mot de passe fort et unique avec ';

  @override
  String get passwordConditionMinLength => 'au moins six caractères';

  @override
  String get passwordCreationMessageIncluding => ', incluant ';

  @override
  String get passwordConditionUppercaseLetters => 'des majuscules';

  @override
  String get passwordConditionLowercaseLetters => 'des minuscules';

  @override
  String get passwordConditionNumbers => 'des chiffres';

  @override
  String get passwordConditionSpecialCharacter => 'un caractère spécial';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', et ';

  @override
  String get nonViableTimeSlot => 'Aucun créneau viable';

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
  String get save => 'Enregistrer';

  @override
  String get selectWeek => 'Sélectionner une semaine';

  @override
  String get selectYear => 'Sélectionner une année';

  @override
  String get retrievingDataIssue => 'Problème de récupération des données';

  @override
  String get recurring => 'Récurrent';

  @override
  String get nonRecurring => 'Non récurrent';

  @override
  String get dailyReurring => 'Quotidien';

  @override
  String get weeklyReurring => 'Hebdomadaire';

  @override
  String get biweeklyReurring => 'Quinzaine';

  @override
  String get monthlyReurring => 'Mensuel';

  @override
  String get yearlyReurring => 'Annuel';

  @override
  String get ellipsisEmprtNotes => 'Notes...';

  @override
  String get tileShareDelete => 'Supprimer';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Tuile de prévision';

  @override
  String get previewOthers => 'Autres';

  @override
  String get goodMorning => 'Bon matin';

  @override
  String get goodDay => 'Bonne journée';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String youHaveXBlocks(String count) {
    return 'Vous avez $count blocs à venir.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Vous avez $count tuiles à venir.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Vous avez $count partages de tuiles à venir.';
  }

  @override
  String countTileShare(String count) {
    return '$count partages de tuiles';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Vous avez $blockCount blocs et $tileCount tuiles à venir.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Vous avez $blockCount blocs et $tileShareCount partages de tuiles à venir.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Vous avez $tileCount tuiles et $tileShareCount partages de tuiles à venir.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Vous avez $blockCount blocs, $tileCount tuiles et $tileShareCount partages de tuiles à venir.';
  }

  @override
  String get noTilesPreview =>
      'Vous n\'avez rien à venir pour le reste de la journée.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Créer une tuile';

  @override
  String get previewTileForecast => 'Prévision';

  @override
  String get previewTileOptions => 'Options';

  @override
  String get previewTileMore => 'Plus';

  @override
  String get previewTileShuffle => 'Mélanger';

  @override
  String get previewTileRevise => 'Réviser';

  @override
  String get previewTileDeferAll => 'Tout différer';

  @override
  String get previewLocationName => 'Localisation';

  @override
  String get previewTagName => 'Étiquette';

  @override
  String get previewClassificationName => 'Classification';

  @override
  String get previewBlockedOut => 'Bloqué';

  @override
  String get accountInfo => 'Informations du compte';

  @override
  String get fistName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get tilePreferences => 'Préférences des tuiles';

  @override
  String get notificationsPreferences => 'Préférences de notifications';

  @override
  String get security => 'Sécurité';

  @override
  String get connections => 'Connexions';

  @override
  String get myLocations => 'Mes localisations';

  @override
  String get aboutTiler => 'À propos de Tiler';

  @override
  String get howToUseTiler => 'Comment utiliser Tiler';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get setLocation => 'Définir la localisation';

  @override
  String get connectCalendars => 'Connecter vos agendas';

  @override
  String get configure => 'Configurer';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get googleCalendar => 'Google Agenda';

  @override
  String get appleCalendar => 'Agenda Apple';

  @override
  String get googleTasks => 'Google Tâches';

  @override
  String get microsoft => 'Microsoft';

  @override
  String get slack => 'Slack';

  @override
  String get addCalendar => 'Ajouter un calendrier';

  @override
  String get calendarConnected => 'Calendrier connecté';

  @override
  String get calendarConnectionDeclined => 'Connexion au calendrier annulée';

  @override
  String get calendarConnectionError =>
      'Impossible de connecter votre calendrier';

  @override
  String get sleepDuration => 'Durée du sommeil';

  @override
  String get transportationMethodQuestion => 'Comment vous déplacez-vous ?';

  @override
  String get defineYourTimeRestrictions =>
      'Définissez vos restrictions horaires';

  @override
  String get setWorkHours => 'Définir les heures de travail';

  @override
  String get setYourBlockOutHours => 'Définir vos heures bloquées';

  @override
  String get travelMediumBiking => 'Vélo';

  @override
  String get travelMediumTransit => 'Transports en commun';

  @override
  String get travelMediumDriving => 'Voiture';

  @override
  String get travelMediumTransport => 'Transport';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio min';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio h';
  }

  @override
  String get bedTime => 'Heure du coucher';

  @override
  String get sleepTime => 'Heure de sommeil';

  @override
  String get scheduleFullness => 'Charge de l\'emploi du temps';

  @override
  String get scheduleFullnessDescription =>
      'À quel point votre emploi du temps doit-il être chargé ?';

  @override
  String scheduleFullnessValue(int percentage) {
    return 'Charge cible de $percentage %';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Les cibles vont de $minimum % à $maximum %. Cela conserve une base utile tout en laissant de la place aux changements et aux trajets.';
  }

  @override
  String get schedulePreferences => 'Préférences de l\'emploi du temps';

  @override
  String get lighter => 'Plus léger';

  @override
  String get balanced => 'Équilibré';

  @override
  String get fuller => 'Plus chargé';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Les préférences des tuiles ont été mises à jour avec succès.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Les préférences de notifications ont été mises à jour avec succès.';

  @override
  String get tileReminders => 'Rappels de tuiles';

  @override
  String get appUpdates => 'Mises à jour de l\'application';

  @override
  String get marketingUpdates => 'Mises à jour marketing';

  @override
  String get emailNotifications => 'Notifications e-mail';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get countryCode => 'Indicatif pays';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'Les informations du compte ont été mises à jour avec succès.';

  @override
  String get reachingServerIssues =>
      'Problème de connexion aux serveurs de Tiler';

  @override
  String get deleteAccountConfirmation =>
      'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get integrationsSetLocation => 'Définir la localisation';

  @override
  String get googleCalender => 'Google Agenda';

  @override
  String get passwordsMustMatch => 'Les mots de passe doivent correspondre';

  @override
  String get parenthesisLate => '(En retard)';

  @override
  String get failedToAddIntegration => 'Échec de l\'ajout de l\'intégration';

  @override
  String get unknownProvider => 'Fournisseur inconnu';

  @override
  String get manageCalendars => 'Gérer les agendas';

  @override
  String get calendarItems => 'Éléments de l\'agenda';

  @override
  String get noCalendarItemsFound => 'Aucun élément d\'agenda trouvé';

  @override
  String get calendarItemsWillAppearHere =>
      'Vos éléments d\'agenda apparaîtront ici';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount agendas actifs sur $totalCount';
  }

  @override
  String get toggleCalendarsToSync =>
      'Activez les agendas à synchroniser avec Tiler';

  @override
  String get unknownCalendar => 'Agenda inconnu';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount actifs sur $totalCount';
  }

  @override
  String integrationCount(int count) {
    return '$count intégrations';
  }

  @override
  String get errorLoadingCalendarItems =>
      'Erreur lors du chargement des éléments d\'agenda';

  @override
  String get integratedCalendars => 'Agendas';

  @override
  String get integrationAdd => 'Ajouter';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Peut Tiler accéder à votre localisation pour fournir des recommandations et notifications basées sur votre position ?';

  @override
  String get recurringTasks => 'Tâches récurrentes';

  @override
  String get yourProfession => 'Votre profession ?';

  @override
  String get yourProfessionQuestion => 'Que faites-vous ?';

  @override
  String get yourProfessionHint =>
      'Décrivez ce que vous faites pour le travail';

  @override
  String get medicalProfessional => 'Professionnel de santé';

  @override
  String get softwareDeveloper => 'Développeur logiciel';

  @override
  String get student => 'Étudiant';

  @override
  String get engineer => 'Ingénieur';

  @override
  String get fieldSalesProfessional => 'Commercial terrain';

  @override
  String get remoteWorker => 'Travailleur à distance & nomade numérique';

  @override
  String get stayAtHomeParent => 'Parent au foyer';

  @override
  String get clientAccountManagers => 'Gestionnaires de clients/comptes';

  @override
  String get other => 'Autre';

  @override
  String get tileSuggestions => 'Suggestions de tuiles';

  @override
  String get personalOrWorkQuestion => 'À quoi allez-vous utiliser Tiler ?';

  @override
  String get enter3chars => 'Saisissez au moins 3 caractères.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Partez dans $duration pour arriver à l\'heure';
  }

  @override
  String get leaveNowToArriveOnTime =>
      'Partez maintenant pour arriver à l\'heure !';

  @override
  String durationDrive(String duration) {
    return '$duration en voiture';
  }

  @override
  String durationTransit(String duration) {
    return '$duration en transports';
  }

  @override
  String durationBike(String duration) {
    return '$duration à vélo';
  }

  @override
  String durationWalk(String duration) {
    return '$duration à pied';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration en voiture vers $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration en transports vers $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration à vélo vers $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration à pied vers $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Partez avant $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Trafic détecté - recalcul d\'itinéraire suggéré';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Trafic : +$minutes min de retard';
  }

  @override
  String get heavyTrafficExpected => 'Trafic dense attendu';

  @override
  String get addWithAI => 'Ajouter avec l\'IA';

  @override
  String get focusTime => 'Temps de concentration';

  @override
  String get videoMeeting => 'Visioconférence';

  @override
  String get sharedWith => 'Partagé avec';

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
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
    return ' $travelMode vers ';
  }

  @override
  String get travelModeDriving => 'en voiture';

  @override
  String get travelModeWalking => 'à pied';

  @override
  String get travelModeBicycling => 'à vélo';

  @override
  String get travelModeTransitLower => 'en transports';

  @override
  String travelDurationCompact(int minutes) {
    return '$minutes min';
  }

  @override
  String get yourDayIsOptimized => 'Votre journée est optimisée.';

  @override
  String get yourDayAtAGlance => 'Votre journée en un coup d\'œil';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration de temps de trajet aujourd\'hui.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count tuiles planifiées pour aujourd\'hui.';
  }

  @override
  String get viewRoute => 'Voir l\'itinéraire';

  @override
  String get focusModeChip => 'Mode concentration';

  @override
  String get showRouteChip => 'Afficher l\'itinéraire';

  @override
  String get reOptimizeChip => 'Re-optimiser';

  @override
  String get todayColon => 'Aujourd\'hui :';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount tuiles, $blockCount blocs';
  }

  @override
  String get timeSavedColon => 'Temps économisé :';

  @override
  String get travelTimeColon => 'Temps de trajet :';

  @override
  String travelTime(String duration) {
    return 'Temps de trajet : $duration';
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
  String get scheduleConflict => 'Conflit d\'emploi du temps';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" et \"$tile2\" sont planifiés au même moment';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '\"$tile1\" a lieu pendant \"$tile2\" ($overlap de chevauchement)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '\"$tile1\" chevauche \"$tile2\" de $overlap';
  }

  @override
  String get fix => 'Corriger';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Conflit : chevauchement de $minutes min';
  }

  @override
  String get oneScheduleConflict => '1 conflit d\'emploi du temps';

  @override
  String countScheduleConflicts(int count) {
    return '$count conflits d\'emploi du temps';
  }

  @override
  String get tapToReviewAndResolve => 'Touchez pour examiner et résoudre';

  @override
  String countConflicts(int count) {
    return '$count conflits';
  }

  @override
  String get tapToExpand => 'Touchez pour déplier';

  @override
  String conflictingTiles(int count) {
    return '$count tuiles en conflit';
  }

  @override
  String totalOverlap(String duration) {
    return 'Chevauchement total : $duration';
  }

  @override
  String get autoResolve => 'Résolution automatique';

  @override
  String get untitledTile => 'Tuile sans titre';

  @override
  String get untitledEvent => 'Sans titre';

  @override
  String get extendedEventSingular => '1 événement prolongé';

  @override
  String extendedEventsPlural(int count) {
    return '$count événements prolongés';
  }

  @override
  String get extendedEventsTapToView =>
      'Touchez pour voir les événements de la journée et les longs événements';

  @override
  String get extendedEventsTitle => 'Événements prolongés';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements de plus de 16 heures',
      one: '1 événement de plus de 16 heures',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Itinéraire du jour';

  @override
  String get noLocationsToday => 'Aucune localisation aujourd\'hui';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Ajoutez des localisations à vos tuiles pour voir votre itinéraire quotidien';

  @override
  String countStops(int count) {
    return '$count arrêts';
  }

  @override
  String get routeOptimized => 'Itinéraire optimisé';

  @override
  String savedTravelTime(String duration) {
    return '$duration de temps de trajet économisés';
  }

  @override
  String get firstStop => 'Premier arrêt';

  @override
  String get stop => 'Arrêt';

  @override
  String arriveBy(String time) {
    return 'Arrivez avant $time';
  }

  @override
  String get fromPreviousStop => 'depuis l\'arrêt précédent';

  @override
  String get viewTile => 'Voir la tuile';

  @override
  String get editTile => 'Modifier la tuile';

  @override
  String get startNavigation => 'Démarrer la navigation';

  @override
  String get noLocationAvailable => 'Aucune localisation';

  @override
  String get seeTodaysRoute => 'Voir l\'itinéraire du jour';

  @override
  String get whatWouldYouLikeToDo => 'Que souhaitez-vous faire ?';

  @override
  String get describeATask =>
      'Décrivez une tâche, on s\'occupe de la planification.';

  @override
  String get microphonePermissionDenied => 'Autorisation du micro refusée.';

  @override
  String failedToStartRecording(String error) {
    return 'Échec du démarrage de l\'enregistrement : $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Échec de l\'arrêt de l\'enregistrement : $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Erreur de conversion audio : $error';
  }

  @override
  String get audioConversionFailed => 'Échec de la conversion audio';

  @override
  String get recordingPathIsEmpty => 'Le chemin d\'enregistrement est vide';

  @override
  String get noActiveRecording => 'Aucun enregistrement actif';

  @override
  String get joinMeeting => 'Rejoindre la réunion';

  @override
  String get openLink => 'Ouvrir le lien';

  @override
  String get actions => 'Actions';

  @override
  String get hideActions => 'Masquer les actions';

  @override
  String get pendingRsvpSingular => '1 événement nécessite une réponse';

  @override
  String pendingRsvpPlural(int count) {
    return '$count événements nécessitent une réponse';
  }

  @override
  String get pendingRsvpHappeningNow => 'En cours - répondez pour rejoindre';

  @override
  String get pendingRsvpStartingSoon =>
      'Commence bientôt - répondez maintenant';

  @override
  String get pendingRsvpWithinHour => 'Commence dans une heure';

  @override
  String get pendingRsvpUpcoming => 'À venir - touchez pour répondre';

  @override
  String get pendingRsvpTapToReview => 'Touchez pour examiner et répondre';

  @override
  String get pendingRsvpTitle => 'Réponses en attente';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements en attente de votre réponse',
      one: '1 événement en attente de votre réponse',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Commence bientôt';

  @override
  String get pendingRsvpLater => 'Plus tard aujourd\'hui & à venir';

  @override
  String get declinedRsvpSingular => '1 événement refusé';

  @override
  String declinedRsvpPlural(int count) {
    return '$count événements refusés';
  }

  @override
  String get declinedRsvp => 'Événements refusés';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 en attente, $declinedCount refusés';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount en attente, 1 refusé';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount en attente, $declinedCount refusés';
  }

  @override
  String get rsvpNeedsAction => 'Réponse requise';

  @override
  String get rsvpTentative => 'Peut-être';

  @override
  String get rsvpAccepted => 'Accepté';

  @override
  String get rsvpDeclined => 'Refusé';

  @override
  String unableToOpenLinkError(String link) {
    return 'Impossible d\'ouvrir le lien : $link';
  }

  @override
  String get leaveNow => 'Partez maintenant !';

  @override
  String leaveInMinutes(int minutes) {
    return 'Partez dans $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count alertes';
  }

  @override
  String get alertChipLeaveNow => 'Partez maintenant';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Partez dans $minutes min';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflits',
      one: '1 conflit',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count journées complètes',
      one: '1 journée complète',
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
  String get accepted => 'Accepté';

  @override
  String get declined => 'Refusé';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Répondre à $calendarSource';
  }

  @override
  String get unknown => 'Invitation de calendrier';

  @override
  String get loadingPreviousDays => 'Chargement des jours précédents...';

  @override
  String get loadingUpcomingDays => 'Chargement des jours à venir...';

  @override
  String get requestTimeout =>
      'Délai d\'attente dépassé - veuillez vérifier votre connexion';

  @override
  String get failedToPauseTile => 'Échec de la mise en pause de la tuile';

  @override
  String get failedToResumeTile => 'Échec de la reprise de la tuile';

  @override
  String get failedToMoveUpTask => 'Échec de l\'avancement de la tâche';

  @override
  String get failedToUpdateTile => 'Échec de la mise à jour de la tuile';

  @override
  String get failedToBuzzSchedule => 'Échec de l\'alerte de l\'emploi du temps';

  @override
  String get failedToShuffleSchedule =>
      'Échec du mélange de l\'emploi du temps';

  @override
  String get failedToProcrastinateTile => 'Échec du report de la tuile';

  @override
  String get tutorialStepYourScheduleTitle => 'Votre emploi du temps';

  @override
  String get tutorialStepYourScheduleBody =>
      'Votre journée est organisée en tuiles — des blocs horaires intelligents que Tiler dispose pour vous. Faites défiler pour voir votre journée complète.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Créer et optimiser';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Touchez ici pour créer une nouvelle tâche. Dites à Tiler ce qu\'il faut faire et combien de temps cela prendra — Tiler trouve le moment.';

  @override
  String get tutorialCalloutReOptimize => 'Re-optimiser';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'Journée détournée ? Recalculez à partir de maintenant en gardant votre plan à venir grossièrement stable';

  @override
  String get tutorialCalloutTravelTime => 'Temps de trajet';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Tiler prend en compte le trajet entre les localisations';

  @override
  String get tutorialStepQuickCreateTitle => 'Création rapide';

  @override
  String get tutorialStepQuickCreateBody =>
      'C\'est la feuille d\'ajout rapide. Nommez votre tuile et définissez une durée pour un ajout rapide.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'C\'est la feuille d\'ajout rapide derrière moi ! Nommez votre tuile, définissez une durée et touchez Ajouter — Tiler s\'occupe du reste.';

  @override
  String get tutorialCalloutNameYourTile => 'Nommez votre tuile';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Décrivez la tâche que vous voulez accomplir';

  @override
  String get tutorialCalloutSetDuration => 'Définir la durée';

  @override
  String get tutorialCalloutSetDurationDesc =>
      'Combien de temps prendra cette tâche ?';

  @override
  String get tutorialCalloutMoreOptions => 'Plus d\'options';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Ajoutez localisation, échéance ou répétition via l\'éditeur complet';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Ajoutez localisation, échéance ou répétition';

  @override
  String get tutorialStepTilerWorksTitle => 'Tiler travaille pour vous';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tiler dispose automatiquement vos tuiles en fonction de vos niveaux d\'énergie, des temps de trajet et des échéances. Ajoutez simplement ce que vous devez faire — Tiler s\'occupe du moment.';

  @override
  String get tutorialCalloutForecast => 'Prévision';

  @override
  String get tutorialCalloutForecastDesc =>
      'Voyez quand une tuile sera insérée avant de la sélectionner';

  @override
  String get tutorialCalloutShuffle => 'Mélanger';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Mélangez les choses et suggérez ce que vous devriez faire ensuite';

  @override
  String get tutorialCalloutDeferAll => 'Tout différer';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Mauvaise journée ? Poussez tout vers l\'avant';

  @override
  String get tutorialStepControlTilesTitle => 'Contrôlez vos tuiles';

  @override
  String get tutorialStepControlTilesBody =>
      'Chaque tuile a des commandes pour gérer vos tâches en temps réel :';

  @override
  String get tutorialCalloutPlay => 'Lecture';

  @override
  String get tutorialCalloutPlayDesc =>
      'Commencez à travailler sur cette tuile';

  @override
  String get tutorialCalloutPause => 'Pause';

  @override
  String get tutorialCalloutPauseDesc =>
      'Prenez une pause — Tiler replanifie le reste';

  @override
  String get tutorialCalloutComplete => 'Terminer';

  @override
  String get tutorialCalloutCompleteDesc =>
      'Terminé ! Marquez-la comme achevée';

  @override
  String get tutorialCalloutProcrastinate => 'Procrastiner';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Pas maintenant — reportez-la plus tard';

  @override
  String get tutorialStepBigPictureTitle => 'Voir l\'ensemble';

  @override
  String get tutorialStepBigPictureBody =>
      'Touchez l\'icône calendrier pour basculer entre trois vues :';

  @override
  String get tutorialCalloutDaily => 'Quotidien';

  @override
  String get tutorialCalloutDailyDesc =>
      'Heure par heure — votre agenda détaillé';

  @override
  String get tutorialCalloutWeekly => 'Hebdomadaire';

  @override
  String get tutorialCalloutWeeklyDesc =>
      'Voir toute la semaine d\'un coup d\'œil';

  @override
  String get tutorialCalloutMonthly => 'Mensuel';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Planifiez à l\'avance avec un aperçu mensuel';

  @override
  String get tutorialStepToolkitTitle => 'Votre boîte à outils';

  @override
  String get tutorialStepToolkitBody =>
      'Ces outils pratiques sont toujours à portée de main :';

  @override
  String get tutorialCalloutShare => 'Partager';

  @override
  String get tutorialCalloutShareDesc =>
      'Collaborez — partagez des tuiles avec d\'autres';

  @override
  String get tutorialCalloutSearch => 'Rechercher';

  @override
  String get tutorialCalloutSearchDesc =>
      'Trouvez n\'importe quelle tuile par son nom';

  @override
  String get tutorialCalloutSettings => 'Paramètres';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Personnalisez votre expérience, connectez vos agendas, définissez vos préférences';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Touchez le bouton de chat pour ajouter ou ajuster des tuiles en parlant simplement à Tiler';

  @override
  String get tutorialStepChatTitle => 'Discuter avec Tiler';

  @override
  String get tutorialStepChatBody =>
      'Touchez le bouton de chat à tout moment pour ajouter ou ajuster des tuiles en parlant simplement à Tiler — aucun formulaire nécessaire.';

  @override
  String get tutorialNavNext => 'Suivant';

  @override
  String get tutorialNavNextArrow => 'Suivant →';

  @override
  String get tutorialNavBack => 'Retour';

  @override
  String get tutorialNavBackArrow => '← Retour';

  @override
  String get tutorialNavSkip => 'Passer';

  @override
  String get tutorialNavLetsGo => 'C\'est parti !';

  @override
  String get welcomeExplainerHeadline => 'Tuiles vs Blocs';

  @override
  String get welcomeExplainerSubtitle =>
      'Un coup d\'œil sur la façon dont Tiler planifie votre journée.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Les blocs sont fixes. Ils ont lieu à un moment précis.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Les tuiles sont flexibles. Tiler les place autour de vos blocs.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'Le dentiste a été déplacé à $time — Tiler replanifie vos tuiles autour.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Déplacé';

  @override
  String get welcomeExplainerReplannedBadge => 'Replanifié';

  @override
  String get welcomeExplainerBlockStandup => 'Standup d\'équipe';

  @override
  String get welcomeExplainerBlockDentist => 'Dentiste';

  @override
  String get welcomeExplainerTileWorkout => 'Séance de sport';

  @override
  String get welcomeExplainerTileReport => 'Rédiger un rapport';

  @override
  String get welcomeExplainerTileGroceries => 'Courses';

  @override
  String get welcomeExplainerLegendBlock => 'Bloc';

  @override
  String get welcomeExplainerLegendTile => 'Tuile';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Préférences des tuiles';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Vos préférences IA sont ici — votre mode de déplacement, vos heures de travail et personnelles, et les heures bloquées.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Comment vous déplacez';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tiler budgétise le temps de trajet entre les tuiles selon votre mode de déplacement habituel.';

  @override
  String get tutorialStepTilePrefsHoursTitle =>
      'Heures de travail et personnelles';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Quand Tiler peut planifier des tuiles de travail par rapport aux tuiles personnelles. Touchez l\'une des deux pour définir un profil.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Heures bloquées';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Heure du coucher et durée du sommeil — les heures dans lesquelles Tiler ne planifie jamais.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'Transcription';

  @override
  String get newChat => 'Nouveau chat';

  @override
  String get noChatHistory => 'Aucun historique de chat';

  @override
  String get unknownChat => 'Chat inconnu';

  @override
  String get transcriptionFailed => 'Échec de la transcription';

  @override
  String get acceptChanges => 'Accepter les modifications';

  @override
  String get noRequestToExecute => 'Aucune requête à exécuter';

  @override
  String get initializingAction => 'Initialisation de la génération d\'action';

  @override
  String get settingThingsUp => 'Mise en place';

  @override
  String get preparingRequest => 'Préparation de votre requête';

  @override
  String get gettingReady => 'Préparation en cours';

  @override
  String get processingAction => 'Traitement de l\'action';

  @override
  String get workingOnIt => 'En cours de traitement';

  @override
  String get analyzingRequest => 'Analyse de votre requête';

  @override
  String get thinking => 'Réflexion';

  @override
  String get actionComplete => 'Traitement de l\'action terminé';

  @override
  String get processingDone => 'Traitement terminé';

  @override
  String get allSet => 'C\'est prêt';

  @override
  String get finishedProcessing => 'Traitement terminé';

  @override
  String get generatingSummary => 'Génération du résumé';

  @override
  String get summarizingResults => 'Synthèse des résultats';

  @override
  String get creatingOverview => 'Création de l\'aperçu';

  @override
  String get preparingSummary => 'Préparation du résumé';

  @override
  String get summaryComplete => 'Génération du résumé terminée';

  @override
  String get summaryReady => 'Résumé prêt';

  @override
  String get overviewComplete => 'Aperçu terminé';

  @override
  String get doneSummarizing => 'Synthèse terminée';

  @override
  String get loadingSchedule => 'Chargement des données de l\'emploi du temps';

  @override
  String get fetchingSchedule => 'Récupération de votre emploi du temps';

  @override
  String get retrievingCalendar => 'Récupération de l\'agenda';

  @override
  String get loadingTimeline => 'Chargement de la chronologie';

  @override
  String get optimizingSchedule => 'Optimisation de l\'emploi du temps';

  @override
  String get reorganizingDay => 'Réorganisation de votre journée';

  @override
  String get findingBestFit => 'Recherche du meilleur créneau';

  @override
  String get adjustingTimeline => 'Ajustement de la chronologie';

  @override
  String get scheduleComplete => 'Optimisation de l\'emploi du temps terminée';

  @override
  String get scheduleUpdated => 'Emploi du temps mis à jour';

  @override
  String get timelineOptimized => 'Chronologie optimisée';

  @override
  String get allDone => 'Tout est terminé';

  @override
  String get connectionLost => 'Connexion perdue. Veuillez actualiser';

  @override
  String get sendingRequest => 'Envoi de la requête';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'Connexion WebSocket perdue après 5 tentatives';

  @override
  String get webSocketMessageHandlingError =>
      'Erreur lors du traitement du message';

  @override
  String get jsonParseError => 'Erreur d\'analyse JSON';

  @override
  String get processError => 'Erreur de traitement';

  @override
  String get socketConnectionError => 'Erreur de connexion socket';

  @override
  String get keepAliveFailed => 'Échec du maintien de la connexion';

  @override
  String get copy => 'Copier';

  @override
  String get entityIdNotFound => 'Aucun identifiant d\'entité d\'aperçu trouvé';

  @override
  String get feedback => 'Commentaires';

  @override
  String get feedbackCategory => 'Catégorie';

  @override
  String get feedbackCategoryBug => 'Bogue';

  @override
  String get feedbackCategoryFeature => 'Fonctionnalité';

  @override
  String get feedbackCategoryEnhancement => 'Amélioration';

  @override
  String get feedbackCategoryGeneral => 'Général';

  @override
  String get feedbackTitle => 'Titre';

  @override
  String get feedbackTitleHint => 'Résumé bref de vos commentaires';

  @override
  String get feedbackDescription => 'Description';

  @override
  String get feedbackDescriptionHint =>
      'Fournissez des détails sur vos commentaires';

  @override
  String get feedbackSubmitted => 'Commentaires envoyés avec succès';

  @override
  String get feedbackError => 'Échec de l\'envoi des commentaires';

  @override
  String get noPreviewsAvailable =>
      'Aucune TileCast disponible pour cette requête';

  @override
  String get previewUnavailable =>
      'La TileCast sélectionnée n\'est pas disponible';

  @override
  String get previewSummaryUnavailable =>
      'La TileCast n\'a pas pu être chargée';

  @override
  String get previewGenerating => 'Génération de la TileCast…';

  @override
  String get previewTimedOut =>
      'La TileCast prend plus de temps que prévu. Réessayez dans un instant.';

  @override
  String get previewGenerationFailed =>
      'Nous n\'avons pas pu générer cette TileCast.';

  @override
  String get previewInvalidated =>
      'Cette TileCast n\'est plus valide car votre emploi du temps a changé.';

  @override
  String get previewStaleBanner =>
      'Cette TileCast reflète un instantané antérieur de votre emploi du temps.';

  @override
  String get previewNonViableLabel => 'Impossible à planifier';

  @override
  String get reviewChanges => 'Vérifier les modifications';

  @override
  String get previewRetry => 'Réessayer';

  @override
  String get previewPreparing => 'Préparation de la TileCast…';

  @override
  String get previewReadyToView => 'Touchez pour voir la TileCast';

  @override
  String get previewActionsOutdated => 'Périmé — envoyez un nouveau message';

  @override
  String get previewActionsUnavailable => 'TileCast indisponible';

  @override
  String get tileCastStaleNote =>
      'Votre emploi du temps a changé — cette TileCast peut être obsolète';

  @override
  String get tileCastAlsoIncluded => 'Aussi inclus';

  @override
  String actionsCount(int count) {
    return '$count actions';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'Chargement des notes…';

  @override
  String get notesSaving => 'Enregistrement…';

  @override
  String get notesSaved => 'Enregistré';

  @override
  String get notesUnsaved => 'Édition…';

  @override
  String get notesSaveError => 'Enregistrement impossible';

  @override
  String get notesSaveNow => 'Enregistrer maintenant';

  @override
  String get notesShowPreview => 'Aperçu';

  @override
  String get notesShowEditor => 'Modifier';

  @override
  String get notesPreviewEmpty => 'Rien à prévisualiser pour l\'instant.';

  @override
  String get notesLinkPromptTitle => 'Insérer un lien';

  @override
  String get notesConflictTitle =>
      'Une autre personne a mis à jour cette note.';

  @override
  String get notesConflictDiscardMine => 'Abandonner la mienne';

  @override
  String get notesConflictKeepEditing => 'Continuer l\'édition';

  @override
  String get notesToolBold => 'Gras';

  @override
  String get notesToolItalic => 'Italique';

  @override
  String get notesToolStrikethrough => 'Barré';

  @override
  String get notesToolInlineCode => 'Code en ligne';

  @override
  String get notesToolHeading1 => 'Titre 1';

  @override
  String get notesToolHeading2 => 'Titre 2';

  @override
  String get notesToolBulletList => 'Liste à puces';

  @override
  String get notesToolNumberedList => 'Liste numérotée';

  @override
  String get notesToolTaskList => 'Liste de tâches';

  @override
  String get notesToolQuote => 'Citation';

  @override
  String get notesToolLink => 'Lien';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesViewerTitle => 'Note';

  @override
  String get notesTapToAdd => 'Touchez pour ajouter une note';

  @override
  String get notesTapToEdit => 'Touchez pour modifier · appui long pour lire';

  @override
  String get notesDone => 'Terminé';

  @override
  String get endOfDay => 'Fin de la journée';

  @override
  String get search => 'Rechercher';

  @override
  String get share => 'Partager';

  @override
  String get openChat => 'Ouvrir le chat';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get switchCalendarView => 'Changer de vue de calendrier';

  @override
  String get previewSundialGreeting => 'Bonjour.';

  @override
  String get previewSundialCountsPrefix => 'Aujourd\'hui, il y a';

  @override
  String get previewSundialCountsSuffix => 'en attente.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count tuiles';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count blocs';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count partages de tuiles';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours heures de travail';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins minutes de trajet';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'votre journée est libre à partir de $time';
  }

  @override
  String get previewSundialAndSeparator => 'et';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count lieux';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '$hours h de sommeil';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '$hours h de libre';
  }

  @override
  String get previewSundialFullyBooked => 'Complètement rempli';

  @override
  String get previewSundialTier0 => 'Journée libre';

  @override
  String get previewSundialTier1 => 'Démarrage';

  @override
  String get previewSundialTier2 => 'En cours';

  @override
  String get previewSundialTier3 => 'Belle progression';

  @override
  String get previewSundialTier4 => 'Presque terminé';

  @override
  String get previewSundialTodayLabel => 'Aujourd\'hui';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles tuiles, $blocks blocs, $nonViable non planifiés';
  }

  @override
  String get timelineClearHeading => 'Votre chronologie est libre aujourd\'hui';

  @override
  String get timelineClearAddTask => 'Ajouter une tuile';

  @override
  String get aiConsentTitle => 'Faites connaissance avec Tiler IA';

  @override
  String get aiConsentSubtitle => 'Votre assistant de planification IA';

  @override
  String get aiConsentIntro =>
      'Pour transformer vos mots en emploi du temps, Tiler IA partage ce que vous envoyez avec des fournisseurs IA de confiance.';

  @override
  String get aiConsentDataTitle => 'Ce que nous envoyons';

  @override
  String get aiConsentDataBody =>
      'Les messages et enregistrements vocaux que vous envoyez, ainsi que les détails pertinents de votre emploi du temps.';

  @override
  String get aiConsentProvidersTitle => 'Qui les reçoit';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini et OpenAI, nos fournisseurs IA tiers.';

  @override
  String get aiConsentPrivacyLink => 'Lire notre politique de confidentialité';

  @override
  String get aiConsentContinue => 'Continuer vers Tiler IA';

  @override
  String get aiConsentAgreementNotice =>
      'En continuant, vous acceptez de partager ces données avec le fournisseur tiers tel que décrit ci-dessus.';

  @override
  String get aiConsentClose => 'Fermer';

  @override
  String get legalFooterPrefix => 'En continuant, vous acceptez les';

  @override
  String get legalFooterTerms => 'Conditions';

  @override
  String get legalFooterAnd => 'et';

  @override
  String get legalFooterPrivacy => 'Confidentialité';

  @override
  String get aiConsentLinkError => 'Impossible d\'ouvrir le lien.';

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
}
