import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_section_header.dart';

/// Tab 3: Kho tài liệu DocsHub, Phát thông báo khẩn & Nhật ký quản trị (Audit Logs)
class AdminDocsBroadcastTab extends StatefulWidget {
  final AdminState state;

  const AdminDocsBroadcastTab({
    super.key,
    required this.state,
  });

  @override
  State<AdminDocsBroadcastTab> createState() => _AdminDocsBroadcastTabState();
}

class _AdminDocsBroadcastTabState extends State<AdminDocsBroadcastTab> {
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastContentCtrl = TextEditingController();
  String _selectedBroadcastFaculty = 'Tất cả';

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastContentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PHÁT THÔNG BÁO KHẨN
          AdminSectionHeader(
            title: 'Phát Thông Báo Khẩn Toàn Trường',
            subtitle: 'Gửi thông báo tới toàn thể sinh viên hoặc theo từng khoa cụ thể',
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(height: 8),
          _buildBroadcastForm(context, isDark, colorScheme),
          const SizedBox(height: 28),

          // 2. QUẢN LÝ KHO TÀI LIỆU (DOCSHUB)
          AdminSectionHeader(
            title: 'Quản Lý Kho Tài Liệu Học Tập (DocsHub)',
            subtitle: 'Hiện có ${widget.state.documents.length} tài liệu học phần được chia sẻ',
            icon: Icons.folder_shared_outlined,
          ),
          const SizedBox(height: 8),
          _buildDocsList(context, isDark, colorScheme),
          const SizedBox(height: 28),

          // 3. NHẬT KÝ QUẢN TRỊ HỆ THỐNG (AUDIT TRAIL)
          AdminSectionHeader(
            title: 'Nhật Ký Quản Trị Hệ Thống (Audit Logs)',
            subtitle: 'Lưu vết tự động các hành động kiểm duyệt và quản trị',
            icon: Icons.history_edu_rounded,
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới nhật ký',
              onPressed: () => context.read<AdminCubit>().loadAuditLogs(),
            ),
          ),
          const SizedBox(height: 8),
          _buildAuditLogsList(context, isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBroadcastForm(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : AppTheme.borderLight,
          width: 0.8,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _broadcastTitleCtrl,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề thông báo *',
              hintText: 'VD: Lịch thi kết thúc học kỳ 2 năm học 2025-2026...',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastContentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nội dung chi tiết thông báo *',
              hintText: 'Nhập nội dung thông báo gửi đến sinh viên...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Phạm vi gửi: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedBroadcastFaculty,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tất cả',
                        child: Text('Toàn bộ sinh viên trường'),
                      ),
                      DropdownMenuItem(
                        value: 'Khoa Công nghệ Thông tin',
                        child: Text('Khoa CNTT'),
                      ),
                      DropdownMenuItem(
                        value: 'Khoa Kinh tế và Quản trị',
                        child: Text('Khoa Kinh tế'),
                      ),
                      DropdownMenuItem(
                        value: 'Khoa Ngoại ngữ',
                        child: Text('Khoa Ngoại ngữ'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBroadcastFaculty = val);
                      }
                    },
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () {
                  final title = _broadcastTitleCtrl.text.trim();
                  final content = _broadcastContentCtrl.text.trim();
                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng điền đủ tiêu đề và nội dung thông báo'),
                      ),
                    );
                    return;
                  }
                  context.read<AdminCubit>().broadcastAnnouncement(
                    title: title,
                    content: content,
                    targetFaculty: _selectedBroadcastFaculty,
                  );
                  _broadcastTitleCtrl.clear();
                  _broadcastContentCtrl.clear();
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Phát thông báo ngay',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocsList(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final docs = widget.state.documents;
    if (docs.isEmpty) {
      return AdminEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Chưa có tài liệu nào trong DocsHub',
        subtitle: 'Kho tài liệu học tập của sinh viên hiện đang trống.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final doc = docs[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.coralColor(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.coralColor(context),
                size: 22,
              ),
            ),
            title: Text(
              doc.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Mã môn: ${doc.code} • ${doc.faculty} • Tải về: ${doc.downloads} lượt',
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.coralColor(context),
                size: 20,
              ),
              tooltip: 'Xóa tài liệu',
              onPressed: () => AdminConfirmDialog.show(
                context,
                title: 'Xóa tài liệu học tập?',
                content:
                    'Tài liệu "${doc.title}" sẽ bị xóa vĩnh viễn khỏi kho lưu trữ DocsHub.',
                confirmLabel: 'Xóa tài liệu',
                icon: Icons.delete_forever_rounded,
                isDestructive: true,
                onConfirm: () =>
                    context.read<AdminCubit>().deleteDocument(doc.id),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsList(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final logs = widget.state.auditLogs;
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : AppTheme.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'Chưa có bản ghi nhật ký quản trị nào trong phiên này.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, idx) {
        final log = logs[idx];
        final timeStr =
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            log.action,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.targetType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Admin: ${log.adminEmail}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.details,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
