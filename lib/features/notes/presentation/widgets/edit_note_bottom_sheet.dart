import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/note_entity.dart';
import '../cubit/notes_cubit.dart';

class EditNoteBottomSheet extends StatefulWidget {
  final NoteEntity note;

  const EditNoteBottomSheet({super.key, required this.note});

  static Future<void> show(BuildContext context, {required NoteEntity note}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<NotesCubit>()),
          BlocProvider.value(value: context.read<AuthCubit>()),
        ],
        child: EditNoteBottomSheet(note: note),
      ),
    );
  }

  @override
  State<EditNoteBottomSheet> createState() => _EditNoteBottomSheetState();
}

class _EditNoteBottomSheetState extends State<EditNoteBottomSheet> {
  late final TextEditingController _contentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nội dung ghi chú không được để trống!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (text.length > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghi chú không được vượt quá 150 ký tự!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Tiền kiểm tra từ ngữ không phù hợp (Bad Words Filter) trước khi lưu ghi chú
    if (sl.isRegistered<BadWordsFilterService>()) {
      final checkResult = sl<BadWordsFilterService>().check(
        text,
        actionLabel: 'chỉnh sửa ghi chú',
      );
      if (!checkResult.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkResult.suggestionMessage ??
                  'Ghi chú chứa từ ngữ không phù hợp với chuẩn mực văn hóa Phenikaa.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<NotesCubit>().updateNote(
        noteId: widget.note.id,
        currentUserId: authState.user.uid,
        newContent: text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật ghi chú thành công!'),
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
                        color: AppTheme.primaryColor(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Chỉnh sửa ghi chú',
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
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
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
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
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
                      'Lưu thay đổi',
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
