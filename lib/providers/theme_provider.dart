import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config_store.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeState extends _$ThemeState {
  @override
  ThemeMode build() {
    return ConfigStore().themeMode();
  }

  ThemeMode getTheme() {
    return state;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    ConfigStore().updateThemeMode(state);
  }
}
