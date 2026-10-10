import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/moderation_cubit.dart';
import '../cubit/moderation_state.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final currentUid = authState is Authenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Người dùng đã chặn', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<ModerationCubit, ModerationState>(
        listener: (context, state) {
          if (state.message != null && state.status == ModerationActionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.primaryColor(context),
                duration: const Duration(seconds: 2),
              ),
            );
            context.read<ModerationCubit>().clearMessage();
          }
        },
        builder: (context, state) {
          final blockedUsers = state.blockedUsers;

          if (blockedUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block_flipped,
                        size: 52,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Danh sách chặn trống',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Khi bạn chặn người dùng nào đó, họ sẽ xuất hiện tại đây và bạn có thể bỏ chặn bất kỳ lúc nào.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blockedUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: user.userAvatar.isNotEmpty ? NetworkImage(user.userAvatar) : null,
                      child: user.userAvatar.isEmpty
                          ? Text(
                              user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.userFaculty.isNotEmpty ? user.userFaculty : 'Sinh viên Phenikaa',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Bỏ chặn người dùng?'),
                            content: Text('Bạn có chắc chắn muốn bỏ chặn ${user.userName}? Họ sẽ có thể xem lại bài viết và nhắn tin cho bạn.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<ModerationCubit>().unblockUser(
                                        currentUserId: currentUid,
                                        blockedUserId: user.userId,
                                      );
                                },
                                child: const Text('Bỏ chặn'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Bỏ chặn', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
