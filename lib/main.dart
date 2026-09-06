import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pu_connection/l10n/app_localizations.dart';
import 'package:pu_connection/core/localization/locale_viewmodel.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_viewmodel.dart';
import 'core/localization/locale_viewmodel.dart';
import 'features/onboarding/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeViewModel().loadSavedTheme();
  await LocaleViewModel().loadSavedLocale();

  runApp(const PUConnectionApp());
}

class PUConnectionApp extends StatelessWidget {
  const PUConnectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeViewModel(), LocaleViewModel()]),
      builder: (context, child) {
        return MaterialApp(
          title: 'PU Connection',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeViewModel().themeMode,
          locale: LocaleViewModel().locale,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: const SplashPage(),
        );
      },
    );
  }
}
