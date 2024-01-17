import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config_store.dart';
import '../i18n/strings.g.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleState extends _$LocaleState {
  @override
  Locale build() {
    final localeValue = ConfigStore().locale();
    return Locale(localeValue);
  }

  Locale getLocale() {
    return state;
  }

  void setLocale(Locale locale) {
    state = locale;
    ConfigStore().updateLocale(state.languageCode);
    LocaleSettings.setLocaleRaw(state.languageCode);
  }
}
