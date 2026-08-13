import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subguard/l10n/app_localizations.dart';
import '../models/subscription.dart';
import '../models/billing_cycle.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';
import '../services/recurring_billing_service.dart';

class SubscriptionState {
  final List<Subscription> subscriptions;
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Map<String, double> get monthlyTotalsByCurrency {
    final totals = <String, double>{};
    for (final sub in subscriptions) {
      final amount = sub.billingCycle == BillingCycle.monthly ? sub.cost : (sub.cost / 12);
      totals[sub.currency] = (totals[sub.currency] ?? 0.0) + amount;
    }
    return totals;
  }

  Map<String, double> get yearlyTotalsByCurrency {
    final totals = <String, double>{};
    for (final sub in subscriptions) {
      final amount = sub.billingCycle == BillingCycle.yearly ? sub.cost : (sub.cost * 12);
      totals[sub.currency] = (totals[sub.currency] ?? 0.0) + amount;
    }
    return totals;
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState()) {
    loadAndAdvanceSubscriptions();
  }

  Future<AppLocalizations> _getHeadlessL10n() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_locale') ?? 'en';
    return await AppLocalizations.delegate.load(Locale(langCode));
  }

  Future<void> loadAndAdvanceSubscriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subs = await DatabaseHelper.instance.getAllSubscriptions();
      final now = DateTime.now();
      
      final l10n = await _getHeadlessL10n();

      for (int i = 0; i < subs.length; i++) {
        final sub = subs[i];
        
        if (sub.nextBillingDate.isBefore(now) && !sub.nextBillingDate.isAtSameMomentAs(now)) {
          final nextDate = RecurringBillingService.calculateNextBillingDate(sub.nextBillingDate, sub.billingCycle, nowOverride: now);
          
          if (nextDate != sub.nextBillingDate) {
            final updatedSub = sub.copyWith(nextBillingDate: nextDate);
            await DatabaseHelper.instance.updateSubscription(updatedSub);
            
            await NotificationService.instance.scheduleSubscriptionNotifications(
              updatedSub, 
              l10n.notifTitle, 
              l10n.notifBody48(updatedSub.name), 
              l10n.notifBody24(updatedSub.name)
            );
            
            subs[i] = updatedSub;
          }
        }
      }

      state = state.copyWith(subscriptions: subs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveSubscription(Subscription sub, String title, String body48, String body24, {bool isUpdate = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (isUpdate) {
        await DatabaseHelper.instance.updateSubscription(sub);
      } else {
        await DatabaseHelper.instance.insertSubscription(sub);
      }
      await NotificationService.instance.scheduleSubscriptionNotifications(sub, title, body48, body24);
      await loadAndAdvanceSubscriptions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e; 
    }
  }

  Future<void> deleteSubscription(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await DatabaseHelper.instance.deleteSubscription(id);
      await NotificationService.instance.cancelNotifications(id);
      await loadAndAdvanceSubscriptions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e;
    }
  }
}
