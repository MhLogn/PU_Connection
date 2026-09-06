import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';
import '../../features/onboarding/presentation/pages/preference_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/intro', builder: (context, state) => const IntroPage()),
    GoRoute(
      path: '/preference',
      builder: (context, state) => const PreferencePage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
  ],
);
