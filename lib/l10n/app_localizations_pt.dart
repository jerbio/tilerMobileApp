// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String professionTaskPreview(String profession) {
    String _temp0 = intl.Intl.selectLogic(
      profession,
      {
        'medical': 'Acompanhar pacientes → Pausa',
        'software': 'Concentração → Revisão de código',
        'student': 'Sessão de estudo → Preparar tarefas',
        'engineer': 'Revisão de projeto → Planejamento',
        'sales': 'Ligações a clientes → Deslocamento',
        'remote': 'Trabalho focado → Reunião de equipe',
        'parent': 'Levar à escola → Tempo para você',
        'account': 'Reunião com clientes → Acompanhamento',
        'other': 'Concentração → Metas pessoais',
      },
    );
    return '$_temp0';
  }

  @override
  String get professionAiExplanation =>
      'Ajude a IA a planejar conforme seu trabalho';

  @override
  String get selectProfession => 'Selecione uma profissão para continuar.';

  @override
  String get scheduleReadFailedTitle =>
      'Não foi possível carregar seus eventos.';

  @override
  String get scheduleReadFailedBody => 'Tente novamente em instantes.';

  @override
  String get scheduleReadRefreshFailed =>
      'Não foi possível atualizar seus eventos.';

  @override
  String get scheduleReadRetained => 'Mostrando sua última agenda carregada.';

  @override
  String get scheduleReadRetrying => 'Tentando novamente...';

  @override
  String get scheduleReadSignIn => 'Entre para carregar seus eventos.';

  @override
  String get scheduleSummaryUnavailable => 'Resumo indisponível';

  @override
  String get notesLoadFailed =>
      'Não foi possível carregar suas notas. Abra o editor de notas novamente.';

  @override
  String get shareNotesLoadFailed =>
      'Não foi possível carregar as notas. Tente novamente.';

  @override
  String get shareAddPerson => 'Adicionar pessoa';

  @override
  String get onboardingSubmitFailed =>
      'Não foi possível salvar sua configuração. Suas escolhas foram mantidas. Tente novamente ou pule esta etapa por enquanto.';

  @override
  String operationFailed(String operation) {
    return '$operation falhou. Tente novamente.';
  }

  @override
  String get scheduleLoadFailed =>
      'Não foi possível carregar sua agenda. Atualize para tentar novamente.';

  @override
  String get chatConnectionFailed =>
      'Não foi possível conectar ao chat. Abra o chat novamente.';

  @override
  String get chatHistoryFailed =>
      'Não foi possível carregar seu histórico de chat. Abra a conversa novamente.';

  @override
  String get chatSendFailed =>
      'Sua mensagem não pôde ser enviada. Verifique sua conexão e tente novamente.';

  @override
  String get chatRecordingFailed =>
      'Não foi possível iniciar a gravação de voz. Verifique o acesso ao microfone e tente novamente.';

  @override
  String get chatCancelRecordingFailed =>
      'Não foi possível cancelar a gravação de voz. Tente parar a gravação novamente.';

  @override
  String get whiteSpace => ' ';

  @override
  String get add => 'Adicionar';

  @override
  String get setupCustomRestrictions => 'Configurar restrições personalizadas';

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
  String get todayStatusClearDayHeadline => 'Dia tranquilo, nada urgente.';

  @override
  String get todayStatusClearDaySubtext => 'Deixe o Tiler trabalhar por si.';

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
  String get tileShare => 'Bloco partilhado';

  @override
  String get tileShareActivityInvitationUnknown =>
      'Resultado do envio do convite desconhecido';

  @override
  String get tileShareActivityExplicitResend =>
      'O convite poderá ter sido enviado. Envie-o novamente de forma explícita, se necessário.';

  @override
  String get tileShareActivityEmail => 'E-mail';

  @override
  String get tileShareActivitySms => 'SMS';

  @override
  String get tileShareActivityPush => 'Notificação push';

  @override
  String get tileShareActivityTitle => 'Atividades';

  @override
  String get tileShareActivityRefresh => 'Atualizar';

  @override
  String get tileShareActivityRetry => 'Tentar novamente';

  @override
  String get tileShareActivityEmpty => 'Ainda não há atividade.';

  @override
  String get tileShareActivityFailed =>
      'Não foi possível carregar a atividade. Verifique a sua ligação e tente novamente.';

  @override
  String get tileShareActivityAccess =>
      'Esta atividade já não está disponível para si.';

  @override
  String get tileShareActivityUnknown => 'Atividade atualizada';

  @override
  String get tileShareActivityUnavailable => 'Elemento já não disponível';

  @override
  String get tileShareActivityMore => 'Carregar mais';

  @override
  String get tileShareActivityClusterCreated => 'TileShare criado';

  @override
  String get tileShareActivityClusterDeleted => 'TileShare eliminado';

  @override
  String get tileShareActivityTiletteAdded => 'Tilette adicionado';

  @override
  String get tileShareActivityTiletteEdited => 'Tilette atualizado';

  @override
  String get tileShareActivityTiletteDeleted => 'Tilette eliminado';

  @override
  String get tileShareActivityTiletteRestored => 'Tilette restaurado';

  @override
  String get tileShareActivityRecipientAdded => 'Participante adicionado';

  @override
  String get tileShareActivityRecipientRemoved => 'Participante removido';

  @override
  String get tileShareActivityRecipientRestored => 'Participante restaurado';

  @override
  String get tileShareActivityAccepted => 'Atribuição aceite';

  @override
  String get tileShareActivityDeclined => 'Atribuição recusada';

  @override
  String get tileShareActivityInvitationSent => 'Convite enviado';

  @override
  String get tileShareActivityInvitationFailed =>
      'Não foi possível enviar o convite';

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
  String get dayFilterAll => 'Tudo';

  @override
  String get dayFilterBlocks => 'Blocos';

  @override
  String get dayFilterTiles => 'Tilhas';

  @override
  String get dayFilterTooltip => 'Mostrar tudo, apenas blocos ou apenas tilhas';

  @override
  String dayFilterShowingBlocks(int shown, int total) {
    return 'Mostrando apenas blocos · $shown de $total';
  }

  @override
  String dayFilterShowingTiles(int shown, int total) {
    return 'Mostrando apenas tilhas · $shown de $total';
  }

  @override
  String dayFilterEmptyBlocks(String day) {
    return 'Nenhum bloco no $day';
  }

  @override
  String dayFilterEmptyTiles(String day) {
    return 'Nenhuma tilha no $day';
  }

  @override
  String get dayFilterShowAll => 'Mostrar tudo';

  @override
  String get dayFilterAutoCleared => 'Mostrando tudo — filtro limpo';

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
  String durationDaysHoursShort(int days, int hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durationDaysShort(int days) {
    return '${days}d';
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
  String get dayGridAllDay => 'Dia inteiro';

  @override
  String get dayGridHeaderAllClear => 'Tudo em ordem';

  @override
  String dayGridHeaderConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflitos',
      one: '1 conflito',
    );
    return '$_temp0';
  }

  @override
  String dayGridHeaderNeedAttention(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$summary precisam de aten??o',
      one: '$summary precisa de aten??o',
    );
    return '$_temp0';
  }

  @override
  String get dayGridHeaderReview => 'Rever';

  @override
  String get dayGridDaySummary => 'Resumo do dia';

  @override
  String get bottomNavToday => 'Hoje';

  @override
  String get bottomNavTiler => 'Tiler';

  @override
  String get dayGridHeaderRespond => 'Responder';

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
  String get switchDayGridLayout => 'Alterar layout do dia';

  @override
  String get openDayRibbon => 'Ver dias';

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
  String get addTileScreenTitleFlexible => 'Adicionar bloco';

  @override
  String get addTileScreenTitleFixed => 'Adicionar bloco fixo';

  @override
  String get addTileTypeFlexible => 'Bloco flexível';

  @override
  String get addTileTypeFixed => 'Bloco fixo';

  @override
  String get addTileTypeSelectorLabel => 'Tipo de bloco';

  @override
  String addTileExplanationFlexible(String emphasis) {
    return 'O Tiler encontrará o $emphasis para isso.';
  }

  @override
  String addTileExplanationFixed(String emphasis) {
    return 'Os blocos acontecem em $emphasis.';
  }

  @override
  String get addTileFindTime => 'Encontrar horário';

  @override
  String get addTileSubmitting => 'Enviando';

  @override
  String get addTileNameRequired => 'O nome é obrigatório';

  @override
  String get addTileTitleRequired => 'O título é obrigatório';

  @override
  String get addTileFieldTaskName => 'NOME DA TAREFA';

  @override
  String get addTileFieldTitle => 'TÍTULO';

  @override
  String get addTileFieldDuration => 'DURAÇÃO';

  @override
  String get addTileFieldCompleteBy => 'CONCLUIR ATÉ';

  @override
  String get addTileFieldPreferredTime => 'HORÁRIO PREFERIDO';

  @override
  String get addTileFieldDate => 'DATA';

  @override
  String get addTileFieldStarts => 'INÍCIO';

  @override
  String get addTileFieldEnds => 'TERMINO';

  @override
  String get addTileFieldLocation => 'LOCAL';

  @override
  String get addTileTaskNameHint => 'O que você quer fazer?';

  @override
  String get addTileBlockTitleHint => 'O que é este bloco?';

  @override
  String get addTileValueNotSet => 'Não definido';

  @override
  String get addTileAutoCalculated => 'Calculado automaticamente';

  @override
  String addTileEndsSemantics(String time) {
    return 'Termina às $time, calculado a partir do início e da duração';
  }

  @override
  String addTileTodayDate(String date) {
    return 'Hoje, $date';
  }

  @override
  String get addTileMoreOptions => 'Mais opções';

  @override
  String get addTilePriority => 'Prioridade';

  @override
  String get addTilePriorityLow => 'Baixa';

  @override
  String get addTilePriorityMedium => 'Média';

  @override
  String get addTilePriorityHigh => 'Alta';

  @override
  String get addTilePriorityLowMeaning => 'Se der';

  @override
  String get addTilePriorityMediumMeaning => 'Importante';

  @override
  String get addTilePriorityHighMeaning => 'Precisa ser feito';

  @override
  String get addTilePriorityHelper =>
      'A prioridade ajuda o Tiler a decidir o que proteger primeiro.';

  @override
  String get addTileColorAutomatic => 'Automático';

  @override
  String get addTileColorCustom => 'Personalizado';

  @override
  String get addTileSplitIntoSessions => 'Dividir em sessões';

  @override
  String get addTileSplitHelper =>
      'Divida isto em horas de trabalho separadas.';

  @override
  String addTileSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões',
      one: '1 sessão',
    );
    return '$_temp0';
  }

  @override
  String get addTileFewerSessions => 'Menos sessões';

  @override
  String get addTileMoreSessions => 'Mais sessões';

  @override
  String get addTileFlexibleCompletion => 'Data de conclusão flexível';

  @override
  String get addTileFlexibleCompletionHelper =>
      'O Tiler pode mover esta data levemente se necessário.';

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
  String get addTileRepeatNever => 'Não repete';

  @override
  String get addTileRepeatDays => 'DIAS';

  @override
  String get addTileRepeatsUntil => 'REPETE ATÉ';

  @override
  String get addTileRepeatHelper =>
      'A repetição ajuda o Tiler a planejar tarefas recorrentes.';

  @override
  String get addTileLocationSearchHint => 'Pesquisar locais';

  @override
  String get addTileLocationYourPlaces => 'SEUS LOCAIS';

  @override
  String get addTileLocationSuggestions => 'SUGESTÕES';

  @override
  String get addTileLocationHelper =>
      'O local ajuda o Tiler a otimizar deslocamentos e horários.';

  @override
  String get addTileLocationNoneSaved => 'Nenhum local salvo ainda';

  @override
  String get addTileLocationNoneSavedHelper =>
      'Pesquise um local ou digite um nome como \"loja de bicicletas\" para salvá-lo.';

  @override
  String get addTileLocationNoResults => 'Nenhum local encontrado';

  @override
  String get addTileLocationNoResultsHelper =>
      'Você ainda pode salvar o que digitou como nome do local.';

  @override
  String get addTileLocationSearchFailed =>
      'A pesquisa não está disponível agora';

  @override
  String get addTileLocationSearchFailedHelper =>
      'Verifique sua conexão e tente novamente, ou salve o que digitou como nome do local.';

  @override
  String addTileLocationUseTyped(String query) {
    return 'Usar \"$query\"';
  }

  @override
  String get addTileLocationUseTypedHelper => 'Dê a ele um nome e endereço';

  @override
  String get addTileLocationFallbackName => 'Local';

  @override
  String get addTilePlaceAdd => 'Adicionar local';

  @override
  String get addTilePlaceEdit => 'Editar local';

  @override
  String get addTilePlaceName => 'NOME';

  @override
  String get addTilePlaceAddress => 'ENDEREÇO';

  @override
  String get addTilePlaceNameHint => 'ex.: Walmart perto do trabalho';

  @override
  String get addTilePlaceAddressHint => 'Rua, cidade, estado';

  @override
  String get addTilePlaceSave => 'Salvar local';

  @override
  String get addTilePlaceNameThis => 'Dar nome a este local';

  @override
  String get addTilePlaceNameHelper =>
      'O nome é como você encontra este local novamente. Se dois locais tiverem o mesmo nome, apenas o endereço mais recente será mantido.';

  @override
  String addTilePlaceNameTaken(String name, String address) {
    return 'Você já tem um local chamado \"$name\" no endereço $address. Ao salvar, este nome será movido para este endereço.';
  }

  @override
  String addTilePlaceNameTakenNoAddress(String name) {
    return 'Você já tem um local chamado \"$name\". Ao salvar, este nome será movido para este endereço.';
  }

  @override
  String get addTileFieldPriority => 'PRIORIDADE';

  @override
  String get addTileFieldColor => 'COR';

  @override
  String get addTileColorPresets => 'PRÉ-DEFINIDAS';

  @override
  String get addTileColorAutomaticHelper => 'O Tiler escolhe uma cor para você';

  @override
  String get addTileColorCustomHelper => 'Escolha qualquer cor';

  @override
  String get addTileColorHelper =>
      'A cor só muda a aparência no seu cronograma.';

  @override
  String get addTileColorShuffle => 'Sortear outra cor';

  @override
  String addTileColorSwatch(int index) {
    return 'Cor $index';
  }

  @override
  String get addTileExplanationFlexibleEmphasis => 'melhor horário';

  @override
  String get addTileExplanationFixedEmphasis => 'um horário fixo';

  @override
  String get addTileFieldRepeat => 'REPETIÇÃO';

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
    return 'A PARTIR DAS $start';
  }

  @override
  String addTileDurationEndsNextDay(String time) {
    return '$time, dia seguinte';
  }

  @override
  String addTileDurationEndsSemantics(String end, String start) {
    return 'Termina às $end, a partir de um início às $start. Alterar o horário de término';
  }

  @override
  String get editTileTitleTile => 'Editar bloco';

  @override
  String get editTileTitleBlock => 'Editar bloco';

  @override
  String get editTileSave => 'Salvar alterações';

  @override
  String get editTileSaving => 'Salvando…';

  @override
  String get editTileSectionTiming => 'AGENDA';

  @override
  String get editTileReasonNameRequired =>
      'Dê um título a este bloco para salvá-lo';

  @override
  String get editTileReasonSplitRequired => 'As sessões devem ser no mínimo 1';

  @override
  String get editTileReasonEndNotAfterStart =>
      'O término deve ser após o início';

  @override
  String get editTileDiscardTitle => 'Descartar alterações?';

  @override
  String get editTileDiscardBody =>
      'Suas alterações neste bloco serão perdidas.';

  @override
  String get editTileDiscard => 'Descartar';

  @override
  String get editTileKeepEditing => 'Continuar editando';

  @override
  String get editTileLoadFailed => 'Não foi possível carregar este bloco.';

  @override
  String get editTileSaveFailed =>
      'Não foi possível salvar agora. Suas alterações são mantidas.';

  @override
  String get editTileSectionActions => 'AÇÕES';

  @override
  String get editTileSectionSessions => 'SESSÕES';

  @override
  String get editTileFieldSessions => 'Dividir em sessões';

  @override
  String get editTileFieldDeadline => 'PRAZO';

  @override
  String get editTileSectionAdditional => 'DETALHES ADICIONAIS';

  @override
  String get editTileSectionSuggestions => 'SUGESTÕES';

  @override
  String get editTileCreateAsNewTile => 'Criar como novo bloco';

  @override
  String get editTileSectionProgress => 'PROGRESSO';

  @override
  String editTileProgressComplete(int done, int total) {
    return '$done de $total concluídos';
  }

  @override
  String editTileProgressRemaining(int remaining, int deleted) {
    return '$remaining restantes · $deleted excluídos';
  }

  @override
  String get editTileActionComplete => 'Concluir';

  @override
  String get editTileActionCompleteCaption => 'Marcar como feito';

  @override
  String get editTileActionStartNow => 'Começar agora';

  @override
  String get editTileActionStartNowCaption => 'Mover para agora';

  @override
  String get editTileActionDefer => 'Adiar';

  @override
  String get editTileActionDeferCaption => 'Escolher outro horário';

  @override
  String get editTileActionDelete => 'Excluir';

  @override
  String get editTileActionDeleteCaption => 'Remover';

  @override
  String editTileActionConfirmComplete(String title) {
    return 'Marcar \"$title\" como feito?';
  }

  @override
  String editTileActionConfirmStartNow(String title) {
    return 'Mover \"$title\" para agora?';
  }

  @override
  String editTileActionConfirmDefer(String title) {
    return 'Adiar \"$title\"?';
  }

  @override
  String editTileActionConfirmDelete(String title) {
    return 'Excluir \"$title\"?';
  }

  @override
  String get editTileActionDeleteBody =>
      'Isso remove o bloco do seu cronograma.';

  @override
  String get editTileActionDiscardsEdits =>
      'Suas alterações não salvas serão descartadas.';

  @override
  String get editTileActionFailed => 'Ação não disponível agora.';

  @override
  String editTileActionSemantics(String label, String caption) {
    return '$label, $caption';
  }

  @override
  String get editTileSectionRepetition => 'REPETIÇÃO';

  @override
  String get editTileSectionPriority => 'PRIORIDADE';

  @override
  String get editTileSectionLocation => 'LOCAL';

  @override
  String get editTileLocationRemove => 'Remover local';

  @override
  String get addTileDeadlineClear => 'Remover prazo';

  @override
  String get editTileMenuTileDetails => 'Detalhes do bloco';

  @override
  String get editTileMoreMenu => 'Mais';

  @override
  String get editTileRepeatEveryDay => 'Todos os dias';

  @override
  String get editTileRepeatEveryWeek => 'Toda semana';

  @override
  String editTileRepeatEveryWeekOn(String days) {
    return 'Toda semana em $days';
  }

  @override
  String get editTileRepeatEveryMonth => 'Todo mês';

  @override
  String get editTileRepeatEveryYear => 'Todo ano';

  @override
  String editTileRepeatUntil(String cadence, String date) {
    return '$cadence · até $date';
  }

  @override
  String editTileRepeatUntilDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String editTileRepeatNeverEnds(String cadence) {
    return '$cadence · nunca termina';
  }

  @override
  String get editTileRepeatCalloutTitle => 'Isso criará múltiplas instâncias';

  @override
  String get editTileRepeatCalloutBody =>
      'O Tiler planejará cada ocorrência com base nas suas preferências e disponibilidade.';

  @override
  String get editTileNotesTitle => 'Notas';

  @override
  String get editTileModeReadOnly =>
      'Este bloco está concluído e não pode ser editado. Você ainda pode excluí-lo.';

  @override
  String get editTileModeProcrastinate =>
      'Tempo bloqueado. Mova-o, marque como concluído ou remova-o.';

  @override
  String editTileModeThirdParty(String provider) {
    return 'Gerenciado pelo $provider. Responda ao convite ou exclua-o aqui; edite o evento no $provider.';
  }

  @override
  String get editTileProviderGoogle => 'Google Agenda';

  @override
  String get editTileProviderOutlook => 'Outlook';

  @override
  String get editTileRsvpFailed =>
      'Não foi possível enviar sua resposta agora.';

  @override
  String get editTileWhatIfChecking =>
      'Verificando o que esta alteração afeta…';

  @override
  String editTileWhatIfSummary(int late, int overflow) {
    return 'Afeta outros blocos: $late atrasados, $overflow em estouro';
  }

  @override
  String get editTileWhatIfSheetTitle => 'O que esta alteração afeta';

  @override
  String get editTileWhatIfLate => 'Atrasado';

  @override
  String get editTileWhatIfOverflow => 'Estouro';

  @override
  String get editTileWhatIfClean => 'Nenhum outro bloco é afetado.';

  @override
  String get editTileWhatIfFailed =>
      'Não foi possível verificar o efeito no seu cronograma.';

  @override
  String get editTileWhatIfRetry => 'Tentar novamente';

  @override
  String editTileWhatIfMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias adicionais afetados',
      one: '1 dia adicional afetado',
    );
    return '$_temp0';
  }

  @override
  String get editTileWhatIfUnplaced => 'Não posicionado';

  @override
  String editTileWhatIfAffectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocos afetados',
      one: '1 bloco afetado',
    );
    return '$_temp0';
  }

  @override
  String get editTileEditTitle => 'Editar título';

  @override
  String get tileDetailTitle => 'Detalhes do bloco';

  @override
  String get tileDetailLoadFailed =>
      'Não foi possível carregar os detalhes deste bloco.';

  @override
  String get tileDetailSaveFailed =>
      'Não foi possível salvar agora. Suas alterações são mantidas.';

  @override
  String get tileDetailDeleteSeries => 'Excluir bloco';

  @override
  String tileDetailDeleteConfirm(String title) {
    return 'Excluir \"$title\"?';
  }

  @override
  String get tileDetailDeleteBody =>
      'Cada ocorrência deste bloco será removida do seu cronograma.';

  @override
  String get tileDetailDeleteFailed => 'Não foi possível excluir agora.';

  @override
  String get tileDetailSectionOccurrences => 'OCORRÊNCIAS';

  @override
  String get tileDetailOccurrencesEmpty => 'Nenhuma ocorrência agendada ainda.';

  @override
  String get tileDetailOccurrencesFailed =>
      'Não foi possível carregar as ocorrências.';

  @override
  String get tileDetailOccurrencesEarlier => 'Mostrar anteriores';

  @override
  String get tileDetailOccurrencesLater => 'Mostrar posteriores';

  @override
  String get tileDetailOccurrenceDone => 'Concluído';

  @override
  String tileDetailOccurrenceSemantics(String day, String span, String done) {
    return '$day, $span$done';
  }

  @override
  String editTileTimeChipSemantics(String field, String value) {
    return 'Horário de $field, $value';
  }

  @override
  String editTileDateChipSemantics(String field, String value) {
    return 'Data de $field, $value';
  }

  @override
  String get addTileSubmitFailed =>
      'Não foi possível adicionar agora. Seus detalhes estão salvos.';

  @override
  String get addTileRetry => 'Tentar novamente';

  @override
  String get addTileTimeRestrictionTitle => 'Restrições de horário';

  @override
  String get addTileTimeRestrictionHeading =>
      'Quando o Tiler pode agendar isto?';

  @override
  String get addTileTimeRestrictionSubtitle =>
      'Defina quando esta tilha pode aparecer no seu calendário.';

  @override
  String get addTileRestrictionAnytimeHelper =>
      'O Tiler pode colocá-la quando estiver disponível.';

  @override
  String get addTileRestrictionWork => 'Horário de trabalho';

  @override
  String get addTileRestrictionWorkHelper =>
      'Agendar apenas no seu perfil Trabalho.';

  @override
  String get addTileRestrictionPersonal => 'Horário pessoal';

  @override
  String get addTileRestrictionPersonalHelper =>
      'Agendar apenas no seu perfil Pessoal.';

  @override
  String get addTileRestrictionCustom => 'Horário personalizado';

  @override
  String get addTileRestrictionCustomHelper =>
      'Escolha dias e horários específicos.';

  @override
  String get addTileRestrictionNotSetUp =>
      'Não configurado — use a seta para definir horários';

  @override
  String addTileRestrictionEdit(String name) {
    return 'Editar $name';
  }

  @override
  String get addTileRestrictionTip =>
      'O Tiler respeitará estas restrições ao agendar automaticamente, reotimizar ou sugerir horários para esta tilha.';

  @override
  String get addTileRestrictionLoadFailed =>
      'Não foi possível carregar seus horários de Trabalho e Pessoal.';

  @override
  String addTileRestrictionDayRange(String first, String last) {
    return '$first – $last';
  }

  @override
  String addTileRestrictionWindow(String days, String start, String end) {
    return '$days · $start – $end';
  }

  @override
  String get addTileCustomHoursTitle => 'Horário personalizado';

  @override
  String get addTileCustomHoursSubtitle =>
      'Selecione os dias e janelas de horário em que esta tilha pode ser agendada.';

  @override
  String addTileCustomHoursProfileSubtitle(String name) {
    return 'Selecione os dias e janelas de horário para $name.';
  }

  @override
  String get addTileCustomHoursPresets => 'Predefinições rápidas';

  @override
  String get addTileHoursPresetWeekdays => 'Dias úteis';

  @override
  String get addTileHoursPresetEvenings => 'Noites';

  @override
  String get addTileHoursPresetWeekends => 'Fins de semana';

  @override
  String addTileHoursPresetWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String addTileHoursEndsNextDay(String day, String time) {
    return 'Termina $day às $time';
  }

  @override
  String addTileRestrictionWindowNextDay(
      String days, String start, String end) {
    return '$days · $start – $end (dia seguinte)';
  }

  @override
  String get addTileRestrictionAllDay => 'Dia inteiro';

  @override
  String addTileRestrictionAllDayWindow(String days, String label) {
    return '$days · $label';
  }

  @override
  String get addTileCustomHoursFooter =>
      'Dias desativados serão excluídos do agendamento desta tilha.';

  @override
  String addTileCustomHoursProfileFooter(String name) {
    return 'Aplica-se a cada tilha que usa $name.';
  }

  @override
  String addTileHoursCopy(String day) {
    return 'Copiar horários de $day';
  }

  @override
  String addTileHoursPaste(String day) {
    return 'Colar horários em $day';
  }

  @override
  String get addTileHoursClearCopy => 'Limpar horários copiados';

  @override
  String addTileHoursStartSemantics(String day, String time) {
    return 'Início de $day, $time';
  }

  @override
  String addTileHoursEndSemantics(String day, String time) {
    return 'Fim de $day, $time';
  }

  @override
  String addTileHoursSaveFailed(String name) {
    return 'Não foi possível salvar $name.';
  }

  @override
  String get addTileHoursSaving => 'Salvando…';

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
  String commentsCount(int count) {
    return '$count comentários';
  }

  @override
  String get commentsEmpty => 'Ainda não há comentários';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentsLoading => 'Carregando…';

  @override
  String get commentsLoadEarlier => 'Carregar comentários anteriores';

  @override
  String get commentsLoadEarlierReplies => 'Carregar respostas anteriores';

  @override
  String get commentsRetry => 'Tentar novamente';

  @override
  String get commentsLoadError =>
      'Não foi possível carregar os comentários. Tente novamente.';

  @override
  String get commentsCreateError => 'Não foi possível publicar seu comentário.';

  @override
  String get commentsEditError => 'Não foi possível salvar sua edição.';

  @override
  String get commentsDeleteError => 'Não foi possível excluir o comentário.';

  @override
  String get commentsCreateReplyError =>
      'Não foi possível publicar sua resposta.';

  @override
  String get commentsPlaceholder => 'Escreva um comentário…';

  @override
  String get commentsReplyPlaceholder => 'Escreva uma resposta…';

  @override
  String get commentsSend => 'Enviar';

  @override
  String get commentsSending => 'Enviando…';

  @override
  String get commentsEdit => 'Editar';

  @override
  String get commentsSave => 'Salvar';

  @override
  String get commentsCancel => 'Cancelar';

  @override
  String get commentsDelete => 'Excluir';

  @override
  String get commentsEdited => 'editado';

  @override
  String get commentsDeletedPlaceholder => 'Este comentário foi excluído.';

  @override
  String get commentsDeletedAuthor => 'Usuário excluído';

  @override
  String get commentsReply => 'Responder';

  @override
  String commentsReplies(int count) {
    return '$count respostas';
  }

  @override
  String get commentsShowReplies => 'Mostrar respostas';

  @override
  String get commentsHideReplies => 'Ocultar respostas';

  @override
  String get commentsYou => '(você)';

  @override
  String get commentsMentionSuggestions => 'Pessoas que você pode mencionar';

  @override
  String get commentsAttach => 'Anexar arquivo';

  @override
  String get commentsAttachmentProcessing => 'Verificando arquivo…';

  @override
  String get commentsAttachmentUploaded => 'Enviado';

  @override
  String get commentsAttachmentQueued => 'Na fila';

  @override
  String commentsAttachmentUploadingSummary(int count) {
    return 'Enviando arquivos ($count restantes). Mantenha esta página aberta.';
  }

  @override
  String get commentsAttachmentUploadFailed => 'Falha no envio';

  @override
  String get commentsAttachmentPickFailed =>
      'Não foi possível anexar esse arquivo. Tente novamente.';

  @override
  String commentsAttachmentRemove(String name) {
    return 'Remover $name';
  }

  @override
  String get commentsAttachmentDownload => 'Baixar';

  @override
  String get commentsAttachmentDownloadError =>
      'Não foi possível baixar o arquivo.';

  @override
  String get commentsAttachmentDownloading => 'A transferir…';

  @override
  String commentsAttachmentSaved(String name) {
    return 'Guardado: $name';
  }

  @override
  String get commentsAttachmentOpen => 'Abrir';

  @override
  String get commentsAttachmentOpenFailed =>
      'Não foi possível abrir o ficheiro.';

  @override
  String get commentsAttachmentInvalidType =>
      'Apenas arquivos PDF, DOCX, PNG e JPEG podem ser anexados.';

  @override
  String get commentsAttachmentTooLarge =>
      'Os arquivos devem ter 10 MB ou menos.';

  @override
  String get commentsAttachmentEmpty => 'Esse arquivo está vazio.';

  @override
  String commentsAttachmentLimit(int count) {
    return 'Você pode anexar até $count arquivos.';
  }

  @override
  String get productTourStarting => 'O tour da app está prestes a começar.';

  @override
  String get attentionTabTitle => 'Atenção';

  @override
  String get attentionFilterAll => 'Tudo';

  @override
  String get attentionFilterInvitations => 'Convites';

  @override
  String get attentionFilterChanges => 'Alterações';

  @override
  String get attentionFilterAtRisk => 'Em risco';

  @override
  String get attentionFilterResponses => 'Respostas';

  @override
  String get attentionPillInvitation => 'Convite';

  @override
  String get attentionPillChanged => 'Alterado';

  @override
  String get attentionPillAtRisk => 'Em risco';

  @override
  String get attentionPillDeclined => 'Recusado';

  @override
  String get attentionPillCompleted => 'Concluído';

  @override
  String get attentionPillNotSent => 'Não enviado';

  @override
  String get attentionSomeone => 'Alguém';

  @override
  String attentionReasonInvited(String inviter) {
    return '$inviter convidou você';
  }

  @override
  String attentionReasonInvitedMany(String inviter, int count) {
    return '$inviter convidou você para $count tilettes';
  }

  @override
  String attentionReasonAtRiskOne(String task) {
    return '“$task” não cabe mais na sua agenda';
  }

  @override
  String get attentionReasonAtRiskUntitled =>
      'Uma tilette não cabe mais na sua agenda';

  @override
  String attentionReasonAtRiskMany(int count) {
    return '$count tilettes não cabem mais na sua agenda';
  }

  @override
  String attentionReasonDeadlineMoved(String actor, String from, String to) {
    return '$actor mudou o prazo de $from para $to';
  }

  @override
  String attentionReasonDeadlineChanged(String actor) {
    return '$actor alterou o prazo';
  }

  @override
  String attentionReasonRenamed(String actor) {
    return '$actor renomeou uma tilette';
  }

  @override
  String attentionReasonNotesUpdated(String actor) {
    return '$actor atualizou as notas';
  }

  @override
  String attentionReasonUpdated(String actor) {
    return '$actor atualizou uma tilette';
  }

  @override
  String attentionReasonManyChanges(String actor, int count) {
    return '$actor fez $count alterações';
  }

  @override
  String attentionReasonDeclined(String actor) {
    return '$actor recusou';
  }

  @override
  String attentionReasonDeclinedMany(int count) {
    return '$count pessoas recusaram';
  }

  @override
  String get attentionReasonNotSent => 'Não foi possível enviar um convite';

  @override
  String attentionReasonNotSentMany(int count) {
    return 'Não foi possível enviar $count convites';
  }

  @override
  String get attentionReasonSendUnknown =>
      'Um convite pode não ter sido enviado — envie novamente se necessário';

  @override
  String attentionReasonCompleted(String actor, String task) {
    return '$actor concluiu $task';
  }

  @override
  String attentionReasonCompletedUntitled(String actor) {
    return '$actor concluiu uma tilette';
  }

  @override
  String attentionReasonCompletedMany(int count) {
    return '$count tilettes concluídas';
  }

  @override
  String attentionMetaTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tilettes',
      one: '1 tilette',
    );
    return '$_temp0';
  }

  @override
  String attentionMetaDue(String date) {
    return 'Prazo: $date';
  }

  @override
  String get attentionCtaReview => 'Revisar';

  @override
  String get attentionCtaReviewChanges => 'Revisar alterações';

  @override
  String get attentionCtaReviewPlan => 'Revisar plano';

  @override
  String get attentionCtaView => 'Ver';

  @override
  String get attentionMenuTooltip => 'Mais';

  @override
  String get attentionDismiss => 'Dispensar';

  @override
  String get attentionDismissed => 'Dispensado';

  @override
  String get attentionUndo => 'Desfazer';

  @override
  String get attentionDismissFailed =>
      'Não foi possível dispensar. Tente novamente.';

  @override
  String get attentionUndoFailed =>
      'Não foi possível restaurar. Tente novamente.';

  @override
  String get attentionEmptyTitle => 'Você está em dia';

  @override
  String get attentionEmptyBody => 'Nada precisa da sua atenção agora.';

  @override
  String get attentionEmptyFiltered => 'Nada para mostrar aqui';

  @override
  String get attentionLoadFailed =>
      'Não foi possível carregar algumas atualizações';

  @override
  String get attentionLoadFailedAll => 'Não foi possível carregar Atenção';

  @override
  String get attentionRetry => 'Tentar novamente';

  @override
  String get tileShareModeBroadcast => 'Transmissão';

  @override
  String get tileShareModeProject => 'Projeto';

  @override
  String get tileShareModeClass => 'Turma';

  @override
  String get attentionAccept => 'Aceitar';

  @override
  String get attentionDecline => 'Recusar';

  @override
  String get attentionAcceptAll => 'Aceitar tudo';

  @override
  String get attentionDeclineAll => 'Recusar tudo';

  @override
  String get attentionAcceptDone => 'Aceito';

  @override
  String attentionAcceptDoneMany(int count) {
    return '$count tilettes aceitas';
  }

  @override
  String get attentionDeclineDone => 'Recusado';

  @override
  String attentionDeclineDoneMany(int count) {
    return '$count tilettes recusadas';
  }

  @override
  String get attentionAcceptFailed =>
      'Não foi possível aceitar. Tente novamente.';

  @override
  String get attentionDeclineFailed =>
      'Não foi possível recusar. Tente novamente.';

  @override
  String get attentionScheduleRefreshFailed =>
      'Aceito, mas ainda não foi possível atualizar sua agenda.';

  @override
  String get clusterTitleFallback => 'Compartilhamento sem título';

  @override
  String get clusterRoleMine => 'Criado por você';

  @override
  String clusterRoleFrom(String name) {
    return 'De $name';
  }

  @override
  String get clusterRoleShared => 'Compartilhado com você';

  @override
  String clusterRsvpAccepted(int accepted, int total) {
    return '$accepted de $total aceitos';
  }

  @override
  String clusterRsvpPeople(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total pessoas aceitaram',
      one: '1 pessoa aceitou',
    );
    return '$accepted de $_temp0';
  }

  @override
  String clusterRsvpTasks(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tilettes aceitas',
      one: '1 tilette aceita',
    );
    return '$accepted de $_temp0';
  }

  @override
  String get clusterRsvpUnavailable => 'Respostas indisponíveis';

  @override
  String get clusterMineAccepted => 'Você aceitou';

  @override
  String get clusterMineDeclined => 'Você recusou';

  @override
  String get clusterMinePending => 'Precisa da sua resposta';

  @override
  String get clusterMineMixed => 'Respondido parcialmente';

  @override
  String clusterProjectNeedsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tilettes precisam da sua resposta',
      one: '1 tilette precisa da sua resposta',
    );
    return '$_temp0';
  }

  @override
  String get clusterOverdue => 'Atrasado';

  @override
  String get clusterMenuTooltip => 'Mais ações';

  @override
  String get clusterDelete => 'Excluir';

  @override
  String get clusterDeleteTitle => 'Excluir este compartilhamento?';

  @override
  String clusterDeleteBody(String name) {
    return '“$name” será excluído. Isso não pode ser desfeito.';
  }

  @override
  String clusterDeleteFailed(String name) {
    return 'Não foi possível excluir “$name”. O compartilhamento voltou à sua lista.';
  }

  @override
  String get clusterFilterAll => 'Tudo';

  @override
  String get clusterFilterShared => 'Compartilhado comigo';

  @override
  String get clusterFilterCreated => 'Criado por mim';

  @override
  String get clusterEmptyAllTitle => 'Nada compartilhado ainda';

  @override
  String get clusterEmptyAllBody =>
      'Compartilhe um bloco com alguém e ele aparecerá aqui.';

  @override
  String get clusterEmptySharedTitle => 'Nada compartilhado com você';

  @override
  String get clusterEmptySharedBody =>
      'Quando alguém compartilhar um bloco com você, ele aparecerá aqui.';

  @override
  String get clusterEmptyCreatedTitle => 'Você ainda não compartilhou nada';

  @override
  String get clusterEmptyCreatedBody =>
      'Compartilhe um bloco para ver quem aceitou.';

  @override
  String get clusterEmptyAction => 'Compartilhar um bloco';

  @override
  String get clusterLoadFailed =>
      'Não foi possível carregar alguns compartilhamentos';

  @override
  String get clusterLoadFailedAll =>
      'Não foi possível carregar os compartilhamentos';

  @override
  String get clusterLoadMore => 'Carregar mais';

  @override
  String get clusterLoadMoreFailed => 'Não foi possível carregar mais';

  @override
  String get clustersTabTitle => 'Compartilhamentos';

  @override
  String get previewTitleFallback => 'Revisar agenda';

  @override
  String get previewRegenerate => 'Gerar nova prévia';

  @override
  String get previewSuggested => 'Agenda sugerida';

  @override
  String get previewSelected => 'Agenda selecionada';

  @override
  String previewMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count blocos flexíveis',
      one: 'Move 1 bloco flexível',
    );
    return '$_temp0';
  }

  @override
  String get previewAccept => 'Aceitar';

  @override
  String get previewAcceptAndLock => 'Aceitar e fixar';

  @override
  String get previewAcceptHint => 'Tiler pode mover tarefas flexíveis depois.';

  @override
  String previewLockHint(String when) {
    return 'Fixa $when. As outras sessões continuam flexíveis.';
  }

  @override
  String get previewDecline => 'Recusar';

  @override
  String get previewCannotFit => 'Não é possível encaixar antes do prazo.';

  @override
  String previewOutsideWindow(String when) {
    return 'Agendado fora dos dias mostrados: $when';
  }

  @override
  String get previewNothingThisDay => 'Nada agendado neste dia';

  @override
  String get previewPrevDay => 'Dia anterior';

  @override
  String get previewNextDay => 'Próximo dia';

  @override
  String get previewStale => 'Esta prévia está desatualizada.';

  @override
  String get previewRefresh => 'Atualizar prévia';

  @override
  String get previewSessionInvalid =>
      'Este horário não pode mais ser fixado. Você ainda pode aceitar.';

  @override
  String get previewLoading => 'Verificando sua agenda…';

  @override
  String get previewLoadFailed => 'Não foi possível gerar a prévia.';

  @override
  String get previewGone => 'Este convite não está mais disponível.';

  @override
  String get previewSwitchedOff => 'As prévias não estão disponíveis agora.';

  @override
  String get previewSignIn => 'Entre novamente para ver a prévia.';

  @override
  String get previewInvalid =>
      'Essa solicitação não foi aceita. Tente novamente.';

  @override
  String get previewUnsupportedAccepted => 'Você já aceitou.';

  @override
  String get previewUnsupportedDeadline => 'O prazo já passou.';

  @override
  String get previewUnsupportedConstraints =>
      'Esta tilette se repete, tem um local ou limites que a prévia ainda não consegue mostrar. Você ainda pode responder pela lista.';

  @override
  String get previewUnsupportedOther =>
      'Não é possível gerar uma prévia desta tilette.';

  @override
  String get previewAdding => 'Adicionando ao seu calendário…';

  @override
  String get previewAdded => 'Adicionado ao seu calendário';

  @override
  String get previewNeedsReview =>
      'Adicionado, mas não foi possível confirmar o horário.';

  @override
  String get previewNotAdded => 'Não adicionado';

  @override
  String get previewReasonScheduleChanged =>
      'Sua agenda mudou desde esta prévia.';

  @override
  String get previewReasonAnswered =>
      'Já houve uma resposta ou alteração em outro lugar.';

  @override
  String get previewReasonExpired => 'A prévia expirou.';

  @override
  String get previewReasonOther => 'Não foi possível agendar como na prévia.';

  @override
  String get previewReviewAgain => 'Revisar novamente';

  @override
  String get previewUnconfirmed => 'Não foi possível confirmar sua resposta.';

  @override
  String get previewTryAgain => 'Tentar novamente';

  @override
  String get previewCheckStatus => 'Verificar status';

  @override
  String get previewStillAdding => 'Ainda adicionando…';

  @override
  String get previewDeclined => 'Recusado';

  @override
  String get previewDeclineFailed =>
      'Não foi possível recusar. Tente novamente.';

  @override
  String get previewDone => 'Concluído';

  @override
  String get previewCheckFit => 'Verificar disponibilidade';

  @override
  String get previewDetails => 'Detalhes';

  @override
  String get previewOtherTimes => 'Outros horários';

  @override
  String get previewOriginalSuggestion => 'Sugestão original';

  @override
  String get previewFindAnotherTime => 'Encontrar outro horário';

  @override
  String get previewFindingTimes => 'Procurando outros horários…';

  @override
  String get previewNoDifferentTime => 'Nenhum outro horário encontrado';

  @override
  String get previewOptionsFailed =>
      'Não foi possível carregar outros horários.';

  @override
  String get previewSelectFailed => 'Não foi possível mudar para esse horário.';

  @override
  String get previewNoMoves => 'Não move mais nada';

  @override
  String get previewSessions => 'Sessões';

  @override
  String previewSessionN(int n) {
    return 'Sessão $n';
  }

  @override
  String get previewSessionUnplaced => 'Não foi possível encaixar';

  @override
  String get previewSessionOutside => 'Fora dos dias mostrados';

  @override
  String previewIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemas de agendamento',
      one: '1 problema de agendamento',
    );
    return '$_temp0';
  }

  @override
  String get previewIssueUnscheduled => 'Não foi possível agendar';

  @override
  String get previewIssueConflict => 'Sobrepõe outras tarefas';

  @override
  String previewIssueWindow(String from, String to) {
    return 'Pode ser entre $from e $to';
  }

  @override
  String get previewViewInCalendar => 'Ver no calendário';

  @override
  String get detailLoadFailed =>
      'Não foi possível carregar este compartilhamento.';

  @override
  String get detailNotFound =>
      'Este compartilhamento não está mais disponível.';

  @override
  String get detailRefreshFailed =>
      'Não foi possível atualizar. Mostrando o que já foi carregado.';

  @override
  String get detailTasksFailed => 'Não foi possível carregar suas tilettes.';

  @override
  String get detailTasks => 'Tilettes';

  @override
  String get forecastDeadlinePassed => 'Prazo encerrado';

  @override
  String get broadcastParticipants => 'Participantes';

  @override
  String broadcastViewAll(int count) {
    return 'Ver todos ($count)';
  }

  @override
  String get broadcastNoParticipants => 'Ainda ninguém. Adicione alguém acima.';

  @override
  String get projectNoParticipants =>
      'Ainda ninguém. Atribua uma tilette a alguém na aba Tilettes.';

  @override
  String broadcastDeliveryIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites podem não ter chegado',
      one: '1 convite pode não ter chegado',
    );
    return '$_temp0';
  }

  @override
  String get participantInvited => 'Convidado';

  @override
  String get participantAdding => 'Adicionando…';

  @override
  String get participantAddFailed => 'Não foi possível adicionar.';

  @override
  String get participantRemoveFailed => 'Não foi possível remover.';

  @override
  String participantAlreadyInvited(String who) {
    return '$who já recebeu um convite.';
  }

  @override
  String get participantRemove => 'Remover';

  @override
  String participantRemoveTitle(String who) {
    return 'Remover $who?';
  }

  @override
  String get participantRemoveBody => 'Essa pessoa não terá mais esta tilette.';

  @override
  String deliverySent(String channel) {
    return 'Enviado por $channel';
  }

  @override
  String get deliverySentPlain => 'Convite enviado';

  @override
  String deliveryFailed(String channel) {
    return 'Não foi possível enviar por $channel';
  }

  @override
  String get deliveryFailedPlain => 'Não foi possível enviar o convite';

  @override
  String get deliveryUnknown => 'Entrega desconhecida';

  @override
  String get channelEmail => 'e-mail';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelPush => 'notificação';

  @override
  String classPeopleIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas estão ausentes de algumas tilettes',
      one: '1 pessoa está ausente de algumas tilettes',
    );
    return '$_temp0';
  }

  @override
  String classMissingTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ausente de $count tilettes',
      one: 'Ausente de 1 tilette',
    );
    return '$_temp0';
  }

  @override
  String get classAddToAll => 'Adicionar a todas as tilettes';

  @override
  String get classRemoveBody =>
      'Essa pessoa será removida de todas as tilettes.';

  @override
  String get classTaskNotAdded => 'Não adicionado';

  @override
  String get classAddFailed =>
      'Não foi possível adicionar a todas as tilettes.';

  @override
  String get projectUnassigned => 'Ninguém atribuído';

  @override
  String projectTasksUnassigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tilettes não estão atribuídas a ninguém',
      one: '1 tilette não está atribuída a ninguém',
    );
    return '$_temp0';
  }

  @override
  String get projectAssign => 'Atribuir';

  @override
  String get projectReassign => 'Reatribuir';

  @override
  String get projectReassigning => 'Reatribuindo…';

  @override
  String get projectReassignFailed => 'Não foi possível reatribuir.';

  @override
  String projectAssignTitle(String task) {
    return 'Atribuir $task';
  }

  @override
  String projectOwnsTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Responsável por $count tilettes',
      one: 'Responsável por 1 tilette',
    );
    return '$_temp0';
  }

  @override
  String get projectAlreadyIn => 'Já está neste projeto';

  @override
  String get projectRemoveBody =>
      'As tilettes dessa pessoa ficarão sem responsável.';

  @override
  String get tileShareActivityCommentAdded => 'Comentário adicionado';

  @override
  String get tileShareActivityCommentReplied =>
      'Resposta ao comentário adicionada';

  @override
  String get tileShareActivityCommentEdited => 'Comentário editado';

  @override
  String get tileShareActivityCommentDeleted => 'Comentário excluído';

  @override
  String get commitmentYourTasks => 'Suas tilettes';

  @override
  String get commitmentYourTask => 'Sua tilette';

  @override
  String commitmentPartialAnswered(int done, int total) {
    return '$done de $total respondidos; os demais ainda estão pendentes.';
  }

  @override
  String get commitmentOpenTile => 'Abrir bloco';

  @override
  String get detailEditShare => 'Editar compartilhamento';

  @override
  String get detailEditTask => 'Editar tilette';

  @override
  String get detailAddTask => 'Adicionar tilette';

  @override
  String get detailDeleteTask => 'Excluir tilette';

  @override
  String detailDeleteTaskTitle(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get detailDeleteTaskBody =>
      'Será removida da agenda de todos os participantes.';

  @override
  String get detailEditFailed =>
      'Não foi possível salvar sua alteração. Tente novamente.';

  @override
  String get detailTaskLengthFixed =>
      'A duração de uma tilette não pode mudar depois de compartilhada.';

  @override
  String get taskSheetAssignee => 'RESPONSÁVEL';

  @override
  String get taskSheetEveryone => 'Todos nesta turma têm esta tilette.';

  @override
  String taskSheetAfterShareDeadline(String when) {
    return 'Isso é após o prazo do compartilhamento ($when).';
  }

  @override
  String get taskSheetNameTooShort => 'Use pelo menos 3 caracteres';

  @override
  String get taskSheetPeopleHintClass =>
      'Todos que você adicionar aqui receberão cada tilette desta turma. As alterações de participantes serão enviadas ao salvar.';

  @override
  String get taskSheetPeopleHintProject =>
      'A nova atribuição será enviada ao salvar.';

  @override
  String get tiletteNameLabel => 'NOME DA TILETTE';

  @override
  String get detailEditDetails => 'Editar detalhes';

  @override
  String get detailDeleteShare => 'Excluir compartilhamento';

  @override
  String get detailDeleteShareBody =>
      'As tilettes serão removidas da agenda de todos.';

  @override
  String get detailDeleteShareFailed =>
      'Não foi possível excluir o compartilhamento. Tente novamente.';

  @override
  String get shareNameLabel => 'NOME DO COMPARTILHAMENTO';

  @override
  String get shareModeLabel => 'MODO';

  @override
  String get shareEditModeFixed =>
      'O modo não pode mudar após o compartilhamento.';

  @override
  String get shareEditEffort => 'ESFORÇO TOTAL';

  @override
  String get shareEditEffortHelper => 'A soma das durações das tilettes.';

  @override
  String get shareEditDiscardBody =>
      'Suas alterações neste compartilhamento serão perdidas.';

  @override
  String shareEditTilettesPulledIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tilettes aceitas serão movidas para este prazo.',
      one: '1 tilette aceita será movida para este prazo.',
    );
    return '$_temp0';
  }

  @override
  String shareEditTilettesKeep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count tilettes que ninguém aceitou mantêm seus prazos posteriores.',
      one: '1 tilette que ninguém aceitou mantém seu prazo posterior.',
    );
    return '$_temp0';
  }

  @override
  String taskSheetMoveShareDeadline(String when) {
    return 'Também mudar o prazo do compartilhamento para $when';
  }

  @override
  String get createChooserTitle => 'Compartilhar trabalho';

  @override
  String get createChooserSubtitle => 'Como as pessoas devem participar?';

  @override
  String get createModeBroadcastBody =>
      'Todos recebem sua própria cópia de uma tilette';

  @override
  String get createModeClassBody =>
      'Todos recebem sua própria cópia de um conjunto de tilettes';

  @override
  String get createModeProjectBody =>
      'Todos trabalham em um único conjunto compartilhado de tilettes';

  @override
  String get createComingSoon => 'Em breve';

  @override
  String get createBroadcastTitle => 'Nova transmissão';

  @override
  String get createBroadcastPeopleHint =>
      'Cada pessoa recebe sua própria cópia e é convidada a aceitar.';

  @override
  String get createSend => 'Enviar';

  @override
  String createSendTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar para $count pessoas',
      one: 'Enviar para 1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get createSending => 'Enviando…';

  @override
  String get createNeedsPerson => 'Adicione pelo menos uma pessoa';

  @override
  String get createFailed =>
      'Não foi possível enviar agora. Seus dados foram mantidos.';

  @override
  String get createDiscardTitle => 'Descartar este compartilhamento?';

  @override
  String get createDiscardBody => 'O que você inseriu não será enviado.';

  @override
  String get createClassTitle => 'Nova turma';

  @override
  String get createNeedsTask => 'Adicione pelo menos uma tilette';

  @override
  String get createClassPeopleHint =>
      'Cada pessoa recebe sua própria cópia de cada tilette e é convidada a aceitar.';

  @override
  String get createTilettesLabel => 'TILETTES';

  @override
  String createTiletteWithShare(String length) {
    return '$length · prazo do compartilhamento';
  }

  @override
  String createTiletteDue(String length, String when) {
    return '$length · prazo: $when';
  }

  @override
  String createClassSummary(int count, String effort, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tilettes',
      one: '1 tilette',
    );
    return '$_temp0 · $effort · prazo: $when';
  }

  @override
  String createStepOf(int step, int total) {
    return 'Etapa $step de $total';
  }

  @override
  String get createNextPeople => 'Próximo: pessoas';

  @override
  String get createProjectTitle => 'Novo projeto';

  @override
  String get createProjectSend => 'Criar projeto';

  @override
  String get createCreating => 'Criando…';

  @override
  String get createProjectHint =>
      'Atribua tilettes às pessoas pelo quadro após a criação ou fique com elas.';

  @override
  String get detailLoading => 'Carregando compartilhamento…';

  @override
  String get taskSheetPeopleLabel => 'PESSOAS';

  @override
  String get taskSheetAddPerson => 'ADICIONAR PESSOA';

  @override
  String get taskSheetWillBeAdded => 'Será adicionado';

  @override
  String get taskSheetWillBeRemoved => 'Será removido';

  @override
  String get taskSheetWillBeAssigned => 'Será atribuído ao salvar';

  @override
  String get taskSheetPeopleFailed =>
      'Não foi possível salvar algumas alterações de participantes. Tente novamente abaixo.';

  @override
  String get tileShareSaveChanges => 'Salvar alterações';

  @override
  String get scheduleChangeRefresh => 'Atualizar agenda';

  @override
  String get scheduleChangeUncertainBody =>
      'A alteração pode ter chegado ao servidor. Atualize para verificar se a agenda foi atualizada. Este bloqueio terminará automaticamente.';

  @override
  String get scheduleChangeRefreshing => 'A atualizar a sua linha temporal…';

  @override
  String get scheduleChangeShuffling => 'A experimentar uma nova disposição…';

  @override
  String get scheduleChangeShuffleCommand => 'Baralhar';

  @override
  String get scheduleChangeBuildingTimeline =>
      'A criar a sua primeira linha temporal…';

  @override
  String get scheduleChangeSetupCommand => 'Primeira linha temporal';

  @override
  String get scheduleChangeUncertain => 'Confirmação indisponível';

  @override
  String scheduleChangeAcknowledged(String change) {
    return '$change: Sua linha temporal foi atualizada. Confira as alterações.';
  }

  @override
  String scheduleChangeWentThrough(String change) {
    return '$change foi concluído.';
  }

  @override
  String scheduleChangeFailedLate(String change) {
    return '$change falhou.';
  }

  @override
  String scheduleChangeUnconfirmed(String change) {
    return 'Não foi possível confirmar $change. Verifique sua agenda.';
  }

  @override
  String scheduleChangeNotSent(String change) {
    return 'Não foi possível acessar o Tiler, então $change não foi enviado. Tente novamente.';
  }

  @override
  String get scheduleChangeUnconfirmedGeneric =>
      'Não foi possível confirmar sua última alteração na agenda. Verifique sua agenda.';

  @override
  String get scheduleChangeReattemptTitle => 'Enviar novamente?';

  @override
  String scheduleChangeReattemptBody(String change) {
    return '$change pode já ter sido aplicado. Enviar novamente?';
  }

  @override
  String get scheduleChangeReattemptConfirm => 'Enviar novamente';

  @override
  String scheduleChangeReattemptDeclined(String change) {
    return '$change não foi enviado novamente.';
  }

  @override
  String get scheduleChangeAdding => 'Adicionando evento';

  @override
  String get scheduleChangeSettings => 'Atualizando configurações da agenda';

  @override
  String get scheduleChangeAccepting => 'Aceitando alterações';

  @override
  String get scheduleChangeTargetSchedule => 'Sua agenda';

  @override
  String get scheduleChangeTargetEvent => 'Evento';

  @override
  String get scheduleChangeAllEvents => 'Todos os eventos';

  @override
  String scheduleChangeEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String get scheduleChangesBlocked =>
      'Conclua a alteração atual na agenda antes de iniciar outra.';

  @override
  String scheduleChangesBlockedBy(String change) {
    return 'Conclua a alteração atual na agenda ($change) antes de iniciar outra.';
  }

  @override
  String get scheduleChangeFailed => 'Falha na alteração da agenda';

  @override
  String get scheduleUpdates => 'Atualizações da agenda';

  @override
  String get scheduleUpdatesDescription =>
      'Como o seu dia se move quando a agenda muda.';

  @override
  String get scheduleUpdatesDetailed => 'Detalhado';

  @override
  String get scheduleUpdatesDetailedDescription =>
      'Mostra cada mudança passo a passo.';

  @override
  String get scheduleUpdatesMinimal => 'Mínimo';

  @override
  String get scheduleUpdatesMinimalDescription =>
      'Desliza os blocos para os novos horários.';

  @override
  String get scheduleUpdatesOff => 'Desligado';

  @override
  String get scheduleUpdatesOffDescription => 'Atualiza na hora, sem animação.';

  @override
  String get scheduleChangePlanUpdated => 'Plano atualizado';

  @override
  String get scheduleChangeDayCleared => 'Dia liberado';

  @override
  String scheduleChangeTilesMoved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocos movidos',
      one: '1 bloco movido',
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
      other: '$countString blocos movidos para outros dias',
      one: '1 bloco movido para outro dia',
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
      other: '$countString blocos adicionados',
      one: '1 bloco adicionado',
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
      other: '$countString blocos removidos',
      one: '1 bloco removido',
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
      other: '$countString tempos de deslocamento atualizados',
      one: '1 tempo de deslocamento atualizado',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeFreeGained(String duration) {
    return '+$duration livres';
  }

  @override
  String get scheduleChangeSeeChanges => 'Ver mudanças';

  @override
  String get scheduleChangeWhatChanged => 'O que mudou';

  @override
  String scheduleChangeAdded(String time) {
    return 'Adicionado · $time';
  }

  @override
  String get scheduleChangeRemoved => 'Removido';

  @override
  String scheduleChangeTravelTo(String name) {
    return 'Deslocamento até $name';
  }

  @override
  String get scheduleChangeFreeTime => 'Tempo livre';

  @override
  String scheduleChangeMovedFrom(String time) {
    return 'Movido de $time';
  }

  @override
  String scheduleChangeMovedTo(String time) {
    return 'Movido para $time';
  }

  @override
  String scheduleChangeTileMovedTo(String name, String when) {
    return '$name movido para $when';
  }

  @override
  String scheduleChangeTilesMovedTo(int count, String when) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocos movidos para $when',
      one: '1 bloco movido para $when',
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
      other: '$countString blocos movidos para mais tarde',
      one: '1 bloco movido para mais tarde',
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
      other: '$countString blocos movidos para mais cedo',
      one: '1 bloco movido para mais cedo',
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
      other: '$countString blocos se movendo',
      one: '1 bloco se movendo',
    );
    return '$_temp0';
  }

  @override
  String get scheduleChangeTabChanges => 'Mudanças';

  @override
  String get scheduleChangeTabBeforeAfter => 'Antes e depois';

  @override
  String get scheduleChangeBefore => 'Antes';

  @override
  String get scheduleChangeAfter => 'Depois';

  @override
  String get vibeChatExecutionMode => 'Execução de ações do chat';

  @override
  String get vibeConfirmFirst => 'Confirmar primeiro';

  @override
  String get vibeAutoAct => 'Executar automaticamente';

  @override
  String get vibeAutoActNote =>
      'Execute automaticamente as ações do chat compatíveis. Alterações em massa e destrutivas ainda precisam de revisão.';

  @override
  String get vibeConfirmNote =>
      'Revise as alterações do chat antes de executá-las.';

  @override
  String get vibeConfirmCreation => 'Confirmar criação';

  @override
  String get vibeCheckStatus => 'Verificar status';

  @override
  String get vibeCreationUnknown =>
      'Não foi possível confirmar a criação. Verifique o status antes de tentar novamente.';

  @override
  String get vibeReviewAgain =>
      'Revise a proposta atual antes de confirmar novamente.';

  @override
  String get vibeTileShareCreated => 'TileShare criado.';

  @override
  String get vibeCreationReview => 'Revisar criação de TileShare';

  @override
  String get vibeCreationNote =>
      'Nada é criado até você confirmar. Os destinatários continuam escolhendo se aceitam; esta ação não envia notificações.';

  @override
  String get vibeCreateProject => 'Criar projeto';

  @override
  String get vibeAddTilette => 'Adicionar tilette';

  @override
  String get vibeReviewProject => 'Projeto';

  @override
  String get vibeReviewStarts => 'Início';

  @override
  String get vibeReviewDeadline => 'Prazo';

  @override
  String get vibeReviewMinutes => 'minutos';

  @override
  String get vibeOpenTileShare => 'Abrir TileShare';

  @override
  String get vibeProjectRenamed => 'Projeto renomeado.';

  @override
  String get vibeRenameReview => 'Revisar alteração do nome do projeto';

  @override
  String get vibeRenameProject => 'Renomear projeto';

  @override
  String get vibePreviousName => 'Nome atual';

  @override
  String get vibeRenameNote =>
      'Somente o nome do projeto muda após a confirmação.';

  @override
  String get vibeConfirmRename => 'Confirmar alteração do nome';

  @override
  String get vibeRenameUnknown =>
      'Não foi possível confirmar a alteração do nome. Verifique o status antes de tentar novamente.';

  @override
  String get vibeTiletteRenamed => 'Tilette renomeada.';

  @override
  String get vibeTiletteRenameReview => 'Revisar alteração do nome da tilette';

  @override
  String get vibeRenameTilette => 'Renomear tilette';

  @override
  String get vibeTiletteRenameNote =>
      'Somente o nome da tilette compartilhada muda. Os títulos dos calendários pessoais permanecem iguais.';

  @override
  String get vibeNotesUpdated => 'Notas da tilette atualizadas.';

  @override
  String get vibeNotesReview => 'Revisar notas da tilette';

  @override
  String get vibeEditNotes => 'Atualizar notas da tilette';

  @override
  String get vibePreviousNotes => 'Notas atuais';

  @override
  String get vibeProposedNotes => 'Notas propostas';

  @override
  String get vibeEmptyNotes => 'Sem notas';

  @override
  String get vibeClearNotes => 'Limpar notas';

  @override
  String get vibeNotesNote =>
      'O texto proposto substitui todas as notas da tilette após a confirmação.';

  @override
  String get vibeConfirmNotes => 'Confirmar notas';

  @override
  String get vibeNotesUnknown =>
      'Não foi possível confirmar a atualização das notas. Verifique o status antes de tentar novamente.';

  @override
  String get vibeTiletteDeleted => 'Tilette excluída.';

  @override
  String get vibeDeleteReview => 'Revisar exclusão da tilette';

  @override
  String get vibeDeleteTilette => 'Excluir tilette';

  @override
  String get vibeAssignmentCount => 'Atribuições';

  @override
  String get vibeLinkedCalendarCount => 'Itens de calendário vinculados';

  @override
  String get vibeDeleteNote =>
      'Isso desativa a tilette e o trabalho de calendário vinculado. O projeto e as outras tilettes continuam disponíveis. O histórico de atribuições é mantido; não é possível desfazer a ação aqui.';

  @override
  String get vibeConfirmDeletion => 'Confirmar exclusão';

  @override
  String get vibeDeleteUnknown =>
      'Não foi possível confirmar a exclusão. Verifique o status antes de tentar novamente.';

  @override
  String get vibeOpenProject => 'Abrir projeto';

  @override
  String get vibeTiletteUpdated => 'Tilette atualizada.';

  @override
  String get vibeUpdateReview => 'Revisar atualização da tilette';

  @override
  String get vibeUpdateTilette => 'Atualizar tilette';

  @override
  String get vibeUpdateNote =>
      'Todas as alterações exibidas são salvas juntas após a confirmação. As notas fornecidas substituem a nota inteira.';

  @override
  String get vibeConfirmUpdate => 'Confirmar atualização';

  @override
  String get vibeUpdateRejected =>
      'Nenhuma alteração foi aplicada. Revise a resposta e solicite uma atualização revisada.';

  @override
  String get vibeUpdateUnknown =>
      'Não foi possível confirmar a atualização. Verifique o status antes de tentar novamente.';

  @override
  String get vibeScheduleUpdatePending =>
      'Calculando as agendas do trabalho aceito. Nenhuma alteração foi salva ainda.';

  @override
  String get vibeScheduleNoFit =>
      'Nenhuma alteração foi aplicada. O trabalho restante não coube entre as sessões protegidas. Ajuste a duração ou o prazo e solicite uma atualização revisada.';

  @override
  String get vibeScheduleUpdateFailed =>
      'Nenhuma alteração foi aplicada. A agenda mudou ou não foi possível concluir o cálculo. Solicite uma atualização revisada.';

  @override
  String get vibeUpdateProject => 'Atualizar projeto';

  @override
  String get vibeProjectUpdateReview => 'Revisar atualização do projeto';

  @override
  String get vibeProjectUpdated => 'Projeto atualizado.';

  @override
  String get vibeManageAccess => 'Gerenciar acesso ao projeto';

  @override
  String get vibeManageRecipients => 'Gerenciar destinatários';

  @override
  String get vibeManagementUpdated =>
      'Alterações de destinatários ou acesso salvas.';

  @override
  String get vibeManagementNote =>
      'Revise acima os efeitos sobre destinatários e acesso. A limpeza e a restauração do acesso ao calendário são executadas em segundo plano.';

  @override
  String get vibeAccessReconciliation =>
      'O acesso foi salvo. A limpeza ou restauração do calendário é executada em segundo plano.';

  @override
  String get vibePlanTargetPending => 'Aguardando cálculo conjunto';

  @override
  String get vibePlanTargetNotApplied => 'Não aplicado';

  @override
  String get vibePlanReview => 'Revisar plano de trabalho compartilhado';

  @override
  String get vibePlanUpdated => 'Alterações revisadas salvas juntas.';

  @override
  String get vibePlanNote =>
      'Todos os itens exibidos são salvos juntos após a confirmação. Se algum item mudar ou o acesso for perdido, revise uma nova proposta.';

  @override
  String get shareViewOptions => 'Opções de visualização';

  @override
  String get shareDensityComfortable => 'Confortável';

  @override
  String get shareDensityCompact => 'Compacta';

  @override
  String get shareDensityList => 'Lista';

  @override
  String get shareDensityComfortableHint =>
      'Cartões completos com prévias das notas e ações identificadas.';

  @override
  String get shareDensityCompactHint =>
      'Cartões menores com ações rápidas. Recomendado.';

  @override
  String get shareDensityListHint =>
      'Linhas compactas. Toque em uma tilette para expandir seus detalhes e ações.';

  @override
  String get shareExpandTilette => 'Expandir tilette';

  @override
  String get shareCollapseTilette => 'Recolher tilette';

  @override
  String get shareWork => 'Trabalho';

  @override
  String get sharePeople => 'Pessoas';

  @override
  String get shareActivity => 'Atividade';

  @override
  String get shareMyWork => 'Meu trabalho';

  @override
  String get shareClassHint =>
      'Cada pessoa recebe sua própria cópia de cada tilette.';

  @override
  String get shareProjectHint =>
      'Tilettes atribuídas a pessoas que trabalham por um único objetivo.';

  @override
  String get shareNeedsDecision => 'Precisa da sua decisão';

  @override
  String get shareTilette => 'Tilette';

  @override
  String get shareViewTilette => 'Ver tilette';

  @override
  String get shareReviewRequest => 'Revisar solicitação';

  @override
  String get shareAssignedTo => 'Atribuída a';

  @override
  String get shareAssignedToYou => 'Atribuída a você';

  @override
  String get shareYourResponse => 'Sua resposta';

  @override
  String get shareInvitationHint =>
      'Escolha se deseja adicionar esta tilette à sua agenda.';

  @override
  String get shareReadNotes => 'Ler notas';

  @override
  String get shareEditNotes => 'Editar notas';

  @override
  String get shareOpenDiscussion => 'Abrir discussão';

  @override
  String get shareThreadUnavailable =>
      'A discussão desta tilette está indisponível.';

  @override
  String get shareCommitments => 'Seus compromissos';

  @override
  String get shareNeedsAttention => 'Precisa de atenção';

  @override
  String get shareInProgress => 'Em andamento';

  @override
  String get shareNotStarted => 'Não iniciado';

  @override
  String get shareAwaitingResponse => 'Aguardando resposta';

  @override
  String get shareNoAssignments =>
      'Ainda não há tilettes atribuídas a você neste compartilhamento.';

  @override
  String get shareNotesEmpty => 'Nenhuma nota foi adicionada ainda.';

  @override
  String get shareNoMatches => 'Nenhuma tilette corresponde a este filtro.';

  @override
  String get shareProjectNoPeople =>
      'Ainda ninguém. Atribua uma tilette para adicionar alguém a este projeto.';

  @override
  String shareCompletionCount(int done, int total) {
    return '$done de $total concluídas';
  }

  @override
  String shareMissingAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atribuições ausentes',
      one: '1 atribuição ausente',
    );
    return '$_temp0';
  }

  @override
  String sharePeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
    );
    return '$_temp0';
  }
}
