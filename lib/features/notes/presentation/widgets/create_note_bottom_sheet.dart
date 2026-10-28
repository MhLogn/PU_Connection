import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../clubs/domain/entities/club_entity.dart';
import '../../../clubs/presentation/cubit/club_cubit.dart';
import '../cubit/notes_cubit.dart';

class CreateNoteBottomSheet extends StatefulWidget {
  const CreateNoteBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<NotesCubit>()),
          BlocProvider.value(value: context.read<ClubCubit>()),
          BlocProvider.value(value: context.read<AuthCubit>()),
        ],
        child: const CreateNoteBottomSheet(),
      ),
    );
  }

  @override
  State<CreateNoteBottomSheet> createState() => _CreateNoteBottomSheetState();
}

class _CreateNoteBottomSheetState extends State<CreateNoteBottomSheet> {
  final TextEditingController _contentController = TextEditingController();
  String _audience = 'friends'; // 'friends' | 'club'
  ClubEntity? _selectedClub;
  String? _clubValidationError;
  bool _isSubmitting = false;

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
          content: Text('Vui lòng nhập nội dung ghi chú!'),
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

    // Tiền kiểm tra từ ngữ không phù hợp (Bad Words Filter) trước khi chia sẻ ghi chú
    if (sl.isRegistered<BadWordsFilterService>()) {
      final checkResult = sl<BadWordsFilterService>().check(
        text,
        actionLabel: 'chia sẻ ghi chú',
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
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để tạo ghi chú!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = authState.user;

    if (_audience == 'club') {
      if (_selectedClub == null) {
        setState(() {
          _clubValidationError = 'Vui lòng chọn Câu lạc bộ để chia sẻ ghi chú!';
        });
        return;
      }
      final isMember = _selectedClub!.isMember(user.uid, user.studentId);
      if (!isMember) {
        setState(() {
          _clubValidationError =
              'Bạn chưa tham gia Câu lạc bộ "${_selectedClub!.name}". Chỉ thành viên chính thức mới có quyền đăng Note cho CLB này.';
        });
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<NotesCubit>().createNote(
        authorId: user.uid,
        authorName: user.displayName.isNotEmpty
            ? user.displayName
            : 'Sinh viên PU',
        authorAvatar: user.avatarUrl,
        authorFaculty: user.faculty,
        content: text,
        audience: _audience,
        clubId: _audience == 'club' ? _selectedClub?.id : null,
        clubName: _audience == 'club' ? _selectedClub?.name : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã chia sẻ ghi chú lên PU Connection!'),
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

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserStudentId =
        authState is Authenticated ? authState.user.studentId : '';

    final clubCubitState = context.watch<ClubCubit>().state;
    final allClubs = clubCubitState.clubs;
    final joinedClubs = allClubs
        .where((c) => c.isMember(currentUserId, currentUserStudentId))
        .toList();

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
            // Header
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
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tạo ghi chú mới (Note)',
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
            const SizedBox(height: 8),
            Text(
              'Chia sẻ trạng thái ngắn gọn đến bạn bè hoặc CLB (tối đa 150 ký tự)',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Audience selector
            Text(
              'Phạm vi hiển thị:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppTheme.deepBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _audience = 'friends';
                      _clubValidationError = null;
                    }),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _audience == 'friends'
                            ? AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _audience == 'friends'
                              ? AppTheme.primaryColor(context)
                              : (isDark
                                    ? Colors.white12
                                    : AppTheme.borderLight),
                          width: _audience == 'friends' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 18,
                            color: _audience == 'friends'
                                ? AppTheme.primaryColor(context)
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bạn bè',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _audience == 'friends'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _audience == 'friends'
                                  ? AppTheme.primaryColor(context)
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _audience = 'club';
                        _selectedClub ??= (joinedClubs.isNotEmpty
                            ? joinedClubs.first
                            : (allClubs.isNotEmpty ? allClubs.first : null));
                        if (_selectedClub == null) {
                          _clubValidationError =
                              'Chưa có dữ liệu câu lạc bộ. Vui lòng kiểm tra kết nối mạng.';
                        } else if (!_selectedClub!.isMember(
                          currentUserId,
                          currentUserStudentId,
                        )) {
                          _clubValidationError =
                              'Bạn chưa tham gia Câu lạc bộ "${_selectedClub!.name}". Chỉ thành viên chính thức mới có quyền đăng Note cho CLB này.';
                        } else {
                          _clubValidationError = null;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _audience == 'club'
                            ? AppTheme.accentOrange.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _audience == 'club'
                              ? AppTheme.accentOrange
                              : (isDark
                                    ? Colors.white12
                                    : AppTheme.borderLight),
                          width: _audience == 'club' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 18,
                            color: _audience == 'club'
                                ? AppTheme.accentOrange
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Câu lạc bộ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _audience == 'club'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _audience == 'club'
                                  ? AppTheme.accentOrange
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_audience == 'club') ...[
              const SizedBox(height: 12),
              if (allClubs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Đang tải danh sách câu lạc bộ...',
                    style: TextStyle(fontSize: 12.5),
                  ),
                )
              else
                DropdownButtonFormField<ClubEntity>(
                  value: _selectedClub ??
                      (joinedClubs.isNotEmpty
                          ? joinedClubs.first
                          : allClubs.first),
                  decoration: InputDecoration(
                    labelText: 'Chọn CLB chia sẻ',
                    labelStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: allClubs.map((club) {
                    final isMember = club.isMember(
                      currentUserId,
                      currentUserStudentId,
                    );
                    return DropdownMenuItem<ClubEntity>(
                      value: club,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              club.name,
                              style: const TextStyle(fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isMember)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Chưa tham gia',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Thành viên',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final isMember = val.isMember(
                        currentUserId,
                        currentUserStudentId,
                      );
                      setState(() {
                        _selectedClub = val;
                        if (!isMember) {
                          _clubValidationError =
                              'Bạn chưa tham gia Câu lạc bộ "${val.name}". Chỉ thành viên chính thức mới có quyền đăng Note cho CLB này.';
                        } else {
                          _clubValidationError = null;
                        }
                      });
                    }
                  },
                ),
              if (_clubValidationError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _clubValidationError!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Content text area
            TextField(
              controller: _contentController,
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
                hintText:
                    'Hôm nay bạn đang học môn gì? Có thông báo gì mới muốn gửi đến mọi người?...',
                hintStyle: TextStyle(
                  fontSize: 13,
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

            // Submit Button
            FilledButton(
              onPressed: (_isSubmitting ||
                      (_audience == 'club' && _clubValidationError != null))
                  ? null
                  : _submit,
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
                      'Đăng ghi chú',
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
