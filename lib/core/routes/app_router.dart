import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/main/presentation/pages/main_navigation_page.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';
import '../../features/admin/presentation/pages/admin_portal_page.dart';
import '../../features/auth/presentation/pages/student_qr_scanner_page.dart';

class AuthRouterRefreshNotifier extends ChangeNotifier {
  StreamSubscription? _sub;

  AuthRouterRefreshNotifier() {
    if (sl.isRegistered<AuthCubit>()) {
      _sub = sl<AuthCubit>().stream.listen((_) {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthRouterRefreshNotifier(),
  redirect: (context, state) {
    if (!sl.isRegistered<AuthCubit>()) return null;

    final authState = sl<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAuthenticated = currentUser != null;
    final isAdmin = currentUser?.isAdmin == true;

    final location = state.matchedLocation;

    // 1. Bảo vệ tuyệt đối Route Quản trị viên (/admin)
    if (location.startsWith('/admin')) {
      if (!isAuthenticated) {
        return '/login';
      }
      if (!isAdmin) {
        // Sinh viên thông thường cố tình truy cập /admin bị chặn ngay lập tức
        return '/home';
      }
    }

    // 2. Chuyển hướng người dùng đã đăng nhập khi truy cập /login
    if (location == '/login' && isAuthenticated) {
      return isAdmin ? '/admin' : '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/intro', builder: (context, state) => const IntroPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/preference', redirect: (context, state) => '/login'),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ConversationsPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) {
        try {
          context.read<AdminCubit>();
          return const AdminPortalPage();
        } catch (_) {
          return BlocProvider(
            create: (_) => sl<AdminCubit>(),
            child: const AdminPortalPage(),
          );
        }
      },
    ),
    GoRoute(
      path: '/profile/qr-scanner',
      builder: (context, state) => const StudentQrScannerPage(),
    ),
  ],
);
