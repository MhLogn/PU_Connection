import 'package:flutter/material.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:pu_connection/features/auth/domain/entities/user_entity.dart';

/// Tab 0: Bảng điều khiển tổng quan cho Quản trị viên (Executive Overview Dashboard)
class AdminOverviewTab extends StatelessWidget {
  final AdminState state;
  final UserEntity? currentUser;
  final int pendingClubCount;
  final ValueChanged<int> onNavigateTab;

  const AdminOverviewTab({
    super.key,
    required this.state,
    required this.currentUser,
    required this.pendingClubCount,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final stats = state.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Banner Chào Mừng
          _buildExecutiveBanner(context, isDark, colorScheme),
          const SizedBox(height: 20),

          // 2. Thẻ KPI Tổng quan
          AdminSectionHeader(
            title: 'Chỉ Số Hệ Thống Thời Gian Thực',
            subtitle: 'Dữ liệu được cập nhật tức thời từ dịch vụ Cloud Firestore',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900
                  ? 5
                  : (constraints.maxWidth >= 550 ? 3 : 2);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  AdminStatCard(
                    title: 'Tổng Sinh Viên',
                    value: '${stats.totalStudents}',
                    icon: Icons.people_alt_rounded,
                    accentColor: AppTheme.primaryColor(context),
                    subtitle: 'Tài khoản hoạt động',
                    onTap: () => onNavigateTab(2),
                  ),
                  AdminStatCard(
                    title: 'Bài Viết Feed',
                    value: '${stats.totalPosts}',
                    icon: Icons.dynamic_feed_rounded,
                    accentColor: AppTheme.mintColor(context),
                    subtitle: 'Toàn mạng xã hội',
                  ),
                  AdminStatCard(
                    title: 'Tài Liệu Học Tập',
                    value: '${stats.totalDocuments}',
                    icon: Icons.menu_book_rounded,
                    accentColor: AppTheme.amberColor(context),
                    subtitle: 'DocsHub Phenikaa',
                    onTap: () => onNavigateTab(3),
                  ),
                  AdminStatCard(
                    title: 'Báo Cáo Chờ Xử Lý',
                    value: '${stats.pendingReports}',
                    icon: Icons.shield_outlined,
                    accentColor: AppTheme.coralColor(context),
                    subtitle: stats.pendingReports > 0 ? 'Cần kiểm duyệt ngay' : 'Không có vi phạm',
                    onTap: () => onNavigateTab(1),
                  ),
                  AdminStatCard(
                    title: 'Đề Xuất CLB',
                    value: '$pendingClubCount',
                    icon: Icons.diversity_3_rounded,
                    accentColor: AppTheme.accentColor(context),
                    subtitle: pendingClubCount > 0 ? 'Đang chờ thẩm định' : 'Đã duyệt hết',
                    onTap: () => onNavigateTab(4),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Phím tắt thao tác nhanh (Quick Actions)
          AdminSectionHeader(
            title: 'Thao Tác Quản Trị Trọng Tâm',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 8),
          _buildQuickActionCards(context, isDark, colorScheme),
          const SizedBox(height: 24),

          // 4. Cơ cấu sinh viên theo Khoa/Viện Phenikaa
          AdminSectionHeader(
            title: 'Phân Bổ Sinh Viên Theo Khoa/Viện',
            subtitle: 'Tỷ trọng học viên tham gia mạng xã hội học thuật Phenikaa',
            icon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 8),
          _buildFacultyDistribution(context, isDark, colorScheme, stats),
          const SizedBox(height: 24),

          // 5. Nhật ký hoạt động gần đây
          if (state.auditLogs.isNotEmpty) ...[
            AdminSectionHeader(
              title: 'Hoạt Động Quản Trị Vừa Thực Hiện',
              subtitle: 'Ghi nhận kiểm toán tự động theo thời gian thực',
              icon: Icons.history_rounded,
              trailing: TextButton(
                onPressed: () => onNavigateTab(3),
                child: const Text('Xem tất cả >'),
              ),
            ),
            const SizedBox(height: 6),
            _buildRecentActivityList(context, isDark, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveBanner(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final adminName = currentUser?.displayName ?? 'Quản Trị Viên';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : AppTheme.deepBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.15),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x14123B63),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryColor(context).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: isDark ? AppTheme.primaryColor(context) : Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Chào mừng, $adminName',
                        style: TextStyle(
                          color: isDark ? colorScheme.onSurface : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.primaryColor(context).withValues(alpha: 0.2)
                            : AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cổng Điều Hành Quản Trị PU Connection — Giám sát an toàn thông tin, chuẩn mực ứng xử học đường và kiểm duyệt tài nguyên Đại học Phenikaa.',
                  style: TextStyle(
                    color: isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildActionItem(
              context,
              icon: Icons.shield_outlined,
              label: 'Xử lý báo cáo',
              color: AppTheme.coralColor(context),
              onTap: () => onNavigateTab(1),
            ),
            _buildActionItem(
              context,
              icon: Icons.person_add_outlined,
              label: 'Quản lý sinh viên',
              color: AppTheme.primaryColor(context),
              onTap: () => onNavigateTab(2),
            ),
            _buildActionItem(
              context,
              icon: Icons.campaign_outlined,
              label: 'Phát thông báo khẩn',
              color: AppTheme.amberColor(context),
              onTap: () => onNavigateTab(3),
            ),
            _buildActionItem(
              context,
              icon: Icons.diversity_3_outlined,
              label: 'Duyệt đề xuất CLB',
              color: AppTheme.accentColor(context),
              onTap: () => onNavigateTab(4),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : AppTheme.borderLight,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyDistribution(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    dynamic stats,
  ) {
    if (stats.facultyDistribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : AppTheme.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu phân bổ khoa',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : AppTheme.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        children: stats.facultyDistribution.entries.map<Widget>((entry) {
          final count = entry.value as int;
          final ratio = stats.totalStudents > 0 ? count / stats.totalStudents : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count SV (${(ratio * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6.5,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivityList(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final recentLogs = state.auditLogs.take(3).toList();

    return Column(
      children: recentLogs.map((log) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : AppTheme.borderLight,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppTheme.primaryColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.details,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thực hiện bởi: ${log.adminEmail}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
