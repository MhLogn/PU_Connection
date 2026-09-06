import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pu_connection/l10n/app_localizations.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';

class PreferencePage extends StatelessWidget {
  const PreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
              BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.vietnamese,
                          icon: Icons.language,
                          isSelected: locale.languageCode == 'vi',
                          onTap: () => context.read<LocaleCubit>().setLocale(
                            const Locale('vi'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.english,
                          icon: Icons.translate,
                          isSelected: locale.languageCode == 'en',
                          onTap: () => context.read<LocaleCubit>().setLocale(
                            const Locale('en'),
                          ),
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
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.light,
                          icon: Icons.wb_sunny_rounded,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.light,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.dark,
                          icon: Icons.nightlight_round,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: t.system,
                          icon: Icons.settings_suggest_rounded,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.system,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');
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
