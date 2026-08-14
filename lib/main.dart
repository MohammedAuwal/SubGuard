import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:subguard/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool seenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  } catch (_) {
    // If prefs fail to load for any reason, default to onboarding rather than crashing.
  }

  runApp(ProviderScope(child: SubGuardApp(seenOnboarding: seenOnboarding)));

  // Initialize notifications AFTER the UI is already showing, and never let
  // a failure here bring down the app. This runs on the next event loop
  // turn so first frame is not blocked by any native plugin work.
  Future.delayed(Duration.zero, () async {
    try {
      await NotificationService.instance.initialize();
    } catch (e, st) {
      debugPrint('Notification init failed (non-fatal): $e\n$st');
    }
  });
}

class SubGuardApp extends ConsumerWidget {
  final bool seenOnboarding;
  const SubGuardApp({Key? key, required this.seenOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'SubGuard',
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: [ 
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('pt', ''),
        Locale('de', ''),
      ],
      home: seenOnboarding ? const DashboardScreen() : const OnboardingScreen(),
    );
  }
}
