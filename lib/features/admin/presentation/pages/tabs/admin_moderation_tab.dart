import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pu_connection/core/constants/firebase_constants.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_entity.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_target_type.dart';

/// Tab 1: Hàng đợi kiểm duyệt nội dung & xử lý báo cáo vi phạm
class AdminModerationTab extends StatelessWidget {
  final AdminState state;

  const AdminModerationTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final reports = state.reports;

    return Column(
      children: [
        // Thanh bộ lọc trạng thái (Filter Chips)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : AppTheme.borderLight,
                width: 0.8,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'Tất cả báo cáo',
                  value: 'all',
                  currentValue: state.selectedReportStatus,
                  count: null,
                ),
                _buildFilterChip(
                  context,
                  label: 'Chờ xử lý',
                  value: 'pending',
                  currentValue: state.selectedReportStatus,
                  count: state.stats.pendingReports > 0 ? state.stats.pendingReports : null,
                  badgeColor: AppTheme.coralColor(context),
                ),
                _buildFilterChip(
                  context,
                  label: 'Đã giải quyết',
                  value: 'resolved',
                  currentValue: state.selectedReportStatus,
                  count: null,
                ),
                _buildFilterChip(
                  context,
                  label: 'Đã bỏ qua',
                  value: 'dismissed',
                  currentValue: state.selectedReportStatus,
                  count: null,
                ),
              ],
            ),
          ),
        ),

        // Danh sách báo cáo vi phạm
        Expanded(
          child: reports.isEmpty
              ? AdminEmptyState(
                  icon: Icons.verified_user_rounded,
                  title: 'Không có báo cáo vi phạm nào',
                  subtitle:
                      'Tất cả báo cáo đã được kiểm duyệt xong. Môi trường sinh viên Phenikaa hiện đang văn minh và an toàn.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportItem(context, report, isDark, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String value,
    required String currentValue,
    int? count,
    Color? badgeColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentValue == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: count != null
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor ?? colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : colorScheme.onSurface,
        ),
        selectedColor: AppTheme.primaryColor(context),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        onSelected: (_) => context.read<AdminCubit>().filterReports(value),
      ),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    ReportEntity report,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isPending = report.status == 'pending';
    final targetLabel = report.targetType == ReportTargetType.post
        ? 'Bài viết'
        : (report.targetType == ReportTargetType.comment
            ? 'Bình luận'
            : 'Tài khoản người dùng');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppTheme.coralColor(context).withValues(alpha: 0.35)
              : (isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : AppTheme.borderLight),
          width: isPending ? 1.0 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0x06123B63),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Lý do vi phạm + Loại đối tượng + Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.coralColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.reason.displayName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.coralColor(context),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        targetLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminStatusBadge.fromReportStatus(context, report.status),
            ],
          ),
          const SizedBox(height: 12),

          // Thông tin người gửi & đối tượng bị tố cáo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Người báo cáo: ${report.reporterName} (ID: ${report.reporterId})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: AppTheme.coralColor(context),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tài khoản bị tố cáo: ${report.targetAuthorName} (ID: ${report.targetAuthorId})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.coralColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tường trình chi tiết của sinh viên
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Tường trình: "${report.details}"',
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Nút Xem nội dung chi tiết & Thao tác xử lý
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showReportedContent(context, report),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Xem nội dung gốc'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (isPending) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => context.read<AdminCubit>().resolveReport(
                        report.id,
                        action: 'dismiss',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.65),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Bỏ qua', style: TextStyle(fontSize: 12)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.coralColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => AdminConfirmDialog.show(
                        context,
                        title: 'Gỡ bỏ nội dung vi phạm?',
                        content:
                            'Bài viết hoặc bình luận này sẽ bị xóa khỏi Bảng tin trường và lập biên bản kiểm duyệt hệ thống.',
                        confirmLabel: 'Xác nhận gỡ',
                        icon: Icons.delete_sweep_rounded,
                        isDestructive: true,
                        onConfirm: () => context.read<AdminCubit>().resolveReport(
                          report.id,
                          action: 'delete_content',
                        ),
                      ),
                      child: const Text('Gỡ nội dung', style: TextStyle(fontSize: 12)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => AdminConfirmDialog.show(
                        context,
                        title: 'Đình chỉ tài khoản sinh viên?',
                        content:
                            'Tài khoản của "${report.targetAuthorName}" sẽ bị khóa tạm thời khỏi hệ thống PU Connection vì vi phạm: ${report.reason.displayName}.',
                        confirmLabel: 'Khóa tài khoản',
                        icon: Icons.lock_outline_rounded,
                        isDestructive: true,
                        onConfirm: () => context.read<AdminCubit>().resolveReport(
                          report.id,
                          action: 'ban_user',
                          note: 'Vi phạm: ${report.reason.displayName}',
                        ),
                      ),
                      child: const Text('Khóa SV', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showReportedContent(
    BuildContext context,
    ReportEntity report,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection(FirebaseConstants.postsCollection)
              .doc(report.targetId)
              .get(),
          builder: (context, snapshot) {
            Widget contentWidget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              contentWidget = const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              contentWidget = Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 40,
                      color: AppTheme.amberColor(context),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nội dung gốc không còn tồn tại trên máy chủ (đã bị gỡ bỏ hoặc tác giả tự xóa).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ],
                ),
              );
            } else {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final postContent = data['content'] ?? '';
              final authorName = data['authorName'] ?? 'Sinh viên ẩn danh';
              final authorAvatar = data['authorAvatar'] as String?;
              final images = data['images'] as List<dynamic>? ?? [];

              contentWidget = SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor(context),
                          backgroundImage: authorAvatar != null && authorAvatar.isNotEmpty
                              ? NetworkImage(authorAvatar)
                              : null,
                          child: authorAvatar == null || authorAvatar.isEmpty
                              ? Text(
                                  authorName.isNotEmpty ? authorName[0] : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                'ID bài viết: ${report.targetId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      postContent,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images.first.toString(),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Xem Nội Dung Bị Báo Cáo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    contentWidget,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
