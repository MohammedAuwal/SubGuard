import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String name;
  final double cost;
  final String currency;
  final String billingCycle;
  final DateTime nextBillingDate;

  Subscription({
    String? id,
    required this.name,
    required this.cost,
    required this.currency,
    required this.billingCycle,
    required this.nextBillingDate,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'currency': currency,
      'billingCycle': billingCycle,
      'nextBillingDate': nextBillingDate.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      cost: map['cost'],
      currency: map['currency'],
      billingCycle: map['billingCycle'],
      nextBillingDate: DateTime.parse(map['nextBillingDate']),
    );
  }

  Subscription copyWith({
    String? name,
    double? cost,
    String? currency,
    String? billingCycle,
    DateTime? nextBillingDate,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    );
  }
}
