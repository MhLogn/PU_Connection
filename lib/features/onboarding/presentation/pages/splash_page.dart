import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _warmUpFirestore();
    _navigateNext();
  }

  void _warmUpFirestore() {
    Future.microtask(() async {
      try {
        await FirebaseFirestore.instance
            .collection('health_check')
            .doc('ping')
            .get(const GetOptions(source: Source.cache));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    bool isAuthenticated = false;
    bool isAdmin = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.reload().timeout(const Duration(milliseconds: 1500));
        } catch (_) {}
        final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
        if (sl.isRegistered<AuthRepository>()) {
          isAdmin = await sl<AuthRepository>().isCurrentUserAdmin();
        }
        isAuthenticated = refreshedUser.emailVerified || isAdmin;
      }
    } catch (_) {}

    bool hasSeenIntro = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    } catch (_) {}

    if (mounted) {
      if (isAuthenticated) {
        if (isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else if (hasSeenIntro) {
        context.go('/login');
      } else {
        context.go('/intro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.isDark(context)
                              ? Colors.white12
                              : AppTheme.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.isDark(context)
                                ? Colors.black26
                                : const Color(0x0C123B63),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo/phenikaa_logo.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.school_rounded,
                          size: 90,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppLocalizations.of(context)?.university_name ??
                          'ĐẠI HỌC PHENIKAA',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PU Connection',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppTheme.isDark(context)
                                ? Colors.white
                                : AppTheme.deepBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeContainer(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.accentColor(
                            context,
                          ).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.student_network ??
                            'Mạng xã hội sinh viên Phenikaa',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.student_slogan ??
                      'Tôn trọng – Sáng tạo – Phản biện',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
