import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_launcher');
      
      // Darwin settings for iOS implementation readiness
      const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      
      await _notificationsPlugin.initialize(settings);
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool? androidResult = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Only attempt exact alarms if notifications were granted (Android 13+)
      if (androidResult == true) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
      }

      bool? iosResult = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return (androidResult ?? false) || (iosResult ?? false);
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  // Generates a stable deterministic integer ID from a UUID to survive app restarts
  int _getStableId(String uuid, int offset) {
    final clean = uuid.replaceAll('-', '');
    if (clean.length >= 8) {
      return int.parse(clean.substring(0, 8), radix: 16) + offset;
    }
    return uuid.hashCode + offset;
  }

  NotificationDetails _getPlatformChannelDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'subguard_reminders_v1',
        'Subscription Reminders',
        channelDescription: 'High-priority notifications for upcoming subscription renewals',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleSubscriptionNotifications(Subscription sub, String title, String body48, String body24) async {
    try {
      await cancelNotifications(sub.id);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(sub.nextBillingDate, tz.local);

      final tz.TZDateTime time48 = scheduledDate.subtract(const Duration(hours: 48));
      final tz.TZDateTime time24 = scheduledDate.subtract(const Duration(hours: 24));

      final platformDetails = _getPlatformChannelDetails();

      if (time48.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          _getStableId(sub.id, 48),
          title,
          body48,
          time48,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      if (time24.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          _getStableId(sub.id, 24),
          title,
          body24,
          time24,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notifications for ${sub.name}: $e');
    }
  }

  Future<void> sendImmediateTestNotification(String title, String body) async {
    try {
      await _notificationsPlugin.show(
        99999, // Test ID
        title,
        body,
        _getPlatformChannelDetails(),
      );
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
    }
  }

  Future<void> cancelNotifications(String subscriptionId) async {
    await _notificationsPlugin.cancel(_getStableId(subscriptionId, 48));
    await _notificationsPlugin.cancel(_getStableId(subscriptionId, 24));
  }
}
