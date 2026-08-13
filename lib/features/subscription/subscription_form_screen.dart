import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subguard/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../models/subscription.dart';
import '../../models/billing_cycle.dart';
import '../../providers/subscription_provider.dart';
import '../../services/ocr_service.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  final Subscription? existingSubscription;

  const SubscriptionFormScreen({Key? key, this.existingSubscription}) : super(key: key);

  @override
  ConsumerState<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late String _currency;
  late BillingCycle _billingCycle;
  late DateTime _nextBillingDate;
  bool _isSaving = false;

  final List<String> _supportedCurrencies = ['USD', 'EUR', 'GBP', 'NGN', 'CAD', 'AUD', 'BRL', 'MXN', 'CHF', 'JPY'];

  @override
  void initState() {
    super.initState();
    final sub = widget.existingSubscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _costController = TextEditingController(text: sub?.cost.toStringAsFixed(2) ?? '');
    _currency = sub?.currency ?? 'USD';
    _billingCycle = sub?.billingCycle ?? BillingCycle.monthly;
    _nextBillingDate = sub?.nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final result = await OcrService.instance.scanReceipt();
    if (result != null && mounted) {
      setState(() {
        if (result['name'].toString().isNotEmpty) _nameController.text = result['name'];
        if (result['price'] > 0) _costController.text = result['price'].toStringAsFixed(2);
        if (_supportedCurrencies.contains(result['currency'])) _currency = result['currency'];
        _billingCycle = result['billingCycle'] == 'Yearly' ? BillingCycle.yearly : BillingCycle.monthly;
        if (result['date'] != null) _nextBillingDate = result['date'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt parsed. Please review and confirm.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _nextBillingDate) {
      setState(() {
        _nextBillingDate = DateTime(picked.year, picked.month, picked.day, 12, 0); 
      });
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirm == true && mounted) {
      await ref.read(subscriptionProvider.notifier).deleteSubscription(widget.existingSubscription!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    
    final sub = Subscription(
      id: widget.existingSubscription?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      cost: double.parse(_costController.text.trim()),
      currency: _currency,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBillingDate,
    );

    try {
      await ref.read(subscriptionProvider.notifier).saveSubscription(
        sub, 
        l10n.notifTitle, 
        l10n.notifBody48(sub.name), 
        l10n.notifBody24(sub.name), 
        isUpdate: widget.existingSubscription != null
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSubscription == null ? l10n.addSubscription : l10n.editSubscription),
        actions: [
          if (widget.existingSubscription != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            )
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.existingSubscription == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.scanReceipt),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                          foregroundColor: const Color(0xFF00E5FF)
                        ),
                        onPressed: _scanReceipt,
                      ),
                    if (widget.existingSubscription == null) const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.serviceName),
                      validator: (value) => value == null || value.trim().isEmpty ? l10n.pleaseEnterName : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.cost),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return l10n.required;
                              if (double.tryParse(value) == null || double.parse(value) <= 0) return l10n.invalidAmount;
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency, 
                            decoration: InputDecoration(labelText: l10n.currency),
                            items: _supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _currency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BillingCycle>(
                      initialValue: _billingCycle, 
                      decoration: InputDecoration(labelText: l10n.billingCycle),
                      items: [
                        DropdownMenuItem(value: BillingCycle.monthly, child: Text(l10n.monthly)),
                        DropdownMenuItem(value: BillingCycle.yearly, child: Text(l10n.yearly)),
                      ],
                      onChanged: (val) {
                         if (val != null) setState(() => _billingCycle = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                      tileColor: const Color(0xFF1A1A24),
                      title: Text(l10n.nextBillingDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      subtitle: Text("${_nextBillingDate.toLocal()}".split(' ')[0], style: const TextStyle(fontSize: 16, color: Colors.white)),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF00E5FF)),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(l10n.save),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
