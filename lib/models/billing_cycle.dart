enum BillingCycle {
  monthly,
  yearly
}

extension BillingCycleExtension on BillingCycle {
  String toDatabaseString() {
    return name;
  }

  static BillingCycle fromDatabaseString(String value) {
    return BillingCycle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BillingCycle.monthly,
    );
  }
}
