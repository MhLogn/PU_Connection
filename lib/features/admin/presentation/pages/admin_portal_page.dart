import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../moderation/domain/entities/report_entity.dart';
import '../../../moderation/domain/entities/report_target_type.dart';
import '../../../auth/presentation/pages/change_password_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final _searchUserCtrl = TextEditingController();
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastContentCtrl = TextEditingController();
  String _selectedBroadcastFaculty = 'Tất cả';

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().init();
  }

  @override
  void dispose() {
    _searchUserCtrl.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastContentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAdmin = currentUser?.isAdmin == true;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quyền truy cập bị từ chối')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Khu vực dành riêng cho Quản trị viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tài khoản của bạn không có quyền truy cập Cổng Quản Trị Viên Phenikaa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = AppTheme.isDark(context);
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 850;

    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
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

  Widget _buildWideLayout(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (NavigationRail on Web)
          NavigationRail(
            extended: true,
            minExtendedWidth: 240,
            backgroundColor: isDark ? colorScheme.surface : const Color(0xFF0F172A),
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PU ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Phenikaa Portal',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                          side: const BorderSide(color: Colors.amberAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => ChangePasswordDialog.show(context),
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey, size: 18),
                        label: const Text('Thoát Admin', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
            ],
          ),

          // Main Content View
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  _getTitleForTab(_selectedTabIndex),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.lock_reset_rounded),
                    tooltip: 'Đổi mật khẩu Admin',
                    onPressed: () => ChangePasswordDialog.show(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Làm mới dữ liệu',
                    onPressed: () => context.read<AdminCubit>().init(),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: _buildCurrentTab(context, state, isDark, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
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
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded),
            tooltip: 'Đổi mật khẩu Admin',
            onPressed: () => ChangePasswordDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => context.read<AdminCubit>().init(),
          ),
        ],
      ),
      body: _buildCurrentTab(context, state, isDark, colorScheme),
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
        ],
      ),
    );
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
      default:
        return 'Admin Portal';
    }
  }

  Widget _buildCurrentTab(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    if (state.status == AdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(context, state, isDark, colorScheme);
      case 1:
        return _buildModerationTab(context, state, isDark, colorScheme);
      case 2:
        return _buildUsersTab(context, state, isDark, colorScheme);
      case 3:
        return _buildDocsAndBroadcastTab(context, state, isDark, colorScheme);
      default:
        return const SizedBox();
    }
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final stats = state.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Chào mừng Admin
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [AppTheme.primaryColor(context), const Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hệ Thống Quản Trị PU Connection 🎓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Giám sát hoạt động học thuật, xử lý báo cáo vi phạm và duy trì môi trường văn hóa đại học Phenikaa văn minh.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Thẻ KPI Thống kê
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                title: 'Tổng Sinh Viên',
                value: '${stats.totalStudents}',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Bài Viết Bảng Tin',
                value: '${stats.totalPosts}',
                icon: Icons.article_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Tài Liệu DocsHub',
                value: '${stats.totalDocuments}',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Báo Cáo Chờ Duyệt',
                value: '${stats.pendingReports}',
                icon: Icons.shield_outlined,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cơ cấu sinh viên theo Khoa/Viện
          Text(
            'Phân Bổ Sinh Viên Theo Khoa/Viện Phenikaa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: stats.facultyDistribution.entries.map((entry) {
                final ratio = stats.totalStudents > 0 ? entry.value / stats.totalStudents : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                          ),
                          Text(
                            '${entry.value} SV (${(ratio * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor(context)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: MODERATION & REPORTS ---
  Widget _buildModerationTab(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final reports = state.reports;

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'Tất cả', 'all', state.selectedReportStatus),
                _buildFilterChip(context, 'Chờ duyệt', 'pending', state.selectedReportStatus),
                _buildFilterChip(context, 'Đã giải quyết', 'resolved', state.selectedReportStatus),
                _buildFilterChip(context, 'Đã bỏ qua', 'dismissed', state.selectedReportStatus),
              ],
            ),
          ),
        ),

        // Danh sách báo cáo
        Expanded(
          child: reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 64, color: Colors.green.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Không có báo cáo vi phạm nào!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'Môi trường sinh viên Phenikaa hiện đang an toàn và văn minh.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: reports.length,
                  itemBuilder: (context, idx) {
                    final report = reports[idx];
                    return _buildReportItemCard(context, report, isDark, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, String currentSelected) {
    final isSelected = currentSelected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor(context),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
        onSelected: (_) => context.read<AdminCubit>().filterReports(value),
      ),
    );
  }

  Widget _buildReportItemCard(
    BuildContext context,
    ReportEntity report,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isPending = report.status == 'pending';
    final targetLabel = report.targetType == ReportTargetType.post
        ? 'Bài viết'
        : (report.targetType == ReportTargetType.comment ? 'Bình luận' : 'Người dùng');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.reason.displayName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loại: $targetLabel',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Người báo cáo: ${report.reporterName} (ID: ${report.reporterId})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            Text(
              'Đối tượng bị tố cáo: ${report.targetAuthorName} (ID: ${report.targetAuthorId})',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nội dung tường trình: "${report.details}"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showReportedContent(context, report),
                  icon: const Icon(Icons.preview_rounded, size: 16, color: Color(0xFF0056B3)),
                  label: const Text('Xem nội dung', style: TextStyle(fontSize: 12, color: Color(0xFF0056B3))),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.read<AdminCubit>().resolveReport(report.id, action: 'dismiss'),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Bỏ qua', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Gỡ bỏ nội dung vi phạm?',
                      content: 'Bài viết này sẽ bị xóa khỏi Bảng tin trường và lập biên bản kiểm duyệt.',
                      onConfirm: () => context.read<AdminCubit>().resolveReport(report.id, action: 'delete_content'),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Gỡ nội dung', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Đình chỉ tài khoản sinh viên?',
                      content: 'Tài khoản của ${report.targetAuthorName} sẽ bị khóa tạm thời khỏi hệ thống.',
                      onConfirm: () => context.read<AdminCubit>().resolveReport(
                            report.id,
                            action: 'ban_user',
                            note: 'Vi phạm: ${report.reason.displayName}',
                          ),
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text('Khóa SV', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 3: USER MANAGEMENT ---
  Widget _buildUsersTab(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final users = state.users;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchUserCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm theo MSSV, Họ tên hoặc Email sinh viên...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchUserCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchUserCtrl.clear();
                        context.read<AdminCubit>().searchUsers('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (val) => context.read<AdminCubit>().searchUsers(val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: users.length,
            itemBuilder: (context, idx) {
              final u = users[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.isBanned ? Colors.grey : AppTheme.primaryColor(context),
                    child: Text(
                      u.displayName.isNotEmpty ? u.displayName[0] : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: u.isBanned ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: u.isAdmin
                              ? Colors.purple.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u.userType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: u.isAdmin ? Colors.purple : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'MSSV: ${u.studentId.isNotEmpty ? u.studentId : 'N/A'} • ${u.faculty}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'ban') {
                        context.read<AdminCubit>().toggleBanUser(u.uid, isBanned: !u.isBanned);
                      } else if (val == 'role_mod') {
                        context.read<AdminCubit>().changeUserRole(u.uid, newRole: 'moderator');
                      } else if (val == 'role_admin') {
                        context.read<AdminCubit>().changeUserRole(u.uid, newRole: 'admin');
                      } else if (val == 'role_student') {
                        context.read<AdminCubit>().changeUserRole(u.uid, newRole: 'student');
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'ban',
                        child: Text(u.isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản (Ban)'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'role_student',
                        child: Text('Đặt làm: Sinh viên (Student)'),
                      ),
                      const PopupMenuItem(
                        value: 'role_mod',
                        child: Text('Đặt làm: Kiểm duyệt viên (Mod)'),
                      ),
                      const PopupMenuItem(
                        value: 'role_admin',
                        child: Text('Đặt làm: Quản trị viên (Admin)'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 4: DOCS & BROADCAST ---
  Widget _buildDocsAndBroadcastTab(
    BuildContext context,
    AdminState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần A: Phát thông báo khẩn
          Text(
            'Phát Thông Báo Khẩn Toàn Trường 📢',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _broadcastTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề thông báo',
                    hintText: 'VD: Lịch thi kết thúc học kỳ 2 năm học 2025-2026...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _broadcastContentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung chi tiết',
                    hintText: 'Nhập nội dung thông báo gửi đến sinh viên...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Gửi đến: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedBroadcastFaculty,
                          items: const [
                            DropdownMenuItem(value: 'Tất cả', child: Text('Toàn bộ sinh viên trường')),
                            DropdownMenuItem(value: 'Khoa Công nghệ Thông tin', child: Text('Khoa CNTT')),
                            DropdownMenuItem(value: 'Khoa Kinh tế và Quản trị', child: Text('Khoa Kinh tế')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBroadcastFaculty = val);
                          },
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(context),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final title = _broadcastTitleCtrl.text.trim();
                        final content = _broadcastContentCtrl.text.trim();
                        if (title.isEmpty || content.isEmpty) return;
                        context.read<AdminCubit>().broadcastAnnouncement(
                              title: title,
                              content: content,
                              targetFaculty: _selectedBroadcastFaculty,
                            );
                        _broadcastTitleCtrl.clear();
                        _broadcastContentCtrl.clear();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Phát tin ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Phần B: Quản lý DocsHub
          Text(
            'Quản Lý Kho Tài Liệu Học Tập (DocsHub)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.documents.length,
            itemBuilder: (context, idx) {
              final doc = state.documents[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                  title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('Mã môn: ${doc.code} • ${doc.faculty} • Tải: ${doc.downloads} lượt'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    tooltip: 'Xóa tài liệu',
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Xóa tài liệu khỏi hệ thống?',
                      content: 'Tài liệu "${doc.title}" sẽ bị xóa vĩnh viễn khỏi DocsHub.',
                      onConfirm: () => context.read<AdminCubit>().deleteDocument(doc.id),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showReportedContent(BuildContext context, ReportEntity report) async {
    final targetLabel = report.targetType == ReportTargetType.post
        ? 'bài viết'
        : (report.targetType == ReportTargetType.comment ? 'bình luận' : 'người dùng');

    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      String content = 'Không thể tải nội dung.';
      String authorName = report.targetAuthorName;

      if (report.targetType == ReportTargetType.post) {
        final doc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.postsCollection)
            .doc(report.targetId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          content = data['content'] as String? ?? '(Không có nội dung)';
          authorName = data['authorName'] as String? ?? authorName;
        } else {
          content = '(Bài viết đã bị xóa hoặc không tìm thấy)';
        }
      } else if (report.targetType == ReportTargetType.comment) {
        content = '(Xem bình luận trong bài viết gốc — ID: ${report.targetId})';
      } else {
        content = '(Tài khoản người dùng bị báo cáo — ID: ${report.targetId})';
      }

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.preview_rounded, color: Color(0xFF0056B3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nội dung $targetLabel bị báo cáo',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tác giả: $authorName',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('Lý do báo cáo: ${report.reason.displayName}',
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                const Divider(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(content, style: const TextStyle(fontSize: 13.5)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải nội dung: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
