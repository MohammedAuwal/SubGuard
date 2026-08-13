import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubscriptionDetailsScreen extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({Key? key, required this.subscription}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFFF3B30)),
            onPressed: () {
              ref.read(subscriptionProvider.notifier).deleteSubscription(subscription.id);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 8),
            Text('${subscription.currency} ${subscription.cost.toStringAsFixed(2)}', 
                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
            const SizedBox(height: 24),
            Text('Billing Cycle', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 8),
            Text(subscription.billingCycle, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            Text('Next Renewal', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 8),
            Text(subscription.nextBillingDate.toLocal().toString().split(' ')[0], 
                 style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
