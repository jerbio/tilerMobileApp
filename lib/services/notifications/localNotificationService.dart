import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/procrastinateAll.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileProcrastinate.dart';
import 'package:tiler_app/services/api/notificationData.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/userApi.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../constants.dart' as Constants;

enum NotificationIdTypes { none, nextTile, userSetReminder, depatureTime }

class _NotificationDetailFormat {
  final NotificationIdTypes notificationIdType;
  final String notificationCategoryName;
  final String notificationChannelId;
  final String? notificationCategoryDescription;
  _NotificationDetailFormat(
      {required this.notificationIdType,
      required this.notificationCategoryName,
      required this.notificationChannelId,
      this.notificationCategoryDescription});
}

class LocalNotificationService {
  LocalNotificationService();
  static Map<NotificationIdTypes, _NotificationDetailFormat>? channelDetails;
  static final _localNotificationService = FlutterLocalNotificationsPlugin();
  NotificationData _notificationData = NotificationData.noCredentials();
  UserApi userApi = UserApi();
  SecureStorageManager _storageManager = SecureStorageManager();

  Future<void> initialize(BuildContext context) async {
    tz.initializeTimeZones();
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        print('id $id');
      },
    );

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@drawable/ic_tiler_notificationicon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
    );
    await _localNotificationService.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      print('payload $payload');
    });
    intializeChannelDetails(context);
  }

  Future initializeRemoteNotification() async {
    NotificationData? notificationData =
        await _storageManager.readNotificationData();
    final String notificationPlatform = "upcomingtiles";
    if (notificationData == null || !notificationData.isValid) {
      try {
        await OneSignal.Notifications.requestPermission(true);
      } catch (e) {
        print('Error in requesting notification permissions.');
      }

      notificationData =
          await userApi.getNotificationChannel(notificationPlatform);
      await _storageManager.saveNotificationData(
          notificationData ?? NotificationData.noCredentials());
    }
    if (notificationData != null) {
      _notificationData = notificationData;
    }
  }

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  completeTile(BuildContext context, SubCalendarEvent subTile) async {
    showMessage(AppLocalizations.of(context)!.completing);
    final scheduleState = context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var subCalendarEventApi = SubCalendarEventApi();

    var requestFuture = subCalendarEventApi.complete((subTile));

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        scheduleStatus: scheduleStatus,
        isAlreadyLoaded: true,
        callBack: requestFuture));
  }

  Future handleComplete(BuildContext context, String notificationID) async {
    const completeText = '_complete';
    String subEventComponentId = notificationID;
    int indexOfCompleteText =
        subEventComponentId.toLowerCase().indexOf(completeText);
    if (indexOfCompleteText > 0) {
      subEventComponentId =
          subEventComponentId.substring(0, indexOfCompleteText);
    }
    SubCalendarEvent? subTile =
        getSubCalendartEventById(context, subEventComponentId);
    if (subTile != null && subTile.id != null && subTile.id!.isNotEmpty) {
      await completeTile(context, subTile);
    }
  }

  Future handleDefer(BuildContext context, String notificationID) async {
    const deferText = '_defer';
    const deferAllText = 'deferall';
    if (notificationID.toLowerCase().contains(deferAllText)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ProcrastinateAll()));
    } else {
      String subEventComponentId = notificationID;
      int indexOfDeferText =
          subEventComponentId.toLowerCase().indexOf(deferText);
      if (indexOfDeferText > 0) {
        subEventComponentId =
            subEventComponentId.substring(0, indexOfDeferText);
      }
      SubCalendarEvent? subTile =
          getSubCalendartEventById(context, subEventComponentId);
      if (subTile != null && subTile.id != null && subTile.id!.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TileProcrastinateRoute(
                      tileId: subTile.id!,
                    )));
      }
    }
  }

  SubCalendarEvent? getSubCalendartEventById(
      BuildContext context, String subEventId) {
    final state = context.read<ScheduleBloc>().state;
    PriorScheduleState priorScheduleState =
        ScheduleState.generatePriorScheduleState(state);
    List<SubCalendarEvent> subEvents = priorScheduleState.subEvents
        .where((eachSubEvent) =>
            eachSubEvent.id != null && eachSubEvent.id!.contains(subEventId))
        .toList();
    if (subEvents.isNotEmpty) {
      return subEvents.first;
    }

    return null;
  }

  Future notification(BuildContext context,
      OSNotificationClickResult? notificationResult) async {
    const deferText = 'defer';
    const completeText = 'complete';
    if (notificationResult != null) {
      String? actionId = notificationResult.actionId;
      if (actionId != null) {
        if (actionId.toLowerCase().contains(deferText)) {
          handleDefer(context, actionId);
        } else if (actionId.toLowerCase().contains(completeText)) {
          handleComplete(context, actionId);
        }
      }
    }
  }

  Future notificationHandler(
      BuildContext context, OSNotificationClickEvent? event) async {
    if (event != null) {
      notification(context, event.result);
    }
  }

  Future subscribeToRemoteNotification(BuildContext context) async {
    if (_notificationData.isValid) {
      if (!Constants.isProduction) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      }

      String appId = dotenv.env[Constants.oneSignalAppIdKey] ?? "";
      OneSignal.initialize(appId);
      if (!Constants.isProduction) {
        OneSignal.User.pushSubscription.addObserver((state) {
          print(OneSignal.User.pushSubscription.optedIn);
          print(OneSignal.User.pushSubscription.id);
          print(OneSignal.User.pushSubscription.token);
          print(state.current.jsonRepresentation());
        });
      }

      if (_notificationData.tilerNotificationId != null) {
        await OneSignal.login(_notificationData.tilerNotificationId!)
            .then((value) {
          if (!Constants.isProduction) print("onesignal successful login");
        }).catchError((value) {
          if (!Constants.isProduction) {
            print("onesignal failed to login ");
          }
        });
        OneSignal.Notifications.addClickListener((event) {
          var notificationResult = event.result;
          notificationHandler(context, event);
        });
      }
    }
  }

  intializeChannelDetails(BuildContext context) {
    if (LocalNotificationService.channelDetails == null) {
      LocalNotificationService.channelDetails = {};
      for (var notificationType in NotificationIdTypes.values) {
        String? categoryName;
        String? categoryDescription;
        String? channelId;

        switch (notificationType) {
          case NotificationIdTypes.depatureTime:
            {
              categoryName = AppLocalizations.of(context)!
                  .depatureTimeNotificationCategory;
              channelId = 1.toString();
            }
            break;
          case NotificationIdTypes.nextTile:
            {
              categoryName =
                  AppLocalizations.of(context)!.nextTileNotificationCategory;
              channelId = 2.toString();
            }
            break;
          case NotificationIdTypes.userSetReminder:
            {
              categoryName = AppLocalizations.of(context)!
                  .userSetReminderNotificationCategory;
              channelId = 3.toString();
            }
            break;
          case NotificationIdTypes.none:
            {
              categoryName =
                  AppLocalizations.of(context)!.noneNotificationCategory;
              channelId = 0.toString();
            }
            break;
          default:
            {
              categoryName =
                  AppLocalizations.of(context)!.noneNotificationCategory;
              channelId = 0.toString();
            }
            break;
        }

        if (categoryName != null && channelId != null) {
          _NotificationDetailFormat notificationDetailFormat =
              _NotificationDetailFormat(
                  notificationIdType: notificationType,
                  notificationCategoryName: categoryName,
                  notificationChannelId: channelId,
                  notificationCategoryDescription: categoryDescription);
          LocalNotificationService.channelDetails![notificationType] =
              notificationDetailFormat;
        }
      }
    }
  }

  Future<NotificationDetails> _notificationDetails(
      _NotificationDetailFormat notificationDetailFormat) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            notificationDetailFormat.notificationChannelId,
            notificationDetailFormat.notificationCategoryName,
            channelDescription:
                notificationDetailFormat.notificationCategoryDescription,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true);

    DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    return NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required _NotificationDetailFormat detailFormat,
  }) async {
    final details = await _notificationDetails(detailFormat);
    await _localNotificationService.show(id, title, body, details);
  }

  Future<void> showScheduledNotification(
      {required int id,
      required String title,
      required Duration duration,
      required _NotificationDetailFormat detailFormat,
      String? body}) async {
    final details = await _notificationDetails(detailFormat);
    final currentTime = Utility.currentTime();

    final tzLocationString = await FlutterTimezone.getLocalTimezone();
    final tzLocation = getLocation(tzLocationString);
    final scheduledTime =
        TZDateTime.from(currentTime.add(duration), tzLocation);

    await _localNotificationService.zonedSchedule(
        id, title, body, scheduledTime, details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> nextTileNotification(
      {required SubCalendarEvent tile,
      required BuildContext context,
      String? title}) async {
    if (channelDetails != null) {
      Map<NotificationIdTypes, _NotificationDetailFormat>
          notificationDetailMap = channelDetails!;
      _NotificationDetailFormat notificationDetailFormat =
          notificationDetailMap[NotificationIdTypes.nextTile]!;
      final currentTime = Utility.msCurrentTime;

      final msStartTime = tile.start!.toInt();
      final tenMinFromStartMs =
          msStartTime - (Utility.oneMin.inMilliseconds * 10);

      String name = tile.name == null || tile.name!.isEmpty
          ? ((tile.isProcrastinate ?? false)
              ? AppLocalizations.of(context)!.procrastinateBlockOut
              : "")
          : tile.name!;
      String durationString = AppLocalizations.of(context)!.startsInTenMinutes;
      if (tenMinFromStartMs < currentTime) {
        String startTimeString = MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(tile.startTime));
        this.showNotification(
          id: NotificationIdTypes.nextTile.index,
          title: title ?? name,
          body: AppLocalizations.of(context)!.startingAtTime(startTimeString),
          detailFormat: notificationDetailFormat,
        );
        return;
      }

      Duration delayDuraion =
          Duration(milliseconds: (tenMinFromStartMs - currentTime).toInt());
      delayDuraion =
          delayDuraion.inMilliseconds <= Utility.oneMin.inMilliseconds
              ? Duration(seconds: 15)
              : delayDuraion;
      await this.showScheduledNotification(
          id: NotificationIdTypes.nextTile.index,
          title: title ?? tile.name ?? 'Cleared out time block',
          body: durationString,
          detailFormat: notificationDetailFormat,
          duration: delayDuraion);
    }
  }

  Future<void> concludingTileNotification(
      {required SubCalendarEvent tile,
      required BuildContext context,
      String? title}) async {
    if (channelDetails != null) {
      Map<NotificationIdTypes, _NotificationDetailFormat>
          notificationDetailMap = channelDetails!;
      _NotificationDetailFormat notificationDetailFormat =
          notificationDetailMap[NotificationIdTypes.nextTile]!;
      final currentTime = Utility.msCurrentTime;

      final tileEndTimeMs = tile.end!.toInt();
      final fiveMinFromEndMs =
          tileEndTimeMs - (Utility.oneMin.inMilliseconds * 5);

      String name = tile.name == null || tile.name!.isEmpty
          ? ((tile.isProcrastinate ?? false)
              ? AppLocalizations.of(context)!.procrastinateBlockOut
              : "")
          : tile.name!;
      String durationString = AppLocalizations.of(context)!.endsInTenMinutes;
      if (fiveMinFromEndMs < currentTime) {
        String startTimeString = MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(tile.startTime));
        this.showNotification(
          id: NotificationIdTypes.nextTile.index,
          title: title ?? name,
          body: AppLocalizations.of(context)!.endsAtTime(startTimeString),
          detailFormat: notificationDetailFormat,
        );
        return;
      }

      Duration delayDuraion =
          Duration(milliseconds: (fiveMinFromEndMs - currentTime).toInt());
      delayDuraion =
          delayDuraion.inMilliseconds <= Utility.oneMin.inMilliseconds
              ? Duration(seconds: 15)
              : delayDuraion;
      await this.showScheduledNotification(
          id: NotificationIdTypes.nextTile.index,
          title: title ?? tile.name ?? 'Cleared out time block',
          body: durationString,
          detailFormat: notificationDetailFormat,
          duration: delayDuraion);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotificationService.cancelAll();
  }
}
