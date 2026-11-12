import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bridge/native_bridge.dart';
import '../database/database_helper.dart';
import '../database/recordings_repository.dart';
import '../theme/theme_mode_notifier.dart';
import '../../features/recordings/state/live_recording_notifier.dart';
import '../../features/recordings/state/recordings_notifier.dart';
import '../../features/recordings/state/recordings_state.dart';
import '../../features/settings/state/settings_notifier.dart';
import '../../features/settings/state/settings_state.dart';

import '../i18n/locale_notifier.dart';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

final appLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final bridge = ref.watch(nativeBridgeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsNotifier(bridge, prefs);
  },
);

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  final helper = DatabaseHelper();
  ref.onDispose(() => helper.close());
  return helper;
});

final recordingsRepositoryProvider = Provider<RecordingsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return RecordingsRepository(dbHelper);
});

final nativeBridgeProvider = Provider<NativeBridge>((ref) {
  return NativeBridge();
});

final recordingsProvider =
    StateNotifierProvider<RecordingsNotifier, RecordingsState>((ref) {
      final repository = ref.watch(recordingsRepositoryProvider);
      final bridge = ref.watch(nativeBridgeProvider);
      return RecordingsNotifier(repository, bridge);
    });

final liveRecordingProvider =
    StateNotifierProvider<LiveRecordingNotifier, LiveRecordingState>((ref) {
      final bridge = ref.watch(nativeBridgeProvider);
      return LiveRecordingNotifier(bridge);
    });
