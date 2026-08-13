import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/subscription_form_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  String _getCountdownText(DateTime nextBillingDate, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    
    final difference = target.difference(today).inDays;

    if (difference < 0) return l10n.pastDue;
    if (difference == 0) return l10n.renewsToday;
    if (difference == 1) return l10n.renewsTomorrow;
    return l10n.renewsIn(difference);
  }

  bool _isUrgent(DateTime nextBillingDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    return target.difference(today).inDays <= 3;
  }

  String _formatCurrency(double amount, String currencyCode) {
    try {
      final formatter = NumberFormat.simpleCurrency(name: currencyCode);
      return formatter.format(amount);
    } catch (e) {
      // Fallback if the currency code is unsupported by the local environment
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context)!;

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
      body: state.isLoading && state.subscriptions.isEmpty
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : state.error != null
            ? Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
            : state.subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noSubscriptions, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionFormScreen())),
                          child: Text(l10n.addFirstSubscription),
                        )
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A24), Color(0xFF0D0D12)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.totalMonthlySpend, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ...state.monthlyTotalsByCurrency.entries.map((e) => 
                              Text(_formatCurrency(e.value, e.key), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)))
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.totalYearlySpend, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ...state.yearlyTotalsByCurrency.entries.map((e) => 
                              Text(_formatCurrency(e.value, e.key), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.subscriptions.length,
                          itemBuilder: (context, index) {
                            final sub = state.subscriptions[index];
                            final countdownText = _getCountdownText(sub.nextBillingDate, l10n);
                            final urgent = _isUrgent(sub.nextBillingDate);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionFormScreen(existingSubscription: sub))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Text(countdownText, style: TextStyle(color: urgent ? const Color(0xFFFF3B30) : Colors.grey)),
                                trailing: Text(_formatCurrency(sub.cost, sub.currency), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
      floatingActionButton: state.subscriptions.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionFormScreen())),
            )
          : null,
    );
  }
}
