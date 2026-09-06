import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleViewModel extends ChangeNotifier {
  static final LocaleViewModel _instance = LocaleViewModel._internal();
  factory LocaleViewModel() => _instance;
  LocaleViewModel._internal();

  Locale _locale = const Locale('vi');
  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code');
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }
}
