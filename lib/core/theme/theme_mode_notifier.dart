import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'app_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;
    final value = _prefs.getString(_kThemeModeKey);
    if (value == 'light') {
      state = ThemeMode.light;
    } else if (value == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    if (_prefs != null) {
      String strVal;
      switch (mode) {
        case ThemeMode.light:
          strVal = 'light';
          break;
        case ThemeMode.dark:
          strVal = 'dark';
          break;
        case ThemeMode.system:
          strVal = 'system';
          break;
      }
      await _prefs.setString(_kThemeModeKey, strVal);
    }
  }
}
