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
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const List<ReportReason> _displayReasons = [
    ReportReason.inappropriate,
    ReportReason.spam,
    ReportReason.harassment,
    ReportReason.misinformation,
    ReportReason.academicDishonesty,
    ReportReason.other,
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Vui lòng chọn một lý do báo cáo vi phạm trước khi gửi.',
          ),
          backgroundColor: AppTheme.accentColor(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thực hiện báo cáo!'),
        ),
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
      reason: _selectedReason!,
      details: _detailsController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await context.read<ModerationCubit>().submitReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Đã gửi báo cáo vi phạm. Cảm ơn bạn đã giữ gìn cộng đồng Phenikaa văn minh!',
            ),
            backgroundColor: AppTheme.primaryColor(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: AppTheme.accentOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Báo cáo ${widget.targetType.displayName.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.deepBlue,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Hãy chọn lý do vi phạm tiêu chuẩn cộng đồng sinh viên Phenikaa:',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 14),

            // Radio choices of reasons
            ..._displayReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor(context).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor(context).withValues(alpha: 0.4)
                        : (isDark ? Colors.white12 : AppTheme.borderLight),
                    width: 0.9,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppTheme.primaryColor(context)
                              : colorScheme.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason.displayName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? (isDark ? Colors.white : AppTheme.deepBlue)
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Mô tả thêm chi tiết vi phạm (không bắt buộc)...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : AppTheme.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor(context),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                disabledBackgroundColor: AppTheme.primaryColor(
                  context,
                ).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi báo cáo vi phạm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
