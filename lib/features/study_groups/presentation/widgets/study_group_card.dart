import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/study_group_entity.dart';
import '../cubit/study_group_cubit.dart';
import '../pages/study_group_detail_page.dart';

class StudyGroupCard extends StatelessWidget {
  final StudyGroupEntity group;
  final String currentUserId;

  const StudyGroupCard({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán') || s.contains('giải tích') || s.contains('đại số')) {
      return const Color(0xFF0284C7); // Blue
    } else if (s.contains('lập trình') || s.contains('it') || s.contains('code') || s.contains('flutter')) {
      return const Color(0xFF10B981); // Emerald Green
    } else if (s.contains('anh') || s.contains('toeic') || s.contains('ielts')) {
      return const Color(0xFFF97316); // Orange
    } else if (s.contains('kinh tế') || s.contains('marketing') || s.contains('quản trị')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    return const Color(0xFF0EA5E9);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjectColor = _getSubjectColor(group.subject);
    final isCreator = group.isCreator(currentUserId);
    final isMember = group.isMember(currentUserId);
    final hasRequested = group.hasRequested(currentUserId);
    final isFull = group.isFull;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyGroupDetailPage(
                  group: group,
                  currentUserId: currentUserId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Subject Tag + Member count badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: subjectColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 14, color: subjectColor),
                          const SizedBox(width: 5),
                          Text(
                            group.subject,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: subjectColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isFull
                            ? Colors.red.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 15,
                            color: isFull ? Colors.red : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.currentMembersCount}/${group.maxMembers} thành viên',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Group Title
                Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  group.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Schedule & Location Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(group.studyTime),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Row: Creator info & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Creator info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: subjectColor.withValues(alpha: 0.15),
                          backgroundImage: (group.creatorAvatar != null && group.creatorAvatar!.isNotEmpty)
                              ? NetworkImage(group.creatorAvatar!)
                              : null,
                          child: (group.creatorAvatar == null || group.creatorAvatar!.isEmpty)
                              ? Text(
                                  group.creatorName.isNotEmpty ? group.creatorName[0].toUpperCase() : 'U',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subjectColor),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.creatorName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Trưởng nhóm',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Action Button
                    if (isCreator)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyGroupDetailPage(
                                group: group,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_rounded, size: 15),
                        label: const Text('Quản lý', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    else if (isMember)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyGroupDetailPage(
                                group: group,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
                        label: const Text('Đã tham gia', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    else if (hasRequested)
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<StudyGroupCubit>().cancelRequest(group.id, currentUserId);
                        },
                        icon: const Icon(Icons.close_rounded, size: 15, color: Colors.orange),
                        label: const Text('Hủy yêu cầu', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    else if (isFull)
                      FilledButton.tonal(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Nhóm đã đầy', style: TextStyle(fontSize: 12)),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () {
                          context.read<StudyGroupCubit>().requestToJoin(group.id, currentUserId);
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 15),
                        label: const Text('Xin gia nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
