import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fallback_en.dart';
import 'fallback_mn.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale) {
    _localizedStrings = Map<String, String>.from(
      locale.languageCode == 'en' ? fallbackEnStrings : fallbackMnStrings,
    );
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('mn'), Locale('en')];

  Future<bool> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/i18n/${locale.languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      jsonMap.forEach((key, value) {
        _localizedStrings[key] = value.toString();
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    final Map<String, String> langFallback = locale.languageCode == 'en'
        ? fallbackEnStrings
        : fallbackMnStrings;
    String value =
        _localizedStrings[key] ??
        langFallback[key] ??
        fallbackMnStrings[key] ??
        key;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        value = value.replaceAll('{$paramKey}', paramVal);
      });
    }
    return value;
  }

  static String translateKey(
    String key, {
    Map<String, String>? params,
    String languageCode = 'mn',
  }) {
    final Map<String, String> langFallback = languageCode == 'en'
        ? fallbackEnStrings
        : fallbackMnStrings;
    String value = langFallback[key] ?? fallbackMnStrings[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        value = value.replaceAll('{$paramKey}', paramVal);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['mn', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final localizations = AppLocalizations(locale);
    localizations.load();
    return SynchronousFuture<AppLocalizations>(localizations);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? params}) {
    final loc = AppLocalizations.of(this);
    if (loc != null) {
      return loc.translate(key, params: params);
    }
    return AppLocalizations.translateKey(key, params: params);
  }
}
