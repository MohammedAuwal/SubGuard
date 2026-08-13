import 'package:flutter_test/flutter_test.dart';
import 'package:subguard/services/recurring_billing_service.dart';
import 'package:subguard/models/billing_cycle.dart';

void main() {
  group('Recurring Billing Service Calendar Math', () {
    
    test('January 31 -> February 28 (Non-Leap Year)', () {
      final current = DateTime(2023, 1, 31, 12, 0);
      final now = DateTime(2023, 2, 1, 12, 0); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2023, 2, 28, 12, 0));
    });

    test('January 31 -> February 29 (Leap Year)', () {
      final current = DateTime(2024, 1, 31, 12, 0);
      final now = DateTime(2024, 2, 1, 12, 0); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2024, 2, 29, 12, 0));
    });

    test('February 29 -> February 28 on non-leap year (Yearly Roll)', () {
      final current = DateTime(2024, 2, 29, 12, 0);
      final now = DateTime(2025, 2, 1, 12, 0); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.yearly, nowOverride: now);
      expect(next, DateTime(2025, 2, 28, 12, 0));
    });

    test('December -> January with year rollover', () {
      final current = DateTime(2025, 12, 15, 12, 0);
      final now = DateTime(2026, 1, 1, 12, 0); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2026, 1, 15, 12, 0));
    });

    test('Monthly subscriptions several months overdue', () {
      final current = DateTime(2026, 1, 15, 12, 0);
      final now = DateTime(2026, 8, 10, 12, 0); // 7 months overdue
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2026, 8, 15, 12, 0));
    });

    test('Billing date exactly equal to current time', () {
      final current = DateTime(2026, 8, 13, 11, 44);
      final now = DateTime(2026, 8, 13, 11, 44); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2026, 9, 13, 11, 44));
    });

    test('Billing date in the future (Should not change)', () {
      final current = DateTime(2026, 10, 15, 12, 0);
      final now = DateTime(2026, 8, 13, 11, 44); 
      final next = RecurringBillingService.calculateNextBillingDate(current, BillingCycle.monthly, nowOverride: now);
      expect(next, DateTime(2026, 10, 15, 12, 0));
    });
  });
}
