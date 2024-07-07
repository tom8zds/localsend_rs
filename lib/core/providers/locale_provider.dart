import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

import '../../common/constants.dart';
import '../../common/utils.dart';
import '../../i18n/strings.g.dart';
import '../store/config_store.dart';

part 'locale_provider.g.dart';
part 'locale_provider.freezed.dart';

@freezed
class LocaleConfig with _$LocaleConfig {
  factory LocaleConfig({
    required LocaleMode mode,
    required Locale customLocale,
  }) = _LocaleConfig;
}

extension LocaleConfigExt on LocaleConfig {
  Locale getLocale() {
    switch (mode) {
      case LocaleMode.system:
        return stringToLocale(Platform.localeName);
      case LocaleMode.custom:
        return customLocale;
    }
  }
}

@riverpod
class LocaleState extends _$LocaleState {
  @override
  LocaleConfig build() {
    String localeValue = ConfigStore().locale();
    return LocaleConfig(
        mode: LocaleMode.system, customLocale: stringToLocale(localeValue));
  }

  void onModeChange() {
    if (state.mode == LocaleMode.system) {
      LocaleSettings.useDeviceLocale();
    } else {
      LocaleSettings.setLocaleRaw(state.customLocale.languageCode);
    }
    if (Platform.isWindows) {
      windowManager.setTitle(t.appTitle.parta + t.appTitle.partb);
    }
  }

  void setLocale(Locale locale) {
    ConfigStore().updateLocale(state.toString());
    state = state.copyWith(mode: LocaleMode.custom, customLocale: locale);
    onModeChange();
  }

  LocaleMode getMode() {
    return state.mode;
  }

  void changeMode(LocaleMode mode) {
    state = state.copyWith(mode: mode);
    onModeChange();
  }
}
