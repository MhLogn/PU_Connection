import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';

class TagStudentsBottomSheet extends StatefulWidget {
  final List<Map<String, String>> initiallyTagged;

  const TagStudentsBottomSheet({
    super.key,
    this.initiallyTagged = const [],
  });

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

  final List<Map<String, String>> _mockStudents = [
    {
      'id': 'pu_student_1',
      'name': 'Nguyễn Văn An',
      'studentId': '23010101',
      'faculty': 'CNTT',
      'avatar': '',
    },
    {
      'id': 'pu_student_2',
      'name': 'Trần Thị Mai',
      'studentId': '23010202',
      'faculty': 'Dược - Y',
      'avatar': '',
    },
    {
      'id': 'pu_student_3',
      'name': 'Lê Hoàng Nam',
      'studentId': '23010303',
      'faculty': 'Kinh tế & QTKD',
      'avatar': '',
    },
    {
      'id': 'pu_student_4',
      'name': 'Phạm Thu Trang',
      'studentId': '23010404',
      'faculty': 'Ngôn ngữ Anh',
      'avatar': '',
    },
    {
      'id': 'pu_student_5',
      'name': 'Đỗ Minh Đức',
      'studentId': '23010505',
      'faculty': 'Kỹ thuật Ô tô',
      'avatar': '',
    },
    {
      'id': 'pu_student_6',
      'name': 'Hoàng Phương Thảo',
      'studentId': '23010606',
      'faculty': 'CNTT',
      'avatar': '',
    },
  ];

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppTheme.accentColor(context),
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Xong (${_selected.length})'),
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
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã sinh viên...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                      child: Text(
                        (s['name'] ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

          // Student list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.usersCollection)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                final List<Map<String, String>> studentList = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['displayName'] ?? '').toString();
                    if (name.isNotEmpty) {
                      studentList.add({
                        'id': doc.id,
                        'name': name,
                        'studentId': (data['studentId'] ?? '').toString(),
                        'faculty': (data['faculty'] ?? '').toString(),
                        'avatar': (data['avatarUrl'] ?? '').toString(),
                      });
                    }
                  }
                }

                // Add fallback mock students if not already present
                for (final mock in _mockStudents) {
                  if (!studentList.any((s) => s['id'] == mock['id'])) {
                    studentList.add(mock);
                  }
                }

                final filtered = studentList.where((s) {
                  if (_searchQuery.isEmpty) return true;
                  final n = (s['name'] ?? '').toLowerCase();
                  final sid = (s['studentId'] ?? '').toLowerCase();
                  final f = (s['faculty'] ?? '').toLowerCase();
                  return n.contains(_searchQuery) ||
                      sid.contains(_searchQuery) ||
                      f.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không tìm thấy sinh viên phù hợp'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                  itemBuilder: (ctx, idx) {
                    final s = filtered[idx];
                    final sId = s['id'] ?? '';
                    final isSelected = _selected.any((m) => m['id'] == sId);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected
                            ? AppTheme.accentColor(context)
                            : AppTheme.blueContainer(context),
                        child: Text(
                          (s['name'] ?? 'P')[0].toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        s['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${s['studentId']} • ${s['faculty']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.accentColor(context),
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
