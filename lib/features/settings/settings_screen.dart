import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/locale_provider.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _testNotification(BuildContext context, AppLocalizations l10n) async {
    final granted = await NotificationService.instance.requestPermissions();
    if (granted) {
      await NotificationService.instance.sendImmediateTestNotification(
        l10n.notifTitle,
        l10n.testNotifSuccess,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.testNotifSuccess)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied.')), // Recommend adding to ARB in final pass
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.dataPrivacy, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.dataPrivacyDesc),
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF00E5FF)),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            title: Text(l10n.language),
            leading: const Icon(Icons.language),
            trailing: DropdownButton<String?>(
              value: currentLocale?.languageCode,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.systemDefault)),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'es', child: Text('Español')),
                const DropdownMenuItem(value: 'fr', child: Text('Français')),
                const DropdownMenuItem(value: 'pt', child: Text('Português')),
                const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              ],
              onChanged: (String? newLocale) {
                ref.read(localeProvider.notifier).setLocale(newLocale);
              },
            ),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            title: Text(l10n.testNotifications),
            subtitle: Text(l10n.testNotifDesc),
            leading: const Icon(Icons.notifications_active),
            onTap: () => _testNotification(context, l10n),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            title: Text(l10n.appVersion),
            subtitle: Text(_appVersion.isEmpty ? '...' : _appVersion),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
