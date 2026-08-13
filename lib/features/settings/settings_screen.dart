import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')), // In production, localize this key
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('Data Privacy', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            subtitle: Text('All data is stored locally on this device. SubGuard does not use cloud servers.'),
            leading: Icon(Icons.privacy_tip, color: Color(0xFF00E5FF)),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('System Default'),
            leading: const Icon(Icons.language),
            onTap: () {
              // Future implementation: Add manual language override
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language is currently managed by system settings.')),
              );
            },
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Production)'),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
