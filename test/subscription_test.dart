import 'package:flutter_test/flutter_test.dart';
import 'package:subguard/models/subscription.dart';
import 'package:subguard/models/billing_cycle.dart';

void main() {
  group('Subscription Model Tests', () {
    test('Subscription creates a UUID if not provided', () {
      final sub = Subscription(
        name: 'Netflix',
        cost: 15.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly, // Fixed string to Enum
        nextBillingDate: DateTime(2026, 9, 1),
      );
      expect(sub.id, isNotNull);
      expect(sub.id.isNotEmpty, true);
    });

    test('Subscription serialization toMap() works correctly', () {
      final date = DateTime(2026, 9, 1);
      final sub = Subscription(
        id: 'test-123',
        name: 'Spotify',
        cost: 9.99,
        currency: 'EUR',
        billingCycle: BillingCycle.monthly, // Fixed string to Enum
        nextBillingDate: date,
      );

      final map = sub.toMap();
      expect(map['id'], 'test-123');
      expect(map['name'], 'Spotify');
      expect(map['cost'], 9.99);
      expect(map['currency'], 'EUR');
      expect(map['billingCycle'], 'monthly'); // Enum converts to 'monthly' via .name
      expect(map['nextBillingDate'], date.toIso8601String());
    });
  });
}
