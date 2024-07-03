import 'package:flutter/material.dart';

class Language {
  final String name;
  final String localeName;

  const Language(this.name, this.localeName);
}

const Map<String, Language> supportLanguages = {
  "zh": Language("中文", "zh"),
  "en": Language("English", "en"),
};

enum DeviceType {
  mobile,
  desktop,
  web,
  headless,
  server,
}

extension DeviceTypeExt on DeviceType {
  IconData get icon {
    return switch (this) {
      DeviceType.mobile => Icons.smartphone,
      DeviceType.desktop => Icons.computer,
      DeviceType.web => Icons.language,
      DeviceType.headless => Icons.terminal,
      DeviceType.server => Icons.dns,
    };
  }
}
