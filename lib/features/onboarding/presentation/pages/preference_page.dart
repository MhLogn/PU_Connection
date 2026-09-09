import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class PreferencePage extends StatelessWidget {
  const PreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.setup_title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                      Text(
                        l10n.setup_subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              _buildSectionTitle(context, l10n.app_language_section, Icons.language_rounded),
              const SizedBox(height: 12),
              BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  final isVi = locale.languageCode == 'vi';
                  return Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          flag: '🇻🇳',
                          title: l10n.vietnamese,
                          subtitle: l10n.default_label,
                          isSelected: isVi,
                          onTap: () => context.read<LocaleCubit>().setLocale(const Locale('vi')),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          flag: '🇬🇧',
                          title: l10n.english,
                          subtitle: l10n.international_label,
                          isSelected: !isVi,
                          onTap: () => context.read<LocaleCubit>().setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, l10n.theme_mode_section, Icons.palette_outlined),
              const SizedBox(height: 12),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return Column(
                    children: [
                      _buildThemeTile(
                        context: context,
                        icon: Icons.wb_sunny_rounded,
                        title: l10n.light_theme_title,
                        description: l10n.light_theme_desc,
                        isSelected: themeMode == ThemeMode.light,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(height: 10),
                      _buildThemeTile(
                        context: context,
                        icon: Icons.nightlight_round,
                        title: l10n.dark_theme_title,
                        description: l10n.dark_theme_desc,
                        isSelected: themeMode == ThemeMode.dark,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                      ),
                      const SizedBox(height: 10),
                      _buildThemeTile(
                        context: context,
                        icon: Icons.settings_brightness_rounded,
                        title: l10n.system_theme_title,
                        description: l10n.system_theme_desc,
                        isSelected: themeMode == ThemeMode.system,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.continue_to_login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blueContainer(context)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor(context) : colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(flag, style: const TextStyle(fontSize: 28)),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor(context), size: 20)
                else
                  Icon(
                    Icons.circle_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.25),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryColor(context) : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blueContainer(context)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor(context) : colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor(context).withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor(context) : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor(context) : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked_rounded, color: AppTheme.primaryColor(context), size: 20)
            else
              Icon(
                Icons.radio_button_off_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.25),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

