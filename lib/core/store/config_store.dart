import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigStore {
  static ConfigStore? _instance;
  static SharedPreferences? _prefs;

  factory ConfigStore() {
    if (_instance == null) {
      throw Exception('AppSharedPrefs is not initialized. '
          'Please call AppSharedPrefs.ensureInitialized before.');
    }
    return _instance!;
  }

  const ConfigStore._();

  static ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    _instance ??= const ConfigStore._();
  }

  static const _themeKey = 'theme';
  static const _localeKey = 'locale';

  ThemeMode themeMode() {
    final themeValue = _prefs!.getInt(_themeKey);
    if (themeValue == null) return ThemeMode.system;

    return ThemeMode.values[themeValue];
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    await _prefs!.setInt(_themeKey, theme.index);
  }

  String locale() {
    final localeValue = _prefs!.getString(_localeKey) ?? Platform.localeName;
    return localeValue;
  }

  Future<void> updateLocale(String locale) async {
    await _prefs!.setString(_localeKey, locale);
  }
}
