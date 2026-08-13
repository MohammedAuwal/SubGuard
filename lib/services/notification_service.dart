import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/subscription.dart';
// Note: Timezone initialization omitted for brevity but required in production for scheduled notifications.
// Run flutter pub add timezone

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> scheduleSubscriptionNotifications(Subscription sub, String body48, String body24) async {
    // Ensure permissions are handled appropriately
    // Dummy ID logic based on hashcode
    int id48 = '${sub.id}_48'.hashCode;
    int id24 = '${sub.id}_24'.hashCode;
    
    // In production, use tz.TZDateTime.from to schedule accurately
    // This is a placeholder for the scheduling logic utilizing flutter_local_notifications timezone capabilities
    
    // Schedule 48 hours before
    // await _notificationsPlugin.zonedSchedule(...)
    
    // Schedule 24 hours before
    // await _notificationsPlugin.zonedSchedule(...)
  }

  Future<void> cancelNotifications(String subscriptionId) async {
    await _notificationsPlugin.cancel('${subscriptionId}_48'.hashCode);
    await _notificationsPlugin.cancel('${subscriptionId}_24'.hashCode);
  }
}
