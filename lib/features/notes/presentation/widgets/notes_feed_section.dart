import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../clubs/presentation/cubit/club_cubit.dart';
import '../../../friends/presentation/cubit/friendship_cubit.dart';
import '../../domain/entities/note_entity.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import 'create_note_bottom_sheet.dart';
import 'edit_note_bottom_sheet.dart';

class NotesFeedSection extends StatelessWidget {
  const NotesFeedSection({super.key});

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }

  void _showNoteDetail(BuildContext context, NoteEntity note, bool isAuthor) {
    final isDark = AppTheme.isDark(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<NotesCubit>()),
          BlocProvider.value(value: context.read<AuthCubit>()),
        ],
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor(ctx),
                    child: Text(
                      note.authorName.isNotEmpty
                          ? note.authorName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.authorName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.deepBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              note.audience == 'club'
                                  ? Icons.groups_outlined
                                  : Icons.people_outline_rounded,
                              size: 13,
                              color: note.audience == 'club'
                                  ? AppTheme.accentOrange
                                  : AppTheme.primaryColor(ctx),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.audience == 'club'
                                  ? (note.clubName ?? 'Câu lạc bộ')
                                  : 'Bạn bè',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: note.audience == 'club'
                                    ? AppTheme.accentOrange
                                    : AppTheme.primaryColor(ctx),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${_formatTimeAgo(note.createdAt)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppTheme.canvasLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isAuthor) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor(ctx),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          EditNoteBottomSheet.show(context, note: note);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                        label: Text(
                          'Xóa ghi chú',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa ghi chú này không?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            try {
                              await context.read<NotesCubit>().deleteNote(
                                noteId: note.id,
                                currentUserId: note.authorId,
                              );
                            } catch (_) {}
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserName = authState is Authenticated
        ? authState.user.displayName
        : '';

    final friendState = context.watch<FriendshipCubit>().state;
    final friendIds = friendState.friendsList
        .map((f) => f['userId'].toString())
        .toSet();

    final clubState = context.watch<ClubCubit>().state;
    final userClubIds = clubState.clubs
        .where((c) => c.isMember(currentUserId))
        .map((c) => c.id)
        .toSet();

    final notesState = context.watch<NotesCubit>().state;
    final visibleNotes = notesState.getVisibleNotes(
      currentUserId: currentUserId,
      friendUserIds: friendIds,
      userClubIds: userClubIds,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Title & Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 16,
                      color: AppTheme.accentOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ghi chú sinh viên',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.deepBlue,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Filter Chips (Tất cả, Bạn bè, Câu lạc bộ)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          )
                        : const Color(0xFFEAEFF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: NotesFilter.values.map((filter) {
                      final isSelected = notesState.filter == filter;
                      return GestureDetector(
                        onTap: () =>
                            context.read<NotesCubit>().setFilter(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (filter == NotesFilter.club
                                      ? AppTheme.accentOrange
                                      : AppTheme.primaryColor(context))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            filter.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal list of Notes
          SizedBox(
            height: 122,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount:
                  1 +
                  (visibleNotes.isEmpty
                      ? 1
                      : visibleNotes.length), // 1 is create card
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // First item is always Create Note Card
                if (index == 0) {
                  return _buildCreateNoteCard(
                    context,
                    currentUserName,
                    isDark,
                    colorScheme,
                  );
                }

                // If empty state for this filter
                if (visibleNotes.isEmpty) {
                  return _buildEmptyFilterCard(
                    context,
                    notesState.filter,
                    isDark,
                    colorScheme,
                  );
                }

                final note = visibleNotes[index - 1];
                final isMyNote = note.authorId == currentUserId;
                return _buildNoteCard(
                  context,
                  note,
                  isMyNote,
                  isDark,
                  colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNoteCard(
    BuildContext context,
    String currentUserName,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => CreateNoteBottomSheet.show(context),
      child: Container(
        width: 105,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor(context).withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x06123B63),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.primaryColor(
                    context,
                  ).withValues(alpha: 0.15),
                  child: Text(
                    currentUserName.isNotEmpty
                        ? currentUserName[0].toUpperCase()
                        : '+',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Để lại Note',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.deepBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Chia sẻ nhanh',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterCard(
    BuildContext context,
    NotesFilter filter,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    String msg;
    if (filter == NotesFilter.club) {
      msg = 'Chưa có ghi chú từ CLB bạn tham gia';
    } else if (filter == NotesFilter.friends) {
      msg = 'Chưa có ghi chú từ bạn bè';
    } else {
      msg = 'Chưa có ghi chú nào';
    }

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : AppTheme.borderLight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter == NotesFilter.club
                ? Icons.groups_outlined
                : Icons.people_outline_rounded,
            size: 22,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 6),
          Text(
            msg,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    NoteEntity note,
    bool isMyNote,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isClub = note.audience == 'club';

    return GestureDetector(
      onTap: () => _showNoteDetail(context, note, isMyNote),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMyNote
                ? AppTheme.primaryColor(context).withValues(alpha: 0.4)
                : (isDark ? Colors.white12 : AppTheme.borderLight),
            width: isMyNote ? 1.2 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x06123B63),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar + Name + Audience Icon
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: isClub
                      ? AppTheme.accentOrange
                      : AppTheme.primaryColor(context),
                  child: Text(
                    note.authorName.isNotEmpty
                        ? note.authorName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isMyNote ? 'Bạn' : note.authorName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.deepBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isClub ? Icons.groups_outlined : Icons.people_outline_rounded,
                  size: 13,
                  color: isClub
                      ? AppTheme.accentOrange
                      : AppTheme.primaryColor(context),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Content
            Expanded(
              child: Text(
                note.content,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: colorScheme.onSurface.withValues(alpha: 0.88),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // Bottom row: Timeago and Club tag / Owner indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isClub && note.clubName != null)
                  Expanded(
                    child: Text(
                      note.clubName!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  _formatTimeAgo(note.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
