class Language {
  final String name;
  final String localeName;

  const Language(this.name, this.localeName);
}

const Map<String, Language> supportLanguages = {
  "zh": Language("中文", "zh"),
  "en": Language("English", "en"),
};
