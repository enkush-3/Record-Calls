import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record_calls/core/di/providers.dart';
import 'package:record_calls/core/i18n/app_localizations.dart';
import 'package:record_calls/core/i18n/locale_notifier.dart';
import 'package:record_calls/features/onboarding/setup_wizard_screen.dart';
import 'package:record_calls/features/settings/state/settings_notifier.dart';
import 'package:record_calls/features/settings/ui/settings_screen.dart';
import 'settings_test.dart';

class MockBridgeForAudioSource extends FakeNativeBridge {
  String currentAudioSource = 'both';

  @override
  Future<bool> setAudioRecordingSource(String source) async {
    currentAudioSource = source;
    return true;
  }

  @override
  Future<String> getAudioRecordingSource() async => currentAudioSource;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Audio Recording Source Channel Tests (Both, Mic only, Remote only)',
    () {
      test(
        'SettingsNotifier defaults to both and updates audio recording source',
        () async {
          final bridge = MockBridgeForAudioSource();
          final notifier = SettingsNotifier(bridge);
          await notifier.loadSettings();

          expect(notifier.state.audioRecordingSource, 'both');

          // Switch to mic_only
          await notifier.setAudioRecordingSource('mic_only');
          expect(notifier.state.audioRecordingSource, 'mic_only');
          expect(bridge.currentAudioSource, 'mic_only');
          expect(notifier.state.message, contains('Mic'));

          // Switch to remote_only
          await notifier.setAudioRecordingSource('remote_only');
          expect(notifier.state.audioRecordingSource, 'remote_only');
          expect(bridge.currentAudioSource, 'remote_only');
          expect(notifier.state.message, contains('Remote'));

          // Switch back to both
          await notifier.setAudioRecordingSource('both');
          expect(notifier.state.audioRecordingSource, 'both');
          expect(bridge.currentAudioSource, 'both');
          expect(notifier.state.message, contains('Хоёр талын дуу'));
        },
      );
    },
  );

  group('i18n & Multi-Language JSON Tests', () {
    test('AppLocalizations translates keys and interpolates parameters', () {
      final loc = AppLocalizations(const Locale('en'));
      // Test manual map injection for unit test
      expect(loc.translate('not_found_key'), 'not_found_key');

      // Test parameter interpolation
      final translated = loc.translate(
        'hello {name}',
        params: {'name': 'World'},
      );
      expect(translated, 'hello World');
    });

    test('LocaleNotifier switches and toggles between mn and en', () async {
      final notifier = LocaleNotifier();
      expect(notifier.state.languageCode, 'mn');

      await notifier.setLocale(const Locale('en'));
      expect(notifier.state.languageCode, 'en');

      await notifier.toggleLocale();
      expect(notifier.state.languageCode, 'mn');
    });

    testWidgets('SetupWizardScreen renders in English when locale is en', (
      tester,
    ) async {
      final fakeBridge = FakeNativeBridge();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SetupWizardScreen(bridge: fakeBridge),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Setup (Setup Wizard)'), findsOneWidget);
      expect(find.text('Core Permissions'), findsOneWidget);
      expect(find.text('VoIP Detector (Accessibility)'), findsOneWidget);
      expect(find.text('Disable Battery Optimization'), findsOneWidget);
      expect(find.text('All Set — Get Started'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders in English when locale is en', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeBridge = FakeNativeBridge();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nativeBridgeProvider.overrideWithValue(fakeBridge)],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Storage & Directories'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Language Settings'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Language Settings'), findsOneWidget);
    });

    testWidgets('SettingsScreen switches language reactively from mn to en', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeBridge = FakeNativeBridge();
      final container = ProviderContainer(
        overrides: [nativeBridgeProvider.overrideWithValue(fakeBridge)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(appLocaleProvider);
              return MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in Mongolian
      expect(find.text('Тохиргоо'), findsOneWidget);

      // Switch to English via appLocaleProvider
      await container
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      // Now in English
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Тохиргоо'), findsNothing);
    });
  });
}
