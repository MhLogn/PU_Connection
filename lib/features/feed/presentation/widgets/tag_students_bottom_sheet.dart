import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../friends/domain/repositories/friend_repository.dart';

class TagStudentsBottomSheet extends StatefulWidget {
  final List<Map<String, String>> initiallyTagged;

  const TagStudentsBottomSheet({super.key, this.initiallyTagged = const []});

  static Future<List<Map<String, String>>?> show(
    BuildContext context, {
    List<Map<String, String>> initiallyTagged = const [],
  }) {
    return showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TagStudentsBottomSheet(initiallyTagged: initiallyTagged),
    );
  }

  @override
  State<TagStudentsBottomSheet> createState() => _TagStudentsBottomSheetState();
}

class _TagStudentsBottomSheetState extends State<TagStudentsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _selected = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallyTagged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleStudent(Map<String, String> student) {
    final id = student['id'] ?? '';
    final idx = _selected.indexWhere((s) => s['id'] == id);
    setState(() {
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(student);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.primaryColor(context),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Gắn thẻ bạn bè',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Xong (${_selected.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _searchController,
              onChanged:
                  (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm trong danh sách bạn bè...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
          ),

          // Selected chips row
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _selected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final s = _selected[idx];
                  return Chip(
                    backgroundColor: AppTheme.blueContainer(context),
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor(context),
                      backgroundImage:
                          (s['avatar'] ?? '').isNotEmpty
                              ? AppTheme.imageProvider(s['avatar']!)
                              : null,
                      child:
                          (s['avatar'] ?? '').isEmpty
                              ? Text(
                                (s['name'] ?? 'P')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    ),
                    label: Text(
                      s['name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => _toggleStudent(s),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Real Friend List Stream
          Expanded(
            child:
                currentUserId.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Vui lòng đăng nhập để xem danh sách bạn bè',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: sl<FriendRepository>().getFriendsStream(
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final friendData = snapshot.data ?? [];

                        if (friendData.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.blueContainer(context),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.group_off_rounded,
                                      size: 36,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Bạn chưa có bạn bè để gắn thẻ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Hãy kết bạn với các sinh viên khác để có thể gắn thẻ họ vào bài viết chia sẻ.',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Map friend entities to widget representation
                        final List<Map<String, String>> studentList =
                            friendData.map((f) {
                              return {
                                'id':
                                    (f['userId'] ?? f['id'] ?? '').toString(),
                                'name':
                                    (f['displayName'] ?? f['name'] ?? '')
                                        .toString(),
                                'studentId':
                                    (f['studentId'] ?? '').toString(),
                                'faculty':
                                    (f['faculty'] ?? 'Phenikaa Uni').toString(),
                                'avatar':
                                    (f['avatarUrl'] ?? f['avatar'] ?? '')
                                        .toString(),
                              };
                            }).toList();

                        final filtered =
                            studentList.where((s) {
                              if (_searchQuery.isEmpty) return true;
                              final n = (s['name'] ?? '').toLowerCase();
                              final sid = (s['studentId'] ?? '').toLowerCase();
                              final f = (s['faculty'] ?? '').toLowerCase();
                              return n.contains(_searchQuery) ||
                                  sid.contains(_searchQuery) ||
                                  f.contains(_searchQuery);
                            }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 36,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Không tìm thấy bạn bè phù hợp',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, __) => Divider(
                                height: 1,
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                          itemBuilder: (ctx, idx) {
                            final s = filtered[idx];
                            final sId = s['id'] ?? '';
                            final isSelected = _selected.any(
                              (m) => m['id'] == sId,
                            );
                            final avatarUrl = s['avatar'] ?? '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    isSelected
                                        ? AppTheme.primaryColor(context)
                                        : AppTheme.blueContainer(context),
                                backgroundImage:
                                    avatarUrl.isNotEmpty
                                        ? AppTheme.imageProvider(avatarUrl)
                                        : null,
                                child:
                                    avatarUrl.isEmpty
                                        ? Text(
                                          (s['name'] ?? 'P')[0].toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : AppTheme.primaryColor(
                                                      context,
                                                    ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              title: Text(
                                s['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                s['faculty']!.isNotEmpty
                                    ? (s['studentId']!.isNotEmpty
                                        ? '${s['studentId']} • ${s['faculty']}'
                                        : s['faculty']!)
                                    : 'Sinh viên Phenikaa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primaryColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) => _toggleStudent(s),
                              ),
                              onTap: () => _toggleStudent(s),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
