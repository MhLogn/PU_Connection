import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_state.dart';
import 'package:pu_connection/features/clubs/domain/entities/club_creation_request_entity.dart';
import 'package:pu_connection/features/clubs/presentation/cubit/club_cubit.dart';
import 'package:pu_connection/features/clubs/presentation/cubit/club_state.dart';

/// Tab 4: Phê duyệt hồ sơ đề xuất thành lập Câu Lạc Bộ sinh viên
class AdminClubApprovalTab extends StatelessWidget {
  const AdminClubApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final adminId = currentUser?.uid ?? '';
    final adminName = currentUser?.displayName ?? 'Ban Quản Trị';

    return BlocConsumer<ClubCubit, ClubState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppTheme.mintColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.coralColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        }
      },
      builder: (context, clubState) {
        final pending = clubState.pendingRequests;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Tổng quan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : AppTheme.deepBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.accentColor(context).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.diversity_3_rounded,
                        color: isDark ? AppTheme.accentColor(context) : Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phê Duyệt Đơn Thành Lập Câu Lạc Bộ',
                            style: TextStyle(
                              color: isDark ? colorScheme.onSurface : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Hiện có ${pending.length} hồ sơ đề xuất thành lập CLB đang chờ thẩm định.',
                            style: TextStyle(
                              color: isDark
                                  ? colorScheme.onSurface.withValues(alpha: 0.7)
                                  : Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Danh sách hồ sơ đề xuất
              if (pending.isEmpty) ...[
                AdminEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Không có đơn đề xuất nào đang chờ duyệt',
                  subtitle:
                      'Tất cả hồ sơ thành lập câu lạc bộ sinh viên Phenikaa đã được xử lý xong.',
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final req = pending[index];
                    return _buildPendingRequestCard(
                      context,
                      req,
                      isDark,
                      colorScheme,
                      adminId,
                      adminName,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestCard(
    BuildContext context,
    ClubCreationRequestEntity req,
    bool isDark,
    ColorScheme colorScheme,
    String adminId,
    String adminName,
  ) {
    final dateStr = req.createdAt != null
        ? '${req.createdAt!.day.toString().padLeft(2, '0')}/${req.createdAt!.month.toString().padLeft(2, '0')}/${req.createdAt!.year}'
        : '--/--/----';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.amberColor(context).withValues(alpha: 0.35),
          width: 0.9,
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
          // Header: Name + Category + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.clubName,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đề xuất ngày: $dateStr',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AdminStatusBadge.fromClubStatus(context, req.status),
            ],
          ),
          const SizedBox(height: 12),

          // Thông tin người sáng lập (Founder)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_pin_rounded,
                  color: AppTheme.primaryColor(context),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Người sáng lập: ${req.founderName} ${req.founderStudentId.isNotEmpty ? '(${req.founderStudentId})' : ''}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Email: ${req.founderEmail} • SĐT: ${req.contactPhone.isNotEmpty ? req.contactPhone : 'Chưa cung cấp'}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mục tiêu & Kế hoạch hoạt động
          Text(
            'Mục tiêu & Kế hoạch hoạt động:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            req.description,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),

          // Lý do thành lập & Lịch sinh hoạt
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lý do thành lập: ${req.reason}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lịch SH: ${req.schedule} • Địa điểm: ${req.location}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nút thao tác: Từ chối & Phê duyệt
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showRejectClubDialog(context, req, adminId, adminName);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppTheme.coralColor(context),
                  ),
                  label: Text(
                    'Từ chối',
                    style: TextStyle(
                      color: AppTheme.coralColor(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.coralColor(context), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _showApproveClubDialog(context, req, adminId, adminName);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text(
                    'Phê duyệt thành lập',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.mintColor(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveClubDialog(
    BuildContext context,
    ClubCreationRequestEntity req,
    String adminId,
    String adminName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.mintColor(ctx), size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Phê Duyệt Thành Lập CLB',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có đồng ý phê duyệt đơn thành lập câu lạc bộ "${req.clubName}" không?\n\n'
          'Sau khi duyệt:\n'
          '• CLB sẽ chính thức xuất hiện trên danh sách CLB của toàn trường.\n'
          '• Sinh viên "${req.founderName}" sẽ được công nhận là Chủ nhiệm CLB.\n'
          '• Nhóm chat chính thức của CLB sẽ được tự động kích hoạt.\n'
          '• Thông báo chúc mừng sẽ được gửi tới tài khoản của sinh viên.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.mintColor(ctx),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ClubCubit>().reviewClubRequest(
                requestId: req.id,
                action: 'approve',
                adminId: adminId,
                adminName: adminName,
              );
            },
            child: const Text('Xác nhận Phê duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectClubDialog(
    BuildContext context,
    ClubCreationRequestEntity req,
    String adminId,
    String adminName,
  ) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppTheme.coralColor(ctx), size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Từ Chối Đơn Thành Lập',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vui lòng nhập lý do từ chối yêu cầu thành lập CLB "${req.clubName}" để sinh viên có thể điều chỉnh lại hồ sơ:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập lý do từ chối';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Nhập lý do cụ thể...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.coralColor(ctx),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final reason = reasonCtrl.text.trim();
                Navigator.pop(ctx);
                context.read<ClubCubit>().reviewClubRequest(
                  requestId: req.id,
                  action: 'reject',
                  rejectionReason: reason,
                  adminId: adminId,
                  adminName: adminName,
                );
              }
            },
            child: const Text('Từ chối hồ sơ'),
          ),
        ],
      ),
    );
  }
}
