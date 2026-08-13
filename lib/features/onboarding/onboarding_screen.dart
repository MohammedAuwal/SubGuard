import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subguard/l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _permissionsRequested = false;

  Future<void> _requestPermissions() async {
    await NotificationService.instance.requestPermissions();
    setState(() {
      _permissionsRequested = true;
    });
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.shield_outlined, size: 120, color: Color(0xFF00E5FF)),
              const SizedBox(height: 40),
              Text(l10n.onboardingTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(l10n.onboardingDesc, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5), textAlign: TextAlign.center),
              const Spacer(),
              if (!_permissionsRequested)
                OutlinedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.notifications_active, color: Color(0xFF00E5FF)),
                  label: Text(l10n.enableNotifications, style: const TextStyle(color: Color(0xFF00E5FF))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                  ),
                ),
              if (!_permissionsRequested) const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _completeOnboarding(context),
                child: Text(l10n.getStarted),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
