import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import '../../services/ocr_service.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  String _currency = 'USD';
  String _billingCycle = 'Monthly';
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));

  Future<void> _scan() async {
    final result = await OcrService.instance.scanReceipt();
    if (result != null) {
      setState(() {
        _nameController.text = result['name'] ?? '';
        _costController.text = result['price'] ?? '';
      });
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final sub = Subscription(
      name: _nameController.text,
      cost: double.tryParse(_costController.text) ?? 0.0,
      currency: _currency,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBillingDate,
    );

    // Provide localized notification bodies
    String body48 = "${sub.name} renews in 48 hours."; 
    String body24 = "${sub.name} renews in 24 hours."; 
    
    ref.read(subscriptionProvider.notifier).addSubscription(sub, body48, body24);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addSubscription)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.scanReceipt),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                foregroundColor: const Color(0xFF00E5FF)
              ),
              onPressed: _scan,
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.serviceName)),
            const SizedBox(height: 16),
            TextField(controller: _costController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.cost)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            )
          ],
        ),
      ),
    );
  }
}
