import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_target_type.dart';
import '../cubit/moderation_cubit.dart';

class ReportBottomSheet extends StatefulWidget {
  final String targetId;
  final ReportTargetType targetType;
  final String targetAuthorId;
  final String targetAuthorName;

  const ReportBottomSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetAuthorId,
    this.targetAuthorName = '',
  });

  static Future<void> show(
    BuildContext context, {
    required String targetId,
    required ReportTargetType targetType,
    required String targetAuthorId,
    String targetAuthorName = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ModerationCubit>(),
        child: ReportBottomSheet(
          targetId: targetId,
          targetType: targetType,
          targetAuthorId: targetAuthorId,
          targetAuthorName: targetAuthorName,
        ),
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  ReportReason _selectedReason = ReportReason.spam;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thực hiện báo cáo!')),
      );
      return;
    }

    final reporter = authState.user;
    setState(() => _isSubmitting = true);

    final report = ReportEntity(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}_${reporter.uid}',
      reporterId: reporter.uid,
      reporterName: reporter.displayName,
      targetId: widget.targetId,
      targetType: widget.targetType,
      targetAuthorId: widget.targetAuthorId,
      targetAuthorName: widget.targetAuthorName,
      reason: _selectedReason,
      details: _detailsController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await context.read<ModerationCubit>().submitReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã gửi báo cáo vi phạm. Cảm ơn bạn đã giữ gìn cộng đồng Phenikaa văn minh!'),
            backgroundColor: AppTheme.primaryColor(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi báo cáo: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Báo cáo ${widget.targetType.displayName.toLowerCase()}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy chọn lý do vi phạm tiêu chuẩn cộng đồng trường Đại học Phenikaa:',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),

            // Radio choices of reasons
            ...ReportReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppTheme.primaryColor(context) : colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reason.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Mô tả thêm chi tiết vi phạm (không bắt buộc)...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),

            FilledButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi báo cáo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
