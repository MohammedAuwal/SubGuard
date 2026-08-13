import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, List<Subscription>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionNotifier() : super([]) {
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final subs = await DatabaseHelper.instance.getAllSubscriptions();
    state = subs;
  }

  Future<void> addSubscription(Subscription sub, String localized48Body, String localized24Body) async {
    await DatabaseHelper.instance.insertSubscription(sub);
    await NotificationService.instance.scheduleSubscriptionNotifications(sub, localized48Body, localized24Body);
    await _loadSubscriptions();
  }

  Future<void> deleteSubscription(String id) async {
    await DatabaseHelper.instance.deleteSubscription(id);
    await NotificationService.instance.cancelNotifications(id);
    await _loadSubscriptions();
  }
}
