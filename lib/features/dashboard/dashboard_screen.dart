import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../add_subscription/add_subscription_screen.dart';
import '../subscription_details/subscription_details_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context)!;
    
    double totalMonthly = subscriptions.fold(0, (sum, item) {
      return sum + (item.billingCycle == 'Monthly' ? item.cost : (item.cost / 12));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
      ),
      body: subscriptions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noSubscriptions, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())),
                    child: Text(l10n.addFirstSubscription),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A1A24), Color(0xFF0D0D12)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(l10n.totalMonthlySpend, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('\$${totalMonthly.toStringAsFixed(2)}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      final daysLeft = sub.nextBillingDate.difference(DateTime.now()).inDays;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailsScreen(subscription: sub))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(l10n.renewsIn(daysLeft > 0 ? daysLeft : 0), style: TextStyle(color: daysLeft <= 3 ? const Color(0xFFFF3B30) : Colors.grey)),
                          trailing: Text('${sub.currency} ${sub.cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
      floatingActionButton: subscriptions.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())),
            )
          : null,
    );
  }
}
