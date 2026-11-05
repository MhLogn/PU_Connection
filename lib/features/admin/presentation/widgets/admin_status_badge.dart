import 'package:flutter/material.dart';
import 'package:pu_connection/core/theme/app_theme.dart';

enum AdminBadgeType {
  success,
  warning,
  danger,
  info,
  neutral,
}

/// Huy hiệu trạng thái chuẩn hóa cho khu vực Quản trị viên (Admin Status Badge)
class AdminStatusBadge extends StatelessWidget {
  final String label;
  final AdminBadgeType type;
  final IconData? icon;
  final bool isDense;

  const AdminStatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.isDense = false,
  });

  /// Factory cho trạng thái Báo cáo vi phạm
  factory AdminStatusBadge.fromReportStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const AdminStatusBadge(
          label: 'Chờ xử lý',
          type: AdminBadgeType.warning,
          icon: Icons.hourglass_top_rounded,
        );
      case 'resolved':
        return const AdminStatusBadge(
          label: 'Đã giải quyết',
          type: AdminBadgeType.success,
          icon: Icons.check_circle_rounded,
        );
      case 'dismissed':
        return const AdminStatusBadge(
          label: 'Đã bỏ qua',
          type: AdminBadgeType.neutral,
          icon: Icons.remove_circle_outline_rounded,
        );
      default:
        return AdminStatusBadge(
          label: status.toUpperCase(),
          type: AdminBadgeType.info,
        );
    }
  }

  /// Factory cho trạng thái Đề xuất thành lập CLB
  factory AdminStatusBadge.fromClubStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const AdminStatusBadge(
          label: 'Chờ thẩm định',
          type: AdminBadgeType.warning,
          icon: Icons.hourglass_top_rounded,
        );
      case 'approved':
        return const AdminStatusBadge(
          label: 'Đã phê duyệt',
          type: AdminBadgeType.success,
          icon: Icons.verified_rounded,
        );
      case 'rejected':
        return const AdminStatusBadge(
          label: 'Đã từ chối',
          type: AdminBadgeType.danger,
          icon: Icons.cancel_rounded,
        );
      default:
        return AdminStatusBadge(
          label: status,
          type: AdminBadgeType.info,
        );
    }
  }

  /// Factory cho Vai trò người dùng (User Role)
  factory AdminStatusBadge.fromUserRole(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminStatusBadge(
          label: 'QUẢN TRỊ VIÊN',
          type: AdminBadgeType.danger,
          icon: Icons.admin_panel_settings_rounded,
          isDense: true,
        );
      case 'moderator':
        return const AdminStatusBadge(
          label: 'KIỂM DUYỆT VIÊN',
          type: AdminBadgeType.info,
          icon: Icons.shield_rounded,
          isDense: true,
        );
      default:
        return const AdminStatusBadge(
          label: 'SINH VIÊN',
          type: AdminBadgeType.neutral,
          icon: Icons.school_rounded,
          isDense: true,
        );
    }
  }

  /// Factory cho trạng thái Tài khoản sinh viên
  factory AdminStatusBadge.fromUserBanStatus(BuildContext context, bool isBanned) {
    if (isBanned) {
      return const AdminStatusBadge(
        label: 'Đã khóa tài khoản',
        type: AdminBadgeType.danger,
        icon: Icons.lock_rounded,
        isDense: true,
      );
    }
    return const AdminStatusBadge(
      label: 'Đang hoạt động',
      type: AdminBadgeType.success,
      icon: Icons.check_circle_outline_rounded,
      isDense: true,
    );
  }

  /// Factory cho trạng thái kích hoạt danh bạ Phenikaa
  factory AdminStatusBadge.fromActivationStatus(
    BuildContext context,
    bool isActivated,
  ) {
    if (isActivated) {
      return const AdminStatusBadge(
        label: 'Đã kích hoạt app',
        type: AdminBadgeType.success,
        icon: Icons.check_rounded,
        isDense: true,
      );
    }
    return const AdminStatusBadge(
      label: 'Chờ kích hoạt',
      type: AdminBadgeType.warning,
      icon: Icons.schedule_rounded,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (baseColor, isFilled) = _resolveColors(context);

    final horizontalPadding = isDense ? 7.0 : 10.0;
    final verticalPadding = isDense ? 3.0 : 5.0;
    final fontSize = isDense ? 11.0 : 12.0;
    final iconSize = isDense ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: baseColor),
            SizedBox(width: isDense ? 4 : 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: baseColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, bool) _resolveColors(BuildContext context) {
    switch (type) {
      case AdminBadgeType.success:
        return (AppTheme.mintColor(context), false);
      case AdminBadgeType.warning:
        return (AppTheme.amberColor(context), false);
      case AdminBadgeType.danger:
        return (AppTheme.coralColor(context), false);
      case AdminBadgeType.info:
        return (AppTheme.primaryColor(context), false);
      case AdminBadgeType.neutral:
        final isDark = AppTheme.isDark(context);
        return (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), false);
    }
  }
}
