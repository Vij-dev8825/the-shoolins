import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'app_language';

  AppLanguage? _language;
  bool _isLoading = true;

  AppLanguage? get language => _language;
  bool get isLoading => _isLoading;
  bool get hasChosenLanguage => _language != null;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _language = AppLanguage.fromCode(code);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}
