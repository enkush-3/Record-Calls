import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record_calls/core/theme/theme_mode_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier Tests', () {
    test('defaults to ThemeMode.system when no preferences stored', () {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier(null);
      expect(notifier.state, ThemeMode.system);
    });

    test('loads saved theme mode from preferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, ThemeMode.dark);
    });

    test('updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeModeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');
    });
  });
}
