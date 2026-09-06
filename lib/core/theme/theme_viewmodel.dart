import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static final ThemeViewModel _instance = ThemeViewModel._internal();
  factory ThemeViewModel() => _instance;
  ThemeViewModel._internal();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';

    await prefs.setString('theme_mode', themeString);
  }
}
