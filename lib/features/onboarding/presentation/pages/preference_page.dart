import 'package:flutter/material.dart';
import 'package:pu_connection/l10n/app_localizations.dart';
import '../../../../core/theme/theme_viewmodel.dart';
import '../../../../core/localization/locale_viewmodel.dart';
import '../../../auth/presentation/pages/login_page.dart';

class PreferencePage extends StatelessWidget {
  const PreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final themeVM = ThemeViewModel();
    final localeVM = LocaleViewModel();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                t.setup_title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                t.language,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: localeVM,
                builder: (context, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.vietnamese,
                          icon: Icons.language,
                          isSelected: localeVM.locale.languageCode == 'vi',
                          onTap: () => localeVM.setLocale(const Locale('vi')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.english,
                          icon: Icons.translate,
                          isSelected: localeVM.locale.languageCode == 'en',
                          onTap: () => localeVM.setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                t.theme,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: themeVM,
                builder: (context, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.light,
                          icon: Icons.wb_sunny_rounded,
                          isSelected: themeVM.themeMode == ThemeMode.light,
                          onTap: () => themeVM.setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.dark,
                          icon: Icons.nightlight_round,
                          isSelected: themeVM.themeMode == ThemeMode.dark,
                          onTap: () => themeVM.setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.system,
                          icon: Icons.settings_suggest_rounded,
                          isSelected: themeVM.themeMode == ThemeMode.system,
                          onTap: () => themeVM.setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 2,
                ),
                child: Text(t.continue_btn),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
