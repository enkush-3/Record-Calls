import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/providers.dart';
import 'core/i18n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/privacy_consent_dialog.dart';
import 'features/onboarding/setup_wizard_screen.dart';
import 'features/recordings/ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RecordCallApp(),
    ),
  );
}

class RecordCallApp extends ConsumerWidget {
  const RecordCallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      title: 'Record Call',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends ConsumerStatefulWidget {
  const AppEntryGate({super.key});

  @override
  ConsumerState<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends ConsumerState<AppEntryGate> {
  bool _isLoading = true;
  bool _needsSetup = true;

  @override
  void initState() {
    super.initState();
    _evaluateInitialRoute();
  }

  Future<void> _evaluateInitialRoute() async {
    // 1. Check Privacy Consent
    final hasAccepted = await PrivacyConsentDialog.hasAccepted();

    // 2. Check Permissions via NativeBridge Provider
    final bridge = ref.read(nativeBridgeProvider);
    final status = await bridge.getPermissionsStatus();

    if (mounted) {
      setState(() {
        _needsSetup = !hasAccepted || !status.isAllGranted;
        _isLoading = false;
      });

      if (!hasAccepted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PrivacyConsentDialog.showConsentIfNeeded(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bridge = ref.read(nativeBridgeProvider);
    if (_needsSetup) {
      return SetupWizardScreen(bridge: bridge);
    }

    return const HomeScreen();
  }
}
