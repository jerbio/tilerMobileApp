// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get whiteSpace => ' ';

  @override
  String get add => '追加';

  @override
  String get setupCustomRestrictions => 'カスタム制約の設定';

  @override
  String get customRestrictionTitle => 'カスタム制約';

  @override
  String get customRestrictionHeader => 'カスタム制約の設定';

  @override
  String get customRestrictionHeaderDescription =>
      'このタスクを完了させたいタイミングを選択してください。';

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
  String get deadline_anytime => '締切（いつでも）';

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
  String get tileShareName => 'タイル共有の名前';

  @override
  String get tileShare => 'タイル共有';

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
  String get multiShare => '複数共有';

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
  String get dayFilterAll => 'All';

  @override
  String get dayFilterBlocks => 'Blocks';

  @override
  String get dayFilterTiles => 'Tiles';

  @override
  String get dayFilterTooltip => 'Show all, blocks only, or tiles only';

  @override
  String dayFilterShowingBlocks(int shown, int total) {
    return 'Showing blocks only · $shown of $total';
  }

  @override
  String dayFilterShowingTiles(int shown, int total) {
    return 'Showing tiles only · $shown of $total';
  }

  @override
  String dayFilterEmptyBlocks(String day) {
    return 'No blocks on $day';
  }

  @override
  String dayFilterEmptyTiles(String day) {
    return 'No tiles on $day';
  }

  @override
  String get dayFilterShowAll => 'Show all';

  @override
  String get dayFilterAutoCleared => 'Showing all — filter cleared';

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
    return '${hours}h$minutes分';
  }

  @override
  String durationHoursShort(int hours) {
    return '${hours}h';
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
  String get dayGridAllDay => '??';

  @override
  String get dayGridHeaderAllClear => '???????';

  @override
  String dayGridHeaderConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '??$count?',
      one: '??1?',
    );
    return '$_temp0';
  }

  @override
  String dayGridHeaderNeedAttention(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$summary????????',
      one: '$summary????????',
    );
    return '$_temp0';
  }

  @override
  String get dayGridHeaderReview => '??';

  @override
  String get dayGridDaySummary => '1????';

  @override
  String get bottomNavToday => '??';

  @override
  String get bottomNavTiler => 'Tiler';

  @override
  String get dayGridHeaderRespond => '??';

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
  String get switchDayGridLayout => '1????????????';

  @override
  String get openDayRibbon => '1????';

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
