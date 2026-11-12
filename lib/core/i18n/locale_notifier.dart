import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences? _prefs;
  static const String _prefKey = 'app_language';

  LocaleNotifier([this._prefs]) : super(const Locale('mn')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    if (_prefs != null) {
      final savedCode = _prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'mn')) {
        state = Locale(savedCode);
      }
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    if (_prefs != null) {
      await _prefs.setString(_prefKey, newLocale.languageCode);
    }
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'mn' ? const Locale('en') : const Locale('mn');
    await setLocale(next);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  // If sharedPreferencesProvider is available in di/providers.dart, it will be injected
  return LocaleNotifier();
});
