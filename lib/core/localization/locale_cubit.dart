import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  final SharedPreferences sharedPreferences;

  LocaleCubit({required this.sharedPreferences}) : super(const Locale('vi')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final savedLanguageCode = sharedPreferences.getString('language_code');
    if (savedLanguageCode != null) {
      emit(Locale(savedLanguageCode));
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    emit(newLocale);
    await sharedPreferences.setString('language_code', newLocale.languageCode);
  }
}
