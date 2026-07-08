enum AppLanguage {
  en('en', 'English'),
  hi('hi', 'हिन्दी'),
  ta('ta', 'தமிழ்'),
  te('te', 'తెలుగు'),
  kn('kn', 'ಕನ್ನಡ');

  final String code;
  final String nativeName;

  const AppLanguage(this.code, this.nativeName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.en);
  }
}
