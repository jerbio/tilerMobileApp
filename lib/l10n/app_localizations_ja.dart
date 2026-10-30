// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String professionTaskPreview(String profession) {
    String _temp0 = intl.Intl.selectLogic(
      profession,
      {
        'medical': '患者のフォロー → 休憩',
        'software': '集中時間 → コードレビュー',
        'student': '勉強 → 課題の準備',
        'engineer': '設計レビュー → プロジェクト計画',
        'sales': '顧客への電話 → 移動時間',
        'remote': '集中作業 → チームとの打ち合わせ',
        'parent': '学校への送迎 → 自分の時間',
        'account': '顧客との打ち合わせ → フォローアップ',
        'other': '集中時間 → 個人の目標',
      },
    );
    return '$_temp0';
  }

  @override
  String get professionAiExplanation => 'AIがあなたの仕事に合った予定を提案';

  @override
  String get selectProfession => '続けるには職業を選択してください。';

  @override
  String get scheduleReadFailedTitle => 'イベントを読み込めませんでした。';

  @override
  String get scheduleReadFailedBody => 'しばらくしてからもう一度お試しください。';

  @override
  String get scheduleReadRefreshFailed => 'イベントを更新できませんでした。';

  @override
  String get scheduleReadRetained => '最後に読み込んだ予定を表示しています。';

  @override
  String get scheduleReadRetrying => '再試行しています...';

  @override
  String get scheduleReadSignIn => 'イベントを読み込むにはログインしてください。';

  @override
  String get scheduleSummaryUnavailable => '概要を表示できません';

  @override
  String get notesLoadFailed => 'メモを読み込めませんでした。メモエディターを開き直してください。';

  @override
  String get shareNotesLoadFailed => 'メモを読み込めませんでした。もう一度お試しください。';

  @override
  String get shareAddPerson => '参加者を追加';

  @override
  String get shareDeclinedHint => 'このTiletteを辞退しました。今からでも承諾できます。';

  @override
  String get shareDeclinedScheduleRefreshFailed => '辞退しましたが、予定はまだ更新できていません。';

  @override
  String get onboardingSubmitFailed =>
      '初期設定を保存できませんでした。選択内容は保持されています。もう一度試すか、今はスキップしてください。';

  @override
  String operationFailed(String operation) {
    return '$operationに失敗しました。もう一度お試しください。';
  }

  @override
  String get scheduleLoadFailed => 'スケジュールを読み込めませんでした。更新してもう一度お試しください。';

  @override
  String get chatConnectionFailed => 'チャットに接続できませんでした。チャットを開き直してください。';

  @override
  String get chatHistoryFailed => 'チャット履歴を読み込めませんでした。会話を開き直してください。';

  @override
  String get chatSendFailed => 'メッセージを送信できませんでした。接続を確認してもう一度お試しください。';

  @override
  String get chatRecordingFailed =>
      '音声録音を開始できませんでした。マイクへのアクセスを確認してもう一度お試しください。';

  @override
  String get chatCancelRecordingFailed =>
      '音声録音をキャンセルできませんでした。もう一度録音の停止をお試しください。';

  @override
  String get whiteSpace => ' ';

  @override
  String get add => '追加';

  @override
  String get setupCustomRestrictions => 'カスタム制約の設定';

  @override
  String get day => '日';

  @override
  String get hour => '時';

  @override
  String get min => '分';

  @override
  String get monday => '月曜日';

  @override
  String get tuesday => '火曜日';

  @override
  String get wednesday => '水曜日';

  @override
  String get thursday => '木曜日';

  @override
  String get friday => '金曜日';

  @override
  String get saturday => '土曜日';

  @override
  String get sunday => '日曜日';

  @override
  String get duration => '時間';

  @override
  String get durationStar => '時間*';

  @override
  String get addTile => 'タイルを追加';

  @override
  String get defer => '先延ばし';

  @override
  String get deferAll => 'すべて先延ばし';

  @override
  String get procrastinating => '先延ばし中';

  @override
  String get forecast => '予測';

  @override
  String get whenQ => 'いつ？';

  @override
  String get loading => '読み込み中';

  @override
  String get loadingPrediction => '予測を読み込み中';

  @override
  String get address => '住所';

  @override
  String get settings => '設定';

  @override
  String get nickName => 'ニックネーム';

  @override
  String get selectADeadline => '締切を選択';

  @override
  String get close => '閉じる';

  @override
  String get tileName => 'タイル名';

  @override
  String get tileNameStar => 'タイル名*';

  @override
  String get starAreRequired => '* は必須項目です';

  @override
  String get howManyTimes => '何回か';

  @override
  String get once => '1回';

  @override
  String get weekdaysAndWorkHours => '平日と労働時間';

  @override
  String get weekend => '週末';

  @override
  String get anytime => 'いつでも';

  @override
  String get repetition => '繰り返し';

  @override
  String get reminder => 'リマインダー';

  @override
  String get restriction => '制約';

  @override
  String get username => 'ユーザー名';

  @override
  String get usernameOrEmail => 'ユーザー名またはメール';

  @override
  String get password => 'パスワード';

  @override
  String get email => 'メール';

  @override
  String get back => '戻る';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get passwordIsRequired => 'パスワードは必須です';

  @override
  String get emailIsRequired => 'メールは必須です';

  @override
  String get fieldIsRequired => 'この項目は必須です';

  @override
  String get signingIn => 'ログイン中';

  @override
  String get signInWithEmailCode => 'メールコードでログイン';

  @override
  String get sendAccessCode => 'アクセスコードを送信';

  @override
  String get continueBtn => '続行';

  @override
  String get usePasswordInstead => '代わりにパスワードを使う';

  @override
  String get useAccessCodeInstead => '代わりにアクセスコードを使う';

  @override
  String get registeringUser => 'ユーザーを登録中';

  @override
  String get sendVerificationCode => '認証コードを送信';

  @override
  String get verificationCodeSent => '認証コードをメールに送信しました。';

  @override
  String get verificationCode => '認証コード';

  @override
  String get verifyCode => 'コードを確認';

  @override
  String get resendCode => 'コードを再送信';

  @override
  String get verifyingCode => 'コードを確認中';

  @override
  String get invalidVerificationCode => '無効または期限切れの認証コードです。';

  @override
  String get accessCodeRequiresEmail => 'アクセスコードでのログインにはメールアドレスが必要です。';

  @override
  String get emailCodeInstructions => 'メールを入力してください。認証コードをお送りします。';

  @override
  String verificationCodeInstructions(String email) {
    return '$email に送信された認証コードを入力してください。';
  }

  @override
  String get confirmPasswordRequired => 'パスワードの確認は必須です';

  @override
  String get passwordsDontMatch => 'パスワードと確認用パスワードが一致しません';

  @override
  String get passwordNeedToBeAtLeastSevenCharacters => 'パスワードは7文字以上必要です';

  @override
  String get passwordNeedsToHaveUpperCaseChracters => '大文字を1つ以上含めてください';

  @override
  String get passwordNeedsToHaveLowerCaseChracters => '小文字を1つ以上含めてください';

  @override
  String get passwordNeedsToHaveNumber => '数字を1つ以上含めてください';

  @override
  String get passwordNeedsToHaveASpecialCharacter => '記号を1つ以上含めてください';

  @override
  String get enableLocations => '位置情報の許可を有効にしてください';

  @override
  String get noMatchWasFound => '一致する項目が見つかりません';

  @override
  String get atLeastThreeLettersForLookup => '...Tiler は検索に3文字必要です';

  @override
  String get searchSourceBadgeTiler => 'Tiler';

  @override
  String get searchSourceBadgeGoogle => 'Google';

  @override
  String get searchSourceBadgeMicrosoft => 'Microsoft';

  @override
  String searchConnectedAccount(String account) {
    return '$account 経由';
  }

  @override
  String get searchPartialFailureWarning => '一部の予定を検索できませんでした。';

  @override
  String get searchUnavailableMessage => '検索は一時的に利用できません。もう一度お試しください。';

  @override
  String get searchRetry => '再試行';

  @override
  String get noLocationMatchWasFound => '一致する場所が見つかりません';

  @override
  String get noLocation => '場所なし';

  @override
  String get clearedColon => 'クリア: ';

  @override
  String get complete => '完了';

  @override
  String get delete => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get now => '今すぐ';

  @override
  String get color => '色';

  @override
  String get pickAColor => '色を選択';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get play => '再生';

  @override
  String get successfullyPaused => '一時停止しました';

  @override
  String get successfullyResumed => '再開しました';

  @override
  String get successfullyCompleted => '完了しました';

  @override
  String get completed => '完了';

  @override
  String get deleted => '削除済み';

  @override
  String get scheduled => '予定済み';

  @override
  String get movedUpToNow => '今に移動';

  @override
  String get pausing => '一時停止中';

  @override
  String get resuming => '再開中';

  @override
  String get movingUp => 'タイルを先へ移動';

  @override
  String get completing => '完了処理中';

  @override
  String get deleting => '削除中';

  @override
  String get deleteBlockConfirming => 'このブロックを削除します...';

  @override
  String get deleteTileConfirming => 'このタイルを削除します...';

  @override
  String get deleteNow => '今すぐ削除';

  @override
  String get deleteGoogleWarning => '⚠️ Google カレンダーからも削除されます';

  @override
  String get deleteOutlookWarning => '⚠️ Outlook からも削除されます';

  @override
  String get previously => '以前';

  @override
  String get upcoming => '今後の予定';

  @override
  String get failedToSendRequest => 'リクエストの送信に失敗しました';

  @override
  String get revise => '修正';

  @override
  String get revisingSchedule => 'スケジュールを調整中';

  @override
  String get procrastinateBlockOut => 'タイルの休止';

  @override
  String get lunchBreak => '昼休み';

  @override
  String get coffeeBreak => 'コーヒーブレイク';

  @override
  String get morningBreak => '朝の休憩';

  @override
  String get afternoonBreak => '午後の休憩';

  @override
  String get freeTime => '空き時間';

  @override
  String get freeSlotHeader => '空き時間';

  @override
  String get freeSlotNow => '今すぐ空き';

  @override
  String get quickBreak => '短い休憩';

  @override
  String get shortBreak => '小休憩';

  @override
  String get blockedTime => 'ブロックされた時間';

  @override
  String get start => '開始';

  @override
  String get end => '終了';

  @override
  String get deadline => '締切';

  @override
  String get split => '分割';

  @override
  String get timeBlocks => '時間ブロック';

  @override
  String get swipeRightToTileIt => '右にスワイプしてタイルを作成';

  @override
  String get failedToReviseScheduleRequest => 'スケジュール変更のリクエストに失敗しました';

  @override
  String get daily => '毎日';

  @override
  String get weekly => '毎週';

  @override
  String get monthly => '毎月';

  @override
  String get yearly => '毎年';

  @override
  String get none => 'なし';

  @override
  String get noneNotificationCategory => 'デフォルト';

  @override
  String get nextTileNotificationCategory => '次のタイル';

  @override
  String get userSetReminderNotificationCategory => 'ユーザー設定のリマインダー';

  @override
  String get depatureTimeNotificationCategory => '出発時間';

  @override
  String get tile => 'タイル';

  @override
  String get appointment => 'ブロック';

  @override
  String startingAtTime(String time) {
    return '$time に開始';
  }

  @override
  String endsAtTime(String time) {
    return '$time に終了';
  }

  @override
  String get startsInTenMinutes => '10分後に開始';

  @override
  String get endsInTenMinutes => '5分後に終了';

  @override
  String startsInDuration(String duration) {
    return '$duration後に開始';
  }

  @override
  String concludesAtTime(String tileName) {
    return '🏁 $tileName がまもなく終了します';
  }

  @override
  String get home => '自宅';

  @override
  String get work => '仕事';

  @override
  String get googleLogo => 'Googleロゴ';

  @override
  String get edit => '編集';

  @override
  String get workProfileHours => '労働時間';

  @override
  String get personalHours => '個人時間';

  @override
  String get setWorkProfileHours => '労働時間を設定';

  @override
  String get setPersonalHours => '個人時間を設定';

  @override
  String get customHours => 'カスタム時間';

  @override
  String get logout => 'ログアウト';

  @override
  String get noteEllipsis => 'メモ...';

  @override
  String get tapToCreateNewTile => 'タップして新しいタイルを作成';

  @override
  String get emptyDayHeaderLine1 => 'まだ予定はありません。';

  @override
  String get emptyDayFooterLine1 => '数秒で始めよう';

  @override
  String get emptyDayFooterLine2 => 'カレンダーをインポートするか、タイルを作成してください。';

  @override
  String get emptyDayOr => 'または';

  @override
  String get emptyDayImportGoogleCalendarButton => 'Google カレンダーをインポート';

  @override
  String get suggestions => '提案';

  @override
  String get progress => '進捗';

  @override
  String get youNeedToLeaveIn => '出発まで残り';

  @override
  String youNeedToLeaveInDuration(String duration) {
    return '$duration後に出発する必要があります';
  }

  @override
  String durationLate(String duration) {
    return '$duration遅れ';
  }

  @override
  String elapsedDurationAgo(String duration) {
    return '$duration前に経過';
  }

  @override
  String completedDurationAgo(String duration) {
    return '$duration前に完了';
  }

  @override
  String durationLeft(String duration) {
    return '残り$duration';
  }

  @override
  String get issuesConnectingToTiler => 'Tilerへの接続に問題が発生しています';

  @override
  String completedCount(String count) {
    return '完了 ($count)';
  }

  @override
  String deletedCount(String count) {
    return '削除済み ($count)';
  }

  @override
  String tiledCount(String count) {
    return '残りタイル ($count)';
  }

  @override
  String countTile(String count) {
    return '$count個のタイル';
  }

  @override
  String numberOfTilesSelected(String number) {
    return '$number個のタイルを選択中';
  }

  @override
  String get completeTiles => 'タイルを完了';

  @override
  String get thisFitsInYourSchedule => 'これはスケジュールに収まります。';

  @override
  String get warningColon => '警告: ';

  @override
  String get oneEventAtRisk => '1件のイベントがリスクにあります';

  @override
  String countEventAtRisk(String number) {
    return '$number件のイベントがリスクにあります';
  }

  @override
  String get oneConflict => '1件の競合';

  @override
  String countConflict(String number) {
    return '$number件の競合';
  }

  @override
  String get create => '作成';

  @override
  String get thisEventWouldCause => 'このイベントは以下を引き起こします ';

  @override
  String errorMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get unScheduledTiles => '未スケジュールのタイル';

  @override
  String numberOfUnScheduledTiles(String number) {
    return '$number個の未スケジュールタイル';
  }

  @override
  String numberOfMoreUsers(String number) {
    return '+$number人';
  }

  @override
  String get unScheduled => '未スケジュール';

  @override
  String get allScheduled => 'すべて予定済み';

  @override
  String get getOnIt => '始めよう';

  @override
  String get done => '完了';

  @override
  String get late => '遅れ';

  @override
  String get onTime => '時間通り';

  @override
  String get todayStatusPlacedTitle => '正常に配置されました';

  @override
  String get todayStatusAttentionTitle => '対応が必要です';

  @override
  String get todayStatusLateTitle => '遅延中';

  @override
  String get todayStatusAttentionHelper => 'これらは本日の空き時間には収まりませんでした。';

  @override
  String get todayStatusLateHelper => '周囲のタイルとの移動時間のため、予定通り到着できません。';

  @override
  String todayStatusTileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countタイル',
    );
    return '$_temp0';
  }

  @override
  String todayStatusTilesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'タイルを完了',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusTilesNeedAttention => '対応が必要';

  @override
  String get todayStatusTilesRunningLate => '遅延中';

  @override
  String get todayStatusEverythingOnTrack => 'すべて順調です';

  @override
  String get todayStatusEverythingElseOnTrack => 'その他もすべて順調です';

  @override
  String get todayStatusOnTrackSubcopy => '遅延しているスケジュール済みタイルはありません。';

  @override
  String get todayStatusClearDay => '今日は空いています。';

  @override
  String get todayStatusClearDayHeadline => '軽めの一日、至急の予定はありません。';

  @override
  String get todayStatusClearDaySubtext => 'Tilerにあなたの代わりに働かせてください。';

  @override
  String get todayStatusPreviewCta => 'より良いプランをプレビュー';

  @override
  String get todayStatusPreviewLoading => 'プレビュー準備中…';

  @override
  String get todayStatusPreviewUnavailable => 'プレビューを生成できませんでした。プランは変更されていません。';

  @override
  String get todayStatusUntitledTile => '無題のタイル';

  @override
  String get todayStatusShowAll => 'すべて表示';

  @override
  String todayStatusExpandSection(String section) {
    return '$section を展開';
  }

  @override
  String todayStatusCollapseSection(String section) {
    return '$section を折りたたむ';
  }

  @override
  String get todayStatusReasonDueToday => '本日締切';

  @override
  String get todayStatusReasonNoOpenSlot => '空き時間なし';

  @override
  String get todayStatusReasonTravelInfeasible => '移動のため実行不可';

  @override
  String get todayStatusReasonOutsideHours => '利用可能な時間の外';

  @override
  String get todayStatusReasonDependencyBlocked => '別のタイルを待機中';

  @override
  String todayStatusReasonNeedsTime(String duration) {
    return '$duration が必要です';
  }

  @override
  String get todayStatusReasonManualHold => 'あなたの判断が必要です';

  @override
  String get todayStatusReasonUnknown => '収まりませんでした';

  @override
  String todayStatusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countセッション',
    );
    return '$_temp0';
  }

  @override
  String get todayStatusSelectTiles => 'タイルを選択';

  @override
  String todayStatusExpandGroup(String title) {
    return '$title のセッションを展開';
  }

  @override
  String todayStatusCollapseGroup(String title) {
    return '$title のセッションを折りたたむ';
  }

  @override
  String get analysis => '分析';

  @override
  String get noDataAvailable => 'データがありません';

  @override
  String get sleep => '睡眠';

  @override
  String get overview => '概要';

  @override
  String get driveTime => '運転時間';

  @override
  String get signUpWithGoogle => 'Googleでサインアップ';

  @override
  String get signUpWithApple => 'Appleでサインアップ';

  @override
  String get signUpWithMicrosoft => 'Microsoftでサインアップ';

  @override
  String get signIn => 'ログイン';

  @override
  String get signUp => '新規登録';

  @override
  String get invalidUsernameOrPassword => 'ユーザー名またはパスワードが違います';

  @override
  String get noInternetConnection => 'インターネット接続がありません';

  @override
  String get oneHour => '1時間';

  @override
  String countHours(String count) {
    return '$count時間';
  }

  @override
  String get oneMinute => '1分';

  @override
  String countMinutes(String count) {
    return '$count分';
  }

  @override
  String countDays(String count) {
    return '$count日';
  }

  @override
  String lateDate(String date) {
    return '遅れ ($date)';
  }

  @override
  String get custom => 'カスタム';

  @override
  String get allowAccessDescription =>
      'Tilerはタイルと予定の効率的なスケジューリングを可能にするため、位置情報データを使用します。\nご自身のデータはプライバシーが保護され、この目的にのみ使用されます。';

  @override
  String get allowLocationAccessQ => '位置情報の使用を許可しますか？';

  @override
  String get allow => '許可';

  @override
  String get deny => '拒否';

  @override
  String get afternoon => '午後';

  @override
  String get evening => '夕方';

  @override
  String get night => '夜';

  @override
  String get morningAndAfternoon => '午前 & 午後';

  @override
  String get afternoonAndEvening => '午後 & 夕方';

  @override
  String get lateEvening => '夜遅く';

  @override
  String get prediction => '予測';

  @override
  String get softDeadline => '柔軟な締切';

  @override
  String get location => '場所';

  @override
  String get dashEmptyString => '--';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteYourTilerAccountQ => 'アカウントを削除しますか？';

  @override
  String get no => 'いいえ';

  @override
  String get dismiss => '閉じる';

  @override
  String get forgetPassword => 'パスワードを忘れた場合';

  @override
  String get forgotPasswordBtn => 'パスワードをお忘れですか？';

  @override
  String get resetPassword => 'パスワードをリセット';

  @override
  String get reset => 'リセット';

  @override
  String lookingUp(String text) {
    return '「$text」を検索中';
  }

  @override
  String get lowPriorityTrunc => '低';

  @override
  String get mediumPriorityTrunc => '中';

  @override
  String get highPriorityTrunc => '高';

  @override
  String failedToAddGoogleCalendar(String email) {
    return '追加に失敗しました $email';
  }

  @override
  String deletedCalendar(String email) {
    return '$emailのカレンダーを削除しました';
  }

  @override
  String get loadingIntegrations => '連携を読み込み中';

  @override
  String get noThirdPartyIntegtions => 'サードパーティのカレンダーはありません';

  @override
  String get addGoogleCalendar => 'Google カレンダーを追加';

  @override
  String get integrations => '連携';

  @override
  String get integrateOtherCalendars => 'サードパーティのカレンダーと連携';

  @override
  String get clear => 'クリア';

  @override
  String get next => '次へ';

  @override
  String get previous => '前へ';

  @override
  String get skip => 'スキップ';

  @override
  String get morningPerson => '🌅 朝活型';

  @override
  String get morning => '午前';

  @override
  String get middayPerson => '🌞 日中活発型';

  @override
  String get nightPerson => '🌃 夜型';

  @override
  String get enterAddress => '住所を入力';

  @override
  String get primaryLocationQuestion => '仕事や学習の主な場所はどこですか？';

  @override
  String get useDeviceLocation => 'デバイスの現在地使用';

  @override
  String get energyLevelDescriptionQuestion => '1日を通しての集中力のパターンを教えてください';

  @override
  String get incompleteRequest => '不完全なリクエストが送信されました';

  @override
  String get addContact => '連絡先を追加';

  @override
  String get invalidContactFormat => '有効なメールアドレスまたは電話番号ではありません';

  @override
  String deadlineTime(String time) {
    return '締切: $time';
  }

  @override
  String get accept => '受ける';

  @override
  String get decline => '辞退';

  @override
  String get preview => 'プレビュー';

  @override
  String get addTilette => 'タイルレットを追加';

  @override
  String get tileShare => 'タイル共有';

  @override
  String get tileShareActivityInvitationUnknown => '招待の送信結果は不明です';

  @override
  String get tileShareActivityExplicitResend =>
      '招待は送信されている可能性があります。必要に応じて明示的に再送信してください。';

  @override
  String get tileShareActivityEmail => 'メール';

  @override
  String get tileShareActivitySms => 'SMS';

  @override
  String get tileShareActivityPush => 'プッシュ通知';

  @override
  String get tileShareActivityTitle => 'アクティビティ';

  @override
  String get tileShareActivityRefresh => '更新';

  @override
  String get tileShareActivityRetry => '再試行';

  @override
  String get tileShareActivityEmpty => 'まだアクティビティはありません。';

  @override
  String get tileShareActivityFailed => 'アクティビティを読み込めませんでした。接続を確認して再試行してください。';

  @override
  String get tileShareActivityAccess => 'このアクティビティはもう利用できません。';

  @override
  String get tileShareActivityUnknown => 'アクティビティが更新されました';

  @override
  String get tileShareActivityUnavailable => 'この項目はもう利用できません';

  @override
  String get tileShareActivityMore => 'さらに読み込む';

  @override
  String get tileShareActivityClusterCreated => 'TileShareを作成しました';

  @override
  String get tileShareActivityClusterDeleted => 'TileShareを削除しました';

  @override
  String get tileShareActivityTiletteAdded => 'Tiletteを追加しました';

  @override
  String get tileShareActivityTiletteEdited => 'Tiletteを更新しました';

  @override
  String get tileShareActivityTiletteDeleted => 'Tiletteを削除しました';

  @override
  String get tileShareActivityTiletteRestored => 'Tiletteを復元しました';

  @override
  String get tileShareActivityRecipientAdded => '参加者を追加しました';

  @override
  String get tileShareActivityRecipientRemoved => '参加者を削除しました';

  @override
  String get tileShareActivityRecipientRestored => '参加者を復元しました';

  @override
  String get tileShareActivityAccepted => '割り当てを承諾しました';

  @override
  String get tileShareActivityDeclined => '割り当てを辞退しました';

  @override
  String get tileShareActivityInvitationSent => '招待を送信しました';

  @override
  String get tileShareActivityInvitationFailed => '招待を送信できませんでした';

  @override
  String get update => '更新';

  @override
  String get noDesignatedTiles => '指定されたタイルはありません';

  @override
  String get noTileCluster => 'まだタイル共有が作成されていません';

  @override
  String get errorLoadingTilelist => 'タイルリストの読み込みにエラーが発生しました';

  @override
  String get failedToLoadTileShareCluster => 'タイル共有クラスタの読み込みに失敗しました';

  @override
  String get missingTileShareCluster => 'タイル共有クラスタがありません';

  @override
  String get outBound => 'アウトバウンド';

  @override
  String get inBound => 'インバウンド';

  @override
  String get errorOccurred => 'エラーが発生しました!!\nもう一度お試しください。';

  @override
  String get authenticationIssues => '認証に問題が発生しています。';

  @override
  String get userIsNotAuthenticated => 'ユーザーが認証されていません。';

  @override
  String get responseContentError => 'レスポンスに期待するコンテンツが含まれていません。';

  @override
  String get responseHandlingError => 'レスポンスの処理に失敗しました。';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get tomorrow => '明日';

  @override
  String get travel => '移動';

  @override
  String numberOfDayForecast(String number) {
    return '$number日間の予測';
  }

  @override
  String get knotDuration => '--';

  @override
  String get failedToGetPreview => 'プレビューの取得に失敗しました';

  @override
  String get noDriving => '運転なし';

  @override
  String get tileShareNoteEllipsis => 'メモ...';

  @override
  String get hi => 'こんにちは';

  @override
  String get welcome => 'ようこそ';

  @override
  String get passwordCreationMessagePart1 => '強い独自のパスワードを作成します。 ';

  @override
  String get passwordConditionMinLength => '6文字以上';

  @override
  String get passwordCreationMessageIncluding => '以下を含む';

  @override
  String get passwordConditionUppercaseLetters => '大文字';

  @override
  String get passwordConditionLowercaseLetters => '小文字';

  @override
  String get passwordConditionNumbers => '数字';

  @override
  String get passwordConditionSpecialCharacter => '特殊文字';

  @override
  String get listSeparator => '、';

  @override
  String get listFinalSeparator => '、および';

  @override
  String get nonViableTimeSlot => '実行可能な時間帯はありません';

  @override
  String numberAm(String number) {
    return '${number}AM';
  }

  @override
  String numberPm(String number) {
    return '${number}PM';
  }

  @override
  String get dayCast => 'デイキャスト';

  @override
  String get save => '保存';

  @override
  String get selectWeek => '週を選択';

  @override
  String get selectYear => '年を選択';

  @override
  String get retrievingDataIssue => 'データ取得に問題が発生しています';

  @override
  String get recurring => '繰り返し';

  @override
  String get nonRecurring => '非繰り返し';

  @override
  String get dailyReurring => '毎日';

  @override
  String get weeklyReurring => '毎週';

  @override
  String get biweeklyReurring => '隔週';

  @override
  String get monthlyReurring => '毎月';

  @override
  String get yearlyReurring => '毎年';

  @override
  String get ellipsisEmprtNotes => 'メモ...';

  @override
  String get tileShareDelete => '削除';

  @override
  String get commaDelimiter => ',';

  @override
  String get foreCastTile => '予測タイル';

  @override
  String get previewOthers => 'その他';

  @override
  String get goodMorning => 'おはようございます';

  @override
  String get goodDay => 'こんにちは';

  @override
  String get goodEvening => 'こんばんは';

  @override
  String youHaveXBlocks(String count) {
    return '今後の予定に$count個のブロックがあります。';
  }

  @override
  String youHaveXTiles(String count) {
    return '今後の予定に$count個のタイルがあります。';
  }

  @override
  String youHaveXTileShares(String count) {
    return '今後の予定に$count件のタイル共有があります。';
  }

  @override
  String countTileShare(String count) {
    return '$count件のタイル共有';
  }

  @override
  String youHaveCountBlocksAndCountTiles(String blockCount, String tileCount) {
    return '今後の予定に$blockCount個のブロックと$tileCount個のタイルがあります。';
  }

  @override
  String youHaveCountBlocksAndCountTileShares(
      String blockCount, String tileShareCount) {
    return '今後の予定に$blockCount個のブロックと$tileShareCount件のタイル共有があります。';
  }

  @override
  String youHaveCountTilesAndCountTileShares(
      String tileCount, String tileShareCount) {
    return '今後の予定に$tileCount個のタイルと$tileShareCount件のタイル共有があります。';
  }

  @override
  String youHaveCountBlocksCountTilesAndCountTileShares(
      String blockCount, String tileCount, String tileShareCount) {
    return '今後の予定に$blockCount個のブロック、$tileCount個のタイル、$tileShareCount件のタイル共有があります。';
  }

  @override
  String get noTilesPreview => '今日の残り時間、予定はありません。';

  @override
  String previewEllipsisText(String shortenedText) {
    return '$shortenedText...';
  }

  @override
  String get createTile => 'タイルを作成';

  @override
  String get previewTileForecast => '予測';

  @override
  String get previewTileOptions => 'オプション';

  @override
  String get previewTileMore => 'もっと表示';

  @override
  String get previewTileShuffle => 'シャッフル';

  @override
  String get previewTileRevise => '見直し';

  @override
  String get previewTileDeferAll => 'すべて先延ばし';

  @override
  String get previewLocationName => '場所';

  @override
  String get previewTagName => 'タグ';

  @override
  String get previewClassificationName => '分類';

  @override
  String get previewBlockedOut => 'ブロック済み';

  @override
  String get accountInfo => 'アカウント情報';

  @override
  String get fistName => '名';

  @override
  String get lastName => '姓';

  @override
  String get tilePreferences => 'タイルの設定';

  @override
  String get notificationsPreferences => '通知の設定';

  @override
  String get security => 'セキュリティ';

  @override
  String get connections => '接続';

  @override
  String get myLocations => 'マイロケーション';

  @override
  String get aboutTiler => 'Tilerについて';

  @override
  String get howToUseTiler => 'Tilerの使い方';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get setLocation => 'ロケーションを設定';

  @override
  String get connectCalendars => 'カレンダーを接続';

  @override
  String get configure => '設定';

  @override
  String get comingSoon => '近日公開';

  @override
  String get googleCalendar => 'Google カレンダー';

  @override
  String get appleCalendar => 'Apple カレンダー';

  @override
  String get googleTasks => 'Google タスク';

  @override
  String get microsoft => 'Microsoft';

  @override
  String get slack => 'Slack';

  @override
  String get addCalendar => 'カレンダーを追加';

  @override
  String get calendarConnected => 'カレンダーを接続しました';

  @override
  String get calendarConnectionDeclined => 'カレンダー接続がキャンセルされました';

  @override
  String get calendarConnectionError => 'カレンダーを接続できませんでした';

  @override
  String get sleepDuration => '睡眠時間';

  @override
  String get transportationMethodQuestion => 'どのように移動していますか？';

  @override
  String get defineYourTimeRestrictions => '時間帯の制約を定義';

  @override
  String get setWorkHours => '労働時間を設定';

  @override
  String get setYourBlockOutHours => 'ブロックアウト時間を設定';

  @override
  String get travelMediumBiking => '自転車';

  @override
  String get travelMediumTransit => '公共交通機関';

  @override
  String get travelMediumDriving => '自動車';

  @override
  String get travelMediumTransport => '乗り物';

  @override
  String previewRatioTimeMinutes(String ratio) {
    return '$ratio分';
  }

  @override
  String previewRatioTimeHours(String ratio) {
    return '$ratio時間';
  }

  @override
  String get bedTime => '就寝時間';

  @override
  String get sleepTime => '睡眠時間';

  @override
  String get scheduleFullness => 'スケジュールの充実度';

  @override
  String get scheduleFullnessDescription => 'スケジュールはどのくらい充実させたいですか？';

  @override
  String scheduleFullnessValue(int percentage) {
    return '目標充実度$percentage%';
  }

  @override
  String scheduleFullnessLimits(int minimum, int maximum) {
    return '目標は$minimum%〜$maximum%の範囲です。変更や移動の余裕を残しつつ、実用的な基準を維持します。';
  }

  @override
  String get schedulePreferences => 'スケジュールの設定';

  @override
  String get lighter => '軽め';

  @override
  String get balanced => 'バランス';

  @override
  String get fuller => '充実';

  @override
  String get tilePreferencesUpdatedSuccessfully => 'タイルの設定を更新しました。';

  @override
  String get notificationsPreferencesUpdatedSuccessfully => '通知の設定を更新しました。';

  @override
  String get tileReminders => 'タイルのリマインダー';

  @override
  String get appUpdates => 'アプリの更新';

  @override
  String get marketingUpdates => 'マーケティングの更新';

  @override
  String get emailNotifications => 'メール通知';

  @override
  String get fullName => '氏名';

  @override
  String get phoneNumber => '電話番号';

  @override
  String get countryCode => '国番号';

  @override
  String get dateOfBirth => '生年月日';

  @override
  String get accountInfoUpdatedSuccessfully => 'アカウント情報を更新しました。';

  @override
  String get reachingServerIssues => 'Tilerサーバーへの接続に問題が発生しています';

  @override
  String get deleteAccountConfirmation => '本当にアカウントを削除しますか？この操作は元に戻せません。';

  @override
  String get disconnect => '切断';

  @override
  String get integrationsSetLocation => 'ロケーションを設定';

  @override
  String get googleCalender => 'Google カレンダー';

  @override
  String get passwordsMustMatch => 'パスワードが一致する必要があります';

  @override
  String get parenthesisLate => '(遅れ)';

  @override
  String get failedToAddIntegration => '連携の追加に失敗しました';

  @override
  String get unknownProvider => '不明なプロバイダー';

  @override
  String get manageCalendars => 'カレンダーの管理';

  @override
  String get calendarItems => 'カレンダー項目';

  @override
  String get noCalendarItemsFound => 'カレンダー項目が見つかりません';

  @override
  String get calendarItemsWillAppearHere => 'カレンダー項目がここに表示されます';

  @override
  String calendarsActive(int selectedCount, int totalCount) {
    return '$totalCount件中$selectedCount件のカレンダーが有効';
  }

  @override
  String get toggleCalendarsToSync => 'Tilerと同期するカレンダーを切り替え';

  @override
  String get unknownCalendar => '不明なカレンダー';

  @override
  String activeStatusBadge(int selectedCount, int totalCount) {
    return '$totalCount件中$selectedCount件が有効';
  }

  @override
  String integrationCount(int count) {
    return '$count件の連携';
  }

  @override
  String get errorLoadingCalendarItems => 'カレンダー項目の読み込みにエラーが発生しました';

  @override
  String get integratedCalendars => 'カレンダー';

  @override
  String get integrationAdd => '追加';

  @override
  String get timeAndLocationSecondarySubTitle =>
      '位置情報にアクセスしてもよろしいですか？\n場所ベースの推奨や通知を提供するために';

  @override
  String get recurringTasks => '繰り返しのタスク';

  @override
  String get yourProfession => 'あなたの職業は？';

  @override
  String get yourProfessionQuestion => 'お仕事は何をされていますか？';

  @override
  String get yourProfessionHint => 'お仕事の内容を教えてください';

  @override
  String get medicalProfessional => '医療従事者';

  @override
  String get softwareDeveloper => 'ソフトウェア開発者';

  @override
  String get student => '学生';

  @override
  String get engineer => 'エンジニア';

  @override
  String get fieldSalesProfessional => 'フィールドセールス';

  @override
  String get remoteWorker => 'リモートワーカー & デジタルノマード';

  @override
  String get stayAtHomeParent => '専業主婦/夫';

  @override
  String get clientAccountManagers => 'アカウントマネージャー';

  @override
  String get other => 'その他';

  @override
  String get tileSuggestions => 'タイルの提案';

  @override
  String get personalOrWorkQuestion => 'Tilerは何のために使いますか？';

  @override
  String get enter3chars => '3文字以上入力してください。';

  @override
  String leaveInDurationToArriveOnTime(String duration) {
    return '定刻到着のため、$duration後に出発';
  }

  @override
  String get leaveNowToArriveOnTime => '定刻到着のため、今すぐ出発！';

  @override
  String durationDrive(String duration) {
    return '$duration運転';
  }

  @override
  String durationTransit(String duration) {
    return '$duration交通機関';
  }

  @override
  String durationBike(String duration) {
    return '$duration自転車';
  }

  @override
  String durationWalk(String duration) {
    return '$duration徒歩';
  }

  @override
  String driveToDestination(String duration, String destination) {
    return '$destinationまで$duration運転';
  }

  @override
  String transitToDestination(String duration, String destination) {
    return '$destinationまで$duration交通機関';
  }

  @override
  String bikeToDestination(String duration, String destination) {
    return '$destinationまで$duration自転車';
  }

  @override
  String walkToDestination(String duration, String destination) {
    return '$destinationまで$duration徒歩';
  }

  @override
  String leaveByTime(String time) {
    return '$timeまでに出発';
  }

  @override
  String get trafficDetectedReroutingSuggested => '渋滞を検出 - 経路変更を提案';

  @override
  String trafficDelayMinutes(String minutes) {
    return '渋滞: $minutes分の遅延';
  }

  @override
  String get heavyTrafficExpected => '大渋滞が予想されます';

  @override
  String get addWithAI => 'AIで追加';

  @override
  String get focusTime => '集中時間';

  @override
  String get videoMeeting => 'ビデオ会議';

  @override
  String get sharedWith => '共有先';

  @override
  String durationMinutes(String minutes) {
    return '$minutes分';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String travelDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String travelDurationHours(int hours) {
    return '$hours時間';
  }

  @override
  String travelDurationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String travelViaRoute(String route) {
    return '$route経由';
  }

  @override
  String travelModeToDestination(String travelMode) {
    return '$travelModeで ';
  }

  @override
  String get travelModeDriving => '運転';

  @override
  String get travelModeWalking => '徒歩';

  @override
  String get travelModeBicycling => '自転車';

  @override
  String get travelModeTransitLower => '公共交通機関';

  @override
  String travelDurationCompact(int minutes) {
    return '$minutes分';
  }

  @override
  String get yourDayIsOptimized => 'あなたの1日は最適化されました。';

  @override
  String get yourDayAtAGlance => '今日の1日の概要';

  @override
  String totalTravelTimeToday(String duration) {
    return '今日の移動時間$duration。';
  }

  @override
  String tilesScheduledForToday(int count) {
    return '今日に$count個のタイルが予定されています。';
  }

  @override
  String get viewRoute => 'ルートを表示';

  @override
  String get focusModeChip => '集中モード';

  @override
  String get showRouteChip => 'ルートを表示';

  @override
  String get reOptimizeChip => '再最適化';

  @override
  String get dayFilterAll => 'すべて';

  @override
  String get dayFilterBlocks => 'ブロック';

  @override
  String get dayFilterTiles => 'タイル';

  @override
  String get dayFilterTooltip => 'すべて、ブロックのみ、タイルのみを表示';

  @override
  String dayFilterShowingBlocks(int shown, int total) {
    return 'ブロックのみを表示中 · $total件中$shown件';
  }

  @override
  String dayFilterShowingTiles(int shown, int total) {
    return 'タイルのみを表示中 · $total件中$shown件';
  }

  @override
  String dayFilterEmptyBlocks(String day) {
    return '$dayにブロックはありません';
  }

  @override
  String dayFilterEmptyTiles(String day) {
    return '$dayにタイルはありません';
  }

  @override
  String get dayFilterShowAll => 'すべて表示';

  @override
  String get dayFilterAutoCleared => 'すべてを表示しています — フィルター解除';

  @override
  String get todayColon => '今日:';

  @override
  String tilesBlocksCount(int tileCount, int blockCount) {
    return '$tileCount個のタイル、$blockCount個のブロック';
  }

  @override
  String get timeSavedColon => '節約した時間:';

  @override
  String get travelTimeColon => '移動時間:';

  @override
  String travelTime(String duration) {
    return '移動時間: $duration';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String durationDaysHoursShort(int days, int hours) {
    return '$days日$hours時間';
  }

  @override
  String durationDaysShort(int days) {
    return '$days日';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hours時間';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes分';
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
  String get scheduleConflict => 'スケジュール競合';

  @override
  String conflictSameTime(String tile1, String tile2) {
    return '「$tile1」と「$tile2」が同じ時間にスケジュールされています';
  }

  @override
  String conflictDuring(String tile1, String tile2, String overlap) {
    return '「$tile1」は「$tile2」の時間内にあります（$overlap重複）';
  }

  @override
  String conflictOverlaps(String tile1, String tile2, String overlap) {
    return '「$tile1」は「$tile2」と$overlap重複しています';
  }

  @override
  String get fix => '修正';

  @override
  String conflictOverlapMinutes(int minutes) {
    return '競合: $minutes分重複';
  }

  @override
  String get oneScheduleConflict => 'スケジュール競合1件';

  @override
  String countScheduleConflicts(int count) {
    return 'スケジュール競合$count件';
  }

  @override
  String get tapToReviewAndResolve => 'タップして確認・解決';

  @override
  String countConflicts(int count) {
    return '競合$count件';
  }

  @override
  String get tapToExpand => 'タップして展開';

  @override
  String conflictingTiles(int count) {
    return '競合するタイル$count個';
  }

  @override
  String totalOverlap(String duration) {
    return '重複合計: $duration';
  }

  @override
  String get autoResolve => '自動解決';

  @override
  String get untitledTile => '無題のタイル';

  @override
  String get untitledEvent => '無題';

  @override
  String get extendedEventSingular => '長時間イベント1件';

  @override
  String extendedEventsPlural(int count) {
    return '長時間イベント$count件';
  }

  @override
  String get extendedEventsTapToView => 'タップして1日中および長時間のイベントを表示';

  @override
  String get extendedEventsTitle => '長時間イベント';

  @override
  String get dayGridAllDay => '終日';

  @override
  String get dayGridHeaderAllClear => 'すべて正常';

  @override
  String dayGridHeaderConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '競合$count件',
      one: '競合1件',
    );
    return '$_temp0';
  }

  @override
  String dayGridHeaderNeedAttention(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$summaryに要注意',
      one: '$summaryに要注意',
    );
    return '$_temp0';
  }

  @override
  String get dayGridHeaderReview => '確認';

  @override
  String get dayGridDaySummary => '1日の概要';

  @override
  String get bottomNavToday => '今日';

  @override
  String get bottomNavTiler => 'Tiler';

  @override
  String get dayGridHeaderRespond => '返信';

  @override
  String extendedEventsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のイベントが16時間を超えています',
      one: '16時間を超えるイベント1件',
    );
    return '$_temp0';
  }

  @override
  String get todaysRoute => '今日のルート';

  @override
  String get noLocationsToday => '今日、場所は設定されていません';

  @override
  String get addLocationsToSeeTodaysRoute => 'タイルに場所を追加して、1日のルートを確認';

  @override
  String countStops(int count) {
    return '$countヶ所';
  }

  @override
  String get routeOptimized => 'ルートが最適化されました';

  @override
  String savedTravelTime(String duration) {
    return '移動時間$durationを節約';
  }

  @override
  String get firstStop => '最初の目的地';

  @override
  String get stop => '目的地';

  @override
  String arriveBy(String time) {
    return '$timeまでに到着';
  }

  @override
  String get fromPreviousStop => '前の目的地から';

  @override
  String get viewTile => 'タイルを表示';

  @override
  String get editTile => 'タイルを編集';

  @override
  String get startNavigation => 'ナビを開始';

  @override
  String get noLocationAvailable => '場所なし';

  @override
  String get seeTodaysRoute => '今日のルートを見る';

  @override
  String get whatWouldYouLikeToDo => '何をしたいですか？';

  @override
  String get describeATask => 'タスクを説明してください。タイル化はTilerにお任せを。';

  @override
  String get microphonePermissionDenied => 'マイクの使用が拒否されました。';

  @override
  String failedToStartRecording(String error) {
    return '録音を開始できません: $error';
  }

  @override
  String failedToStopRecording(String error) {
    return '録音を停止できません: $error';
  }

  @override
  String audioConversionError(String error) {
    return '音声の変換エラー: $error';
  }

  @override
  String get audioConversionFailed => '音声の変換に失敗しました';

  @override
  String get recordingPathIsEmpty => '録音パスが空です';

  @override
  String get noActiveRecording => '進行中の録音はありません';

  @override
  String get joinMeeting => '会議に参加';

  @override
  String get openLink => 'リンクを開く';

  @override
  String get actions => 'アクション';

  @override
  String get hideActions => 'アクションを非表示';

  @override
  String get pendingRsvpSingular => '回答が必要なイベント1件';

  @override
  String pendingRsvpPlural(int count) {
    return '回答が必要なイベント$count件';
  }

  @override
  String get pendingRsvpHappeningNow => '現在開催中 - 参加するには回答してください';

  @override
  String get pendingRsvpStartingSoon => 'まもなく開始 - 今すぐ回答';

  @override
  String get pendingRsvpWithinHour => '1時間以内に開始';

  @override
  String get pendingRsvpUpcoming => '今後の予定 - タップして回答';

  @override
  String get pendingRsvpTapToReview => 'タップして確認して回答';

  @override
  String get pendingRsvpTitle => '回答待ち';

  @override
  String pendingRsvpSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のイベントがあなたの回答を待っています',
      one: '1件のイベントがあなたの回答を待っています',
    );
    return '$_temp0';
  }

  @override
  String get pendingRsvpUrgent => 'まもなく開始';

  @override
  String get pendingRsvpLater => '今日の後半 & 今後の予定';

  @override
  String get declinedRsvpSingular => '辞退したイベント1件';

  @override
  String declinedRsvpPlural(int count) {
    return '辞退したイベント$count件';
  }

  @override
  String get declinedRsvp => '辞退したイベント';

  @override
  String rsvpMixedOnePending(int declinedCount) {
    return '回答待ち1件、辞退$declinedCount件';
  }

  @override
  String rsvpMixedOneDeclined(int pendingCount) {
    return '回答待ち$pendingCount件、辞退1件';
  }

  @override
  String rsvpMixed(int pendingCount, int declinedCount) {
    return '回答待ち$pendingCount件、辞退$declinedCount件';
  }

  @override
  String get rsvpNeedsAction => '回答が必要';

  @override
  String get rsvpTentative => '予定保留';

  @override
  String get rsvpAccepted => '承諾済み';

  @override
  String get rsvpDeclined => '辞退済み';

  @override
  String unableToOpenLinkError(String link) {
    return 'リンクを開けませんでした: $link';
  }

  @override
  String get leaveNow => '今すぐ出発！';

  @override
  String leaveInMinutes(int minutes) {
    return '$minutes分後に出発';
  }

  @override
  String multipleAlertsTitle(int count) {
    return '$count件のアラート';
  }

  @override
  String get alertChipLeaveNow => '今すぐ出発';

  @override
  String alertChipLeaveIn(int minutes) {
    return '$minutes分後に出発';
  }

  @override
  String alertChipConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '競合$count件',
      one: '競合1件',
    );
    return '$_temp0';
  }

  @override
  String alertChipAllDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '1日中$count件',
      one: '1日中1件',
    );
    return '$_temp0';
  }

  @override
  String alertChipRsvp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'RSVP$count件',
      one: 'RSVP1件',
    );
    return '$_temp0';
  }

  @override
  String get accepted => '承諾済み';

  @override
  String get declined => '辞退済み';

  @override
  String respondToCalendar(String calendarSource) {
    return '$calendarSourceに回答';
  }

  @override
  String get unknown => 'カレンダーの招待';

  @override
  String get loadingPreviousDays => '以前の日にちを読み込み中...';

  @override
  String get loadingUpcomingDays => '今後の日にちを読み込み中...';

  @override
  String get requestTimeout => 'リクエストがタイムアウトしました - 接続を確認してください';

  @override
  String get failedToPauseTile => 'タイルの一時停止に失敗しました';

  @override
  String get failedToResumeTile => 'タイルの再開に失敗しました';

  @override
  String get failedToMoveUpTask => 'タスクの繰り上げに失敗しました';

  @override
  String get failedToUpdateTile => 'タイルの更新に失敗しました';

  @override
  String get failedToBuzzSchedule => 'スケジュールのBuzzに失敗しました';

  @override
  String get failedToShuffleSchedule => 'スケジュールのシャッフルに失敗しました';

  @override
  String get failedToProcrastinateTile => 'タイルの先延ばしに失敗しました';

  @override
  String get tutorialStepYourScheduleTitle => 'あなたのスケジュール';

  @override
  String get tutorialStepYourScheduleBody =>
      'あなたの1日は「タイル」に整理されています。Tilerがあなたのために並べ替えるスマートな時間ブロックです。上下にスクロールして1日全体を確認しましょう。';

  @override
  String get tutorialStepCreateOptimizeTitle => '作成 & 最適化';

  @override
  String get tutorialStepCreateOptimizeBody =>
      'ここをタップして新しいタスクを作成。Tilerに何をするか・どれくらいの時間がかかるかを伝えれば、Tilerが「いつやるか」を決定します。';

  @override
  String get tutorialCalloutReOptimize => '再最適化';

  @override
  String get tutorialCalloutReOptimizeDesc =>
      '予定が狂いましたか？今後の計画をほぼそのままに保ったまま、今から再計算します';

  @override
  String get tutorialCalloutTravelTime => '移動時間';

  @override
  String get tutorialCalloutTravelTimeDesc => 'Tilerは場所間の通勤時間を考慮します';

  @override
  String get tutorialStepQuickCreateTitle => 'クイック作成';

  @override
  String get tutorialStepQuickCreateBody =>
      'ここはクイック追加シートです。タイルに名前を付けて所要時間を設定して、素早く追加しましょう。';

  @override
  String get tutorialStepQuickCreateSheetBody =>
      '私の背後はクイック追加シートです！タイルに名前を付けて所要時間を設定し、「追加」をタップしてください。あとはTilerにお任せを。';

  @override
  String get tutorialCalloutNameYourTile => 'タイルに名前を付ける';

  @override
  String get tutorialCalloutNameYourTileDesc => '達成したいタスクを説明してください';

  @override
  String get tutorialCalloutSetDuration => '所要時間を設定';

  @override
  String get tutorialCalloutSetDurationDesc => 'このタスクにどれくらい時間がかかりますか？';

  @override
  String get tutorialCalloutMoreOptions => 'その他のオプション';

  @override
  String get tutorialCalloutMoreOptionsDesc => 'フルエディターから場所、締切、繰り返しを追加できます';

  @override
  String get tutorialCalloutMoreOptionsSheetDesc => '場所、締切、繰り返しを追加';

  @override
  String get tutorialStepTilerWorksTitle => 'Tilerがあなたのために働きます';

  @override
  String get tutorialStepTilerWorksBody =>
      'Tilerはあなたのエネルギーレベル、移動時間、締切に基づいてタイルを自動的に並べます。やるべきことを追加するだけ - 「いつやるか」はTilerに任せましょう。';

  @override
  String get tutorialCalloutForecast => '予測';

  @override
  String get tutorialCalloutForecastDesc => 'タイルを選択する前に、どこに挿入されるかを確認できます';

  @override
  String get tutorialCalloutShuffle => 'シャッフル';

  @override
  String get tutorialCalloutShuffleDesc => '並び順をシャッフルして、次にやるべきことを提案';

  @override
  String get tutorialCalloutDeferAll => 'すべて先延ばし';

  @override
  String get tutorialCalloutDeferAllDesc => 'つらい日ですか？すべて後ろにずらします';

  @override
  String get tutorialStepControlTilesTitle => 'タイルをコントロール';

  @override
  String get tutorialStepControlTilesBody =>
      '各タイルには、タスクをリアルタイムで管理するためのコントロールがあります：';

  @override
  String get tutorialCalloutPlay => '開始';

  @override
  String get tutorialCalloutPlayDesc => 'このタイルに取り掛かる';

  @override
  String get tutorialCalloutPause => '一時停止';

  @override
  String get tutorialCalloutPauseDesc => '休憩 - Tilerが残りを再スケジュールします';

  @override
  String get tutorialCalloutComplete => '完了';

  @override
  String get tutorialCalloutCompleteDesc => '完了！終了とマーク';

  @override
  String get tutorialCalloutProcrastinate => '先延ばし';

  @override
  String get tutorialCalloutProcrastinateDesc => '今はやらない - 後ろにずらします';

  @override
  String get tutorialStepBigPictureTitle => '全体像を見る';

  @override
  String get tutorialStepBigPictureBody => 'カレンダーのアイコンをタップして、3つのビューを切り替えられます：';

  @override
  String get tutorialCalloutDaily => '1日表示';

  @override
  String get tutorialCalloutDailyDesc => '1時間単位 - 詳細な1日の予定';

  @override
  String get tutorialCalloutWeekly => '週表示';

  @override
  String get tutorialCalloutWeeklyDesc => '1週間全体をひと目で確認';

  @override
  String get tutorialCalloutMonthly => '月表示';

  @override
  String get tutorialCalloutMonthlyDesc => '月間の概要で先を見通して計画';

  @override
  String get tutorialStepToolkitTitle => 'あなたのツールキット';

  @override
  String get tutorialStepToolkitBody => 'これらの便利なツールはいつでも手の届くところにあります：';

  @override
  String get tutorialCalloutShare => '共有';

  @override
  String get tutorialCalloutShareDesc => 'コラボレーション - タイルを他の人と共有';

  @override
  String get tutorialCalloutSearch => '検索';

  @override
  String get tutorialCalloutSearchDesc => 'タイル名から任意のタイルを見つける';

  @override
  String get tutorialCalloutSettings => '設定';

  @override
  String get tutorialCalloutSettingsDesc => '体験をカスタマイズ、カレンダーを接続、環境設定を設定';

  @override
  String get tutorialCalloutChat => 'チャット';

  @override
  String get tutorialCalloutChatDesc => 'チャットボタンをタップして、Tilerと話すだけでタイルを追加・調整';

  @override
  String get tutorialStepChatTitle => 'Tilerとチャット';

  @override
  String get tutorialStepChatBody =>
      'いつでもチャットボタンをタップして、Tilerと話すだけでタイルを追加・調整できます - フォームは不要。';

  @override
  String get tutorialNavNext => '次へ';

  @override
  String get tutorialNavNextArrow => '次へ →';

  @override
  String get tutorialNavBack => '戻る';

  @override
  String get tutorialNavBackArrow => '← 戻る';

  @override
  String get tutorialNavSkip => 'スキップ';

  @override
  String get tutorialNavLetsGo => 'レッツゴー！';

  @override
  String get welcomeExplainerHeadline => 'タイルとブロックの違い';

  @override
  String get welcomeExplainerSubtitle => 'Tilerが1日を計画する仕組みを簡単に紹介。';

  @override
  String get welcomeExplainerBlocksCaption => 'ブロックは固定。決められた時間に起こります。';

  @override
  String get welcomeExplainerTilesCaption => 'タイルは柔軟。Tilerがブロックの周りに配置します。';

  @override
  String welcomeExplainerReplanCaption(String time) {
    return '歯医者が$timeに移動 - Tilerがそれに合わせてタイルを再計画します。';
  }

  @override
  String get welcomeExplainerMovedBadge => '移動';

  @override
  String get welcomeExplainerReplannedBadge => '再計画';

  @override
  String get welcomeExplainerBlockStandup => 'チームの朝会';

  @override
  String get welcomeExplainerBlockDentist => '歯医者';

  @override
  String get welcomeExplainerTileWorkout => '運動';

  @override
  String get welcomeExplainerTileReport => 'レポート作成';

  @override
  String get welcomeExplainerTileGroceries => '買い物';

  @override
  String get welcomeExplainerLegendBlock => 'ブロック';

  @override
  String get welcomeExplainerLegendTile => 'タイル';

  @override
  String tutorialStepCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tutorialStepSettingsTilesTitle => 'タイルの設定';

  @override
  String get tutorialStepSettingsTilesBody =>
      'AIの設定はこのページにあります - 移動手段、仕事と個人の時間、ブロックアウト時間など。';

  @override
  String get tutorialStepTilePrefsTransportTitle => '移動手段';

  @override
  String get tutorialStepTilePrefsTransportBody =>
      'Tilerは普段の移動方法に基づいて、タイル間の移動時間を計算します。';

  @override
  String get tutorialStepTilePrefsHoursTitle => '仕事と個人の時間';

  @override
  String get tutorialStepTilePrefsHoursBody =>
      'Tilerが仕事用と個人用のタイルをスケジュールできる時間帯。タップしてプロファイルを設定できます。';

  @override
  String get tutorialStepTilePrefsBlockOutTitle => 'ブロックアウト時間';

  @override
  String get tutorialStepTilePrefsBlockOutBody =>
      '就寝時間と睡眠時間 - Tilerが決してスケジュールしない時間帯。';

  @override
  String get chat => 'チャット';

  @override
  String get transcribing => '文字起こし中';

  @override
  String get newChat => '新しいチャット';

  @override
  String get noChatHistory => 'チャット履歴はありません';

  @override
  String get unknownChat => '不明なチャット';

  @override
  String get transcriptionFailed => '文字起こしに失敗しました';

  @override
  String get acceptChanges => '変更を受け入れる';

  @override
  String get noRequestToExecute => '実行するリクエストはありません';

  @override
  String get initializingAction => 'アクション生成を初期化中';

  @override
  String get settingThingsUp => 'セットアップ中';

  @override
  String get preparingRequest => 'リクエストを準備中';

  @override
  String get gettingReady => '準備中';

  @override
  String get processingAction => 'アクションを処理中';

  @override
  String get workingOnIt => '対応中';

  @override
  String get analyzingRequest => 'リクエストを解析中';

  @override
  String get thinking => '思考中';

  @override
  String get actionComplete => 'アクションの処理が完了しました';

  @override
  String get processingDone => '処理が完了しました';

  @override
  String get allSet => 'すべて準備完了';

  @override
  String get finishedProcessing => '処理が終了しました';

  @override
  String get generatingSummary => 'サマリーを生成中';

  @override
  String get summarizingResults => '結果を要約中';

  @override
  String get creatingOverview => '概要を作成中';

  @override
  String get preparingSummary => 'サマリーを準備中';

  @override
  String get summaryComplete => 'サマリー生成が完了しました';

  @override
  String get summaryReady => 'サマリーが準備完了';

  @override
  String get overviewComplete => '概要が完了しました';

  @override
  String get doneSummarizing => '要約が完了しました';

  @override
  String get loadingSchedule => 'スケジュールデータを読み込み中';

  @override
  String get fetchingSchedule => 'スケジュールを取得中';

  @override
  String get retrievingCalendar => 'カレンダーを取得中';

  @override
  String get loadingTimeline => 'タイムラインを読み込み中';

  @override
  String get optimizingSchedule => 'スケジュールを最適化中';

  @override
  String get reorganizingDay => '1日を再編成中';

  @override
  String get findingBestFit => '最適な時間を探索中';

  @override
  String get adjustingTimeline => 'タイムラインを調整中';

  @override
  String get scheduleComplete => 'スケジュールの最適化が完了しました';

  @override
  String get scheduleUpdated => 'スケジュールを更新しました';

  @override
  String get timelineOptimized => 'タイムラインを最適化しました';

  @override
  String get allDone => 'すべて完了';

  @override
  String get connectionLost => '接続が切断されました。再読み込みしてください';

  @override
  String get sendingRequest => 'リクエストを送信中';

  @override
  String get webSocketConnectionLostAfter5Attempts =>
      'WebSocket接続が5回の試行後に切断されました';

  @override
  String get webSocketMessageHandlingError => 'メッセージの処理中にエラーが発生しました';

  @override
  String get jsonParseError => 'JSONの解析エラー';

  @override
  String get processError => 'プロセスエラー';

  @override
  String get socketConnectionError => 'ソケット接続エラー';

  @override
  String get keepAliveFailed => '接続維持に失敗しました';

  @override
  String get copy => 'コピー';

  @override
  String get entityIdNotFound => 'プレビューのエンティティIDが見つかりません';

  @override
  String get feedback => 'フィードバック';

  @override
  String get feedbackCategory => 'カテゴリ';

  @override
  String get feedbackCategoryBug => 'バグ';

  @override
  String get feedbackCategoryFeature => '機能';

  @override
  String get feedbackCategoryEnhancement => '機能強化';

  @override
  String get feedbackCategoryGeneral => '一般';

  @override
  String get feedbackTitle => 'タイトル';

  @override
  String get feedbackTitleHint => 'フィードバックの簡単な概要';

  @override
  String get feedbackDescription => '説明';

  @override
  String get feedbackDescriptionHint => 'フィードバックの詳細を教えてください';

  @override
  String get feedbackSubmitted => 'フィードバックを正常に送信しました';

  @override
  String get feedbackError => 'フィードバックの送信に失敗しました';

  @override
  String get noPreviewsAvailable => 'このリクエストで利用可能なタイルキャストはありません';

  @override
  String get previewUnavailable => '選択したタイルキャストは利用できません';

  @override
  String get previewSummaryUnavailable => 'タイルキャストを読み込めませんでした';

  @override
  String get previewGenerating => 'タイルキャストを生成中…';

  @override
  String get previewTimedOut =>
      'タイルキャストの生成に予想より時間がかかっています。しばらくしてからもう一度お試しください。';

  @override
  String get previewGenerationFailed => 'このタイルキャストを生成できませんでした。';

  @override
  String get previewInvalidated => 'スケジュールが変更されたため、このタイルキャストは有効ではなくなりました。';

  @override
  String get previewStaleBanner => 'このタイルキャストは、あなたのスケジュールの以前のスナップショットを反映しています。';

  @override
  String get previewNonViableLabel => 'スケジュールできませんでした';

  @override
  String get reviewChanges => '変更を確認';

  @override
  String get previewRetry => '再試行';

  @override
  String get previewPreparing => 'タイルキャストを準備中…';

  @override
  String get previewReadyToView => 'タップしてタイルキャストを表示';

  @override
  String get previewActionsOutdated => '期限切れ - 新しいメッセージを送信';

  @override
  String get previewActionsUnavailable => 'タイルキャストを利用できません';

  @override
  String get tileCastStaleNote => 'スケジュールが変更されました - このタイルキャストは最新ではなくなっています';

  @override
  String get tileCastAlsoIncluded => 'その他にも含まれています';

  @override
  String actionsCount(int count) {
    return '$count件のアクション';
  }

  @override
  String get ok => 'OK';

  @override
  String get notesLoading => 'メモを読み込み中…';

  @override
  String get notesSaving => '保存中…';

  @override
  String get notesSaved => '保存しました';

  @override
  String get notesUnsaved => '編集中…';

  @override
  String get notesSaveError => '保存できませんでした';

  @override
  String get notesSaveNow => '今すぐ保存';

  @override
  String get notesShowPreview => 'プレビュー';

  @override
  String get notesShowEditor => '編集';

  @override
  String get notesPreviewEmpty => 'プレビューする内容がありません。';

  @override
  String get notesLinkPromptTitle => 'リンクを挿入';

  @override
  String get notesConflictTitle => '他の人がこのメモを更新しました。';

  @override
  String get notesConflictDiscardMine => '自分の側を破棄';

  @override
  String get notesConflictKeepEditing => '編集を続ける';

  @override
  String get notesToolBold => '太字';

  @override
  String get notesToolItalic => 'イタリック';

  @override
  String get notesToolStrikethrough => '取り消し線';

  @override
  String get notesToolInlineCode => 'インラインコード';

  @override
  String get notesToolHeading1 => '見出し1';

  @override
  String get notesToolHeading2 => '見出し2';

  @override
  String get notesToolBulletList => '箇条書きリスト';

  @override
  String get notesToolNumberedList => '番号付きリスト';

  @override
  String get notesToolTaskList => 'タスクリスト';

  @override
  String get notesToolQuote => '引用';

  @override
  String get notesToolLink => 'リンク';

  @override
  String get notesTitle => 'メモ';

  @override
  String get notesViewerTitle => 'メモ';

  @override
  String get notesTapToAdd => 'タップしてメモを追加';

  @override
  String get notesTapToEdit => 'タップして編集・長押しして読む';

  @override
  String get notesDone => '完了';

  @override
  String get endOfDay => '1日の終了';

  @override
  String get search => '検索';

  @override
  String get share => '共有';

  @override
  String get openChat => 'チャットを開く';

  @override
  String get goToToday => '今日へ移動';

  @override
  String get switchCalendarView => 'カレンダーのビューを切り替え';

  @override
  String get switchDayGridLayout => '1日のレイアウト切替';

  @override
  String get openDayRibbon => '1日を表示';

  @override
  String get previewSundialGreeting => 'こんにちは。';

  @override
  String get previewSundialCountsPrefix => '今日は';

  @override
  String get previewSundialCountsSuffix => 'が待っています。';

  @override
  String previewSundialTilesClause(String count) {
    return 'タイル$count個';
  }

  @override
  String previewSundialBlocksClause(String count) {
    return 'ブロック$count個';
  }

  @override
  String previewSundialTileSharesClause(String count) {
    return 'タイル共有$count件';
  }

  @override
  String previewSundialWorkClause(String hours) {
    return '仕事$hours時間';
  }

  @override
  String previewSundialTransitClause(String mins) {
    return '移動$mins分';
  }

  @override
  String previewSundialClearsByClause(String time) {
    return '$timeまでに予定が空きます';
  }

  @override
  String get previewSundialAndSeparator => 'と';

  @override
  String previewSundialDistance(String distance, String unit) {
    return '$distance$unit';
  }

  @override
  String previewSundialLocations(String count) {
    return '$countか所';
  }

  @override
  String previewSundialSleepHours(String hours) {
    return '睡眠$hours時間';
  }

  @override
  String previewSundialFreeHours(String hours) {
    return '空き時間$hours時間';
  }

  @override
  String get previewSundialFullyBooked => '予定が埋まっています';

  @override
  String get previewSundialTier0 => '余裕のある日';

  @override
  String get previewSundialTier1 => 'スタート';

  @override
  String get previewSundialTier2 => '進行中';

  @override
  String get previewSundialTier3 => '順調に進んでいます';

  @override
  String get previewSundialTier4 => 'あと少し';

  @override
  String get previewSundialTodayLabel => '今日';

  @override
  String previewSundialCompositionA11y(
      String tiles, String blocks, String nonViable) {
    return 'タイル$tiles個、ブロック$blocks個、未スケジュール$nonViable件';
  }

  @override
  String get timelineClearHeading => '今日のタイムラインは空いています';

  @override
  String get timelineClearAddTask => 'タイルを追加';

  @override
  String get aiConsentTitle => 'Tiler AIへようこそ';

  @override
  String get aiConsentSubtitle => 'あなたのAI計画アシスタント';

  @override
  String get aiConsentIntro =>
      'あなたの言葉をスケジュールに変えるために、Tiler AIはあなたが送った内容を信頼できるAIプロバイダーと共有します。';

  @override
  String get aiConsentDataTitle => '送信される内容';

  @override
  String get aiConsentDataBody => 'あなたが送ったメッセージと音声録音、およびスケジュールからの関連する詳細情報。';

  @override
  String get aiConsentProvidersTitle => '受信者';

  @override
  String get aiConsentProvidersBody =>
      'Google GeminiとOpenAI。サードパーティのAIプロバイダーです。';

  @override
  String get aiConsentPrivacyLink => 'プライバシーポリシーを読む';

  @override
  String get aiConsentContinue => 'Tiler AIへ進む';

  @override
  String get aiConsentAgreementNotice =>
      '続行すると、上記の通りサードパーティのプロバイダーとこのデータを共有することに同意したことになります。';

  @override
  String get aiConsentClose => '閉じる';

  @override
  String get legalFooterPrefix => '続行すると、Tilerの';

  @override
  String get legalFooterTerms => '利用規約';

  @override
  String get legalFooterAnd => 'および';

  @override
  String get legalFooterPrivacy => 'プライバシーポリシー';

  @override
  String get aiConsentLinkError => 'リンクを開けませんでした。';

  @override
  String get addTileScreenTitleFlexible => 'タイルを追加';

  @override
  String get addTileScreenTitleFixed => 'ブロックを追加';

  @override
  String get addTileTypeFlexible => 'フレキシブルタイル';

  @override
  String get addTileTypeFixed => '固定ブロック';

  @override
  String get addTileTypeSelectorLabel => 'タイルの種類';

  @override
  String addTileExplanationFlexible(String emphasis) {
    return 'Tiler がこれに$emphasisを探します。';
  }

  @override
  String addTileExplanationFixed(String emphasis) {
    return 'ブロックは$emphasisに行われます。';
  }

  @override
  String get addTileFindTime => '時間を検討';

  @override
  String get addTileSubmitting => '送信中';

  @override
  String get addTileNameRequired => '名前は必須です';

  @override
  String get addTileTitleRequired => 'タイトルは必須です';

  @override
  String get addTileFieldTaskName => 'タスク名';

  @override
  String get addTileFieldTitle => 'タイトル';

  @override
  String get addTileFieldDuration => '時間';

  @override
  String get addTileFieldCompleteBy => '完了期限';

  @override
  String get addTileFieldPreferredTime => '希望時間';

  @override
  String get addTileFieldDate => '日付';

  @override
  String get addTileFieldStarts => '開始';

  @override
  String get addTileFieldEnds => '終了';

  @override
  String get addTileFieldLocation => '場所';

  @override
  String get addTileTaskNameHint => '何をしますか？';

  @override
  String get addTileBlockTitleHint => 'このブロックは何ですか？';

  @override
  String get addTileValueNotSet => '未設定';

  @override
  String get addTileAutoCalculated => '自動計算';

  @override
  String addTileEndsSemantics(String time) {
    return '開始と時間から計算して$timeに終了';
  }

  @override
  String addTileTodayDate(String date) {
    return '今日, $date';
  }

  @override
  String get addTileMoreOptions => 'その他のオプション';

  @override
  String get addTilePriority => '優先度';

  @override
  String get addTilePriorityLow => '低';

  @override
  String get addTilePriorityMedium => '中';

  @override
  String get addTilePriorityHigh => '高';

  @override
  String get addTilePriorityLowMeaning => 'できるといい';

  @override
  String get addTilePriorityMediumMeaning => '重要';

  @override
  String get addTilePriorityHighMeaning => '必ずやる';

  @override
  String get addTilePriorityHelper => '優先度は、Tiler が最初に守るべきタスクを決める手助けをします。';

  @override
  String get addTileColorAutomatic => '自動';

  @override
  String get addTileColorCustom => 'カスタム';

  @override
  String get addTileSplitIntoSessions => 'セッションに分割';

  @override
  String get addTileSplitHelper => '別の作業時間に分けてください。';

  @override
  String addTileSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countセッション',
    );
    return '$_temp0';
  }

  @override
  String get addTileFewerSessions => 'セッションを減らす';

  @override
  String get addTileMoreSessions => 'セッションを増やす';

  @override
  String get addTileFlexibleCompletion => '柔軟な完了日';

  @override
  String get addTileFlexibleCompletionHelper =>
      '必要に応じて、Tiler がこの日付をわずかに移動できます。';

  @override
  String get addTilePreferredTimeCustom => 'カスタム';

  @override
  String addTileDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String addTileDurationHours(int hours) {
    return '$hours時間';
  }

  @override
  String addTileDurationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get addTileRepeat => '繰り返し';

  @override
  String get addTileRepeatNever => '繰り返しなし';

  @override
  String get addTileRepeatDays => '曜日';

  @override
  String get addTileRepeatsUntil => '繰り返す終了';

  @override
  String get addTileRepeatHelper => '繰り返しは、Tiler が定期タスクを予定する手助けをします。';

  @override
  String get addTileLocationSearchHint => '場所を検索';

  @override
  String get addTileLocationYourPlaces => 'あなたの場所';

  @override
  String get addTileLocationSuggestions => '候補';

  @override
  String get addTileLocationHelper => '場所により、Tiler が移動時間やスケジュールを最適化できます。';

  @override
  String get addTileLocationNoneSaved => 'まだ保存された場所はありません';

  @override
  String get addTileLocationNoneSavedHelper =>
      '場所を検索するか、「自転車店」のような名前を入力して保存してください。';

  @override
  String get addTileLocationNoResults => '場所が見つかりません';

  @override
  String get addTileLocationNoResultsHelper => '入力した内容をそのまま場所名として保存できます。';

  @override
  String get addTileLocationSearchFailed => '検索できません';

  @override
  String get addTileLocationSearchFailedHelper =>
      '接続を確認して再試行するか、入力した内容を場所名として保存してください。';

  @override
  String addTileLocationUseTyped(String query) {
    return '「$query」を使用';
  }

  @override
  String get addTileLocationUseTypedHelper => '名前と住所を設定';

  @override
  String get addTileLocationFallbackName => '場所';

  @override
  String get addTilePlaceAdd => '場所を追加';

  @override
  String get addTilePlaceEdit => '場所を編集';

  @override
  String get addTilePlaceName => '名前';

  @override
  String get addTilePlaceAddress => '住所';

  @override
  String get addTilePlaceNameHint => '例: 職場の近くのウォルマート';

  @override
  String get addTilePlaceAddressHint => '番地、市区町村、都道府県';

  @override
  String get addTilePlaceSave => '場所を保存';

  @override
  String get addTilePlaceNameThis => 'この場所の名前を付ける';

  @override
  String get addTilePlaceNameHelper =>
      '名前は、この場所を後に探すためのものです。同じ名前の場所が2つあると、新しい住所だけが残ります。';

  @override
  String addTilePlaceNameTaken(String name, String address) {
    return '「$name」という名の場所が既に$addressにあります。保存すると、この名前は新しい住所に移動されます。';
  }

  @override
  String addTilePlaceNameTakenNoAddress(String name) {
    return '「$name」という名の場所が既にあります。保存すると、この名前は新しい住所に移動されます。';
  }

  @override
  String get addTileFieldPriority => '優先度';

  @override
  String get addTileFieldColor => '色';

  @override
  String get addTileColorPresets => 'プリセット';

  @override
  String get addTileColorAutomaticHelper => 'Tiler があなたのために色を選びます';

  @override
  String get addTileColorCustomHelper => '好きな色を選べます';

  @override
  String get addTileColorHelper => '色は、スケジュールの表示の見た目のみが変わります。';

  @override
  String get addTileColorShuffle => '別の色にシャッフル';

  @override
  String addTileColorSwatch(int index) {
    return '色 $index';
  }

  @override
  String get addTileExplanationFlexibleEmphasis => '最適な時間';

  @override
  String get addTileExplanationFixedEmphasis => '固定の時間';

  @override
  String get addTileFieldRepeat => '繰り返し';

  @override
  String get addTileDurationQuick => 'クイック';

  @override
  String get addTileDurationCustom => 'カスタム';

  @override
  String get addTileDurationHourLabel => '時間';

  @override
  String get addTileDurationMinuteLabel => '分';

  @override
  String addTileDurationEndsFromStart(String start) {
    return '$startから';
  }

  @override
  String addTileDurationEndsNextDay(String time) {
    return '$time, 翌日';
  }

  @override
  String addTileDurationEndsSemantics(String end, String start) {
    return '$startから開始して$endに終了。終了時間を変更';
  }

  @override
  String get editTileTitleTile => 'タイルを編集';

  @override
  String get editTileTitleBlock => 'ブロックを編集';

  @override
  String get editTileSave => '変更を保存';

  @override
  String get editTileSaving => '保存中…';

  @override
  String get editTileSectionTiming => '時間';

  @override
  String get editTileReasonNameRequired => '保存するには、このタイルにタイトルを付けてください';

  @override
  String get editTileReasonSplitRequired => 'セッションは最低1つにしてください';

  @override
  String get editTileReasonEndNotAfterStart => '終了は開始の後に設定してください';

  @override
  String get editTileDiscardTitle => '変更を破棄しますか？';

  @override
  String get editTileDiscardBody => 'このタイルの変更が失われます。';

  @override
  String get editTileDiscard => '破棄';

  @override
  String get editTileKeepEditing => '編集を続ける';

  @override
  String get editTileLoadFailed => 'このタイルを読み込めませんでした。';

  @override
  String get editTileSaveFailed => '現在保存できません。変更は保持されています。';

  @override
  String get editTileSectionActions => 'アクション';

  @override
  String get editTileSectionSessions => 'セッション';

  @override
  String get editTileFieldSessions => 'セッションに分割';

  @override
  String get editTileFieldDeadline => '期限';

  @override
  String get editTileSectionAdditional => '追加の詳細';

  @override
  String get editTileSectionSuggestions => '候補';

  @override
  String get editTileCreateAsNewTile => '新しいタイルとして作成';

  @override
  String get editTileSectionProgress => '進捗';

  @override
  String editTileProgressComplete(int done, int total) {
    return '$total中$done完了';
  }

  @override
  String editTileProgressRemaining(int remaining, int deleted) {
    return '$remaining件残り · $deleted件削除';
  }

  @override
  String get editTileActionComplete => '完了';

  @override
  String get editTileActionCompleteCaption => '完了としてマーク';

  @override
  String get editTileActionStartNow => '今すぐ開始';

  @override
  String get editTileActionStartNowCaption => '今に移動';

  @override
  String get editTileActionDefer => '先延ばし';

  @override
  String get editTileActionDeferCaption => '別の時間を選ぶ';

  @override
  String get editTileActionDelete => '削除';

  @override
  String get editTileActionDeleteCaption => '取り除く';

  @override
  String editTileActionConfirmComplete(String title) {
    return '「$title」を完了としてマークしますか？';
  }

  @override
  String editTileActionConfirmStartNow(String title) {
    return '「$title」を今に移動しますか？';
  }

  @override
  String editTileActionConfirmDefer(String title) {
    return '「$title」を先延ばしにしますか？';
  }

  @override
  String editTileActionConfirmDelete(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get editTileActionDeleteBody => 'これにより、このタイルがスケジュールから削除されます。';

  @override
  String get editTileActionDiscardsEdits => '保存されていない変更が破棄されます。';

  @override
  String get editTileActionFailed => '現在実行できません。';

  @override
  String editTileActionSemantics(String label, String caption) {
    return '$label、$caption';
  }

  @override
  String get editTileSectionRepetition => '繰り返し';

  @override
  String get editTileSectionPriority => '優先度';

  @override
  String get editTileSectionLocation => '場所';

  @override
  String get editTileLocationRemove => '場所を削除';

  @override
  String get addTileDeadlineClear => '期限を削除';

  @override
  String get editTileMenuTileDetails => 'タイルの詳細';

  @override
  String get editTileMoreMenu => 'その他';

  @override
  String get editTileRepeatEveryDay => '毎日';

  @override
  String get editTileRepeatEveryWeek => '毎週';

  @override
  String editTileRepeatEveryWeekOn(String days) {
    return '毎週 $days';
  }

  @override
  String get editTileRepeatEveryMonth => '毎月';

  @override
  String get editTileRepeatEveryYear => '毎年';

  @override
  String editTileRepeatUntil(String cadence, String date) {
    return '$cadence · $dateまで';
  }

  @override
  String editTileRepeatUntilDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String editTileRepeatNeverEnds(String cadence) {
    return '$cadence · 終了しない';
  }

  @override
  String get editTileRepeatCalloutTitle => '複数のインスタンスが作成されます';

  @override
  String get editTileRepeatCalloutBody => 'Tiler が、設定と空き時間に基づいて各回を予定します。';

  @override
  String get editTileNotesTitle => 'メモ';

  @override
  String get editTileModeReadOnly => 'このタイルは完了済みで編集できません。削除することはできます。';

  @override
  String get editTileModeProcrastinate =>
      'ブロックされた時間です。移動するか、完了にマークするか、削除してください。';

  @override
  String editTileModeThirdParty(String provider) {
    return '$provider が管理しています。招待への返信またはここで削除してください。イベントの編集は$providerで行ってください。';
  }

  @override
  String get editTileProviderGoogle => 'Google カレンダー';

  @override
  String get editTileProviderOutlook => 'Outlook';

  @override
  String get editTileRsvpFailed => '現在、返信を送信できません。';

  @override
  String get editTileWhatIfChecking => 'この変更の影響を確認中…';

  @override
  String editTileWhatIfSummary(int late, int overflow) {
    return '他のタイルに影響: $late件が遅延, $overflow件がオーバーフロー';
  }

  @override
  String get editTileWhatIfSheetTitle => 'この変更の影響';

  @override
  String get editTileWhatIfLate => '遅延';

  @override
  String get editTileWhatIfOverflow => 'オーバーフロー';

  @override
  String get editTileWhatIfClean => '他のタイルには影響しません。';

  @override
  String get editTileWhatIfFailed => 'スケジュールへの影響を確認できませんでした。';

  @override
  String get editTileWhatIfRetry => '再試行';

  @override
  String editTileWhatIfMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '追加で$count日影響',
      one: '追加で1日影響',
    );
    return '$_temp0';
  }

  @override
  String get editTileWhatIfUnplaced => '未配置';

  @override
  String editTileWhatIfAffectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '影響を受けたタイル$count件',
      one: '影響を受けたタイル1件',
    );
    return '$_temp0';
  }

  @override
  String get editTileEditTitle => 'タイトルを編集';

  @override
  String get tileDetailTitle => 'タイルの詳細';

  @override
  String get tileDetailLoadFailed => 'このタイルの詳細を読み込めませんでした。';

  @override
  String get tileDetailSaveFailed => '現在保存できません。変更は保持されています。';

  @override
  String get tileDetailDeleteSeries => 'タイルを削除';

  @override
  String tileDetailDeleteConfirm(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get tileDetailDeleteBody => 'このタイルのすべての回がスケジュールから削除されます。';

  @override
  String get tileDetailDeleteFailed => '現在削除できません。';

  @override
  String get tileDetailSectionOccurrences => '回';

  @override
  String get tileDetailOccurrencesEmpty => 'まだ予定されている回はありません。';

  @override
  String get tileDetailOccurrencesFailed => '回を読み込めませんでした。';

  @override
  String get tileDetailOccurrencesEarlier => '前の表示';

  @override
  String get tileDetailOccurrencesLater => '後の表示';

  @override
  String get tileDetailOccurrenceDone => '完了';

  @override
  String tileDetailOccurrenceSemantics(String day, String span, String done) {
    return '$day, $span$done';
  }

  @override
  String editTileTimeChipSemantics(String field, String value) {
    return '$fieldの時間, $value';
  }

  @override
  String editTileDateChipSemantics(String field, String value) {
    return '$fieldの日付, $value';
  }

  @override
  String get addTileSubmitFailed => '現在追加できません。内容は保存されています。';

  @override
  String get addTileRetry => '再試行';

  @override
  String get addTileTimeRestrictionTitle => '時間の制限';

  @override
  String get addTileTimeRestrictionHeading => 'Tilerはこのタイルをいつスケジュールできますか？';

  @override
  String get addTileTimeRestrictionSubtitle => 'このタイルをカレンダーに表示できる時間を設定します。';

  @override
  String get addTileRestrictionAnytimeHelper => 'Tilerはあなたの空き時間に自由に配置できます。';

  @override
  String get addTileRestrictionWork => '勤務時間';

  @override
  String get addTileRestrictionWorkHelper => '勤務プロフィールの時間にのみスケジュールします。';

  @override
  String get addTileRestrictionPersonal => 'プライベート時間';

  @override
  String get addTileRestrictionPersonalHelper => 'プライベートプロフィールの時間にのみスケジュールします。';

  @override
  String get addTileRestrictionCustom => 'カスタム時間';

  @override
  String get addTileRestrictionCustomHelper => '特定の曜日と時間を選択します。';

  @override
  String get addTileRestrictionNotSetUp => '未設定 — 矢印を使って時間を設定してください';

  @override
  String addTileRestrictionEdit(String name) {
    return '$nameを編集';
  }

  @override
  String get addTileRestrictionTip =>
      'Tilerは、このタイルの自動スケジュール、再最適化、時間の提案時にこれらの制限を尊重します。';

  @override
  String get addTileRestrictionLoadFailed => '勤務時間とプライベート時間を読み込めませんでした。';

  @override
  String addTileRestrictionDayRange(String first, String last) {
    return '$first – $last';
  }

  @override
  String addTileRestrictionWindow(String days, String start, String end) {
    return '$days · $start – $end';
  }

  @override
  String get addTileCustomHoursTitle => 'カスタム時間';

  @override
  String get addTileCustomHoursSubtitle => 'このタイルをスケジュールできる曜日と時間帯を選択してください。';

  @override
  String addTileCustomHoursProfileSubtitle(String name) {
    return '$nameの曜日と時間帯を選択してください。';
  }

  @override
  String get addTileCustomHoursPresets => 'クイックプリセット';

  @override
  String get addTileHoursPresetWeekdays => '平日';

  @override
  String get addTileHoursPresetEvenings => '夕方〜夜';

  @override
  String get addTileHoursPresetWeekends => '週末';

  @override
  String addTileHoursPresetWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String addTileHoursEndsNextDay(String day, String time) {
    return '$day $timeに終了';
  }

  @override
  String addTileRestrictionWindowNextDay(
      String days, String start, String end) {
    return '$days · $start – $end（翌日）';
  }

  @override
  String get addTileRestrictionAllDay => '終日';

  @override
  String addTileRestrictionAllDayWindow(String days, String label) {
    return '$days · $label';
  }

  @override
  String get addTileCustomHoursFooter => '無効にした曜日は、このタイルのスケジュール対象から除外されます。';

  @override
  String addTileCustomHoursProfileFooter(String name) {
    return '$nameを使用するすべてのタイルに適用されます。';
  }

  @override
  String addTileHoursCopy(String day) {
    return '$dayの時間をコピー';
  }

  @override
  String addTileHoursPaste(String day) {
    return '$dayに時間をペースト';
  }

  @override
  String get addTileHoursClearCopy => 'コピーした時間をクリア';

  @override
  String addTileHoursStartSemantics(String day, String time) {
    return '$dayの開始、$time';
  }

  @override
  String addTileHoursEndSemantics(String day, String time) {
    return '$dayの終了、$time';
  }

  @override
  String addTileHoursSaveFailed(String name) {
    return '$nameを保存できませんでした。';
  }

  @override
  String get addTileHoursSaving => '保存中…';

  @override
  String searchResultsForQuery(int count, String query) {
    return '\"$query\" の結果: $count 件';
  }

  @override
  String get searchFilterAll => 'すべて';

  @override
  String get searchFilterTiler => 'Tiler';

  @override
  String get searchFilterGoogle => 'Google';

  @override
  String get searchFilterOutlook => 'Outlook';

  @override
  String get startNow => '今すぐ開始';

  @override
  String dueOnDate(String date) {
    return '期限: $date';
  }

  @override
  String get noResultsForProvider => 'このカレンダーに結果はありません';

  @override
  String get readOnly => '読み取り専用';

  @override
  String commentsCount(int count) {
    return '$count件のコメント';
  }

  @override
  String get commentsEmpty => 'まだコメントがありません';

  @override
  String get commentsTitle => 'コメント';

  @override
  String get commentsLoading => '読み込み中…';

  @override
  String get commentsLoadEarlier => '以前のコメントを読み込む';

  @override
  String get commentsLoadEarlierReplies => '以前の返信を読み込む';

  @override
  String get commentsRetry => '再試行';

  @override
  String get commentsLoadError => 'コメントを読み込めませんでした。もう一度お試しください。';

  @override
  String get commentsCreateError => 'コメントを公開できませんでした。';

  @override
  String get commentsEditError => '編集内容を保存できませんでした。';

  @override
  String get commentsDeleteError => 'コメントを削除できませんでした。';

  @override
  String get commentsCreateReplyError => '返信を公開できませんでした。';

  @override
  String get commentsPlaceholder => 'コメントを書き込む…';

  @override
  String get commentsReplyPlaceholder => '返信を書き込む…';

  @override
  String get commentsSend => '送信';

  @override
  String get commentsSending => '送信中…';

  @override
  String get commentsEdit => '編集';

  @override
  String get commentsSave => '保存';

  @override
  String get commentsCancel => 'キャンセル';

  @override
  String get commentsDelete => '削除';

  @override
  String get commentsEdited => '編集済み';

  @override
  String get commentsDeletedPlaceholder => 'このコメントは削除されました。';

  @override
  String get commentsDeletedAuthor => '削除されたユーザー';

  @override
  String get commentsReply => '返信';

  @override
  String commentsReplies(int count) {
    return '$count件の返信';
  }

  @override
  String get commentsShowReplies => '返信を表示';

  @override
  String get commentsHideReplies => '返信を非表示';

  @override
  String get commentsYou => '(あなた)';

  @override
  String get commentsMentionSuggestions => 'メンション可能な人';

  @override
  String get commentsAttach => 'ファイルを添付';

  @override
  String get commentsAttachmentProcessing => 'ファイルを確認中…';

  @override
  String get commentsAttachmentUploaded => 'アップロード済み';

  @override
  String get commentsAttachmentQueued => 'キューに追加済み';

  @override
  String commentsAttachmentUploadingSummary(int count) {
    return 'ファイルをアップロード中（残り$count件）。このページを開いたままにしてください。';
  }

  @override
  String get commentsAttachmentUploadFailed => 'アップロードに失敗しました';

  @override
  String get commentsAttachmentPickFailed => 'そのファイルを添付できませんでした。もう一度お試しください。';

  @override
  String commentsAttachmentRemove(String name) {
    return '$nameを削除';
  }

  @override
  String get commentsAttachmentDownload => 'ダウンロード';

  @override
  String get commentsAttachmentDownloadError => 'ファイルをダウンロードできませんでした。';

  @override
  String get commentsAttachmentDownloading => 'ダウンロード中…';

  @override
  String commentsAttachmentSaved(String name) {
    return '保存しました：$name';
  }

  @override
  String get commentsAttachmentOpen => '開く';

  @override
  String get commentsAttachmentOpenFailed => 'ファイルを開けませんでした。';

  @override
  String get commentsAttachmentInvalidType =>
      '添付できるのはPDF、DOCX、PNG、JPEGファイルのみです。';

  @override
  String get commentsAttachmentTooLarge => 'ファイルは10 MB以下でなければなりません。';

  @override
  String get commentsAttachmentEmpty => 'そのファイルは空です。';

  @override
  String commentsAttachmentLimit(int count) {
    return '$count件までのファイルを添付できます。';
  }

  @override
  String get productTourStarting => 'アプリのツアーがまもなく始まります。';

  @override
  String get attentionTabTitle => '要確認';

  @override
  String get attentionFilterAll => 'すべて';

  @override
  String get attentionFilterInvitations => '招待';

  @override
  String get attentionFilterChanges => '変更';

  @override
  String get attentionFilterAtRisk => '予定に入らない';

  @override
  String get attentionFilterResponses => '回答';

  @override
  String get attentionPillInvitation => '招待';

  @override
  String get attentionPillChanged => '変更あり';

  @override
  String get attentionPillAtRisk => '予定に入らない';

  @override
  String get attentionPillDeclined => '辞退済み';

  @override
  String get attentionPillCompleted => '完了';

  @override
  String get attentionPillNotSent => '未送信';

  @override
  String get attentionSomeone => '誰か';

  @override
  String attentionReasonInvited(String inviter) {
    return '$inviterさんから招待されました';
  }

  @override
  String attentionReasonInvitedMany(String inviter, int count) {
    return '$inviterさんから$count件のTiletteに招待されました';
  }

  @override
  String attentionReasonAtRiskOne(String task) {
    return '「$task」が予定に収まらなくなりました';
  }

  @override
  String get attentionReasonAtRiskUntitled => 'Tiletteが1件、予定に収まらなくなりました';

  @override
  String attentionReasonAtRiskMany(int count) {
    return '$count件のTiletteが予定に収まらなくなりました';
  }

  @override
  String attentionReasonDeadlineMoved(String actor, String from, String to) {
    return '$actorさんが期限を$fromから$toに変更しました';
  }

  @override
  String attentionReasonDeadlineChanged(String actor) {
    return '$actorさんが期限を変更しました';
  }

  @override
  String attentionReasonRenamed(String actor) {
    return '$actorさんがTiletteの名前を変更しました';
  }

  @override
  String attentionReasonNotesUpdated(String actor) {
    return '$actorさんがメモを更新しました';
  }

  @override
  String attentionReasonUpdated(String actor) {
    return '$actorさんがTiletteを更新しました';
  }

  @override
  String attentionReasonManyChanges(String actor, int count) {
    return '$actorさんが$count件の変更を行いました';
  }

  @override
  String attentionReasonDeclined(String actor) {
    return '$actorさんが辞退しました';
  }

  @override
  String attentionReasonDeclinedMany(int count) {
    return '$count人が辞退しました';
  }

  @override
  String get attentionReasonNotSent => '招待を送信できませんでした';

  @override
  String attentionReasonNotSentMany(int count) {
    return '$count件の招待を送信できませんでした';
  }

  @override
  String get attentionReasonSendUnknown => '招待が送信されていない可能性があります。必要に応じて再送してください';

  @override
  String attentionReasonCompleted(String actor, String task) {
    return '$actorさんが$taskを完了しました';
  }

  @override
  String attentionReasonCompletedUntitled(String actor) {
    return '$actorさんがTiletteを完了しました';
  }

  @override
  String attentionReasonCompletedMany(int count) {
    return '$count件のTiletteが完了しました';
  }

  @override
  String attentionMetaTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTilette',
    );
    return '$_temp0';
  }

  @override
  String attentionMetaDue(String date) {
    return '期限：$date';
  }

  @override
  String get attentionCtaReview => '確認';

  @override
  String get attentionCtaReviewChanges => '変更を確認';

  @override
  String get attentionCtaReviewPlan => 'プランを確認';

  @override
  String get attentionCtaView => '表示';

  @override
  String get attentionMenuTooltip => 'その他';

  @override
  String get attentionDismiss => '非表示';

  @override
  String get attentionDismissed => '非表示にしました';

  @override
  String get attentionUndo => '元に戻す';

  @override
  String get attentionDismissFailed => '非表示にできませんでした。もう一度お試しください。';

  @override
  String get attentionUndoFailed => '復元できませんでした。もう一度お試しください。';

  @override
  String get attentionEmptyTitle => 'すべて確認済みです';

  @override
  String get attentionEmptyBody => '現在、確認が必要な項目はありません。';

  @override
  String get attentionEmptyFiltered => '表示する項目はありません';

  @override
  String get attentionLoadFailed => '一部の更新を読み込めませんでした';

  @override
  String get attentionLoadFailedAll => '要確認の項目を読み込めませんでした';

  @override
  String get attentionRetry => '再試行';

  @override
  String get tileShareModeBroadcast => '一斉配信';

  @override
  String get tileShareModeProject => 'プロジェクト';

  @override
  String get tileShareModeClass => 'クラス';

  @override
  String get attentionAccept => '承諾';

  @override
  String get attentionDecline => '辞退';

  @override
  String get attentionAcceptAll => 'すべて承諾';

  @override
  String get attentionDeclineAll => 'すべて辞退';

  @override
  String get attentionAcceptDone => '承諾済み';

  @override
  String attentionAcceptDoneMany(int count) {
    return '$count件のTiletteを承諾しました';
  }

  @override
  String get attentionDeclineDone => '辞退済み';

  @override
  String attentionDeclineDoneMany(int count) {
    return '$count件のTiletteを辞退しました';
  }

  @override
  String get attentionAcceptFailed => '承諾できませんでした。もう一度お試しください。';

  @override
  String get attentionDeclineFailed => '辞退できませんでした。もう一度お試しください。';

  @override
  String get attentionScheduleRefreshFailed => '承諾しましたが、予定はまだ更新できていません。';

  @override
  String get clusterTitleFallback => '名前のない共有';

  @override
  String get clusterRoleMine => 'あなたが作成';

  @override
  String clusterRoleFrom(String name) {
    return '$nameさんから';
  }

  @override
  String get clusterRoleShared => 'あなたへの共有';

  @override
  String clusterRsvpAccepted(int accepted, int total) {
    return '$total件中$accepted件が承諾済み';
  }

  @override
  String clusterRsvpPeople(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total人',
    );
    return '$_temp0中$accepted人が承諾済み';
  }

  @override
  String clusterRsvpTasks(int accepted, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total件のTilette',
    );
    return '$_temp0中$accepted件が承諾済み';
  }

  @override
  String get clusterRsvpUnavailable => '回答を取得できません';

  @override
  String get clusterMineAccepted => '承諾しました';

  @override
  String get clusterMineDeclined => '辞退しました';

  @override
  String get clusterMinePending => '回答が必要です';

  @override
  String get clusterMineMixed => '一部回答済み';

  @override
  String clusterProjectNeedsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTiletteに回答が必要です',
    );
    return '$_temp0';
  }

  @override
  String get clusterOverdue => '期限切れ';

  @override
  String get clusterMenuTooltip => 'その他の操作';

  @override
  String get clusterDelete => '削除';

  @override
  String get clusterDeleteTitle => 'この共有を削除しますか？';

  @override
  String clusterDeleteBody(String name) {
    return '「$name」を削除します。この操作は元に戻せません。';
  }

  @override
  String clusterDeleteFailed(String name) {
    return '「$name」を削除できませんでした。一覧に戻しました。';
  }

  @override
  String get clusterFilterAll => 'すべて';

  @override
  String get clusterFilterShared => '自分への共有';

  @override
  String get clusterFilterCreated => '自分が作成';

  @override
  String get clusterEmptyAllTitle => 'まだ共有はありません';

  @override
  String get clusterEmptyAllBody => 'タイルを誰かと共有すると、ここに表示されます。';

  @override
  String get clusterEmptySharedTitle => 'あなたへの共有はありません';

  @override
  String get clusterEmptySharedBody => '誰かがあなたにタイルを共有すると、ここに表示されます。';

  @override
  String get clusterEmptyCreatedTitle => 'まだ何も共有していません';

  @override
  String get clusterEmptyCreatedBody => 'タイルを共有すると、誰が承諾したか確認できます。';

  @override
  String get clusterEmptyAction => 'タイルを共有';

  @override
  String get clusterLoadFailed => '一部の共有を読み込めませんでした';

  @override
  String get clusterLoadFailedAll => '共有を読み込めませんでした';

  @override
  String get clusterLoadMore => 'さらに読み込む';

  @override
  String get clusterLoadMoreFailed => '追加で読み込めませんでした';

  @override
  String get clustersTabTitle => '共有';

  @override
  String get previewTitleFallback => '予定を確認';

  @override
  String get previewRegenerate => '新しいプレビューを作成';

  @override
  String get previewSuggested => '提案された予定';

  @override
  String get previewSelected => '選択した予定';

  @override
  String previewMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '時間を調整できるタイルを$count件移動します',
    );
    return '$_temp0';
  }

  @override
  String get previewAccept => '承諾';

  @override
  String get previewAcceptAndLock => '承諾して固定';

  @override
  String get previewAcceptHint => 'Tilerは後で時間を調整できる作業を移動することがあります。';

  @override
  String previewLockHint(String when) {
    return '$whenに固定します。他のセッションは調整可能なままです。';
  }

  @override
  String get previewDecline => '辞退';

  @override
  String get previewCannotFit => '期限までに予定に入れられません。';

  @override
  String previewOutsideWindow(String when) {
    return '表示されている日以外に予定されています：$when';
  }

  @override
  String get previewNothingThisDay => 'この日に予定はありません';

  @override
  String get previewPrevDay => '前の日';

  @override
  String get previewNextDay => '次の日';

  @override
  String get previewStale => 'このプレビューは古くなっています。';

  @override
  String get previewRefresh => 'プレビューを更新';

  @override
  String get previewSessionInvalid => 'この時間は固定できなくなりました。承諾は引き続き可能です。';

  @override
  String get previewLoading => '予定を確認しています…';

  @override
  String get previewLoadFailed => 'プレビューを作成できませんでした。';

  @override
  String get previewGone => 'この招待は利用できなくなりました。';

  @override
  String get previewSwitchedOff => '現在プレビューは利用できません。';

  @override
  String get previewSignIn => 'プレビューを見るには再度ログインしてください。';

  @override
  String get previewInvalid => 'このリクエストは受け付けられませんでした。もう一度お試しください。';

  @override
  String get previewUnsupportedAccepted => 'すでに承諾しています。';

  @override
  String get previewUnsupportedDeadline => '期限が過ぎています。';

  @override
  String get previewUnsupportedConstraints =>
      'このTiletteには繰り返し、場所、またはプレビューではまだ表示できない制約があります。一覧から回答することはできます。';

  @override
  String get previewUnsupportedOther => 'このTiletteのプレビューは表示できません。';

  @override
  String get previewAdding => 'カレンダーに追加しています…';

  @override
  String get previewAdded => 'カレンダーに追加しました';

  @override
  String get previewNeedsReview => '追加しましたが、時間を確認できませんでした。';

  @override
  String get previewNotAdded => '追加されませんでした';

  @override
  String get previewReasonScheduleChanged => 'このプレビューの作成後に予定が変更されました。';

  @override
  String get previewReasonAnswered => '別の場所で回答または変更されました。';

  @override
  String get previewReasonExpired => 'プレビューの有効期限が切れました。';

  @override
  String get previewReasonOther => 'プレビューどおりに予定に入れられませんでした。';

  @override
  String get previewReviewAgain => '再確認';

  @override
  String get previewUnconfirmed => '回答を確認できませんでした。';

  @override
  String get previewTryAgain => '再試行';

  @override
  String get previewCheckStatus => '状態を確認';

  @override
  String get previewStillAdding => '追加を続けています…';

  @override
  String get previewDeclined => '辞退済み';

  @override
  String get previewDeclineFailed => '辞退できませんでした。もう一度お試しください。';

  @override
  String get previewDone => '完了';

  @override
  String get previewCheckFit => '予定に収まるか確認';

  @override
  String get previewDetails => '詳細';

  @override
  String get previewOtherTimes => '他の時間';

  @override
  String get previewOriginalSuggestion => '最初の提案';

  @override
  String get previewFindAnotherTime => '別の時間を探す';

  @override
  String get previewFindingTimes => '他の時間を探しています…';

  @override
  String get previewNoDifferentTime => '別の時間は見つかりませんでした';

  @override
  String get previewOptionsFailed => '他の時間を読み込めませんでした。';

  @override
  String get previewSelectFailed => 'その時間に変更できませんでした。';

  @override
  String get previewNoMoves => '他の予定は移動しません';

  @override
  String get previewSessions => 'セッション';

  @override
  String previewSessionN(int n) {
    return 'セッション$n';
  }

  @override
  String get previewSessionUnplaced => '予定に入れられませんでした';

  @override
  String get previewSessionOutside => '表示されている日以外';

  @override
  String previewIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '予定の問題が$count件あります',
    );
    return '$_temp0';
  }

  @override
  String get previewIssueUnscheduled => '予定に入れられませんでした';

  @override
  String get previewIssueConflict => '他の作業と重なっています';

  @override
  String previewIssueWindow(String from, String to) {
    return '$from〜$toに予定できます';
  }

  @override
  String get previewViewInCalendar => 'カレンダーで表示';

  @override
  String get detailLoadFailed => 'この共有を読み込めませんでした。';

  @override
  String get detailNotFound => 'この共有は利用できなくなりました。';

  @override
  String get detailRefreshFailed => '更新できませんでした。読み込み済みの内容を表示しています。';

  @override
  String get detailTasksFailed => '共有のTiletteを読み込めませんでした。';

  @override
  String get detailTasks => 'Tilette';

  @override
  String get forecastDeadlinePassed => '期限が過ぎています';

  @override
  String get broadcastParticipants => '参加者';

  @override
  String broadcastViewAll(int count) {
    return 'すべて表示（$count）';
  }

  @override
  String get broadcastNoParticipants => 'まだ参加者はいません。上から追加してください。';

  @override
  String get projectNoParticipants =>
      'まだ参加者はいません。Tiletteタブで誰かにTiletteを割り当ててください。';

  @override
  String broadcastDeliveryIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の招待が届いていない可能性があります',
    );
    return '$_temp0';
  }

  @override
  String get participantInvited => '招待済み';

  @override
  String get participantAdding => '追加しています…';

  @override
  String get participantAddFailed => '追加できませんでした。';

  @override
  String get participantRemoveFailed => '削除できませんでした。';

  @override
  String participantAlreadyInvited(String who) {
    return '$whoさんはすでに招待されています。';
  }

  @override
  String get participantRemove => '削除';

  @override
  String participantRemoveTitle(String who) {
    return '$whoさんを削除しますか？';
  }

  @override
  String get participantRemoveBody => 'この参加者はこのTiletteを持たなくなります。';

  @override
  String deliverySent(String channel) {
    return '$channelで送信済み';
  }

  @override
  String get deliverySentPlain => '招待を送信しました';

  @override
  String deliveryFailed(String channel) {
    return '$channelで送信できませんでした';
  }

  @override
  String get deliveryFailedPlain => '招待を送信できませんでした';

  @override
  String get deliveryUnknown => '配信状況は不明です';

  @override
  String get channelEmail => 'メール';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelPush => '通知';

  @override
  String classPeopleIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人が一部のTiletteに参加していません',
    );
    return '$_temp0';
  }

  @override
  String classMissingTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTiletteに未参加',
    );
    return '$_temp0';
  }

  @override
  String get classAddToAll => 'すべてのTiletteに追加';

  @override
  String get classRemoveBody => 'この参加者はすべてのTiletteから削除されます。';

  @override
  String get classTaskNotAdded => '未追加';

  @override
  String get classAddFailed => 'すべてのTiletteに追加できませんでした。';

  @override
  String get projectUnassigned => '担当者なし';

  @override
  String projectTasksUnassigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTiletteに担当者がいません',
    );
    return '$_temp0';
  }

  @override
  String get projectAssign => '割り当て';

  @override
  String get projectReassign => '再割り当て';

  @override
  String get projectReassigning => '再割り当てしています…';

  @override
  String get projectReassignFailed => '再割り当てできませんでした。';

  @override
  String projectAssignTitle(String task) {
    return '$taskを割り当て';
  }

  @override
  String projectOwnsTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTiletteを担当',
    );
    return '$_temp0';
  }

  @override
  String get projectAlreadyIn => 'すでにこのプロジェクトに参加しています';

  @override
  String get projectRemoveBody => 'この参加者のTiletteは担当者なしになります。';

  @override
  String get tileShareActivityCommentAdded => 'コメントを追加しました';

  @override
  String get tileShareActivityCommentReplied => 'コメントへの返信を追加しました';

  @override
  String get tileShareActivityCommentEdited => 'コメントを編集しました';

  @override
  String get tileShareActivityCommentDeleted => 'コメントを削除しました';

  @override
  String get commitmentYourTasks => 'あなたのTilette';

  @override
  String get commitmentYourTask => 'あなたのTilette';

  @override
  String commitmentPartialAnswered(int done, int total) {
    return '$total件中$done件に回答済みです。残りは回答待ちです。';
  }

  @override
  String get commitmentOpenTile => 'タイルを開く';

  @override
  String get detailEditShare => '共有を編集';

  @override
  String get detailEditTask => 'Tiletteを編集';

  @override
  String get detailAddTask => 'Tiletteを追加';

  @override
  String get detailDeleteTask => 'Tiletteを削除';

  @override
  String detailDeleteTaskTitle(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get detailDeleteTaskBody => '参加者全員の予定から削除されます。';

  @override
  String get detailEditFailed => '変更を保存できませんでした。もう一度お試しください。';

  @override
  String get detailTaskLengthFixed => '共有後はTiletteの所要時間を変更できません。';

  @override
  String get taskSheetAssignee => '担当者';

  @override
  String get taskSheetEveryone => 'このクラスの全員がこのTiletteを持っています。';

  @override
  String taskSheetAfterShareDeadline(String when) {
    return '共有の期限（$when）より後です。';
  }

  @override
  String get taskSheetNameTooShort => '3文字以上で入力してください';

  @override
  String get taskSheetPeopleHintClass =>
      'ここで追加した人は、このクラスのすべてのTiletteを受け取ります。参加者の変更は保存時に送信されます。';

  @override
  String get taskSheetPeopleHintProject => '新しい割り当ては保存時に送信されます。';

  @override
  String get tiletteNameLabel => 'Tilette名';

  @override
  String get detailEditDetails => '詳細を編集';

  @override
  String get detailDeleteShare => '共有を削除';

  @override
  String get detailDeleteShareBody => '全員の予定から共有のTiletteが削除されます。';

  @override
  String get detailDeleteShareFailed => '共有を削除できませんでした。もう一度お試しください。';

  @override
  String get shareNameLabel => '共有名';

  @override
  String get shareModeLabel => 'モード';

  @override
  String get shareEditModeFixed => '共有後はモードを変更できません。';

  @override
  String get shareEditEffort => '合計作業時間';

  @override
  String get shareEditEffortHelper => '共有のTiletteの所要時間の合計です。';

  @override
  String get shareEditDiscardBody => 'この共有への変更は失われます。';

  @override
  String shareEditTilettesPulledIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '承諾済みのTilette$count件の期限をこの期限に変更します。',
    );
    return '$_temp0';
  }

  @override
  String shareEditTilettesKeep(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '誰も承諾していないTilette$count件は、後の期限を維持します。',
    );
    return '$_temp0';
  }

  @override
  String taskSheetMoveShareDeadline(String when) {
    return '共有の期限も$whenに変更';
  }

  @override
  String get createChooserTitle => '作業を共有';

  @override
  String get createChooserSubtitle => 'どのように参加してもらいますか？';

  @override
  String get createModeBroadcastBody => '全員が1件のTiletteのコピーをそれぞれ受け取ります';

  @override
  String get createModeClassBody => '全員が一組のTiletteのコピーをそれぞれ受け取ります';

  @override
  String get createModeProjectBody => '全員で一組のTiletteを共有して作業します';

  @override
  String get createComingSoon => '近日公開';

  @override
  String get createBroadcastTitle => '新しい一斉配信';

  @override
  String get createBroadcastPeopleHint => '各自がコピーを受け取り、承諾を求められます。';

  @override
  String get createSend => '送信';

  @override
  String createSendTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人に送信',
    );
    return '$_temp0';
  }

  @override
  String get createSending => '送信しています…';

  @override
  String get createNeedsPerson => '少なくとも1人追加してください';

  @override
  String get createFailed => '現在送信できません。入力内容は保持されています。';

  @override
  String get createDiscardTitle => 'この共有を破棄しますか？';

  @override
  String get createDiscardBody => '入力した内容は送信されません。';

  @override
  String get createClassTitle => '新しいクラス';

  @override
  String get createNeedsTask => '少なくとも1件のTiletteを追加してください';

  @override
  String get createClassPeopleHint => '各自がすべてのTiletteのコピーを受け取り、承諾を求められます。';

  @override
  String get createTilettesLabel => 'Tilette';

  @override
  String createTiletteWithShare(String length) {
    return '$length · 共有と同じ期限';
  }

  @override
  String createTiletteDue(String length, String when) {
    return '$length · 期限：$when';
  }

  @override
  String createClassSummary(int count, String effort, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のTilette',
    );
    return '$_temp0 · $effort · 期限：$when';
  }

  @override
  String createStepOf(int step, int total) {
    return 'ステップ$step/$total';
  }

  @override
  String get createNextPeople => '次へ：参加者';

  @override
  String get createProjectTitle => '新しいプロジェクト';

  @override
  String get createProjectSend => 'プロジェクトを作成';

  @override
  String get createCreating => '作成しています…';

  @override
  String get createProjectHint => '作成後にボードから参加者にTiletteを割り当てるか、自分で担当してください。';

  @override
  String get detailLoading => '共有を読み込んでいます…';

  @override
  String get taskSheetPeopleLabel => '参加者';

  @override
  String get taskSheetAddPerson => '参加者を追加';

  @override
  String get taskSheetWillBeAdded => '追加されます';

  @override
  String get taskSheetWillBeRemoved => '削除されます';

  @override
  String get taskSheetWillBeAssigned => '保存時に割り当てられます';

  @override
  String get taskSheetPeopleFailed => '参加者の変更の一部を保存できませんでした。以下で再試行してください。';

  @override
  String get tileShareSaveChanges => '変更を保存';

  @override
  String get scheduleChangeRefresh => 'スケジュールを更新';

  @override
  String get scheduleChangeUncertainBody =>
      '変更がサーバーに届いている可能性があります。更新して、スケジュールに変更があるか確認してください。この制限は自動的に解除されます。';

  @override
  String get scheduleChangeRefreshing => 'タイムラインを更新しています…';

  @override
  String get scheduleChangeShuffling => '新しい並べ方を試しています…';

  @override
  String get scheduleChangeShuffleCommand => 'シャッフル';

  @override
  String get scheduleChangeBuildingTimeline => '最初のタイムラインを作成しています…';

  @override
  String get scheduleChangeSetupCommand => '最初のタイムライン';

  @override
  String get scheduleChangeUncertain => '確認できません';

  @override
  String scheduleChangeAcknowledged(String change) {
    return '$change：タイムラインが更新されました。変更を確認してください。';
  }

  @override
  String scheduleChangeWentThrough(String change) {
    return '$changeが完了しました。';
  }

  @override
  String scheduleChangeFailedLate(String change) {
    return '$changeに失敗しました。';
  }

  @override
  String scheduleChangeUnconfirmed(String change) {
    return '$changeを確認できませんでした。スケジュールを確認してください。';
  }

  @override
  String scheduleChangeNotSent(String change) {
    return 'Tilerに接続できなかったため、$changeは送信されませんでした。もう一度お試しください。';
  }

  @override
  String get scheduleChangeUnconfirmedGeneric =>
      '直前のスケジュール変更を確認できませんでした。スケジュールを確認してください。';

  @override
  String get scheduleChangeReattemptTitle => 'もう一度送信しますか？';

  @override
  String scheduleChangeReattemptBody(String change) {
    return '$changeはすでに反映されている可能性があります。もう一度送信しますか？';
  }

  @override
  String get scheduleChangeReattemptConfirm => 'もう一度送信';

  @override
  String scheduleChangeReattemptDeclined(String change) {
    return '$changeは再送信されませんでした。';
  }

  @override
  String get scheduleChangeAdding => '予定を追加中';

  @override
  String get scheduleChangeSettings => 'スケジュール設定を更新中';

  @override
  String get scheduleChangeAccepting => '変更を承認中';

  @override
  String get scheduleChangeTargetSchedule => 'あなたのスケジュール';

  @override
  String get scheduleChangeTargetEvent => '予定';

  @override
  String get scheduleChangeAllEvents => 'すべての予定';

  @override
  String scheduleChangeEventCount(int count) {
    return '$count件の予定';
  }

  @override
  String get scheduleChangesBlocked => '現在のスケジュール変更が完了してから、次の変更を開始してください。';

  @override
  String scheduleChangesBlockedBy(String change) {
    return '現在のスケジュール変更（$change）が完了してから、次の変更を開始してください。';
  }

  @override
  String get scheduleChangeFailed => 'スケジュール変更に失敗しました';

  @override
  String get scheduleUpdates => 'スケジュールの更新';

  @override
  String get scheduleUpdatesDescription => 'スケジュールが変わったときの一日の動き方。';

  @override
  String get scheduleUpdatesDetailed => '詳細';

  @override
  String get scheduleUpdatesDetailedDescription => '変更を一つずつ順に表示します。';

  @override
  String get scheduleUpdatesMinimal => 'シンプル';

  @override
  String get scheduleUpdatesMinimalDescription => 'タイルを新しい時間へスライドします。';

  @override
  String get scheduleUpdatesOff => 'オフ';

  @override
  String get scheduleUpdatesOffDescription => 'アニメーションなしですぐに更新します。';

  @override
  String get scheduleChangePlanUpdated => 'プランを更新しました';

  @override
  String get scheduleChangeDayCleared => 'この日は空になりました';

  @override
  String scheduleChangeTilesMoved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString件のタイルを移動',
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
      other: '$countString件のタイルを別の日に移動',
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
      other: '$countString件のタイルを追加',
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
      other: '$countString件のタイルを削除',
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
      other: '$countString件の移動時間を更新',
    );
    return '$_temp0';
  }

  @override
  String scheduleChangeFreeGained(String duration) {
    return '空き時間 +$duration';
  }

  @override
  String get scheduleChangeSeeChanges => '変更を見る';

  @override
  String get scheduleChangeWhatChanged => '変更内容';

  @override
  String scheduleChangeAdded(String time) {
    return '追加 · $time';
  }

  @override
  String get scheduleChangeRemoved => '削除';

  @override
  String scheduleChangeTravelTo(String name) {
    return '$nameへの移動';
  }

  @override
  String get scheduleChangeFreeTime => '空き時間';

  @override
  String scheduleChangeMovedFrom(String time) {
    return '$timeから移動';
  }

  @override
  String scheduleChangeMovedTo(String time) {
    return '$timeに移動';
  }

  @override
  String scheduleChangeTileMovedTo(String name, String when) {
    return '$nameを$whenに移動';
  }

  @override
  String scheduleChangeTilesMovedTo(int count, String when) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString件のタイルを$whenに移動',
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
      other: '$countString件のタイルを後ろに移動',
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
      other: '$countString件のタイルを前に移動',
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
      other: '$countString件のタイルを移動中',
    );
    return '$_temp0';
  }

  @override
  String get scheduleChangeTabChanges => '変更';

  @override
  String get scheduleChangeTabBeforeAfter => '変更前と変更後';

  @override
  String get scheduleChangeBefore => '変更前';

  @override
  String get scheduleChangeAfter => '変更後';

  @override
  String get vibeChatExecutionMode => 'チャットのアクション実行';

  @override
  String get vibeConfirmFirst => '先に確認する';

  @override
  String get vibeAutoAct => '自動実行';

  @override
  String get vibeAutoActNote =>
      '対応するチャットのアクションを自動実行します。一括変更や削除などの操作は引き続き確認が必要です。';

  @override
  String get vibeConfirmNote => 'チャットによる変更を実行前に確認します。';

  @override
  String get vibeConfirmCreation => '作成を確定';

  @override
  String get vibeCheckStatus => '状態を確認';

  @override
  String get vibeCreationUnknown => '作成を確認できませんでした。再試行する前に状態を確認してください。';

  @override
  String get vibeReviewAgain => '再度確定する前に、現在の提案を確認してください。';

  @override
  String get vibeTileShareCreated => 'TileShareを作成しました。';

  @override
  String get vibeCreationReview => 'TileShareの作成を確認';

  @override
  String get vibeCreationNote =>
      '確定するまで何も作成されません。受信者は承諾するかどうかを引き続き選べます。この操作では通知は送信されません。';

  @override
  String get vibeCreateProject => 'プロジェクトを作成';

  @override
  String get vibeAddTilette => 'Tiletteを追加';

  @override
  String get vibeReviewProject => 'プロジェクト';

  @override
  String get vibeReviewStarts => '開始';

  @override
  String get vibeReviewDeadline => '締切';

  @override
  String get vibeReviewMinutes => '分';

  @override
  String get vibeOpenTileShare => 'TileShareを開く';

  @override
  String get vibeProjectRenamed => 'プロジェクトの名前を変更しました。';

  @override
  String get vibeRenameReview => 'プロジェクトの名前変更を確認';

  @override
  String get vibeRenameProject => 'プロジェクトの名前を変更';

  @override
  String get vibePreviousName => '現在の名前';

  @override
  String get vibeRenameNote => '確定後に変更されるのはプロジェクトの名前だけです。';

  @override
  String get vibeConfirmRename => '名前変更を確定';

  @override
  String get vibeRenameUnknown => '名前変更を確認できませんでした。再試行する前に状態を確認してください。';

  @override
  String get vibeTiletteRenamed => 'Tiletteの名前を変更しました。';

  @override
  String get vibeTiletteRenameReview => 'Tiletteの名前変更を確認';

  @override
  String get vibeRenameTilette => 'Tiletteの名前を変更';

  @override
  String get vibeTiletteRenameNote =>
      '共有されているTiletteの名前だけが変更されます。個人のカレンダーのタイトルは変わりません。';

  @override
  String get vibeNotesUpdated => 'Tiletteのメモを更新しました。';

  @override
  String get vibeNotesReview => 'Tiletteのメモを確認';

  @override
  String get vibeEditNotes => 'Tiletteのメモを更新';

  @override
  String get vibePreviousNotes => '現在のメモ';

  @override
  String get vibeProposedNotes => '提案されたメモ';

  @override
  String get vibeEmptyNotes => 'メモなし';

  @override
  String get vibeClearNotes => 'メモを消去';

  @override
  String get vibeNotesNote => '確定後、提案されたテキストがTiletteのメモ全体を置き換えます。';

  @override
  String get vibeConfirmNotes => 'メモを確定';

  @override
  String get vibeNotesUnknown => 'メモの更新を確認できませんでした。再試行する前に状態を確認してください。';

  @override
  String get vibeTiletteDeleted => 'Tiletteを削除しました。';

  @override
  String get vibeDeleteReview => 'Tiletteの削除を確認';

  @override
  String get vibeDeleteTilette => 'Tiletteを削除';

  @override
  String get vibeAssignmentCount => '割り当て';

  @override
  String get vibeLinkedCalendarCount => 'リンクされたカレンダー項目';

  @override
  String get vibeDeleteNote =>
      'Tiletteとリンクされたカレンダーの作業を無効にします。プロジェクトと他のTiletteは引き続き利用できます。割り当て履歴は保持されます。ここでは元に戻せません。';

  @override
  String get vibeConfirmDeletion => '削除を確定';

  @override
  String get vibeDeleteUnknown => '削除を確認できませんでした。再試行する前に状態を確認してください。';

  @override
  String get vibeOpenProject => 'プロジェクトを開く';

  @override
  String get vibeTiletteUpdated => 'Tiletteを更新しました。';

  @override
  String get vibeUpdateReview => 'Tiletteの更新を確認';

  @override
  String get vibeUpdateTilette => 'Tiletteを更新';

  @override
  String get vibeUpdateNote =>
      '確定後、表示されたすべての変更をまとめて保存します。入力されたメモは既存のメモ全体を置き換えます。';

  @override
  String get vibeConfirmUpdate => '更新を確定';

  @override
  String get vibeUpdateRejected => '変更は適用されませんでした。回答を確認し、修正した更新案を依頼してください。';

  @override
  String get vibeUpdateUnknown => '更新を確認できませんでした。再試行する前に状態を確認してください。';

  @override
  String get vibeScheduleUpdatePending => '承諾済みの作業の予定を計算しています。変更はまだ保存されていません。';

  @override
  String get vibeScheduleNoFit =>
      '変更は適用されませんでした。保護されたセッションの合間に残りの作業を予定できませんでした。所要時間または締切を調整し、修正した更新案を依頼してください。';

  @override
  String get vibeScheduleUpdateFailed =>
      '変更は適用されませんでした。予定が変更されたか、計算を完了できませんでした。修正した更新案を依頼してください。';

  @override
  String get vibeUpdateProject => 'プロジェクトを更新';

  @override
  String get vibeProjectUpdateReview => 'プロジェクトの更新を確認';

  @override
  String get vibeProjectUpdated => 'プロジェクトを更新しました。';

  @override
  String get vibeManageAccess => 'プロジェクトへのアクセスを管理';

  @override
  String get vibeManageRecipients => '受信者を管理';

  @override
  String get vibeManagementUpdated => '受信者またはアクセスの変更を保存しました。';

  @override
  String get vibeManagementNote =>
      '上記の受信者とアクセスへの影響を確認してください。カレンダーへのアクセスの整理と復元はバックグラウンドで行われます。';

  @override
  String get vibeAccessReconciliation =>
      'アクセスを保存しました。カレンダーの整理または復元はバックグラウンドで行われます。';

  @override
  String get vibePlanTargetPending => '全体の計算を待機中';

  @override
  String get vibePlanTargetNotApplied => '未適用';

  @override
  String get vibePlanReview => '共有作業のプランを確認';

  @override
  String get vibePlanUpdated => '確認済みの変更をまとめて保存しました。';

  @override
  String get vibePlanNote =>
      '確定後、表示されたすべての対象をまとめて保存します。対象が変更された場合やアクセスを失った場合は、新しい提案を確認してください。';

  @override
  String get shareViewOptions => '表示オプション';

  @override
  String get shareDensityComfortable => 'ゆったり';

  @override
  String get shareDensityCompact => 'コンパクト';

  @override
  String get shareDensityList => 'リスト';

  @override
  String get shareDensityComfortableHint => 'メモのプレビューと操作名を表示したカード。';

  @override
  String get shareDensityCompactHint => 'クイック操作が使える小さめのカード。おすすめです。';

  @override
  String get shareDensityListHint => '行を詰めて表示します。Tiletteをタップすると詳細と操作が展開されます。';

  @override
  String get shareExpandTilette => 'Tiletteを展開';

  @override
  String get shareCollapseTilette => 'Tiletteを折りたたむ';

  @override
  String get shareWork => '作業';

  @override
  String get sharePeople => '参加者';

  @override
  String get shareActivity => 'アクティビティ';

  @override
  String get shareMyWork => '自分の作業';

  @override
  String get shareClassHint => '全員が各Tiletteのコピーをそれぞれ受け取ります。';

  @override
  String get shareProjectHint => '複数の参加者にTiletteを割り当て、1つの目標に向けて作業します。';

  @override
  String get shareNeedsDecision => '判断が必要です';

  @override
  String get shareTilette => 'Tilette';

  @override
  String get shareViewTilette => 'Tiletteを表示';

  @override
  String get shareReviewRequest => 'リクエストを確認';

  @override
  String get shareAssignedTo => '担当者';

  @override
  String get shareAssignedToYou => 'あなたに割り当て済み';

  @override
  String get shareYourResponse => 'あなたの回答';

  @override
  String get shareInvitationHint => 'このTiletteを自分の予定に追加するかどうかを選んでください。';

  @override
  String get shareReadNotes => 'メモを読む';

  @override
  String get shareEditNotes => 'メモを編集';

  @override
  String get shareOpenDiscussion => 'ディスカッションを開く';

  @override
  String get shareThreadUnavailable => 'このTiletteのディスカッションは利用できません。';

  @override
  String get shareCommitments => 'あなたが引き受けた作業';

  @override
  String get shareNeedsAttention => '要確認';

  @override
  String get shareInProgress => '進行中';

  @override
  String get shareNotStarted => '未開始';

  @override
  String get shareAwaitingResponse => '回答待ち';

  @override
  String get shareNoAssignments => 'この共有では、まだあなたにTiletteが割り当てられていません。';

  @override
  String get shareNotesEmpty => 'まだメモは追加されていません。';

  @override
  String get shareNoMatches => 'この絞り込み条件に一致するTiletteはありません。';

  @override
  String get shareProjectNoPeople =>
      'まだ参加者はいません。Tiletteを割り当てると、このプロジェクトに参加者を追加できます。';

  @override
  String shareCompletionCount(int done, int total) {
    return '$total件中$done件完了';
  }

  @override
  String shareMissingAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '割り当てが$count件不足しています',
    );
    return '$_temp0';
  }

  @override
  String sharePeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人',
    );
    return '$_temp0';
  }
}
