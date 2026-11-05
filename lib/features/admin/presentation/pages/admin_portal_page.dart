import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/core/theme/theme_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_club_approval_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_docs_broadcast_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_moderation_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_overview_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_users_tab.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_state.dart';
import 'package:pu_connection/features/auth/presentation/pages/change_password_dialog.dart';
import 'package:pu_connection/features/clubs/presentation/cubit/club_cubit.dart';

/// Cổng Quản Trị Viên PU Connection — Classic Modern Architecture
class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().init();
    context.read<ClubCubit>().initPendingRequestsStream();
  }

  void _confirmSignOut(BuildContext context) {
    AdminConfirmDialog.show(
      context,
      title: 'Đăng xuất Quản trị viên?',
      content:
          'Bạn có chắc chắn muốn kết thúc phiên làm việc Quản trị viên và quay về màn hình đăng nhập?',
      confirmLabel: 'Đăng xuất',
      icon: Icons.logout_rounded,
      isDestructive: true,
      onConfirm: () async {
        await context.read<AuthCubit>().signOut();
        if (context.mounted) {
          context.go('/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAdmin = currentUser?.isAdmin == true;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quyền truy cập bị từ chối')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gpp_bad_rounded,
                  size: 64,
                  color: AppTheme.coralColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Khu vực dành riêng cho Quản trị viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài khoản của bạn không có đặc quyền truy cập Cổng Quản Trị Viên Phenikaa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go(currentUser != null ? '/home' : '/login');
                    }
                  },
                  child: const Text('Quay lại trang chủ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 850;

    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppTheme.mintColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.coralColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (isWide) {
          return _buildWideLayout(context, state, isDark, colorScheme);
        }
        return _buildMobileLayout(context, state, isDark, colorScheme);
      },
    );
  }

  // --- BỐ CỤC MÀN HÌNH RỘNG (DESKTOP & TABLET >= 850px) ---
  Widget _buildWideLayout(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final clubState = context.watch<ClubCubit>().state;
    final pendingClubCount = clubState.pendingRequests.length;

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail Sidebar phong cách Classic Modern
          NavigationRail(
            extended: true,
            minExtendedWidth: 240,
            backgroundColor: colorScheme.surface,
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedTabIndex = index),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PU ADMIN',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Phenikaa Portal',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút đổi Theme Light/Dark trực quan
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
                          context.read<ThemeCubit>().setThemeMode(nextMode);
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkOrangeAccent
                              : AppTheme.primaryColor(context),
                        ),
                        label: Text(
                          isDark ? 'Giao diện Sáng' : 'Giao diện Tối',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () => ChangePasswordDialog.show(context),
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 18,
                        ),
                        label: Text(
                          'Thoát Admin',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Tổng quan'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: state.stats.pendingReports > 0,
                  label: Text('${state.stats.pendingReports}'),
                  backgroundColor: AppTheme.coralColor(context),
                  child: const Icon(Icons.shield_outlined),
                ),
                selectedIcon: const Icon(Icons.shield_rounded),
                label: const Text('Kiểm duyệt'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: Text('Sinh viên'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign_rounded),
                label: Text('Tài liệu & Tin báo'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: pendingClubCount > 0,
                  label: Text('$pendingClubCount'),
                  backgroundColor: AppTheme.accentColor(context),
                  child: const Icon(Icons.diversity_3_outlined),
                ),
                selectedIcon: const Icon(Icons.diversity_3_rounded),
                label: const Text('Duyệt CLB'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 0.8, width: 0.8),

          // Main View Content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  _getTitleForTab(_selectedTabIndex),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? AppTheme.darkOrangeAccent : null,
                    ),
                    tooltip: isDark ? 'Chuyển sang nền sáng' : 'Chuyển sang nền tối',
                    onPressed: () {
                      final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
                      context.read<ThemeCubit>().setThemeMode(nextMode);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Làm mới dữ liệu',
                    onPressed: () => context.read<AdminCubit>().init(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: AppTheme.coralColor(context),
                    ),
                    tooltip: 'Đăng xuất Quản trị viên',
                    onPressed: () => _confirmSignOut(context),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: _buildCurrentTab(context, state),
            ),
          ),
        ],
      ),
    );
  }

  // --- BỐ CỤC MÀN HÌNH ĐIỆN THOẠI (MOBILE < 850px) ---
  Widget _buildMobileLayout(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final clubState = context.watch<ClubCubit>().state;
    final pendingClubCount = clubState.pendingRequests.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cổng Quản Trị Viên',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Đại học Phenikaa',
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppTheme.darkOrangeAccent : null,
            ),
            tooltip: isDark ? 'Nền sáng' : 'Nền tối',
            onPressed: () {
              final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
              context.read<ThemeCubit>().setThemeMode(nextMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => context.read<AdminCubit>().init(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'password') {
                ChangePasswordDialog.show(context);
              } else if (val == 'logout') {
                _confirmSignOut(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Đổi mật khẩu Admin'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppTheme.coralColor(ctx),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(color: AppTheme.coralColor(ctx)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCurrentTab(context, state),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.stats.pendingReports > 0,
              label: Text('${state.stats.pendingReports}'),
              backgroundColor: AppTheme.coralColor(context),
              child: const Icon(Icons.shield_outlined),
            ),
            selectedIcon: const Icon(Icons.shield_rounded),
            label: 'Kiểm duyệt',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Sinh viên',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingClubCount > 0,
              label: Text('$pendingClubCount'),
              backgroundColor: AppTheme.accentColor(context),
              child: const Icon(Icons.diversity_3_outlined),
            ),
            selectedIcon: const Icon(Icons.diversity_3_rounded),
            label: 'Duyệt CLB',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context, AdminState state) {
    if (state.status == AdminStatus.loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor(context),
        ),
      );
    }

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final clubState = context.watch<ClubCubit>().state;

    switch (_selectedTabIndex) {
      case 0:
        return AdminOverviewTab(
          state: state,
          currentUser: currentUser,
          pendingClubCount: clubState.pendingRequests.length,
          onNavigateTab: (tabIdx) => setState(() => _selectedTabIndex = tabIdx),
        );
      case 1:
        return AdminModerationTab(state: state);
      case 2:
        return AdminUsersTab(state: state);
      case 3:
        return AdminDocsBroadcastTab(state: state);
      case 4:
        return const AdminClubApprovalTab();
      default:
        return const SizedBox();
    }
  }

  String _getTitleForTab(int tab) {
    switch (tab) {
      case 0:
        return 'Bảng Điều Khiển Tổng Quan';
      case 1:
        return 'Hàng Đợi Kiểm Duyệt & Báo Cáo Vi Phạm';
      case 2:
        return 'Quản Lý Danh Sách Sinh Viên';
      case 3:
        return 'Kho Tài Liệu & Thông Báo Khẩn';
      case 4:
        return 'Phê Duyệt Đơn Thành Lập Câu Lạc Bộ';
      default:
        return 'Admin Portal';
    }
  }
}
