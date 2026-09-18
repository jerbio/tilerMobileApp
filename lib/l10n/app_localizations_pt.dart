// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Adicionar';

  @override
  String get setupCustomRestrictions => 'Configurar restrições personalizadas';

  @override
  String get customRestrictionTitle => 'Restrições personalizadas';

  @override
  String get customRestrictionHeader => 'Configurar restrições personalizadas';

  @override
  String get customRestrictionHeaderDescription =>
      'Selecione quando deseja concluir esta tarefa.';

  @override
  String get day => 'Dia';

  @override
  String get hour => 'Hora';

  @override
  String get min => 'Min';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get duration => 'Duração';

  @override
  String get durationStar => 'Duração*';

  @override
  String get addTile => 'Adicionar bloco';

  @override
  String get defer => 'Adiar';

  @override
  String get deferAll => 'Adiar tudo';

  @override
  String get procrastinating => 'A procrastinar';

  @override
  String get forecast => 'Previsão';

  @override
  String get whenQ => 'Quando?';

  @override
  String get loading => 'A carregar';

  @override
  String get loadingPrediction => 'A carregar previsão';

  @override
  String get address => 'Morada';

  @override
  String get settings => 'Definições';

  @override
  String get nickName => 'Nome de utilizador';

  @override
  String get deadline_anytime => 'Prazo(Quando quiser)';

  @override
  String get selectADeadline => 'Selecionar um prazo';

  @override
  String get close => 'Fechar';

  @override
  String get tileName => 'Nome do bloco';

  @override
  String get tileNameStar => 'Nome do bloco*';

  @override
  String get starAreRequired => '* são campos obrigatórios';

  @override
  String get howManyTimes => 'Quantas vezes';

  @override
  String get once => 'Uma vez';

  @override
  String get weekdaysAndWorkHours => 'Dias de semana e horas de trabalho';

  @override
  String get weekend => 'Fim de semana';

  @override
  String get anytime => 'Quando quiser';

  @override
  String get repetition => 'Repetição';

  @override
  String get reminder => 'Lembrete';

  @override
  String get restriction => 'Restrição';

  @override
  String get username => 'Nome de utilizador';

  @override
  String get usernameOrEmail => 'Nome de utilizador ou email';

  @override
  String get password => 'Palavra-passe';

  @override
  String get email => 'Email';

  @override
  String get back => 'Voltar';

  @override
  String get confirmPassword => 'Confirmar palavra-passe';

  @override
  String get passwordIsRequired => 'A palavra-passe é obrigatória';

  @override
  String get emailIsRequired => 'O email é obrigatório';

  @override
  String get fieldIsRequired => 'Este campo é obrigatório';

  @override
  String get signingIn => 'A iniciar sessão';

  @override
  String get signInWithEmailCode => 'Iniciar sessão com código de email';

  @override
  String get sendAccessCode => 'Enviar código de acesso';

  @override
  String get continueBtn => 'Continuar';

  @override
  String get usePasswordInstead => 'Usar palavra-passe em vez disso';

  @override
  String get useAccessCodeInstead => 'Usar código de acesso em vez disso';

  @override
  String get registeringUser => 'A registar utilizador';

  @override
  String get sendVerificationCode => 'Enviar código de verificação';

  @override
  String get verificationCodeSent =>
      'Código de verificação enviado para o seu email.';

  @override
  String get verificationCode => 'Código de verificação';

  @override
  String get verifyCode => 'Verificar código';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get verifyingCode => 'A verificar código';

  @override
  String get invalidVerificationCode =>
      'Código de verificação inválido ou expirado.';

  @override
  String get accessCodeRequiresEmail =>
      'A iniciação de sessão com código de acesso requer um endereço de email.';

  @override
  String get emailCodeInstructions =>
      'Indique o seu email e enviaremos-lhe um código de verificação.';

  @override
  String verificationCodeInstructions(String email) {
    return 'Indique o código de verificação enviado para $email.';
  }

  @override
  String get confirmPasswordRequired =>
      'A palavra-passe de confirmação é obrigatória';

  @override
  String get passwordsDontMatch =>
      'A palavra-passe e a confirmação não coincidem';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters =>
      'A palavra-passe deve ter pelo menos 7 caracteres';

  @override
  String get passwordNeedsToHaveUpperCaseChracters =>
      'A palavra-passe deve ter uma letra maiúscula';

  @override
  String get passwordNeedsToHaveLowerCaseChracters =>
      'A palavra-passe deve ter uma letra minúscula';

  @override
  String get passwordNeedsToHaveNumber => 'A palavra-passe deve ter um número';

  @override
  String get passwordNeedsToHaveASpecialCharacter =>
      'A palavra-passe deve ter pelo menos 1 caractere especial';

  @override
  String get enableLocations => 'Ativar permissões de localização';

  @override
  String get noMatchWasFound => 'Nenhum resultado encontrado';

  @override
  String get atLeastThreeLettersForLookup =>
      '…O Tiler precisa de três caracteres para a pesquisa';

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
      'Não foi possível pesquisar alguns calendários.';

  @override
  String get searchUnavailableMessage =>
      'A pesquisa está temporariamente indisponível. Tente novamente.';

  @override
  String get searchRetry => 'Tentar novamente';

  @override
  String get noLocationMatchWasFound =>
      'Nenhuma correspondência de localização encontrada';

  @override
  String get noLocation => 'Sem localização';

  @override
  String get clearedColon => 'Limpo: ';

  @override
  String get complete => 'Concluído';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get now => 'Agora';

  @override
  String get color => 'Cor';

  @override
  String get pickAColor => 'Escolher uma cor';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Retomar';

  @override
  String get play => 'Reproduzir';

  @override
  String get successfullyPaused => 'Pausado com sucesso';

  @override
  String get successfullyResumed => 'Retomado com sucesso';

  @override
  String get successfullyCompleted => 'Concluído com sucesso';

  @override
  String get completed => 'Concluído';

  @override
  String get deleted => 'Eliminado';

  @override
  String get scheduled => 'Agendado';

  @override
  String get movedUpToNow => 'A mover para agora';

  @override
  String get pausing => 'A pausar';

  @override
  String get resuming => 'A retomar';

  @override
  String get movingUp => 'A mover o seu bloco para cima';

  @override
  String get completing => 'A concluir';

  @override
  String get deleting => 'A eliminar';

  @override
  String get deleteBlockConfirming => 'A eliminar este compromisso...';

  @override
  String get deleteTileConfirming => 'A eliminar este bloco...';

  @override
  String get deleteNow => 'Eliminar agora';

  @override
  String get deleteGoogleWarning =>
      '⚠️ Isto também eliminará do Google Calendar';

  @override
  String get deleteOutlookWarning => '⚠️ Isto também eliminará do Outlook';

  @override
  String get previously => 'Anteriormente';

  @override
  String get upcoming => 'Próximos';

  @override
  String get failedToSendRequest => 'Falha ao enviar o pedido';

  @override
  String get revise => 'Rever';

  @override
  String get revisingSchedule => 'A rever a agenda';

  @override
  String get procrastinateBlockOut => 'Pausa de bloco';

  @override
  String get lunchBreak => 'Pausa do almoço';

  @override
  String get coffeeBreak => 'Pausa para o café';

  @override
  String get morningBreak => 'Pausa da manhã';

  @override
  String get afternoonBreak => 'Pausa da tarde';

  @override
  String get freeTime => 'Tempo livre';

  @override
  String get freeSlotHeader => 'Tempo livre';

  @override
  String get freeSlotNow => 'Livre agora';

  @override
  String get quickBreak => 'Pausa rápida';

  @override
  String get shortBreak => 'Pausa curta';

  @override
  String get blockedTime => 'Tempo bloqueado';

  @override
  String get start => 'Início';

  @override
  String get end => 'Fim';

  @override
  String get deadline => 'Prazo';

  @override
  String get split => 'Dividir';

  @override
  String get timeBlocks => 'Blocos de tempo';

  @override
  String get swipeRightToTileIt => 'Deslize para a direita para planejar';

  @override
  String get failedToReviseScheduleRequest =>
      'Falha ao rever a solicitação da agenda';

  @override
  String get daily => 'Diário';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensal';

  @override
  String get yearly => 'Anual';

  @override
  String get none => 'Nenhum';

  @override
  String get noneNotificationCategory => 'Padrão';

  @override
  String get nextTileNotificationCategory => 'Próximo bloco';

  @override
  String get userSetReminderNotificationCategory =>
      'Lembrete definido pelo utilizador';

  @override
  String get depatureTimeNotificationCategory => 'Hora de partida';

  @override
  String get tile => 'Bloco';

  @override
  String get appointment => 'Bloco';

  @override
  String startingAtTime(String time) {
    return 'Começa às $time';
  }

  @override
  String endsAtTime(String time) {
    return 'Termina às $time';
  }

  @override
  String get startsInTenMinutes => 'Começa em dez minutos';

  @override
  String get endsInTenMinutes => 'Termina em cinco minutos';

  @override
  String startsInDuration(String duration) {
    return 'Começa em $duration';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName está por terminar';
  }

  @override
  String get home => 'Casa';

  @override
  String get work => 'Trabalho';

  @override
  String get googleLogo => 'Logótipo do Google';

  @override
  String get edit => 'Editar';

  @override
  String get workProfileHours => 'Horas de trabalho';

  @override
  String get personalHours => 'Horas pessoais';

  @override
  String get setWorkProfileHours => 'Definir horas de trabalho';

  @override
  String get setPersonalHours => 'Definir horas pessoais';

  @override
  String get customHours => 'Horas personalizadas';

  @override
  String get logout => 'Terminar sessão';

  @override
  String get noteEllipsis => 'Nota...';

  @override
  String get tapToCreateNewTile => 'Toque para criar um novo bloco';

  @override
  String get emptyDayHeaderLine1 => 'Ainda sem planos.';

  @override
  String get emptyDayFooterLine1 => 'Comece em segundos';

  @override
  String get emptyDayFooterLine2 => 'importe calendários ou crie blocos.';

  @override
  String get emptyDayOr => 'ou';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Importar Google Calendar';

  @override
  String get suggestions => 'Sugestões';

  @override
  String get progress => 'Progresso';

  @override
  String get youNeedToLeaveIn => 'Tem de sair em';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return 'Tem de sair em $duration';
  }

  @override
  String durationLate(String duration) {
    return 'Atrasado em $duration';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return 'Decorrido $duration atrás';
  }

  @override
  String completedDurationAgo(String duration) {
    return 'Concluído $duration atrás';
  }

  @override
  String durationLeft(String duration) {
    return 'Restam $duration';
  }

  @override
  String get issuesConnectingToTiler => 'Problemas ao ligar ao Tiler';

  @override
  String completedCount(String count) {
    return 'Concluídos ($count)';
  }

  @override
  String deletedCount(String count) {
    return 'Eliminados ($count)';
  }

  @override
  String tiledCount(String count) {
    return 'Blocos restantes ($count)';
  }

  @override
  String countTile(String count) {
    return '$count blocos';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number blocos selecionados';
  }

  @override
  String get completeTiles => 'Concluir blocos';

  @override
  String get thisFitsInYourSchedule => 'Isto cabe na sua agenda.';

  @override
  String get warningColon => 'Aviso: ';

  @override
  String get oneEventAtRisk => '1 evento em risco';

  @override
  String countEventAtRisk(String number) {
    return '$number eventos em risco';
  }

  @override
  String get oneConflict => '1 conflito';

  @override
  String countConflict(String number) {
    return '$number conflitos';
  }

  @override
  String get create => 'Criar';

  @override
  String get thisEventWouldCause => 'Este evento causaria ';

  @override
  String errorMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get unScheduledTiles => 'Blocos não agendados';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number blocos não agendados';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number mais';
  }

  @override
  String get unScheduled => 'Não agendado';

  @override
  String get allScheduled => 'Tudo agendado';

  @override
  String get getOnIt => 'Mãos à obra';

  @override
  String get done => 'Concluído';

  @override
  String get late => 'Atrasado';

  @override
  String get onTime => 'A tempo';

  @override
  String get todayStatusPlacedTitle => 'Colocado com sucesso';

  @override
  String get todayStatusAttentionTitle => 'Precisa de atenção';

  @override
  String get todayStatusLateTitle => 'Atrasado';

  @override
  String get todayStatusAttentionHelper =>
      'Estes não couberam no tempo disponível de hoje.';

  @override
  String get todayStatusLateHelper =>
      'O tempo de deslocação entre estes e os blocos à sua volta faz com que não consiga chegar a horas.';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocos',
      one: '1 bloco',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Blocos concluídos',
      one: 'Bloco concluído',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => 'Precisa de atenção';

  @override
  String get todayStatusTilesRunningLate => 'Atrasado';

  @override
  String get todayStatusEverythingOnTrack => 'Tudo está no prazo';

  @override
  String get todayStatusEverythingElseOnTrack => 'Tudo o resto está no prazo';

  @override
  String get todayStatusOnTrackSubcopy =>
      'Nenhum bloco agendado está atrasado.';

  @override
  String get todayStatusClearDay => 'O seu dia está livre.';

  @override
  String get todayStatusPreviewCta => 'Pré-visualizar um plano melhor';

  @override
  String get todayStatusPreviewLoading => 'A preparar a pré-visualização…';

  @override
  String get todayStatusPreviewUnavailable =>
      'Não foi possível gerar a pré-visualização. O seu plano mantém-se inalterado.';

  @override
  String get todayStatusUntitledTile => 'Bloco sem título';

  @override
  String get todayStatusShowAll => 'Mostrar tudo';

  @override
  String todayStatusExpandSection(String section) {
    return 'Expandir $section';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return 'Recolher $section';
  }

  @override
  String get todayStatusReasonDueToday => 'Prazo hoje';

  @override
  String get todayStatusReasonNoOpenSlot => 'Sem período disponível';

  @override
  String get todayStatusReasonTravelInfeasible =>
      'A deslocação torna isso inviável';

  @override
  String get todayStatusReasonOutsideHours => 'Fora das horas disponíveis';

  @override
  String get todayStatusReasonDependencyBlocked => 'A aguardar outro bloco';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return 'Precisa de $duration';
  }

  @override
  String get todayStatusReasonManualHold => 'Precisa da sua decisão';

  @override
  String get todayStatusReasonUnknown => 'Não coube';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões',
      one: '1 sessão',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'Selecionar blocos';

  @override
  String todayStatusExpandGroup(String title) {
    return 'Expandir as sessões de $title';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return 'Recolher as sessões de $title';
  }

  @override
  String get analysis => 'Análise';

  @override
  String get noDataAvailable => 'Sem dados disponíveis';

  @override
  String get sleep => 'Sono';

  @override
  String get overview => 'Visão geral';

  @override
  String get driveTime => 'Tempo de condução';

  @override
  String get signUpWithGoogle => 'Iniciar sessão com o Google';

  @override
  String get signUpWithApple => 'Iniciar sessão com a Apple';

  @override
  String get signUpWithMicrosoft => 'Iniciar sessão com a Microsoft';

  @override
  String get signIn => 'Iniciar sessão';

  @override
  String get signUp => 'Registar';

  @override
  String get invalidUsernameOrPassword =>
      'Nome de utilizador ou palavra-passe inválidos';

  @override
  String get noInternetConnection => 'Sem ligação à internet';

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
    return '$count dias';
  }

  @override
  String lateDate(String date) {
    return 'Atrasado ($date)';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String get allowAccessDescription =>
      'O Tiler recolhe dados de localização para permitir a agendamento eficiente de blocos e compromissos.\nOs seus dados mantêm-se privados e são apenas utilizados para este fim.';

  @override
  String get allowLocationAccessQ => 'Permitir o acesso à localização?';

  @override
  String get allow => 'Permitir';

  @override
  String get deny => 'Recusar';

  @override
  String get afternoon => 'Tarde';

  @override
  String get evening => 'Noite';

  @override
  String get night => 'Noite';

  @override
  String get morningAndAfternoon => 'Manhã & Tarde';

  @override
  String get afternoonAndEvening => 'Tarde & Noite';

  @override
  String get lateEvening => 'Noite avançada';

  @override
  String get prediction => 'Previsão';

  @override
  String get softDeadline => 'Prazo flexível';

  @override
  String get location => 'Localização';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'Eliminar conta';

  @override
  String get deleteYourTilerAccountQ => 'Eliminar conta?';

  @override
  String get no => 'Não';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get forgetPassword => 'Esqueci a palavra-passe';

  @override
  String get forgotPasswordBtn => 'Esqueceu-se da palavra-passe?';

  @override
  String get resetPassword => 'Repor palavra-passe';

  @override
  String get reset => 'Repor';

  @override
  String lookingUp(String text) {
    return 'A pesquisar $text';
  }

  @override
  String get lowPriorityTrunc => 'Baixa';

  @override
  String get mediumPriorityTrunc => 'Média';

  @override
  String get highPriorityTrunc => 'Alta';

  @override
  String failedToAddGoogleCalendar(String email) {
    return 'Falha ao adicionar $email';
  }

  @override
  String deletedCalendar(String email) {
    return 'Calendário $email eliminado';
  }

  @override
  String get loadingIntegrations => 'A carregar integrações';

  @override
  String get noThirdPartyIntegtions => 'Sem calendários de terceiros';

  @override
  String get addGoogleCalendar => 'Adicionar Google Calendar';

  @override
  String get integrations => 'Integrações';

  @override
  String get integrateOtherCalendars => 'Integrar com calendários de terceiros';

  @override
  String get clear => 'Limpar';

  @override
  String get next => 'Seguinte';

  @override
  String get previous => 'Anterior';

  @override
  String get skip => 'Saltar';

  @override
  String get morningPerson => '🌅 Pessoa matinal';

  @override
  String get morning => 'Manhã';

  @override
  String get middayPerson => '🌞 Pessoa de meodia';

  @override
  String get nightPerson => '🌃 Pessoa noturna';

  @override
  String get enterAddress => 'Indique a sua morada';

  @override
  String get primaryLocationQuestion =>
      'Qual é a sua localização principal para trabalho ou estudo?';

  @override
  String get useDeviceLocation => 'Usar a localização do meu dispositivo';

  @override
  String get energyLevelDescriptionQuestion =>
      'Como descreveria os seus níveis de energia ao longo do dia?';

  @override
  String get incompleteRequest => 'A solicitação completa não foi enviada';

  @override
  String get addContact => 'Adicionar contacto';

  @override
  String get invalidContactFormat =>
      'Não é um email nem um número de telefone válidos';

  @override
  String deadlineTime(String time) {
    return 'Prazo: $time';
  }

  @override
  String get accept => 'Aceitar';

  @override
  String get decline => 'Recusar';

  @override
  String get preview => 'Pré-visualização';

  @override
  String get addTilette => 'Adicionar Tilette';

  @override
  String get tileShareName => 'Nome do bloco partilhado';

  @override
  String get tileShare => 'Bloco partilhado';

  @override
  String get update => 'Atualizar';

  @override
  String get noDesignatedTiles => 'Nenhum bloco designado';

  @override
  String get noTileCluster => 'Nenhum bloco partilhado criado';

  @override
  String get errorLoadingTilelist => 'Erro ao carregar a lista de blocos';

  @override
  String get failedToLoadTileShareCluster =>
      'Falha ao carregar o cluster de blocos partilhados';

  @override
  String get missingTileShareCluster =>
      'Cluster de blocos partilhados em falta';

  @override
  String get outBound => 'Em saída';

  @override
  String get inBound => 'Em entrada';

  @override
  String get multiShare => 'Partilha múltipla';

  @override
  String get errorOccurred => 'Ocorreu um erro!!\nTente novamente.';

  @override
  String get authenticationIssues => 'Problemas de autenticação.';

  @override
  String get userIsNotAuthenticated => 'O utilizador não está autenticado.';

  @override
  String get responseContentError =>
      'A resposta não contém o conteúdo esperado.';

  @override
  String get responseHandlingError => 'Falha ao processar a resposta.';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get travel => 'Deslocação';

  @override
  String numberOfDayForecast(String number) {
    return 'Previsão de $number dias';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'Falha ao obter a pré-visualização';

  @override
  String get noDriving => 'Sem condução';

  @override
  String get tileShareNoteEllipsis => 'Nota...';

  @override
  String get hi => 'Olá';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get passwordCreationMessagePart1 =>
      'Crie uma palavra-passe forte e única com ';

  @override
  String get passwordConditionMinLength => 'pelo menos seis caracteres';

  @override
  String get passwordCreationMessageIncluding => ', incluindo ';

  @override
  String get passwordConditionUppercaseLetters => 'letras maiúsculas';

  @override
  String get passwordConditionLowercaseLetters => 'letras minúsculas';

  @override
  String get passwordConditionNumbers => 'números';

  @override
  String get passwordConditionSpecialCharacter => 'um caractere especial';

  @override
  String get listSeparator => ', ';

  @override
  String get listFinalSeparator => ', e ';

  @override
  String get nonViableTimeSlot => 'Sem intervalo de tempo viável';

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
  String get selectWeek => 'Selecionar uma semana';

  @override
  String get selectYear => 'Selecionar ano';

  @override
  String get retrievingDataIssue => 'Problema na recuperação de dados';

  @override
  String get recurring => 'Recorrente';

  @override
  String get nonRecurring => 'Não recorrente';

  @override
  String get dailyReurring => 'Diário';

  @override
  String get weeklyReurring => 'Semanal';

  @override
  String get biweeklyReurring => 'Quinzenal';

  @override
  String get monthlyReurring => 'Mensal';

  @override
  String get yearlyReurring => 'Anual';

  @override
  String get ellipsisEmprtNotes => 'Notas...';

  @override
  String get tileShareDelete => 'Eliminar';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => 'Bloco de previsão';

  @override
  String get previewOthers => 'Outros';

  @override
  String get goodMorning => 'Bom dia';

  @override
  String get goodDay => 'Bom dia';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String youHaveXBlocks(String count) {
    return 'Tem $count compromissos a caminho.';
  }

  @override
  String youHaveXTiles(String count) {
    return 'Tem $count blocos a caminho.';
  }

  @override
  String youHaveXTileShares(String count) {
    return 'Tem $count blocos partilhados a caminho.';
  }

  @override
  String countTileShare(String count) {
    return '$count blocos partilhados';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return 'Tem $blockCount compromissos e $tileCount blocos a caminho.';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return 'Tem $blockCount compromissos e $tileShareCount blocos partilhados a caminho.';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return 'Tem $tileCount blocos e $tileShareCount blocos partilhados a caminho.';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return 'Tem $blockCount compromissos, $tileCount blocos e $tileShareCount blocos partilhados a caminho.';
  }

  @override
  String get noTilesPreview => 'Não tem nada previsto para o resto do dia.';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'Criar bloco';

  @override
  String get previewTileForecast => 'Previsão';

  @override
  String get previewTileOptions => 'Opções';

  @override
  String get previewTileMore => 'Mais';

  @override
  String get previewTileShuffle => 'Embaralhar';

  @override
  String get previewTileRevise => 'Rever';

  @override
  String get previewTileDeferAll => 'Adiar tudo';

  @override
  String get previewLocationName => 'Localização';

  @override
  String get previewTagName => 'Etiqueta';

  @override
  String get previewClassificationName => 'Classificação';

  @override
  String get previewBlockedOut => 'Bloqueado';

  @override
  String get accountInfo => 'Informações da conta';

  @override
  String get fistName => 'Nome';

  @override
  String get lastName => 'Apelido';

  @override
  String get tilePreferences => 'Preferências dos blocos';

  @override
  String get notificationsPreferences => 'Preferências de notificações';

  @override
  String get security => 'Segurança';

  @override
  String get connections => 'Conexões';

  @override
  String get myLocations => 'As minhas localizações';

  @override
  String get aboutTiler => 'Sobre o Tiler';

  @override
  String get howToUseTiler => 'Como usar o Tiler';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get setLocation => 'Definir localização';

  @override
  String get connectCalendars => 'Ligar os seus calendários';

  @override
  String get configure => 'Configurar';

  @override
  String get comingSoon => 'Em breve';

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
  String get addCalendar => 'Adicionar calendário';

  @override
  String get calendarConnected => 'Calendário ligado';

  @override
  String get calendarConnectionDeclined =>
      'A ligação ao calendário foi cancelada';

  @override
  String get calendarConnectionError =>
      'Não foi possível ligar o seu calendário';

  @override
  String get sleepDuration => 'Duração do sono';

  @override
  String get transportationMethodQuestion => 'Como se desloca?';

  @override
  String get defineYourTimeRestrictions =>
      'Definir as suas restrições de tempo';

  @override
  String get setWorkHours => 'Definir horas de trabalho';

  @override
  String get setYourBlockOutHours => 'Definir as horas a bloquear';

  @override
  String get travelMediumBiking => 'Bicicleta';

  @override
  String get travelMediumTransit => 'Transporte público';

  @override
  String get travelMediumDriving => 'De carro';

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
  String get bedTime => 'Hora de deitar';

  @override
  String get sleepTime => 'Hora de sono';

  @override
  String get scheduleFullness => 'Preenchimento da agenda';

  @override
  String get scheduleFullnessDescription =>
      'O quão cheia deve estar a sua agenda?';

  @override
  String scheduleFullnessValue(int percentage) {
    return 'Preenchimento alvo de $percentage%';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return 'Os objetivos variam de $minimum% a $maximum%. Isto mantém uma base útil e deixa espaço para alterações e deslocações.';
  }

  @override
  String get schedulePreferences => 'Preferências da agenda';

  @override
  String get lighter => 'Mais leve';

  @override
  String get balanced => 'Equilibrado';

  @override
  String get fuller => 'Mais cheio';

  @override
  String get tilePreferencesUpdatedSuccessfully =>
      'As preferências dos blocos foram atualizadas com sucesso.';

  @override
  String get notificationsPreferencesUpdatedSuccessfully =>
      'As preferências de notificações foram atualizadas com sucesso.';

  @override
  String get tileReminders => 'Lembretes dos blocos';

  @override
  String get appUpdates => 'Atualizações da app';

  @override
  String get marketingUpdates => 'Atualizações de marketing';

  @override
  String get emailNotifications => 'Notificações por email';

  @override
  String get fullName => 'Nome completo';

  @override
  String get phoneNumber => 'Número de telefone';

  @override
  String get countryCode => 'Código do país';

  @override
  String get dateOfBirth => 'Data de nascimento';

  @override
  String get accountInfoUpdatedSuccessfully =>
      'As informações da conta foram atualizadas com sucesso.';

  @override
  String get reachingServerIssues =>
      'Problemas ao contactar os servidores do Tiler';

  @override
  String get deleteAccountConfirmation =>
      'Tem a certeza de que quer eliminar a sua conta? Esta ação não pode ser desfeita.';

  @override
  String get disconnect => 'Desligar';

  @override
  String get integrationsSetLocation => 'Definir localização';

  @override
  String get googleCalender => 'Google Calendar';

  @override
  String get passwordsMustMatch => 'As palavras-passe têm de coincidir';

  @override
  String get parenthesisLate => '(Atrasado)';

  @override
  String get failedToAddIntegration => 'Falha ao adicionar a integração';

  @override
  String get unknownProvider => 'Fornecedor desconhecido';

  @override
  String get manageCalendars => 'Gerir calendários';

  @override
  String get calendarItems => 'Artigos do calendário';

  @override
  String get noCalendarItemsFound => 'Nenhum artigo do calendário encontrado';

  @override
  String get calendarItemsWillAppearHere =>
      'Os artigos do seu calendário aparecerão aqui';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$selectedCount de $totalCount calendários ativos';
  }

  @override
  String get toggleCalendarsToSync =>
      'Ativar os calendários para sincronizar com o Tiler';

  @override
  String get unknownCalendar => 'Calendário desconhecido';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$selectedCount de $totalCount ativos';
  }

  @override
  String integrationCount(int count) {
    return '$count integrações';
  }

  @override
  String get errorLoadingCalendarItems =>
      'Erro ao carregar os artigos do calendário';

  @override
  String get integratedCalendars => 'Calendários';

  @override
  String get integrationAdd => 'Adicionar';

  @override
  String get timeAndLocationSecondarySubTitle =>
      'Pode aceder à sua localização para fornecer recomendações\ne notificações com base na localização?';

  @override
  String get recurringTasks => 'Tarefas recorrentes';

  @override
  String get yourProfession => 'Qual é a sua profissão?';

  @override
  String get yourProfessionQuestion => 'O que faz?';

  @override
  String get yourProfessionHint => 'Descreva o que faz no trabalho';

  @override
  String get medicalProfessional => 'Profissional de saúde';

  @override
  String get softwareDeveloper => 'Desenvolvedor de software';

  @override
  String get student => 'Estudante';

  @override
  String get engineer => 'Engenheiro';

  @override
  String get fieldSalesProfessional => 'Profissional de vendas de campo';

  @override
  String get remoteWorker => 'Trabalhador remoto & Nómada digital';

  @override
  String get stayAtHomeParent => 'Pai/mãe ao cuidado da casa';

  @override
  String get clientAccountManagers => 'Gestores de clientes/contas';

  @override
  String get other => 'Outro';

  @override
  String get tileSuggestions => 'Sugestões de blocos';

  @override
  String get personalOrWorkQuestion => 'Para o que vai usar o Tiler?';

  @override
  String get enter3chars => 'Introduza pelo menos 3 caracteres.';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return 'Saia em $duration para chegar a horas';
  }

  @override
  String get leaveNowToArriveOnTime => 'Saia agora para chegar a horas!';

  @override
  String durationDrive(String duration) {
    return '$duration de carro';
  }

  @override
  String durationTransit(String duration) {
    return '$duration de transporte público';
  }

  @override
  String durationBike(String duration) {
    return '$duration de bicicleta';
  }

  @override
  String durationWalk(String duration) {
    return '$duration a pé';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$duration de carro até a $destination';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$duration de transporte público até a $destination';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$duration de bicicleta até a $destination';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$duration a pé até a $destination';
  }

  @override
  String leaveByTime(String time) {
    return 'Saia até às $time';
  }

  @override
  String get trafficDetectedReroutingSuggested =>
      'Tráfego detetado - sugere-se nova rota';

  @override
  String trafficDelayMinutes(String minutes) {
    return 'Tráfego: +$minutes min de atraso';
  }

  @override
  String get heavyTrafficExpected => 'Tráfego intenso esperado';

  @override
  String get addWithAI => 'Adicionar com IA';

  @override
  String get focusTime => 'Tempo de concentração';

  @override
  String get videoMeeting => 'Reunião de vídeo';

  @override
  String get sharedWith => 'Partilhado com';

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
    return ' $travelMode para ';
  }

  @override
  String get travelModeDriving => 'de carro';

  @override
  String get travelModeWalking => 'a pé';

  @override
  String get travelModeBicycling => 'de bicicleta';

  @override
  String get travelModeTransitLower => 'transporte público';

  @override
  String travelDurationCompact(int minutes) {
    return '${minutes}m';
  }

  @override
  String get yourDayIsOptimized => 'O seu dia está otimizado.';

  @override
  String get yourDayAtAGlance => 'O seu dia de um relance';

  @override
  String totalTravelTimeToday(String duration) {
    return '$duration de tempo de deslocação hoje.';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '$count blocos agendados para hoje.';
  }

  @override
  String get viewRoute => 'Ver rota';

  @override
  String get focusModeChip => 'Modo de foco';

  @override
  String get showRouteChip => 'Mostrar rota';

  @override
  String get reOptimizeChip => 'Reotimizar';

  @override
  String get todayColon => 'Hoje:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount blocos, $blockCount compromissos';
  }

  @override
  String get timeSavedColon => 'Tempo poupado:';

  @override
  String get travelTimeColon => 'Tempo de deslocação:';

  @override
  String travelTime(String duration) {
    return 'Tempo de deslocação: $duration';
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
  String get scheduleConflict => 'Conflito de agendamento';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '\"$tile1\" e \"$tile2\" estão agendados à mesma hora';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '\"$tile1\" está durante \"$tile2\" ($overlap de sobreposição)';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '\"$tile1\" sobrepõe \"$tile2\" por $overlap';
  }

  @override
  String get fix => 'Corrigir';

  @override
  String conflictOverlapMinutes(int minutes) {
    return 'Conflito: ${minutes}m de sobreposição';
  }

  @override
  String get oneScheduleConflict => '1 conflito de agendamento';

  @override
  String countScheduleConflicts(int count) {
    return '$count conflitos de agendamento';
  }

  @override
  String get tapToReviewAndResolve => 'Toque para rever e resolver';

  @override
  String countConflicts(int count) {
    return '$count conflitos';
  }

  @override
  String get tapToExpand => 'Toque para expandir';

  @override
  String conflictingTiles(int count) {
    return '$count blocos em conflito';
  }

  @override
  String totalOverlap(String duration) {
    return 'Sobreposição total: $duration';
  }

  @override
  String get autoResolve => 'Resolução automática';

  @override
  String get untitledTile => 'Bloco sem título';

  @override
  String get untitledEvent => 'Sem título';

  @override
  String get extendedEventSingular => '1 evento prolongado';

  @override
  String extendedEventsPlural(int count) {
    return '$count eventos prolongados';
  }

  @override
  String get extendedEventsTapToView =>
      'Toque para ver eventos de dia inteiro e de longa duração';

  @override
  String get extendedEventsTitle => 'Eventos prolongados';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos de mais de 16 horas',
      one: '1 evento de mais de 16 horas',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => 'Rota de hoje';

  @override
  String get noLocationsToday => 'Sem localizações hoje';

  @override
  String get addLocationsToSeeTodaysRoute =>
      'Adicione localizações aos seus blocos para ver a sua rota diária';

  @override
  String countStops(int count) {
    return '$count paragens';
  }

  @override
  String get routeOptimized => 'Rota otimizada';

  @override
  String savedTravelTime(String duration) {
    return 'Poupou $duration de tempo de deslocação';
  }

  @override
  String get firstStop => 'Primeira paragem';

  @override
  String get stop => 'Paragem';

  @override
  String arriveBy(String time) {
    return 'Chegue até às $time';
  }

  @override
  String get fromPreviousStop => 'da paragem anterior';

  @override
  String get viewTile => 'Ver bloco';

  @override
  String get editTile => 'Editar bloco';

  @override
  String get startNavigation => 'Iniciar navegação';

  @override
  String get noLocationAvailable => 'Sem localização';

  @override
  String get seeTodaysRoute => 'Ver a rota de hoje';

  @override
  String get whatWouldYouLikeToDo => 'O que gostaria de fazer?';

  @override
  String get describeATask =>
      'Descreva uma tarefa, nós tratamos do agendamento.';

  @override
  String get microphonePermissionDenied => 'Permissão do microfone recusada.';

  @override
  String failedToStartRecording(String error) {
    return 'Falha ao iniciar a gravação: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return 'Falha ao parar a gravação: $error';
  }

  @override
  String audioConversionError(String error) {
    return 'Erro de conversão de áudio: $error';
  }

  @override
  String get audioConversionFailed => 'Falha na conversão de áudio';

  @override
  String get recordingPathIsEmpty => 'O caminho da gravação está vazio';

  @override
  String get noActiveRecording => 'Sem gravação ativa';

  @override
  String get joinMeeting => 'Entrar na reunião';

  @override
  String get openLink => 'Abrir ligação';

  @override
  String get actions => 'Ações';

  @override
  String get hideActions => 'Ocultar ações';

  @override
  String get pendingRsvpSingular => '1 evento necessita de resposta';

  @override
  String pendingRsvpPlural(int count) {
    return '$count eventos necessitam de resposta';
  }

  @override
  String get pendingRsvpHappeningNow =>
      'A decorrer agora - responda para entrar';

  @override
  String get pendingRsvpStartingSoon => 'Começa em breve - responda agora';

  @override
  String get pendingRsvpWithinHour => 'Começa dentro de uma hora';

  @override
  String get pendingRsvpUpcoming => 'Próximos - toque para responder';

  @override
  String get pendingRsvpTapToReview => 'Toque para rever e responder';

  @override
  String get pendingRsvpTitle => 'Respostas pendentes';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos à espera da sua resposta',
      one: '1 evento à espera da sua resposta',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'Começam em breve';

  @override
  String get pendingRsvpLater => 'Mais tarde hoje & a chegar';

  @override
  String get declinedRsvpSingular => '1 evento recusado';

  @override
  String declinedRsvpPlural(int count) {
    return '$count eventos recusados';
  }

  @override
  String get declinedRsvp => 'Eventos recusados';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '1 pendente, $declinedCount recusados';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '$pendingCount pendentes, 1 recusado';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '$pendingCount pendentes, $declinedCount recusados';
  }

  @override
  String get rsvpNeedsAction => 'Necessita de resposta';

  @override
  String get rsvpTentative => 'Provisório';

  @override
  String get rsvpAccepted => 'Aceite';

  @override
  String get rsvpDeclined => 'Recusado';

  @override
  String unableToOpenLinkError(String link) {
    return 'Não foi possível abrir a ligação: $link';
  }

  @override
  String get leaveNow => 'Saia já!';

  @override
  String leaveInMinutes(int minutes) {
    return 'Saia em $minutes min';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count alertas';
  }

  @override
  String get alertChipLeaveNow => 'Sair já';

  @override
  String alertChipLeaveIn(int minutes) {
    return 'Sair em ${minutes}m';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflitos',
      one: '1 conflito',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dia inteiro',
      one: '1 dia inteiro',
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
  String get accepted => 'Aceite';

  @override
  String get declined => 'Recusado';

  @override
  String respondToCalendar(String calendarSource) {
    return 'Responda a $calendarSource';
  }

  @override
  String get unknown => 'Convite do calendário';

  @override
  String get loadingPreviousDays => 'A carregar dias anteriores...';

  @override
  String get loadingUpcomingDays => 'A carregar dias a chegar...';

  @override
  String get requestTimeout =>
      'Tempo limite da solicitação - verifique a sua ligação';

  @override
  String get failedToPauseTile => 'Falha ao pausar o bloco';

  @override
  String get failedToResumeTile => 'Falha ao retomar o bloco';

  @override
  String get failedToMoveUpTask => 'Falha ao avançar a tarefa';

  @override
  String get failedToUpdateTile => 'Falha ao atualizar o bloco';

  @override
  String get failedToBuzzSchedule => 'Falha ao impulsionar a agenda';

  @override
  String get failedToShuffleSchedule => 'Falha ao embaralhar a agenda';

  @override
  String get failedToProcrastinateTile => 'Falha ao adiar o bloco';

  @override
  String get tutorialStepYourScheduleTitle => 'A sua agenda';

  @override
  String get tutorialStepYourScheduleBody =>
      'O seu dia é organizado em Blocos - blocos de tempo inteligentes que o Tiler dispõe por si. Role para cima e para baixo para ver o seu dia inteiro.';

  @override
  String get tutorialStepCreateOptimizeTitle => 'Criar & Otimizar';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'Toque aqui para criar uma nova tarefa. Diga ao Tiler o que precisa de fazer e quanto tempo levará - o Tiler trata de quando.';

  @override
  String get tutorialCalloutReOptimize => 'Reotimizar';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      'O dia saiu da rota? Recalcule desde agora mantendo o plano a chegar relativamente estável';

  @override
  String get tutorialCalloutTravelTime => 'Tempo de deslocação';

  @override
  String get tutorialCalloutTravelTimeDesc =>
      'O Tiler tem em conta as deslocações entre localizações';

  @override
  String get tutorialStepQuickCreateTitle => 'Criação rápida';

  @override
  String get tutorialStepQuickCreateBody =>
      'Este é o painel de adição rápida. Dê um nome ao seu bloco e defina uma duração para uma adição rápida.';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      'Este é o painel de adição rápida atrás de mim! Dê um nome ao seu bloco, defina uma duração e toque em Adicionar - o Tiler trata do resto.';

  @override
  String get tutorialCalloutNameYourTile => 'Dê um nome ao seu bloco';

  @override
  String get tutorialCalloutNameYourTileDesc =>
      'Descreva a tarefa que quer realizar';

  @override
  String get tutorialCalloutSetDuration => 'Definir duração';

  @override
  String get tutorialCalloutSetDurationDesc =>
      'Quanto tempo levará esta tarefa?';

  @override
  String get tutorialCalloutMoreOptions => 'Mais opções';

  @override
  String get tutorialCalloutMoreOptionsDesc =>
      'Adicione localização, prazo ou repetição através do editor completo';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc =>
      'Adicione localização, prazo ou repetição';

  @override
  String get tutorialStepTilerWorksTitle => 'O Tiler trabalha por si';

  @override
  String get tutorialStepTilerWorksBody =>
      'O Tiler organiza automaticamente os seus blocos com base nos seus níveis de energia, no tempo de deslocação e nos prazos. Basta adicionar o que precisa de fazer - o Tiler trata de quando.';

  @override
  String get tutorialCalloutForecast => 'Previsão';

  @override
  String get tutorialCalloutForecastDesc =>
      'Veja quando um bloco será inserido antes de o selecionar';

  @override
  String get tutorialCalloutShuffle => 'Embaralhar';

  @override
  String get tutorialCalloutShuffleDesc =>
      'Embaralhe tudo e sugira o que deve fazer a seguir';

  @override
  String get tutorialCalloutDeferAll => 'Adiar tudo';

  @override
  String get tutorialCalloutDeferAllDesc =>
      'Dia difícil? Empurre tudo para a frente';

  @override
  String get tutorialStepControlTilesTitle => 'Controle os seus blocos';

  @override
  String get tutorialStepControlTilesBody =>
      'Cada bloco tem controlos para gerir as suas tarefas em tempo real:';

  @override
  String get tutorialCalloutPlay => 'Reproduzir';

  @override
  String get tutorialCalloutPlayDesc => 'Comece a trabalhar neste bloco';

  @override
  String get tutorialCalloutPause => 'Pausar';

  @override
  String get tutorialCalloutPauseDesc =>
      'Faça uma pausa - o Tiler reorganizará o resto';

  @override
  String get tutorialCalloutComplete => 'Concluir';

  @override
  String get tutorialCalloutCompleteDesc => 'Feito! Marque-o como concluído';

  @override
  String get tutorialCalloutProcrastinate => 'Adiar';

  @override
  String get tutorialCalloutProcrastinateDesc =>
      'Agora não - empurre para mais tarde';

  @override
  String get tutorialStepBigPictureTitle => 'Veja o quadro global';

  @override
  String get tutorialStepBigPictureBody =>
      'Toque no ícone do calendário para alternar entre três vistas:';

  @override
  String get tutorialCalloutDaily => 'Diário';

  @override
  String get tutorialCalloutDailyDesc => 'Hora a hora - a sua agenda detalhada';

  @override
  String get tutorialCalloutWeekly => 'Semanal';

  @override
  String get tutorialCalloutWeeklyDesc => 'Veja a semana inteira de um relance';

  @override
  String get tutorialCalloutMonthly => 'Mensal';

  @override
  String get tutorialCalloutMonthlyDesc =>
      'Planeie com antecedência com uma visão mensal';

  @override
  String get tutorialStepToolkitTitle => 'A sua caixa de ferramentas';

  @override
  String get tutorialStepToolkitBody =>
      'Estas ferramentas úteis estão sempre ao alcance da mão:';

  @override
  String get tutorialCalloutShare => 'Partilhar';

  @override
  String get tutorialCalloutShareDesc =>
      'Colabore - partilhe blocos com outras pessoas';

  @override
  String get tutorialCalloutSearch => 'Pesquisar';

  @override
  String get tutorialCalloutSearchDesc => 'Encontre qualquer bloco pelo nome';

  @override
  String get tutorialCalloutSettings => 'Definições';

  @override
  String get tutorialCalloutSettingsDesc =>
      'Personalize a sua experiência, ligue calendários e defina preferências';

  @override
  String get tutorialCalloutChat => 'Chat';

  @override
  String get tutorialCalloutChatDesc =>
      'Toque no botão de chat para adicionar ou ajustar blocos conversando com o Tiler';

  @override
  String get tutorialStepChatTitle => 'Conversar com o Tiler';

  @override
  String get tutorialStepChatBody =>
      'Toque no botão de chat a qualquer momento para adicionar ou ajustar blocos conversando com o Tiler - sem formulários.';

  @override
  String get tutorialNavNext => 'Seguinte';

  @override
  String get tutorialNavNextArrow => 'Seguinte →';

  @override
  String get tutorialNavBack => 'Anterior';

  @override
  String get tutorialNavBackArrow => '← Anterior';

  @override
  String get tutorialNavSkip => 'Saltar';

  @override
  String get tutorialNavLetsGo => 'Vamos!';

  @override
  String get welcomeExplainerHeadline => 'Blocos vs Compromissos';

  @override
  String get welcomeExplainerSubtitle =>
      'Um vislumbre de como o Tiler planeia o seu dia.';

  @override
  String get welcomeExplainerBlocksCaption =>
      'Os compromissos são fixos. Acontecem a um horário definido.';

  @override
  String get welcomeExplainerTilesCaption =>
      'Os blocos são flexíveis. O Tiler os dispõe à volta dos seus compromissos.';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return 'O dentista movido para às $time - o Tiler reagenda os seus blocos à volta.';
  }

  @override
  String get welcomeExplainerMovedBadge => 'Movido';

  @override
  String get welcomeExplainerReplannedBadge => 'Reagendado';

  @override
  String get welcomeExplainerBlockStandup => 'Standup da equipa';

  @override
  String get welcomeExplainerBlockDentist => 'Dentista';

  @override
  String get welcomeExplainerTileWorkout => 'Treino';

  @override
  String get welcomeExplainerTileReport => 'Escrever relatório';

  @override
  String get welcomeExplainerTileGroceries => 'Compras';

  @override
  String get welcomeExplainerLegendBlock => 'Compromisso';

  @override
  String get welcomeExplainerLegendTile => 'Bloco';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'Preferências dos blocos';

  @override
  String get tutorialStepSettingsTilesBody =>
      'As suas preferências de IA vivem aqui - como se desloca, as suas horas de trabalho e pessoais e as horas a bloquear.';

  @override
  String get tutorialStepTilePrefsTransportTitle => 'Como se desloca';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'O Tiler calcula o tempo de deslocação entre blocos com base na forma como costuma deslocar-se.';

  @override
  String get tutorialStepTilePrefsHoursTitle => 'Horas de trabalho e pessoais';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Quando o Tiler pode agendar blocos de trabalho ou pessoais. Toque em um dos dois para definir um perfil.';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'Horas a bloquear';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      'Hora de deitar e duração do sono: horas em que o Tiler nunca agenda.';

  @override
  String get chat => 'Chat';

  @override
  String get transcribing => 'A transcrever';

  @override
  String get newChat => 'Novo chat';

  @override
  String get noChatHistory => 'Sem histórico de chat';

  @override
  String get unknownChat => 'Chat desconhecido';

  @override
  String get transcriptionFailed => 'Falha na transcrição';

  @override
  String get acceptChanges => 'Aceitar alterações';

  @override
  String get noRequestToExecute => 'Nenhuma solicitação para executar';

  @override
  String get initializingAction => 'A inicializar a geração da ação';

  @override
  String get settingThingsUp => 'A preparar';

  @override
  String get preparingRequest => 'A preparar a sua solicitação';

  @override
  String get gettingReady => 'A preparar-se';

  @override
  String get processingAction => 'A processar a ação';

  @override
  String get workingOnIt => 'A trabalhar nisso';

  @override
  String get analyzingRequest => 'A analisar a sua solicitação';

  @override
  String get thinking => 'A refletir';

  @override
  String get actionComplete => 'Processamento da ação concluído';

  @override
  String get processingDone => 'Processamento concluído';

  @override
  String get allSet => 'Tudo pronto';

  @override
  String get finishedProcessing => 'Processamento terminado';

  @override
  String get generatingSummary => 'A gerar resumo';

  @override
  String get summarizingResults => 'A resumir resultados';

  @override
  String get creatingOverview => 'A criar visão geral';

  @override
  String get preparingSummary => 'A preparar resumo';

  @override
  String get summaryComplete => 'Geração de resumo concluída';

  @override
  String get summaryReady => 'Resumo pronto';

  @override
  String get overviewComplete => 'Visão geral concluída';

  @override
  String get doneSummarizing => 'Resumo concluído';

  @override
  String get loadingSchedule => 'A carregar dados da agenda';

  @override
  String get fetchingSchedule => 'A obter a sua agenda';

  @override
  String get retrievingCalendar => 'A recuperar o calendário';

  @override
  String get loadingTimeline => 'A carregar a linha temporal';

  @override
  String get optimizingSchedule => 'A otimizar a agenda';

  @override
  String get reorganizingDay => 'A reorganizar o seu dia';

  @override
  String get findingBestFit => 'A encontrar o melhor encaixe';

  @override
  String get adjustingTimeline => 'A ajustar a linha temporal';

  @override
  String get scheduleComplete => 'Otimização da agenda concluída';

  @override
  String get scheduleUpdated => 'Agenda atualizada';

  @override
  String get timelineOptimized => 'Linha temporal otimizada';

  @override
  String get allDone => 'Tudo feito';

  @override
  String get connectionLost => 'Ligação perdida. Atualize';

  @override
  String get sendingRequest => 'A enviar a solicitação';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'Ligação WebSocket perdida após 5 tentativas';

  @override
  String get webSocketMessageHandlingError => 'Erro ao processar a mensagem';

  @override
  String get jsonParseError => 'Erro de análise JSON';

  @override
  String get processError => 'Erro de processo';

  @override
  String get socketConnectionError => 'Erro de ligação do socket';

  @override
  String get keepAliveFailed => 'Falha ao manter a ligação ativa';

  @override
  String get copy => 'Copiar';

  @override
  String get entityIdNotFound =>
      'Nenhum id de entidade de pré-visualização encontrado';

  @override
  String get feedback => 'Comentários';

  @override
  String get feedbackCategory => 'Categoria';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategoryFeature => 'Funcionalidade';

  @override
  String get feedbackCategoryEnhancement => 'Melhoria';

  @override
  String get feedbackCategoryGeneral => 'Geral';

  @override
  String get feedbackTitle => 'Título';

  @override
  String get feedbackTitleHint => 'Resumo breve dos seus comentários';

  @override
  String get feedbackDescription => 'Descrição';

  @override
  String get feedbackDescriptionHint =>
      'Forneça detalhes sobre os seus comentários';

  @override
  String get feedbackSubmitted => 'Comentários enviados com sucesso';

  @override
  String get feedbackError => 'Falha ao enviar os comentários';

  @override
  String get noPreviewsAvailable =>
      'Sem TileCasts disponíveis para esta solicitação';

  @override
  String get previewUnavailable => 'O TileCast selecionado não está disponível';

  @override
  String get previewSummaryUnavailable =>
      'Não foi possível carregar o TileCast';

  @override
  String get previewGenerating => 'A gerar TileCast…';

  @override
  String get previewTimedOut =>
      'O TileCast está a demorar mais do que o esperado. Tente novamente num instante.';

  @override
  String get previewGenerationFailed => 'Não conseguimos gerar este TileCast.';

  @override
  String get previewInvalidated =>
      'Este TileCast já não é válido porque a sua agenda mudou.';

  @override
  String get previewStaleBanner =>
      'Este TileCast reflete uma instantânea anterior da sua agenda.';

  @override
  String get previewNonViableLabel => 'Não agendável';

  @override
  String get reviewChanges => 'Rever alterações';

  @override
  String get previewRetry => 'Tentar novamente';

  @override
  String get previewPreparing => 'A preparar TileCast…';

  @override
  String get previewReadyToView => 'Toque para ver o TileCast';

  @override
  String get previewActionsOutdated =>
      'Desatualizado - envie uma nova mensagem';

  @override
  String get previewActionsUnavailable => 'TileCast não disponível';

  @override
  String get tileCastStaleNote =>
      'A sua agenda mudou: este TileCast pode estar desatualizado';

  @override
  String get tileCastAlsoIncluded => 'Também incluído';

  @override
  String actionsCount(int count) {
    return '$count ações';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'A carregar notas…';

  @override
  String get notesSaving => 'A guardar…';

  @override
  String get notesSaved => 'Guardado';

  @override
  String get notesUnsaved => 'A editar…';

  @override
  String get notesSaveError => 'Não foi possível guardar';

  @override
  String get notesSaveNow => 'Guardar agora';

  @override
  String get notesShowPreview => 'Pré-visualizar';

  @override
  String get notesShowEditor => 'Editar';

  @override
  String get notesPreviewEmpty => 'Ainda não há nada para pré-visualizar.';

  @override
  String get notesLinkPromptTitle => 'Inserir ligação';

  @override
  String get notesConflictTitle => 'Outra pessoa atualizou esta nota.';

  @override
  String get notesConflictDiscardMine => 'Descartar as minhas';

  @override
  String get notesConflictKeepEditing => 'Continuar a editar';

  @override
  String get notesToolBold => 'Negrito';

  @override
  String get notesToolItalic => 'Itálico';

  @override
  String get notesToolStrikethrough => 'Riscado';

  @override
  String get notesToolInlineCode => 'Código inline';

  @override
  String get notesToolHeading1 => 'Cabeçalho 1';

  @override
  String get notesToolHeading2 => 'Cabeçalho 2';

  @override
  String get notesToolBulletList => 'Lista de pontos';

  @override
  String get notesToolNumberedList => 'Lista numerada';

  @override
  String get notesToolTaskList => 'Lista de tarefas';

  @override
  String get notesToolQuote => 'Citação';

  @override
  String get notesToolLink => 'Ligação';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesViewerTitle => 'Nota';

  @override
  String get notesTapToAdd => 'Toque para adicionar uma nota';

  @override
  String get notesTapToEdit => 'Toque para editar · toque prolongado para ler';

  @override
  String get notesDone => 'Concluído';

  @override
  String get endOfDay => 'Fim do dia';

  @override
  String get search => 'Pesquisar';

  @override
  String get share => 'Partilhar';

  @override
  String get openChat => 'Abrir chat';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get switchCalendarView => 'Alternar vista do calendário';

  @override
  String get previewSundialGreeting => 'Olá.';

  @override
  String get previewSundialCountsPrefix => 'Hoje há';

  @override
  String get previewSundialCountsSuffix => 'à espera.';

  @override
  String previewSundialTilesClause(String count) {
    return '$count blocos';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return '$count compromissos';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return '$count blocos partilhados';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '$hours horas de trabalho';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '$mins minutos de deslocação';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return 'o seu dia libera-se até às $time';
  }

  @override
  String get previewSundialAndSeparator => 'e';

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
    return '${hours}h de sono';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '${hours}h livres';
  }

  @override
  String get previewSundialFullyBooked => 'Tudo reservado';

  @override
  String get previewSundialTier0 => 'Dia livre';

  @override
  String get previewSundialTier1 => 'A começar';

  @override
  String get previewSundialTier2 => 'Em curso';

  @override
  String get previewSundialTier3 => 'Bom progresso';

  @override
  String get previewSundialTier4 => 'Quase lá';

  @override
  String get previewSundialTodayLabel => 'Hoje';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return '$tiles blocos, $blocks compromissos, $nonViable não agendados';
  }

  @override
  String get timelineClearHeading => 'A sua linha temporal está livre hoje';

  @override
  String get timelineClearAddTask => 'Adicionar um bloco';

  @override
  String get aiConsentTitle => 'Conheça a Tiler AI';

  @override
  String get aiConsentSubtitle => 'O seu assistente de planeamento com IA';

  @override
  String get aiConsentIntro =>
      'Para transformar as suas palavras numa agenda, a Tiler AI partilha o que envia com fornecedores de IA de confiança.';

  @override
  String get aiConsentDataTitle => 'O que enviamos';

  @override
  String get aiConsentDataBody =>
      'As mensagens e gravações de voz que envia, além dos detalhes relevantes da sua agenda.';

  @override
  String get aiConsentProvidersTitle => 'Quem o recebe';

  @override
  String get aiConsentProvidersBody =>
      'Google Gemini e OpenAI, os nossos fornecedores de IA de terceiros.';

  @override
  String get aiConsentPrivacyLink => 'Leia a nossa Política de Privacidade';

  @override
  String get aiConsentContinue => 'Continuar para a Tiler AI';

  @override
  String get aiConsentAgreementNotice =>
      'Ao continuar, concorda em partilhar estes dados com o fornecedor de terceiros conforme descrito acima.';

  @override
  String get aiConsentClose => 'Fechar';

  @override
  String get legalFooterPrefix => 'Ao continuar, aceita os';

  @override
  String get legalFooterTerms => 'Termos';

  @override
  String get legalFooterAnd => 'e';

  @override
  String get legalFooterPrivacy => 'Privacidade';

  @override
  String get aiConsentLinkError => 'Não foi possível abrir a ligação.';

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
  String get startNow => 'Começar agora';

  @override
  String dueOnDate(String date) {
    return 'Vence $date';
  }

  @override
  String get noResultsForProvider => 'Sem resultados deste calendário';

  @override
  String get readOnly => 'Somente leitura';

  @override
  String get productTourStarting => 'O tour da app está prestes a começar.';
}
