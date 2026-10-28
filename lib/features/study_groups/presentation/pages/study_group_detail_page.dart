import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/datasources/phenikaa_student_directory.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../domain/entities/study_group_entity.dart';
import '../cubit/study_group_cubit.dart';
import '../cubit/study_group_state.dart';

class StudyGroupDetailPage extends StatelessWidget {
  final StudyGroupEntity group;
  final String currentUserId;

  const StudyGroupDetailPage({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • Ngày ${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, String> _getStudentInfo(String id) {
    final s = PhenikaaStudentDirectory.getStudentById(id);
    if (s != null) {
      return {
        'name': s.fullName,
        'faculty': s.faculty,
        'studentId': s.studentId,
      };
    }
    return {
      'name': 'Sinh viên Phenikaa ($id)',
      'faculty': 'Đại học Phenikaa',
      'studentId': id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<StudyGroupCubit, StudyGroupState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colorScheme.error,
            ),
          );
          context.read<StudyGroupCubit>().clearMessage();
        } else if (state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          context.read<StudyGroupCubit>().clearMessage();
        }
      },
      builder: (context, state) {
        // Lấy dữ liệu live mới nhất của group từ state nếu có
        final matchingGroups = state.groups.where((g) => g.id == group.id);
        final currentGroup = matchingGroups.isNotEmpty
            ? matchingGroups.first
            : group;

        final isCreator = currentGroup.isCreator(currentUserId);
        final isMember = currentGroup.isMember(currentUserId);
        final hasRequested = currentGroup.hasRequested(currentUserId);
        final isFull = currentGroup.isFull;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: const Text(
              'Chi tiết nhóm học',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            elevation: 0,
            scrolledUnderElevation: 1,
            actions: [
              if (isCreator && currentGroup.isOpen)
                IconButton(
                  icon: const Icon(Icons.lock_outline_rounded),
                  tooltip: 'Đóng nhóm',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        title: const Text('Đóng nhóm học tập'),
                        content: const Text(
                          'Bạn có chắc muốn đóng nhóm này? Nhóm sẽ không nhận thêm thành viên mới.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<StudyGroupCubit>().closeGroup(
                                currentGroup.id,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Tag + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentGroup.subject,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentGroup.isOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentGroup.isOpen
                            ? 'Đang nhận thành viên'
                            : 'Đã đóng',
                        style: TextStyle(
                          color: currentGroup.isOpen
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  currentGroup.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Description Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    currentGroup.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Thông tin chi tiết buổi học (Thời gian, địa điểm, slot)
                const Text(
                  'Kế hoạch học tập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thời gian dự kiến',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(currentGroup.studyTime),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Địa điểm học',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  currentGroup.location,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.group_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quy mô nhóm',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${currentGroup.currentMembersCount} / ${currentGroup.maxMembers} thành viên',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Trưởng nhóm
                const Text(
                  'Người tạo nhóm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(
                      0xFF0284C7,
                    ).withValues(alpha: 0.15),
                    backgroundImage:
                        (currentGroup.creatorAvatar != null &&
                            currentGroup.creatorAvatar!.isNotEmpty)
                        ? NetworkImage(currentGroup.creatorAvatar!)
                        : null,
                    child:
                        (currentGroup.creatorAvatar == null ||
                            currentGroup.creatorAvatar!.isEmpty)
                        ? Text(
                            currentGroup.creatorName.isNotEmpty
                                ? currentGroup.creatorName[0].toUpperCase()
                                : 'U',
                          )
                        : null,
                  ),
                  title: Text(
                    currentGroup.creatorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${currentGroup.creatorFaculty.isNotEmpty ? currentGroup.creatorFaculty : 'Đại học Phenikaa'} • MSSV: ${currentGroup.creatorStudentId.isNotEmpty ? currentGroup.creatorStudentId : currentGroup.creatorId}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.star_rounded, color: Colors.amber),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userId: currentGroup.creatorId,
                          userName: currentGroup.creatorName,
                          studentId: currentGroup.creatorStudentId,
                          faculty: currentGroup.creatorFaculty,
                          avatarUrl: currentGroup.creatorAvatar ?? '',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Danh sách thành viên
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thành viên (${currentGroup.memberIds.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tối đa ${currentGroup.maxMembers} bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentGroup.memberIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final memberId = currentGroup.memberIds[index];
                    final info = _getStudentInfo(memberId);
                    final isLead = memberId == currentGroup.creatorId;

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          width: 0.8,
                        ),
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          info['name']!.isNotEmpty
                              ? info['name']![0].toUpperCase()
                              : 'S',
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              info['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isLead) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Trưởng nhóm',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        info['faculty']!,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(
                              userId: memberId,
                              userName: info['name']!,
                              studentId: info['studentId']!,
                              faculty: info['faculty']!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Yêu cầu chờ duyệt (Chỉ hiển thị cho Trưởng nhóm)
                if (isCreator && currentGroup.pendingRequestIds.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.notification_important_rounded,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yêu cầu xin gia nhập (${currentGroup.pendingRequestIds.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentGroup.pendingRequestIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reqUserId = currentGroup.pendingRequestIds[index];
                      final info = _getStudentInfo(reqUserId);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              child: Text(info['name']![0].toUpperCase()),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info['name']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    info['faculty']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                              tooltip: 'Duyệt vào nhóm',
                              onPressed: () {
                                context.read<StudyGroupCubit>().acceptRequest(
                                  currentGroup.id,
                                  reqUserId,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                              tooltip: 'Từ chối',
                              onPressed: () {
                                context.read<StudyGroupCubit>().rejectRequest(
                                  currentGroup.id,
                                  reqUserId,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Footer
                const SizedBox(height: 10),
                if (!isCreator && isMember)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<StudyGroupCubit>().leaveGroup(
                          currentGroup.id,
                          currentUserId,
                        );
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text(
                        'Rời khỏi nhóm này',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (!isCreator && hasRequested)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<StudyGroupCubit>().cancelRequest(
                          currentGroup.id,
                          currentUserId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        'Hủy yêu cầu tham gia',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (!isCreator && !isFull && currentGroup.isOpen)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<StudyGroupCubit>().requestToJoin(
                          currentGroup.id,
                          currentUserId,
                        );
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text(
                        'Gửi yêu cầu gia nhập nhóm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
