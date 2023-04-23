import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      String? body,
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
      delayDuraion = delayDuraion.inMilliseconds == Duration.zero.inMilliseconds
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
