// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Agregar';

  @override
  String get setupCustomRestrictions =>
      'Configurar restricciones personalizadas';

  @override
  String get customRestrictionTitle => 'Restricciones personalizadas';

  @override
  String get customRestrictionHeader =>
      'Configurar restricciones personalizadas';

  @override
  String get customRestrictionHeaderDescription =>
      'Selecciona cuándo quieres completar esta tarea.';

  @override
  String get day => 'Día';

  @override
  String get hour => 'Hora';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get duration => 'Duración';

  @override
  String get durationStar => 'Duración*';

  @override
  String get addTile => 'Agregar bloque';

  @override
  String get defer => 'Diferir';

  @override
  String get deferAll => 'Diferir todo';

  @override
  String get procrastinating => 'Procrastinando';

  @override
  String get forecast => 'Pronóstico';

  @override
  String get whenQ => '¿Cuándo?';

  @override
  String get loading => 'Cargando';

  @override
  String get loadingPrediction => 'Cargando prediccion';

  @override
  String get address => 'Dirección';

  @override
  String get settings => 'Configuración';

  @override
  String get nickName => 'Nombre de usuario';

  @override
  String get deadline_anytime => 'Fecha límite (Cualquier momento)';

  @override
  String get selectADeadline => 'Selecciona una fecha límite';

  @override
  String get close => 'Cerrar';

  @override
  String get tileName => 'Nombre del bloque';

  @override
  String get tileNameStar => 'Nombre del bloque*';

  @override
  String get starAreRequired => '* son campos obligatorios';

  @override
  String get howManyTimes => 'Cuántas veces';

  @override
  String get once => 'Una vez';

  @override
  String get weekdaysAndWorkHours => 'Días de semana y horario de trabajo';

  @override
  String get weekend => 'Fin de semana';

  @override
  String get anytime => 'Cualquier momento';

  @override
  String get repetition => 'Repetición';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get restriction => 'Restricción';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get usernameOrEmail => 'Usuario o correo';

  @override
  String get password => 'Contraseña';

  @override
  String get email => 'Email';

  @override
  String get back => 'Atrás';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get passwordIsRequired => 'La contraseña es obligatoria';

  @override
  String get emailIsRequired => 'El email es obligatorio';

  @override
  String get fieldIsRequired => 'Este campo es obligatorio';

  @override
  String get signingIn => 'Iniciando sesión';

  @override
  String get signInWithEmailCode => 'Iniciar con codigo por correo';

  @override
  String get sendAccessCode => 'Enviar codigo de acceso';

  @override
  String get continueBtn => 'Continuar';

  @override
  String get usePasswordInstead => 'Usar contrasena';

  @override
  String get useAccessCodeInstead => 'Usar codigo de acceso';

  @override
  String get registeringUser => 'Registrando usuario';

  @override
  String get sendVerificationCode => 'Enviar codigo de verificacion';

  @override
  String get verificationCodeSent =>
      'Se envio un codigo de verificacion a tu correo.';

  @override
  String get verificationCode => 'Codigo de verificacion';

  @override
  String get verifyCode => 'Verificar codigo';

  @override
  String get resendCode => 'Reenviar codigo';

  @override
  String get verifyingCode => 'Verificando codigo';

  @override
  String get invalidVerificationCode =>
      'El codigo de verificacion no es valido o vencio.';

  @override
  String get accessCodeRequiresEmail =>
      'El acceso con codigo requiere una direccion de correo.';

  @override
  String get emailCodeInstructions =>
      'Ingresa tu correo y te enviaremos un codigo de verificacion.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Ingresa el codigo enviado a $email.';
  }

  @override
  String get confirmPasswordRequired =>
      'La contraseña de confirmación es obligatoria';

  @override
  String get passwordsDontMatch =>
      'La contraseña y la confirmación no coinciden';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'La contraseña debe tener al menos 7 caracteres';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'La contraseña debe tener una letra mayúscula';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'La contraseña debe tener una letra minúscula';

  @override
  String get passwordNeedsToHaveNumber => 'La contraseña debe tener un número';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'La contraseña debe tener al menos 1 carácter especial';

  @override
  String get enableLocations => 'Habilitar permisos de ubicación';

  @override
  String get noMatchWasFound => 'No se encontraron coincidencias';

  @override
  String get atLeastThreeLettersForLookup =>
      '…Tiler necesita tres caracteres para una búsqueda';

  @override
  String get searchSourceBadgeTiler => 'Tiler';

  @override
  String get searchSourceBadgeGoogle => 'Google';

  @override
  String get searchSourceBadgeMicrosoft => 'Microsoft';

  @override
  String searchConnectedAccount(String account) {
    return 'vía $account';
  }

  @override
  String get searchPartialFailureWarning =>
      'No se pudieron buscar algunos calendarios.';

  @override
  String get searchUnavailableMessage =>
      'La búsqueda no está disponible temporalmente. Inténtalo de nuevo.';

  @override
  String get searchRetry => 'Reintentar';

  @override
  String get noLocationMatchWasFound =>
      'No se encontró una coincidencia de ubicación';

  @override
  String get noLocation => 'Sin ubicación';

  @override
  String get clearedColon => 'Limpiado: ';

  @override
  String get complete => 'Completar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get now => 'Ahora';

  @override
  String get color => 'Color';

  @override
  String get pickAColor => 'Elegir un color';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get play => 'Reproducir';

  @override
  String get successfullyPaused => 'Pausado con éxito';

  @override
  String get successfullyResumed => 'Reanudado con éxito';

  @override
  String get successfullyCompleted => 'Completado con éxito';

  @override
  String get completed => 'Completado';

  @override
  String get deleted => 'Eliminado';

  @override
  String get scheduled => 'Programado';

  @override
  String get movedUpToNow => 'Moviéndolo hacia ahora';

  @override
  String get pausing => 'Pausando';

  @override
  String get resuming => 'Reanudando';

  @override
  String get movingUp => 'Moviendo tu bloque hacia arriba';

  @override
  String get completing => 'Completando';

  @override
  String get deleting => 'Eliminando';

  @override
  String get deleteBlockConfirming => 'Eliminando este bloque...';

  @override
  String get deleteTileConfirming => 'Eliminando este bloque...';

  @override
  String get deleteNow => 'Eliminar ahora';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Esto también se eliminará de Google Calendar';

  @override
  String get deleteOutlookWarning => '⚠️ Esto también se eliminará de Outlook';

  @override
  String get previously => 'Anteriormente';

  @override
  String get upcoming => 'Próximos';

  @override
  String get failedToSendRequest => 'Error al enviar la solicitud';

  @override
  String get revise => 'Revisar';

  @override
  String get revisingSchedule => 'Revisando la agenda';

  @override
  String get procrastinateBlockOut => 'Descanso';

  @override
  String get lunchBreak => 'Hora del Almuerzo';

  @override
  String get coffeeBreak => 'Pausa para Café';

  @override
  String get morningBreak => 'Pausa Matutina';

  @override
  String get afternoonBreak => 'Pausa Vespertina';

  @override
  String get freeTime => 'Tiempo Libre';

  @override
  String get freeSlotHeader => 'Tiempo libre';

  @override
  String get freeSlotNow => 'Libre ahora';

  @override
  String get quickBreak => 'Pausa Rápida';

  @override
  String get shortBreak => 'Pausa Corta';

  @override
  String get blockedTime => 'Tiempo Bloqueado';

  @override
  String get start => 'Inicio';

  @override
  String get end => 'Fin';

  @override
  String get deadline => 'Fecha límite';

  @override
  String get split => 'Dividir';

  @override
  String get timeBlocks => 'Blocos de tiempo';

  @override
  String get swipeRightToTileIt => 'Desliza a la derecha para planificarlo';

  @override
  String get failedToReviseScheduleRequest =>
      'Error al enviar la solicitud de revisión de la agenda';

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get yearly => 'Anual';

  @override
  String get none => 'Ninguno';

  @override
  String get noneNotificationCategory => 'Predeterminado';

  @override
  String get nextTileNotificationCategory => 'Próximo bloque';

  @override
  String get userSetReminderNotificationCategory =>
      'Recordatorio definido por el usuario';

  @override
  String get depatureTimeNotificationCategory => 'Hora de salida';

  @override
  String get tile => 'Tile';

  @override
  String get appointment => 'Bloque';

  @override
  String startingAtTime(String time) {
    return 'Comienza a las $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Termina a las $time';
  }

  @override
  String get startsInTenMinutes => 'Comienza en diez minutos';

  @override
  String get endsInTenMinutes => 'Termina en cinco minutos';

  @override
  String startsInDuration(String duration) {
    return 'Comienza en $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName terminará pronto';
  }

  @override
  String get home => 'Casa';

  @override
  String get work => 'Trabajo';

  @override
  String get googleLogo => 'Logotipo de Google';

  @override
  String get edit => 'Editar';

  @override
  String get workProfileHours => 'Horario de trabajo';

  @override
  String get personalHours => 'Horas personales';

  @override
  String get setWorkProfileHours => 'Definir horario de trabajo';

  @override
  String get setPersonalHours => 'Definir horas personales';

  @override
  String get customHours => 'Horas personalizadas';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get noteEllipsis => 'Nota...';

  @override
  String get tapToCreateNewTile => 'Toca para crear un nuevo bloque';

  @override
  String get emptyDayHeaderLine1 => 'Aún no hay planes.';

  @override
  String get emptyDayFooterLine1 => 'Comienza en segundos—';

  @override
  String get emptyDayFooterLine2 => 'importa calendarios o crea tiles.';

  @override
  String get emptyDayOr => 'o';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Importar Google Calendar';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get progress => 'Progreso';

  @override
  String get youNeedToLeaveIn => 'Necesitas salir en';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Necesitas salir en $duration';
  }

  @override
  String durationLate(String duration) {
    return '$duration de retraso';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Transcurrido hace $duration';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Completado hace $duration';
  }

  @override
  String durationLeft(String duration) {
    return 'Restan $duration';
  }

  @override
  String get issuesConnectingToTiler => 'Problemas para conectar con Tiler';

  @override
  String completedCount(String count) {
    return 'Completados ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Eliminados ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Bloques restantes ($count)';
  }

  @override
  String countTile(String count) {
    return '$count bloques';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number bloques seleccionados';
  }

  @override
  String get completeTiles => 'Completar bloques';

  @override
  String get thisFitsInYourSchedule => 'Esto cabe en tu agenda.';

  @override
  String get warningColon => 'Advertencia:';

  @override
  String get oneEventAtRisk => '1 evento en riesgo';

  @override
  String countEventAtRisk(String number) {
    return '$number eventos en riesgo';
  }

  @override
  String get oneConflict => '1 conflicto';

  @override
  String countConflict(String number) {
    return '$number conflictos';
  }

  @override
  String get create => 'Crear';

  @override
  String get thisEventWouldCause => 'Este evento causaría ';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get unScheduledTiles => 'Bloques sin programar';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number bloques sin programar';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number más';
  }

  @override
  String get unScheduled => 'Sin programar';

  @override
  String get allScheduled => 'Todo programado';

  @override
  String get getOnIt => 'Ponte a ello';

  @override
  String get done => 'Listo';

  @override
  String get late => 'Atrasado';

  @override
  String get onTime => 'A tiempo';

  @override
  String get todayStatusPlacedTitle => 'Programadas correctamente';

  @override
  String get todayStatusAttentionTitle => 'Necesitan atención';

  @override
  String get todayStatusLateTitle => 'Con retraso';

  @override
  String get todayStatusAttentionHelper =>
      'Estas no cupieron en el tiempo disponible de hoy.';

  @override
  String get todayStatusLateHelper =>
      'El tiempo de viaje entre estas y tus tiles cercanas hace que no puedas llegar a tiempo.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tiles',
      one: '1 tile',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiles completadas',
      one: 'Tile completada',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Necesitan atención';

  @override
  String get todayStatusTilesRunningLate => 'Con retraso';

  @override
  String get todayStatusEverythingOnTrack => 'Todo va según lo previsto';

  @override
  String get todayStatusEverythingElseOnTrack =>
      'Todo lo demás va según lo previsto';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Ninguna tile programada va con retraso.';

  @override
  String get todayStatusClearDay => 'Tu día está despejado.';

  @override
  String get todayStatusPreviewCta => 'Ver un plan mejor';

  @override
  String get todayStatusPreviewLoading => 'Preparando la vista previa…';

  @override
  String get todayStatusPreviewUnavailable =>
      'No se pudo generar la vista previa. Tu plan no ha cambiado.';

  @override
  String get todayStatusUntitledTile => 'Tile sin título';

  @override
  String get todayStatusShowAll => 'Ver todo';

  @override
  String todayStatusExpandSection(String section) {
    return 'Expandir $section';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return 'Contraer $section';
  }

  @override
  String get todayStatusReasonDueToday => 'Vence hoy';

  @override
  String get todayStatusReasonNoOpenSlot => 'Sin hueco disponible';

  @override
  String get todayStatusReasonTravelInfeasible => 'El viaje lo hace inviable';

  @override
  String get todayStatusReasonOutsideHours => 'Fuera del horario disponible';

  @override
  String get todayStatusReasonDependencyBlocked => 'Esperando otra tile';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Necesita $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Necesita tu decisión';

  @override
  String get todayStatusReasonUnknown => 'No cupo';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Seleccionar tiles';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Expandir sesiones de $title';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Contraer sesiones de $title';
  }

  @override
  String get analysis => 'Análisis';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get sleep => 'Dormir';

  @override
  String get overview => 'Resumen';

  @override
  String get driveTime => 'Tiempo de conducción';

  @override
  String get signUpWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signUpWithApple => 'Iniciar sesión con Apple';

  @override
  String get signUpWithMicrosoft => 'Iniciar sesión con Microsoft';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get invalidUsernameOrPassword =>
      'Nombre de usuario o contraseña no válidos';

  @override
  String get noInternetConnection => 'No hay conexión a internet';

  @override
  String get oneHour => '1 hora';

  @override
  String countHours(String count) {
    return '$count horas';
  }

  @override
  String get oneMinute => '1 minuto';

  @override
  String countMinutes(String count) {
    return '$count minutos';
  }

  @override
  String countDays(String count) {
    return '$count días';
  }

  @override
  String lateDate(String date) {
    return 'Atrasado ($date)';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String get allowAccessDescription =>
      'Tiler recopila datos de ubicación para permitir una programación eficiente de bloques y citas. \nTus datos se mantienen privados y solo se usan para este fin.';

  @override
  String get allowLocationAccessQ => '¿Permitir acceso a la ubicación?';

  @override
  String get allow => 'Permitir';

  @override
  String get deny => 'Denegar';

  @override
  String get afternoon => 'Tarde';

  @override
  String get evening => 'Noche';

  @override
  String get night => 'Noche';

  @override
  String get morningAndAfternoon => 'Mañana & Tarde';

  @override
  String get afternoonAndEvening => 'Tarde & Noche';

  @override
  String get lateEvening => 'Fin de la noche';

  @override
  String get prediction => 'Predicción';

  @override
  String get softDeadline => 'Fecha límite flexible';

  @override
  String get location => 'Ubicación';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteYourTilerAccountQ => '¿Eliminar cuenta?';

  @override
  String get no => 'No';

  @override
  String get dismiss => 'Descartar';

  @override
  String get forgetPassword => 'Olvidé mi contraseña';

  @override
  String get forgotPasswordBtn => '¿Olvidaste tu contraseña?';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get reset => 'Restablecer';

  @override
  String lookingUp(String text) {
    return 'Buscando $text';
  }

  @override
  String get lowPriorityTrunc => 'Baja';

  @override
  String get mediumPriorityTrunc => 'Media';

  @override
  String get highPriorityTrunc => 'Alta';

  @override
  String failedToAddGoogleCalendar(String email) {
    return 'Error al agregar $email';
  }

  @override
  String deletedCalendar(String email) {
    return 'Calendario de $email eliminado';
  }

  @override
  String get loadingIntegrations => 'Cargando integraciones';

  @override
  String get noThirdPartyIntegtions => 'Sin calendarios de terceros';

  @override
  String get addGoogleCalendar => 'Agregar Google Calendar';

  @override
  String get integrations => 'Integraciones';

  @override
  String get integrateOtherCalendars => 'Integrar con calendarios de terceros';

  @override
  String get clear => 'Limpiar';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get skip => 'Omitir';

  @override
  String get morningPerson => '🌅 Persona matutina';

  @override
  String get morning => 'Mañana';

  @override
  String get middayPerson => '🌞 Persona de mediodía';

  @override
  String get nightPerson => '🌃 Persona nocturna';

  @override
  String get enterAddress => 'Ingresa tu dirección';

  @override
  String get primaryLocationQuestion =>
      '¿Cuál es tu ubicación principal para el trabajo o los estudios?';

  @override
  String get useDeviceLocation => 'Usar la ubicación de mi dispositivo';

  @override
  String get energyLevelDescriptionQuestion =>
      '¿Cómo describirías tus niveles de energía a lo largo del día?';

  @override
  String get incompleteRequest => 'No se envió la solicitud completa';

  @override
  String get addContact => 'Agregar contacto';

  @override
  String get invalidContactFormat =>
      'No es un correo electrónico o número de teléfono válido';

  @override
  String deadlineTime(String time) {
    return 'Fecha límite: $time';
  }

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get preview => 'Vista previa';

  @override
  String get addTilette => 'Agregar Tilette';

  @override
  String get tileShareName => 'Nombre del bloque compartido';

  @override
  String get tileShare => 'Bloque compartido';

  @override
  String get update => 'Actualizar';

  @override
  String get noDesignatedTiles => 'Sin bloques designados';

  @override
  String get noTileCluster => 'No se crearon bloques compartidos';

  @override
  String get errorLoadingTilelist => 'Error al cargar la lista de bloques';

  @override
  String get failedToLoadTileShareCluster =>
      'Error al cargar el cluster de bloques compartidos';

  @override
  String get missingTileShareCluster => 'Falta el cluster de TileShare';

  @override
  String get outBound => 'En salida';

  @override
  String get inBound => 'En entrada';

  @override
  String get multiShare => 'Compartir múltiple';

  @override
  String get errorOccurred =>
      '¡Ocurrió un error!!\nPor favor, inténtalo de nuevo.';

  @override
  String get authenticationIssues => 'Problemas de autenticación.';

  @override
  String get userIsNotAuthenticated => 'El usuario no está autenticado.';

  @override
  String get responseContentError =>
      'La respuesta no contiene el contenido esperado.';

  @override
  String get responseHandlingError => 'Error al procesar la respuesta.';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get travel => 'Desplazamiento';

  @override
  String numberOfDayForecast(String number) {
    return 'Pronóstico de $number días';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Error al obtener la vista previa';

  @override
  String get noDriving => 'Sin conducir';

  @override
  String get tileShareNoteEllipsis => 'Nota...';

  @override
  String get hi => 'Hola';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get passwordCreationMessagePart1 =>
      'Crea una contraseña fuerte y única con ';

  @override
  String get passwordConditionMinLength => 'al menos seis caracteres';

  @override
  String get passwordCreationMessageIncluding => ', incluyendo ';

  @override
  String get passwordConditionUppercaseLetters => 'letras mayúsculas';

  @override
  String get passwordConditionLowercaseLetters => 'letras minúsculas';

  @override
  String get passwordConditionNumbers => 'números';

  @override
  String get passwordConditionSpecialCharacter => 'un carácter especial';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', y ';

  @override
  String get nonViableTimeSlot => 'Sin intervalo de tiempo viable';

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
  String get save => 'Guardar';

  @override
  String get selectWeek => 'Selecciona una semana';

  @override
  String get selectYear => 'Seleccionar año';

  @override
  String get retrievingDataIssue => 'Problema al recuperar datos';

  @override
  String get recurring => 'Recurrente';

  @override
  String get nonRecurring => 'No recurrente';

  @override
  String get dailyReurring => 'Diario';

  @override
  String get weeklyReurring => 'Semanal';

  @override
  String get biweeklyReurring => 'Quincenal';

  @override
  String get monthlyReurring => 'Mensual';

  @override
  String get yearlyReurring => 'Anual';

  @override
  String get ellipsisEmprtNotes => 'Notas...';

  @override
  String get tileShareDelete => 'Eliminar';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Bloque de pronóstico';

  @override
  String get previewOthers => 'Otros';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodDay => 'Buen día';

  @override
  String get goodEvening => 'Buenas tardes';

  @override
  String youHaveXBlocks(String count) {
    return 'Tienes $count compromisos próximos.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Tienes $count bloques próximos.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Tienes $count bloques compartidos próximos.';
  }

  @override
  String countTileShare(String count) {
    return '$count bloques compartidos';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Tienes $blockCount compromisos y $tileCount bloques próximos.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Tienes $blockCount compromisos y $tileShareCount bloques compartidos próximos.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Tienes $tileCount bloques y $tileShareCount bloques compartidos próximos.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Tienes $blockCount compromisos, $tileCount bloques y $tileShareCount bloques compartidos próximos.';
  }

  @override
  String get noTilesPreview => 'No tienes nada previsto para el resto del día.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Crear bloque';

  @override
  String get previewTileForecast => 'Pronóstico';

  @override
  String get previewTileOptions => 'Opciones';

  @override
  String get previewTileMore => 'Más';

  @override
  String get previewTileShuffle => 'Mezclar';

  @override
  String get previewTileRevise => 'Revisar';

  @override
  String get previewTileDeferAll => 'Diferir todo';

  @override
  String get previewLocationName => 'Ubicación';

  @override
  String get previewTagName => 'Etiqueta';

  @override
  String get previewClassificationName => 'Clasificación';

  @override
  String get previewBlockedOut => 'Bloqueado';

  @override
  String get accountInfo => 'Información de la cuenta';

  @override
  String get fistName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get tilePreferences => 'Preferencias de bloques';

  @override
  String get notificationsPreferences => 'Preferencias de notificaciones';

  @override
  String get security => 'Seguridad';

  @override
  String get connections => 'Conexiones';

  @override
  String get myLocations => 'Mis ubicaciones';

  @override
  String get aboutTiler => 'Acerca de Tiler';

  @override
  String get howToUseTiler => 'Cómo usar Tiler';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get setLocation => 'Definir ubicación';

  @override
  String get connectCalendars => 'Conecta tus calendarios';

  @override
  String get configure => 'Configurar';

  @override
  String get comingSoon => 'Próximamente';

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
  String get addCalendar => 'Añadir calendario';

  @override
  String get calendarConnected => 'Calendario conectado';

  @override
  String get calendarConnectionDeclined =>
      'La conexión del calendario se canceló';

  @override
  String get calendarConnectionError => 'No se pudo conectar tu calendario';

  @override
  String get sleepDuration => 'Duración del sueño';

  @override
  String get transportationMethodQuestion => '¿Cómo te desplazas?';

  @override
  String get defineYourTimeRestrictions => 'Define tus restricciones de tiempo';

  @override
  String get setWorkHours => 'Definir horario de trabajo';

  @override
  String get setYourBlockOutHours => 'Define tus horas bloqueadas';

  @override
  String get travelMediumBiking => 'En bicicleta';

  @override
  String get travelMediumTransit => 'Transporte público';

  @override
  String get travelMediumDriving => 'En auto';

  @override
  String get travelMediumTransport => 'Transporte';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio m';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio h';
  }

  @override
  String get bedTime => 'Hora de dormir';

  @override
  String get sleepTime => 'Hora de sueño';

  @override
  String get scheduleFullness => 'Ocupación del horario';

  @override
  String get scheduleFullnessDescription =>
      '¿Qué tan ocupado debería estar tu horario?';

  @override
  String scheduleFullnessValue(int percentage) {
    return '$percentage por ciento de ocupación objetivo';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Los objetivos oscilan entre el $minimum% y el $maximum%. Esto mantiene una línea base útil mientras deja espacio para cambios y viajes.';
  }

  @override
  String get schedulePreferences => 'Preferencias de horario';

  @override
  String get lighter => 'Más ligero';

  @override
  String get balanced => 'Equilibrado';

  @override
  String get fuller => 'Más completo';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'Las preferencias de bloques se actualizaron con éxito.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'Las preferencias de notificaciones se actualizaron con éxito.';

  @override
  String get tileReminders => 'Recordatorios de bloques';

  @override
  String get appUpdates => 'Actualizaciones de la app';

  @override
  String get marketingUpdates => 'Actualizaciones de marketing';

  @override
  String get emailNotifications => 'Notificaciones por email';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get countryCode => 'Código de país';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'La información de la cuenta se actualizó con éxito.';

  @override
  String get reachingServerIssues =>
      'Problemas para conectar con los servidores de Tiler';

  @override
  String get deleteAccountConfirmation =>
      '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get integrationsSetLocation => 'Definir ubicación';

  @override
  String get googleCalender => 'Google Calendar';

  @override
  String get passwordsMustMatch => 'Las contraseñas deben coincidir';

  @override
  String get parenthesisLate => '(Atrasado)';

  @override
  String get failedToAddIntegration => 'Error al agregar la integración';

  @override
  String get unknownProvider => 'Proveedor desconocido';

  @override
  String get manageCalendars => 'Gestionar calendarios';

  @override
  String get calendarItems => 'Elementos del calendario';

  @override
  String get noCalendarItemsFound =>
      'No se encontraron elementos del calendario';

  @override
  String get calendarItemsWillAppearHere =>
      'Los elementos de tu calendario aparecerán aquí';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount de $totalCount calendarios activos';
  }

  @override
  String get toggleCalendarsToSync =>
      'Activa los calendarios para sincronizar con Tiler';

  @override
  String get unknownCalendar => 'Calendario desconocido';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount de $totalCount activos';
  }

  @override
  String integrationCount(int count) {
    return '$count integraciones';
  }

  @override
  String get errorLoadingCalendarItems =>
      'Error al cargar los elementos del calendario';

  @override
  String get integratedCalendars => 'Calendarios';

  @override
  String get integrationAdd => 'Agregar';

  @override
  String get timeAndLocationSecondarySubTitle =>
      '¿Puede acceder a tu ubicación para ofrecer recomendaciones\ny notificaciones basadas en la ubicación?';

  @override
  String get recurringTasks => 'Tareas recurrentes';

  @override
  String get yourProfession => '¿Tu profesión?';

  @override
  String get yourProfessionQuestion => '¿A qué te dedicas?';

  @override
  String get yourProfessionHint => 'Describe a qué te dedicas en el trabajo';

  @override
  String get medicalProfessional => 'Profesional de la salud';

  @override
  String get softwareDeveloper => 'Desarrollador de software';

  @override
  String get student => 'Estudiante';

  @override
  String get engineer => 'Ingeniero';

  @override
  String get fieldSalesProfessional => 'Profesional de ventas de campo';

  @override
  String get remoteWorker => 'Trabajador remoto & nómada digital';

  @override
  String get stayAtHomeParent => 'Padre/madre de casa';

  @override
  String get clientAccountManagers => 'Gestores de clientes/cuentas';

  @override
  String get other => 'Otro';

  @override
  String get tileSuggestions => 'Sugerencias de bloques';

  @override
  String get personalOrWorkQuestion => '¿Para qué vas a usar Tiler?';

  @override
  String get enter3chars => 'Ingresa al menos 3 caracteres.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Sale en $duration para llegar a tiempo';
  }

  @override
  String get leaveNowToArriveOnTime => 'Sale ahora para llegar a tiempo!';

  @override
  String durationDrive(String duration) {
    return '$duration en auto';
  }

  @override
  String durationTransit(String duration) {
    return '$duration en transporte público';
  }

  @override
  String durationBike(String duration) {
    return '$duration en bicicleta';
  }

  @override
  String durationWalk(String duration) {
    return '$duration a pie';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration en auto hasta $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration en transporte público hasta $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration en bicicleta hasta $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration a pie hasta $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Salir a las $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Tráfico detectado - se sugiere nueva ruta';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Tráfico: +$minutes min de retraso';
  }

  @override
  String get heavyTrafficExpected => 'Se espera tráfico intenso';

  @override
  String get addWithAI => 'Agregar con IA';

  @override
  String get focusTime => 'Tiempo de concentración';

  @override
  String get videoMeeting => 'Reunión de video';

  @override
  String get sharedWith => 'Compartido con';

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
    return '$hours hr';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String travelViaRoute(String route) {
    return 'por $route';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return ' $travelMode a ';
  }

  @override
  String get travelModeDriving => 'conducir';

  @override
  String get travelModeWalking => 'caminar';

  @override
  String get travelModeBicycling => 'bicicleta';

  @override
  String get travelModeTransitLower => 'transporte';

  @override
  String travelDurationCompact(int minutes) {
    return '${minutes}m';
  }

  @override
  String get yourDayIsOptimized => 'Tu día está optimizado.';

  @override
  String get yourDayAtAGlance => 'Tu día de un vistazo';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration de tiempo de viaje hoy.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count tiles programados para hoy.';
  }

  @override
  String get viewRoute => 'Ver ruta';

  @override
  String get focusModeChip => 'Modo Enfoque';

  @override
  String get showRouteChip => 'Mostrar Ruta';

  @override
  String get reOptimizeChip => 'Re-optimizar';

  @override
  String get dayFilterAll => 'Todo';

  @override
  String get dayFilterBlocks => 'Bloques';

  @override
  String get dayFilterTiles => 'Tiles';

  @override
  String get dayFilterTooltip => 'Mostrar todo, solo bloques o solo tiles';

  @override
  String dayFilterShowingBlocks(int shown, int total) {
    return 'Mostrando solo bloques · $shown de $total';
  }

  @override
  String dayFilterShowingTiles(int shown, int total) {
    return 'Mostrando solo tiles · $shown de $total';
  }

  @override
  String dayFilterEmptyBlocks(String day) {
    return 'Sin bloques el $day';
  }

  @override
  String dayFilterEmptyTiles(String day) {
    return 'Sin tiles el $day';
  }

  @override
  String get dayFilterShowAll => 'Mostrar todo';

  @override
  String get dayFilterAutoCleared => 'Mostrando todo — filtro borrado';

  @override
  String get todayColon => 'Hoy:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount tiles, $blockCount bloques';
  }

  @override
  String get timeSavedColon => 'Tiempo ahorrado:';

  @override
  String get travelTimeColon => 'Tiempo de viaje:';

  @override
  String travelTime(String duration) {
    return 'Tiempo de viaje: $duration';
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
  String get scheduleConflict => 'Conflicto de horario';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" y \"$tile2\" están programados a la misma hora';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '\"$tile1\" es durante \"$tile2\" ($overlap de superposición)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '\"$tile1\" se superpone con \"$tile2\" por $overlap';
  }

  @override
  String get fix => 'Arreglar';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Conflicto: ${minutes}m de superposición';
  }

  @override
  String get oneScheduleConflict => '1 Conflicto de horario';

  @override
  String countScheduleConflicts(int count) {
    return '$count Conflictos de horario';
  }

  @override
  String get tapToReviewAndResolve => 'Toca para revisar y resolver';

  @override
  String countConflicts(int count) {
    return '$count conflictos';
  }

  @override
  String get tapToExpand => 'Toca para expandir';

  @override
  String conflictingTiles(int count) {
    return '$count Tiles en conflicto';
  }

  @override
  String totalOverlap(String duration) {
    return 'Superposición total: $duration';
  }

  @override
  String get autoResolve => 'Auto-resolver';

  @override
  String get untitledTile => 'Tile sin título';

  @override
  String get untitledEvent => 'Sin título';

  @override
  String get extendedEventSingular => '1 Evento Extendido';

  @override
  String extendedEventsPlural(int count) {
    return '$count Eventos Extendidos';
  }

  @override
  String get extendedEventsTapToView =>
      'Toca para ver eventos de todo el día y eventos largos';

  @override
  String get extendedEventsTitle => 'Eventos Extendidos';

  @override
  String get dayGridAllDay => 'Todo el día';

  @override
  String get dayGridHeaderAllClear => 'Todo en orden';

  @override
  String dayGridHeaderConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflictos',
      one: '1 conflicto',
    );
    return '$_temp0';
  }

  @override
  String dayGridHeaderNeedAttention(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$summary necesitan atención',
      one: '$summary necesita atención',
    );
    return '$_temp0';
  }

  @override
  String get dayGridHeaderReview => 'Revisar';

  @override
  String get dayGridDaySummary => 'Resumen del día';

  @override
  String get bottomNavToday => 'Hoy';

  @override
  String get bottomNavTiler => 'Tiler';

  @override
  String get dayGridHeaderRespond => 'Responder';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos de más de 16 horas',
      one: '1 evento de más de 16 horas',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Ruta de hoy';

  @override
  String get noLocationsToday => 'Sin ubicaciones hoy';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Agrega ubicaciones a tus tiles para ver tu ruta diaria';

  @override
  String countStops(int count) {
    return '$count paradas';
  }

  @override
  String get routeOptimized => 'Ruta optimizada';

  @override
  String savedTravelTime(String duration) {
    return 'Ahorraste $duration de tiempo de viaje';
  }

  @override
  String get firstStop => 'Primera parada';

  @override
  String get stop => 'Parada';

  @override
  String arriveBy(String time) {
    return 'Llegar a las $time';
  }

  @override
  String get fromPreviousStop => 'desde la parada anterior';

  @override
  String get viewTile => 'Ver Tile';

  @override
  String get editTile => 'Editar Tile';

  @override
  String get startNavigation => 'Iniciar navegación';

  @override
  String get noLocationAvailable => 'Sin ubicación';

  @override
  String get seeTodaysRoute => 'Ver ruta de hoy';

  @override
  String get whatWouldYouLikeToDo => '¿Qué te gustaría hacer?';

  @override
  String get describeATask =>
      'Describe una tarea y nosotros nos encargamos de la planificación.';

  @override
  String get microphonePermissionDenied => 'Permiso del micrófono denegado.';

  @override
  String failedToStartRecording(String error) {
    return 'Error al iniciar la grabación: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Error al detener la grabación: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Error de conversión de audio: $error';
  }

  @override
  String get audioConversionFailed => 'Error en la conversión de audio';

  @override
  String get recordingPathIsEmpty => 'La ruta de grabación está vacía';

  @override
  String get noActiveRecording => 'Sin grabación activa';

  @override
  String get joinMeeting => 'Unirse a la reunión';

  @override
  String get openLink => 'Abrir enlace';

  @override
  String get actions => 'Acciones';

  @override
  String get hideActions => 'Ocultar acciones';

  @override
  String get pendingRsvpSingular => '1 Evento Necesita Respuesta';

  @override
  String pendingRsvpPlural(int count) {
    return '$count Eventos Necesitan Respuesta';
  }

  @override
  String get pendingRsvpHappeningNow =>
      'Ocurriendo ahora - responde para unirte';

  @override
  String get pendingRsvpStartingSoon => 'Comienza pronto - responde ahora';

  @override
  String get pendingRsvpWithinHour => 'Comienza en una hora';

  @override
  String get pendingRsvpUpcoming => 'Próximo - toca para responder';

  @override
  String get pendingRsvpTapToReview => 'Toca para revisar y responder';

  @override
  String get pendingRsvpTitle => 'Respuestas Pendientes';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos esperando tu respuesta',
      one: '1 evento esperando tu respuesta',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Comienza Pronto';

  @override
  String get pendingRsvpLater => 'Más Tarde Hoy y Próximos';

  @override
  String get declinedRsvpSingular => '1 evento rechazado';

  @override
  String declinedRsvpPlural(int count) {
    return '$count eventos rechazados';
  }

  @override
  String get declinedRsvp => 'Eventos rechazados';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 pendiente, $declinedCount rechazados';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount pendientes, 1 rechazado';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount pendientes, $declinedCount rechazados';
  }

  @override
  String get rsvpNeedsAction => 'Necesita Respuesta';

  @override
  String get rsvpTentative => 'Tentativo';

  @override
  String get rsvpAccepted => 'Aceptado';

  @override
  String get rsvpDeclined => 'Rechazado';

  @override
  String unableToOpenLinkError(String link) {
    return 'No se pudo abrir el enlace: $link';
  }

  @override
  String get leaveNow => '¡Sal ahora!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Sal en $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count alertas';
  }

  @override
  String get alertChipLeaveNow => 'Sal Ahora';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Sal ${minutes}m';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Conflictos',
      one: '1 Conflicto',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Todo el día',
      one: '1 Todo el día',
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
  String get accepted => 'Aceptado';

  @override
  String get declined => 'Rechazado';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Responder a $calendarSource';
  }

  @override
  String get unknown => 'Invitación de calendario';

  @override
  String get loadingPreviousDays => 'Cargando días anteriores...';

  @override
  String get loadingUpcomingDays => 'Cargando próximos días...';

  @override
  String get requestTimeout =>
      'Tiempo de solicitud agotado - por favor verifique su conexión';

  @override
  String get failedToPauseTile => 'Error al pausar el tile';

  @override
  String get failedToResumeTile => 'Error al reanudar el tile';

  @override
  String get failedToMoveUpTask => 'Error al mover la tarea';

  @override
  String get failedToUpdateTile => 'Error al actualizar el tile';

  @override
  String get failedToBuzzSchedule => 'Error al notificar la programación';

  @override
  String get failedToShuffleSchedule => 'Error al mezclar la programación';

  @override
  String get failedToProcrastinateTile => 'Error al posponer el tile';

  @override
  String get tutorialStepYourScheduleTitle => 'Tu Horario';

  @override
  String get tutorialStepYourScheduleBody =>
      'Tu día está organizado en Tiles — bloques de tiempo inteligentes que Tiler organiza por ti. Desplázate hacia arriba y abajo para ver tu día completo.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Crear y Optimizar';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Toca aquí para crear una nueva tarea. Dile a Tiler qué necesitas hacer y cuánto tiempo tomará — Tiler decide el cuándo.';

  @override
  String get tutorialCalloutReOptimize => 'Re-optimizar';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      '¿Se descarriló tu día? Recalcula desde ahora manteniendo tu plan aproximadamente estable';

  @override
  String get tutorialCalloutTravelTime => 'Tiempo de Viaje';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'Tiler tiene en cuenta el tiempo de traslado entre ubicaciones';

  @override
  String get tutorialStepQuickCreateTitle => 'Creación Rápida';

  @override
  String get tutorialStepQuickCreateBody =>
      'Esta es la hoja de creación rápida. Nombra tu tile y establece una duración para agregarlo rápidamente.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      '¡Esta es la hoja de creación rápida detrás de mí! Nombra tu tile, establece una duración y toca Agregar — Tiler se encarga del resto.';

  @override
  String get tutorialCalloutNameYourTile => 'Nombra Tu Tile';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Describe la tarea que quieres realizar';

  @override
  String get tutorialCalloutSetDuration => 'Establecer Duración';

  @override
  String get tutorialCalloutSetDurationDesc =>
      '¿Cuánto tiempo tomará esta tarea?';

  @override
  String get tutorialCalloutMoreOptions => 'Más Opciones';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Agrega ubicación, fecha límite o repetición a través del editor completo';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Agrega ubicación, fecha límite o repetición';

  @override
  String get tutorialStepTilerWorksTitle => 'Tiler Trabaja por Ti';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tiler organiza automáticamente tus tiles según tus niveles de energía, tiempo de viaje y fechas límite. Solo agrega lo que necesitas hacer — Tiler se encarga del cuándo.';

  @override
  String get tutorialCalloutForecast => 'Pronóstico';

  @override
  String get tutorialCalloutForecastDesc =>
      'Ve cuándo se insertará un tile antes de seleccionarlo';

  @override
  String get tutorialCalloutShuffle => 'Mezclar';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Mezcla las cosas y sugiere qué deberías hacer a continuación';

  @override
  String get tutorialCalloutDeferAll => 'Posponer Todo';

  @override
  String get tutorialCalloutDeferAllDesc =>
      '¿Día difícil? Empuja todo hacia adelante';

  @override
  String get tutorialStepControlTilesTitle => 'Controla Tus Tiles';

  @override
  String get tutorialStepControlTilesBody =>
      'Cada tile tiene controles para gestionar tus tareas en tiempo real:';

  @override
  String get tutorialCalloutPlay => 'Reproducir';

  @override
  String get tutorialCalloutPlayDesc => 'Comienza a trabajar en este tile';

  @override
  String get tutorialCalloutPause => 'Pausar';

  @override
  String get tutorialCalloutPauseDesc =>
      'Toma un descanso — Tiler reprogramará el resto';

  @override
  String get tutorialCalloutComplete => 'Completar';

  @override
  String get tutorialCalloutCompleteDesc => '¡Listo! Márcalo como terminado';

  @override
  String get tutorialCalloutProcrastinate => 'Procrastinar';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Ahora no — empújalo para después';

  @override
  String get tutorialStepBigPictureTitle => 'Ve el Panorama General';

  @override
  String get tutorialStepBigPictureBody =>
      'Toca el ícono del calendario para alternar entre tres vistas:';

  @override
  String get tutorialCalloutDaily => 'Diario';

  @override
  String get tutorialCalloutDailyDesc => 'Hora por hora — tu agenda detallada';

  @override
  String get tutorialCalloutWeekly => 'Semanal';

  @override
  String get tutorialCalloutWeeklyDesc => 'Ve toda la semana de un vistazo';

  @override
  String get tutorialCalloutMonthly => 'Mensual';

  @override
  String get tutorialCalloutMonthlyDesc => 'Planifica con una vista mensual';

  @override
  String get tutorialStepToolkitTitle => 'Tu Kit de Herramientas';

  @override
  String get tutorialStepToolkitBody =>
      'Estas herramientas prácticas están siempre a tu alcance:';

  @override
  String get tutorialCalloutShare => 'Compartir';

  @override
  String get tutorialCalloutShareDesc => 'Colabora — comparte tiles con otros';

  @override
  String get tutorialCalloutSearch => 'Buscar';

  @override
  String get tutorialCalloutSearchDesc => 'Encuentra cualquier tile por nombre';

  @override
  String get tutorialCalloutSettings => 'Configuración';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Personaliza tu experiencia, conecta calendarios, establece preferencias';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Toca el botón de chat para agregar o ajustar tiles solo hablando con Tiler';

  @override
  String get tutorialStepChatTitle => 'Chatea con Tiler';

  @override
  String get tutorialStepChatBody =>
      'Toca el botón de chat en cualquier momento para agregar o ajustar tiles solo hablando con Tiler — sin formularios.';

  @override
  String get tutorialNavNext => 'Siguiente';

  @override
  String get tutorialNavNextArrow => 'Siguiente →';

  @override
  String get tutorialNavBack => 'Atrás';

  @override
  String get tutorialNavBackArrow => '← Atrás';

  @override
  String get tutorialNavSkip => 'Omitir';

  @override
  String get tutorialNavLetsGo => '¡Vamos!';

  @override
  String get welcomeExplainerHeadline => 'Tiles y Bloques';

  @override
  String get welcomeExplainerSubtitle =>
      'Un vistazo rápido a cómo Tiler planifica tu día.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Los bloques son fijos. Ocurren a una hora determinada.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Los tiles son flexibles. Tiler los acomoda alrededor de tus bloques.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'El dentista pasa a las $time: Tiler replanifica tus tiles a su alrededor.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Cambió';

  @override
  String get welcomeExplainerReplannedBadge => 'Replanificado';

  @override
  String get welcomeExplainerBlockStandup => 'Reunión de equipo';

  @override
  String get welcomeExplainerBlockDentist => 'Dentista';

  @override
  String get welcomeExplainerTileWorkout => 'Ejercicio';

  @override
  String get welcomeExplainerTileReport => 'Escribir informe';

  @override
  String get welcomeExplainerTileGroceries => 'Compras';

  @override
  String get welcomeExplainerLegendBlock => 'Bloque';

  @override
  String get welcomeExplainerLegendTile => 'Tile';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Preferencias de Tiles';

  @override
  String get tutorialStepSettingsTilesBody =>
      'Tus preferencias de IA viven aquí: cómo te desplazas, tus horas de trabajo y personales, y el tiempo bloqueado.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Cómo te desplazas';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tiler calcula el tiempo de viaje entre tiles según tu forma habitual de desplazarte.';

  @override
  String get tutorialStepTilePrefsHoursTitle => 'Horas de trabajo y personales';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Cuándo Tiler puede programar tiles de trabajo o personales. Toca cualquiera para definir un perfil.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Horas bloqueadas';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Hora de dormir y duración del sueño: horas en las que Tiler nunca programa nada.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'Transcribiendo';

  @override
  String get newChat => 'Nuevo chat';

  @override
  String get noChatHistory => 'Sin historial de chat';

  @override
  String get unknownChat => 'Chat desconocido';

  @override
  String get transcriptionFailed => 'Error en la transcripción';

  @override
  String get acceptChanges => 'Aceptar cambios';

  @override
  String get noRequestToExecute => 'No hay solicitud para ejecutar';

  @override
  String get initializingAction => 'Iniciando la generación de la acción';

  @override
  String get settingThingsUp => 'Preparando';

  @override
  String get preparingRequest => 'Preparando tu solicitud';

  @override
  String get gettingReady => 'Preparándose';

  @override
  String get processingAction => 'Procesando la acción';

  @override
  String get workingOnIt => 'Trabajando en ello';

  @override
  String get analyzingRequest => 'Analizando tu solicitud';

  @override
  String get thinking => 'Pensando';

  @override
  String get actionComplete => 'Procesamiento de la acción completado';

  @override
  String get processingDone => 'Procesamiento completado';

  @override
  String get allSet => 'Todo listo';

  @override
  String get finishedProcessing => 'Procesamiento finalizado';

  @override
  String get generatingSummary => 'Generando resumen';

  @override
  String get summarizingResults => 'Resumiendo resultados';

  @override
  String get creatingOverview => 'Creando resumen general';

  @override
  String get preparingSummary => 'Preparando resumen';

  @override
  String get summaryComplete => 'Generación de resumen completada';

  @override
  String get summaryReady => 'Resumen listo';

  @override
  String get overviewComplete => 'Resumen general completado';

  @override
  String get doneSummarizing => 'Resumen completado';

  @override
  String get loadingSchedule => 'Cargando datos de la agenda';

  @override
  String get fetchingSchedule => 'Obteniendo tu agenda';

  @override
  String get retrievingCalendar => 'Recuperando calendario';

  @override
  String get loadingTimeline => 'Cargando la línea de tiempo';

  @override
  String get optimizingSchedule => 'Optimizando la agenda';

  @override
  String get reorganizingDay => 'Reorganizando tu día';

  @override
  String get findingBestFit => 'Buscando el mejor encaje';

  @override
  String get adjustingTimeline => 'Ajustando la línea de tiempo';

  @override
  String get scheduleComplete => 'Optimización de la agenda completada';

  @override
  String get scheduleUpdated => 'Agenda actualizada';

  @override
  String get timelineOptimized => 'Línea de tiempo optimizada';

  @override
  String get allDone => 'Todo hecho';

  @override
  String get connectionLost => 'Conexión perdida. Actualiza';

  @override
  String get sendingRequest => 'Enviando solicitud';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'Conexión WebSocket perdida después de 5 intentos';

  @override
  String get webSocketMessageHandlingError => 'Error al procesar el mensaje';

  @override
  String get jsonParseError => 'Error de análisis JSON';

  @override
  String get processError => 'Error de proceso';

  @override
  String get socketConnectionError => 'Error de conexión de socket';

  @override
  String get keepAliveFailed => 'Error al mantener la conexión activa';

  @override
  String get copy => 'Copiar';

  @override
  String get entityIdNotFound => 'No se encontró id de entidad de vista previa';

  @override
  String get feedback => 'Comentarios';

  @override
  String get feedbackCategory => 'Categoría';

  @override
  String get feedbackCategoryBug => 'Error';

  @override
  String get feedbackCategoryFeature => 'Funcionalidad';

  @override
  String get feedbackCategoryEnhancement => 'Mejora';

  @override
  String get feedbackCategoryGeneral => 'General';

  @override
  String get feedbackTitle => 'Título';

  @override
  String get feedbackTitleHint => 'Resumen breve de tus comentarios';

  @override
  String get feedbackDescription => 'Descripción';

  @override
  String get feedbackDescriptionHint =>
      'Proporciona detalles sobre tus comentarios';

  @override
  String get feedbackSubmitted => 'Comentarios enviados con éxito';

  @override
  String get feedbackError => 'Error al enviar los comentarios';

  @override
  String get noPreviewsAvailable =>
      'No hay TileCasts disponibles para esta solicitud';

  @override
  String get previewUnavailable =>
      'El TileCast seleccionado no está disponible';

  @override
  String get previewSummaryUnavailable => 'No se pudo cargar el TileCast';

  @override
  String get previewGenerating => 'Generando TileCast…';

  @override
  String get previewTimedOut =>
      'El TileCast está tardando más de lo esperado. Intenta de nuevo en un momento.';

  @override
  String get previewGenerationFailed => 'No pudimos generar este TileCast.';

  @override
  String get previewInvalidated =>
      'Este TileCast ya no es válido porque tu agenda cambió.';

  @override
  String get previewStaleBanner =>
      'Este TileCast refleja una instantánea anterior de tu agenda.';

  @override
  String get previewNonViableLabel => 'No se pudo programar';

  @override
  String get reviewChanges => 'Revisar cambios';

  @override
  String get previewRetry => 'Reintentar';

  @override
  String get previewPreparing => 'Preparando TileCast…';

  @override
  String get previewReadyToView => 'Toca para ver el TileCast';

  @override
  String get previewActionsOutdated =>
      'Desactualizado — envía un nuevo mensaje';

  @override
  String get previewActionsUnavailable => 'TileCast no disponible';

  @override
  String get tileCastStaleNote =>
      'Tu agenda cambió — este TileCast puede estar desactualizado';

  @override
  String get tileCastAlsoIncluded => 'También incluido';

  @override
  String actionsCount(int count) {
    return '$count acciones';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'Cargando notas…';

  @override
  String get notesSaving => 'Guardando…';

  @override
  String get notesSaved => 'Guardado';

  @override
  String get notesUnsaved => 'Editando…';

  @override
  String get notesSaveError => 'No se pudo guardar';

  @override
  String get notesSaveNow => 'Guardar ahora';

  @override
  String get notesShowPreview => 'Vista previa';

  @override
  String get notesShowEditor => 'Editar';

  @override
  String get notesPreviewEmpty => 'Nada para previsualizar todavía.';

  @override
  String get notesLinkPromptTitle => 'Insertar enlace';

  @override
  String get notesConflictTitle => 'Alguien más actualizó esta nota.';

  @override
  String get notesConflictDiscardMine => 'Descartar la mía';

  @override
  String get notesConflictKeepEditing => 'Seguir editando';

  @override
  String get notesToolBold => 'Negrita';

  @override
  String get notesToolItalic => 'Cursiva';

  @override
  String get notesToolStrikethrough => 'Tachado';

  @override
  String get notesToolInlineCode => 'Código en línea';

  @override
  String get notesToolHeading1 => 'Título 1';

  @override
  String get notesToolHeading2 => 'Título 2';

  @override
  String get notesToolBulletList => 'Lista con viñetas';

  @override
  String get notesToolNumberedList => 'Lista numerada';

  @override
  String get notesToolTaskList => 'Lista de tareas';

  @override
  String get notesToolQuote => 'Cita';

  @override
  String get notesToolLink => 'Enlace';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesViewerTitle => 'Nota';

  @override
  String get notesTapToAdd => 'Toca para añadir una nota';

  @override
  String get notesTapToEdit => 'Toca para editar · mantén presionado para leer';

  @override
  String get notesDone => 'Listo';

  @override
  String get endOfDay => 'Fin del día';

  @override
  String get search => 'Buscar';

  @override
  String get share => 'Compartir';

  @override
  String get openChat => 'Abrir chat';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get switchCalendarView => 'Cambiar vista de calendario';

  @override
  String get switchDayGridLayout => 'Cambiar diseño del día';

  @override
  String get openDayRibbon => 'Ver días';

  @override
  String get previewSundialGreeting => 'Hola.';

  @override
  String get previewSundialCountsPrefix => 'Hoy tienes';

  @override
  String get previewSundialCountsSuffix => 'por delante.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count tiles';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count bloques';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count tileshares';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours horas de trabajo';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins min en tránsito';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'tu día termina a las $time';
  }

  @override
  String get previewSundialAndSeparator => 'y';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance $unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$count lugares';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '$hours h de sueño';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '$hours h libres';
  }

  @override
  String get previewSundialFullyBooked => 'Todo reservado';

  @override
  String get previewSundialTier0 => 'Día libre';

  @override
  String get previewSundialTier1 => 'Empezando';

  @override
  String get previewSundialTier2 => 'En curso';

  @override
  String get previewSundialTier3 => 'Buen avance';

  @override
  String get previewSundialTier4 => 'Casi listo';

  @override
  String get previewSundialTodayLabel => 'Hoy';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles tiles, $blocks bloques, $nonViable sin programar';
  }

  @override
  String get timelineClearHeading => 'Tu agenda está despejada hoy';

  @override
  String get timelineClearAddTask => 'Añadir tile';

  @override
  String get aiConsentTitle => 'Descubre Tiler AI';

  @override
  String get aiConsentSubtitle => 'Tu asistente de planificación con IA';

  @override
  String get aiConsentIntro =>
      'Para convertir tus palabras en un horario, Tiler AI comparte lo que envías con proveedores de IA de confianza.';

  @override
  String get aiConsentDataTitle => 'Qué enviamos';

  @override
  String get aiConsentDataBody =>
      'Los mensajes y grabaciones de voz que envías, además de detalles relevantes de tu agenda.';

  @override
  String get aiConsentProvidersTitle => 'Quién lo recibe';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini y OpenAI, nuestros proveedores de IA externos.';

  @override
  String get aiConsentPrivacyLink => 'Lee nuestra Política de Privacidad';

  @override
  String get aiConsentContinue => 'Continuar a Tiler AI';

  @override
  String get aiConsentAgreementNotice =>
      'Al continuar, aceptas compartir estos datos con Google Gemini y OpenAI como se describe arriba.';

  @override
  String get aiConsentClose => 'Cerrar';

  @override
  String get legalFooterPrefix => 'Al continuar, aceptas los';

  @override
  String get legalFooterTerms => 'Términos';

  @override
  String get legalFooterAnd => 'y la';

  @override
  String get legalFooterPrivacy => 'Privacidad';

  @override
  String get aiConsentLinkError => 'No se pudo abrir el enlace.';

  @override
  String get addTileScreenTitleFlexible => 'Agregar Tile';

  @override
  String get addTileScreenTitleFixed => 'Agregar bloque';

  @override
  String get addTileTypeFlexible => 'Tile flexible';

  @override
  String get addTileTypeFixed => 'Bloque fijo';

  @override
  String get addTileTypeSelectorLabel => 'Tipo de Tile';

  @override
  String addTileExplanationFlexible(String emphasis) {
    return 'Tiler encontrará el $emphasis para esto.';
  }

  @override
  String addTileExplanationFixed(String emphasis) {
    return 'Los bloques ocurren a $emphasis.';
  }

  @override
  String get addTileFindTime => 'Buscar horario';

  @override
  String get addTileSubmitting => 'Enviando';

  @override
  String get addTileNameRequired => 'El nombre es obligatorio';

  @override
  String get addTileTitleRequired => 'El título es obligatorio';

  @override
  String get addTileFieldTaskName => 'NOMBRE DE LA TAREA';

  @override
  String get addTileFieldTitle => 'TÍTULO';

  @override
  String get addTileFieldDuration => 'DURACIÓN';

  @override
  String get addTileFieldCompleteBy => 'COMPLETAR ANTES DE';

  @override
  String get addTileFieldPreferredTime => 'HORARIO PREFERIDO';

  @override
  String get addTileFieldDate => 'FECHA';

  @override
  String get addTileFieldStarts => 'COMIENZA';

  @override
  String get addTileFieldEnds => 'TERMINA';

  @override
  String get addTileFieldLocation => 'UBICACIÓN';

  @override
  String get addTileTaskNameHint => '¿Qué quieres hacer?';

  @override
  String get addTileBlockTitleHint => '¿Qué es este bloque?';

  @override
  String get addTileValueNotSet => 'Sin definir';

  @override
  String get addTileAutoCalculated => 'Calculado automáticamente';

  @override
  String addTileEndsSemantics(String time) {
    return 'Termina a las $time, calculado a partir del inicio y la duración';
  }

  @override
  String addTileTodayDate(String date) {
    return 'Hoy, $date';
  }

  @override
  String get addTileMoreOptions => 'Más opciones';

  @override
  String get addTilePriority => 'Prioridad';

  @override
  String get addTilePriorityLow => 'Baja';

  @override
  String get addTilePriorityMedium => 'Media';

  @override
  String get addTilePriorityHigh => 'Alta';

  @override
  String get addTilePriorityLowMeaning => 'Estaría bien';

  @override
  String get addTilePriorityMediumMeaning => 'Importante';

  @override
  String get addTilePriorityHighMeaning => 'Debe completarse';

  @override
  String get addTilePriorityHelper =>
      'La prioridad ayuda a Tiler a decidir qué proteger primero.';

  @override
  String get addTileColorAutomatic => 'Automático';

  @override
  String get addTileColorCustom => 'Personalizado';

  @override
  String get addTileSplitIntoSessions => 'Dividir en sesiones';

  @override
  String get addTileSplitHelper =>
      'Divide esto en sesiones de trabajo separadas.';

  @override
  String addTileSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0';
  }

  @override
  String get addTileFewerSessions => 'Menos sesiones';

  @override
  String get addTileMoreSessions => 'Más sesiones';

  @override
  String get addTileFlexibleCompletion => 'Fecha de finalización flexible';

  @override
  String get addTileFlexibleCompletionHelper =>
      'Tiler puede mover esta fecha ligeramente si es necesario.';

  @override
  String get addTilePreferredTimeCustom => 'Personalizado';

  @override
  String addTileDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String addTileDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String addTileDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get addTileRepeat => 'Repetir';

  @override
  String get addTileRepeatNever => 'No se repite';

  @override
  String get addTileRepeatDays => 'DÍAS';

  @override
  String get addTileRepeatsUntil => 'SE REPITE HASTA';

  @override
  String get addTileRepeatHelper =>
      'Repetir ayuda a Tiler a programar tareas recurrentes.';

  @override
  String get addTileLocationSearchHint => 'Buscar ubicaciones';

  @override
  String get addTileLocationYourPlaces => 'TUS LUGARES';

  @override
  String get addTileLocationSuggestions => 'SUGERENCIAS';

  @override
  String get addTileLocationHelper =>
      'La ubicación ayuda a Tiler a optimizar el trayecto y los horarios.';

  @override
  String get addTileLocationNoneSaved => 'Aún no tienes lugares guardados';

  @override
  String get addTileLocationNoneSavedHelper =>
      'Busca un lugar o escribe un nombre como \"taller de bicis\" para guardarlo.';

  @override
  String get addTileLocationNoResults => 'No se encontraron lugares';

  @override
  String get addTileLocationNoResultsHelper =>
      'Aun así puedes guardar lo que escribiste como nombre del lugar.';

  @override
  String get addTileLocationSearchFailed => 'No se pudo buscar en este momento';

  @override
  String get addTileLocationSearchFailedHelper =>
      'Revisa tu conexión e inténtalo de nuevo, o guarda lo que escribiste como nombre del lugar.';

  @override
  String addTileLocationUseTyped(String query) {
    return 'Usar \"$query\"';
  }

  @override
  String get addTileLocationUseTypedHelper => 'Dale un nombre y una dirección';

  @override
  String get addTileLocationFallbackName => 'Ubicación';

  @override
  String get addTilePlaceAdd => 'Agregar lugar';

  @override
  String get addTilePlaceEdit => 'Editar lugar';

  @override
  String get addTilePlaceName => 'NOMBRE';

  @override
  String get addTilePlaceAddress => 'DIRECCIÓN';

  @override
  String get addTilePlaceNameHint => 'p. ej. Walmart cerca del trabajo';

  @override
  String get addTilePlaceAddressHint => 'Calle, ciudad, estado';

  @override
  String get addTilePlaceSave => 'Guardar lugar';

  @override
  String get addTilePlaceNameThis => 'Nombrar este lugar';

  @override
  String get addTilePlaceNameHelper =>
      'El nombre es la forma de volver a encontrar este lugar. Si nombras dos lugares igual, solo se conserva la dirección más reciente.';

  @override
  String addTilePlaceNameTaken(String name, String address) {
    return 'Ya tienes un lugar llamado \"$name\" en $address. Al guardar, ese nombre pasará a esta dirección.';
  }

  @override
  String addTilePlaceNameTakenNoAddress(String name) {
    return 'Ya tienes un lugar llamado \"$name\". Al guardar, ese nombre pasará a esta dirección.';
  }

  @override
  String get addTileFieldPriority => 'PRIORIDAD';

  @override
  String get addTileFieldColor => 'COLOR';

  @override
  String get addTileColorPresets => 'PREDEFINIDOS';

  @override
  String get addTileColorAutomaticHelper => 'Tiler elige un color por ti';

  @override
  String get addTileColorCustomHelper => 'Elige cualquier color';

  @override
  String get addTileColorHelper =>
      'El color solo cambia cómo se ve esto en tu agenda.';

  @override
  String get addTileColorShuffle => 'Probar otro color';

  @override
  String addTileColorSwatch(int index) {
    return 'Color $index';
  }

  @override
  String get addTileExplanationFlexibleEmphasis => 'mejor momento';

  @override
  String get addTileExplanationFixedEmphasis => 'una hora fija';

  @override
  String get addTileFieldRepeat => 'REPETIR';

  @override
  String get addTileDurationQuick => 'RÁPIDO';

  @override
  String get addTileDurationCustom => 'PERSONALIZADO';

  @override
  String get addTileDurationHourLabel => 'Hora';

  @override
  String get addTileDurationMinuteLabel => 'Min';

  @override
  String addTileDurationEndsFromStart(String start) {
    return 'DESDE $start';
  }

  @override
  String addTileDurationEndsNextDay(String time) {
    return '$time, día siguiente';
  }

  @override
  String addTileDurationEndsSemantics(String end, String start) {
    return 'Termina a las $end, desde un inicio a las $start. Cambiar la hora de fin';
  }

  @override
  String get editTileTitleTile => 'Editar tile';

  @override
  String get editTileTitleBlock => 'Editar bloque';

  @override
  String get editTileSave => 'Guardar cambios';

  @override
  String get editTileSaving => 'Guardando…';

  @override
  String get editTileSectionTiming => 'HORARIO';

  @override
  String get editTileReasonNameRequired =>
      'Ponle un título a este tile para guardarlo';

  @override
  String get editTileReasonSplitRequired => 'Las sesiones deben ser al menos 1';

  @override
  String get editTileReasonEndNotAfterStart =>
      'El fin debe ser después del inicio';

  @override
  String get editTileDiscardTitle => '¿Descartar cambios?';

  @override
  String get editTileDiscardBody => 'Se perderán tus cambios a este tile.';

  @override
  String get editTileDiscard => 'Descartar';

  @override
  String get editTileKeepEditing => 'Seguir editando';

  @override
  String get editTileLoadFailed => 'No se pudo cargar este tile.';

  @override
  String get editTileSaveFailed =>
      'No se pudo guardar en este momento. Tus cambios se conservan.';

  @override
  String get editTileSectionActions => 'ACCIONES';

  @override
  String get editTileSectionSessions => 'SESIONES';

  @override
  String get editTileFieldSessions => 'Dividir en sesiones';

  @override
  String get editTileFieldDeadline => 'FECHA LÍMITE';

  @override
  String get editTileSectionAdditional => 'DETALLES ADICIONALES';

  @override
  String get editTileSectionSuggestions => 'SUGERENCIAS';

  @override
  String get editTileCreateAsNewTile => 'Crear como tile nuevo';

  @override
  String get editTileSectionProgress => 'PROGRESO';

  @override
  String editTileProgressComplete(int done, int total) {
    return '$done de $total completados';
  }

  @override
  String editTileProgressRemaining(int remaining, int deleted) {
    return '$remaining restantes · $deleted eliminados';
  }

  @override
  String get editTileActionComplete => 'Completar';

  @override
  String get editTileActionCompleteCaption => 'Marcar como hecho';

  @override
  String get editTileActionStartNow => 'Empezar ahora';

  @override
  String get editTileActionStartNowCaption => 'Mover a ahora';

  @override
  String get editTileActionDefer => 'Posponer';

  @override
  String get editTileActionDeferCaption => 'Elegir otra hora';

  @override
  String get editTileActionDelete => 'Eliminar';

  @override
  String get editTileActionDeleteCaption => 'Quitar';

  @override
  String editTileActionConfirmComplete(String title) {
    return '¿Marcar \"$title\" como hecho?';
  }

  @override
  String editTileActionConfirmStartNow(String title) {
    return '¿Mover \"$title\" a ahora?';
  }

  @override
  String editTileActionConfirmDefer(String title) {
    return '¿Posponer \"$title\"?';
  }

  @override
  String editTileActionConfirmDelete(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get editTileActionDeleteBody => 'Esto quita el tile de tu agenda.';

  @override
  String get editTileActionDiscardsEdits =>
      'Se descartarán tus cambios sin guardar.';

  @override
  String get editTileActionFailed => 'No se pudo hacer eso en este momento.';

  @override
  String editTileActionSemantics(String label, String caption) {
    return '$label, $caption';
  }

  @override
  String get editTileSectionRepetition => 'REPETICIÓN';

  @override
  String get editTileSectionPriority => 'PRIORIDAD';

  @override
  String get editTileSectionLocation => 'UBICACIÓN';

  @override
  String get editTileLocationRemove => 'Quitar ubicación';

  @override
  String get addTileDeadlineClear => 'Quitar fecha límite';

  @override
  String get editTileMenuTileDetails => 'Detalles del tile';

  @override
  String get editTileMoreMenu => 'Más';

  @override
  String get editTileRepeatEveryDay => 'Cada día';

  @override
  String get editTileRepeatEveryWeek => 'Cada semana';

  @override
  String editTileRepeatEveryWeekOn(String days) {
    return 'Cada semana los $days';
  }

  @override
  String get editTileRepeatEveryMonth => 'Cada mes';

  @override
  String get editTileRepeatEveryYear => 'Cada año';

  @override
  String editTileRepeatUntil(String cadence, String date) {
    return '$cadence · hasta el $date';
  }

  @override
  String editTileRepeatUntilDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String editTileRepeatNeverEnds(String cadence) {
    return '$cadence · sin fin';
  }

  @override
  String get editTileRepeatCalloutTitle => 'Esto creará varias repeticiones';

  @override
  String get editTileRepeatCalloutBody =>
      'Tiler programará cada repetición según tus preferencias y disponibilidad.';

  @override
  String get editTileNotesTitle => 'Notas';

  @override
  String get editTileModeReadOnly =>
      'Este tile ya terminó, así que no se puede editar. Aún puedes eliminarlo.';

  @override
  String get editTileModeProcrastinate =>
      'Tiempo bloqueado. Muévelo, márcalo como hecho o elimínalo.';

  @override
  String editTileModeThirdParty(String provider) {
    return 'Gestionado por $provider. Responde a la invitación o elimínalo aquí; edita el evento en $provider.';
  }

  @override
  String get editTileProviderGoogle => 'Google Calendar';

  @override
  String get editTileProviderOutlook => 'Outlook';

  @override
  String get editTileRsvpFailed =>
      'No se pudo enviar tu respuesta en este momento.';

  @override
  String get editTileWhatIfChecking => 'Revisando qué afecta este cambio…';

  @override
  String editTileWhatIfSummary(int late, int overflow) {
    return 'Afecta a otros tiles: $late tarde, $overflow desbordados';
  }

  @override
  String get editTileWhatIfSheetTitle => 'Qué afecta este cambio';

  @override
  String get editTileWhatIfLate => 'Tarde';

  @override
  String get editTileWhatIfOverflow => 'Desbordados';

  @override
  String get editTileWhatIfClean => 'No afecta a ningún otro tile.';

  @override
  String get editTileWhatIfFailed =>
      'No se pudo revisar el efecto en tu agenda.';

  @override
  String get editTileWhatIfRetry => 'Reintentar';

  @override
  String get editTileEditTitle => 'Editar título';

  @override
  String get tileDetailTitle => 'Detalles del tile';

  @override
  String get tileDetailLoadFailed =>
      'No se pudieron cargar los detalles de este tile.';

  @override
  String get tileDetailSaveFailed =>
      'No se pudo guardar ahora. Tus cambios se conservan.';

  @override
  String get tileDetailDeleteSeries => 'Eliminar tile';

  @override
  String tileDetailDeleteConfirm(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get tileDetailDeleteBody =>
      'Se eliminarán todas las repeticiones de este tile de tu agenda.';

  @override
  String get tileDetailDeleteFailed => 'No se pudo eliminar ahora.';

  @override
  String get tileDetailSectionOccurrences => 'REPETICIONES';

  @override
  String get tileDetailOccurrencesEmpty =>
      'Aún no hay repeticiones programadas.';

  @override
  String get tileDetailOccurrencesFailed =>
      'No se pudieron cargar las repeticiones.';

  @override
  String get tileDetailOccurrencesEarlier => 'Ver anteriores';

  @override
  String get tileDetailOccurrencesLater => 'Ver siguientes';

  @override
  String get tileDetailOccurrenceDone => 'Hecho';

  @override
  String tileDetailOccurrenceSemantics(String day, String span, String done) {
    return '$day, $span$done';
  }

  @override
  String editTileTimeChipSemantics(String field, String value) {
    return 'Hora de $field, $value';
  }

  @override
  String editTileDateChipSemantics(String field, String value) {
    return 'Fecha de $field, $value';
  }

  @override
  String get addTileSubmitFailed =>
      'No se pudo agregar en este momento. Tus datos se guardaron.';

  @override
  String get addTileRetry => 'Reintentar';

  @override
  String searchResultsForQuery(int count, String query) {
    return '$count resultados para \"$query\"';
  }

  @override
  String get searchFilterAll => 'Todos';

  @override
  String get searchFilterTiler => 'Tiler';

  @override
  String get searchFilterGoogle => 'Google';

  @override
  String get searchFilterOutlook => 'Outlook';

  @override
  String get startNow => 'Empezar ahora';

  @override
  String dueOnDate(String date) {
    return 'Vence $date';
  }

  @override
  String get noResultsForProvider => 'No hay resultados de este calendario';

  @override
  String get readOnly => 'Solo lectura';

  @override
  String get productTourStarting =>
      'Tu recorrido por la app está a punto de comenzar.';
}
