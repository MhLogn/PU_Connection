import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../pages/chat_detail_page.dart';

class NewChatBottomSheet extends StatefulWidget {
  const NewChatBottomSheet({super.key});

  @override
  State<NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<Map<String, String>> _mockStudents = [
    {
      'id': 'pu_student_1',
      'name': 'Nguyễn Văn An',
      'studentId': '23010101',
      'faculty': 'CNTT',
      'major': 'Khoa học máy tính',
    },
    {
      'id': 'pu_student_2',
      'name': 'Trần Thị Mai',
      'studentId': '23010202',
      'faculty': 'Dược - Y',
      'major': 'Dược học',
    },
    {
      'id': 'pu_student_3',
      'name': 'Lê Hoàng Nam',
      'studentId': '23010303',
      'faculty': 'Kinh tế & QTKD',
      'major': 'Quản trị kinh doanh',
    },
    {
      'id': 'pu_student_4',
      'name': 'Phạm Thu Trang',
      'studentId': '23010404',
      'faculty': 'Ngôn ngữ Anh',
      'major': 'Tiếng Anh thương mại',
    },
    {
      'id': 'pu_student_5',
      'name': 'Đỗ Minh Đức',
      'studentId': '23010505',
      'faculty': 'Kỹ thuật Ô tô',
      'major': 'Cơ điện tử ô tô',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChatWith({
    required String targetUserId,
    required String targetUserName,
    required String targetUserFaculty,
    String targetUserAvatar = '',
  }) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.uid;
    final currentUserName = authState.user.displayName.isNotEmpty
        ? authState.user.displayName
        : 'Sinh viên Phenikaa';
    final currentUserAvatar = authState.user.avatarUrl;
    final currentUserFaculty = authState.user.faculty;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (targetUserId == currentUserId) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Không thể tự nhắn tin cho chính mình!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chatCubit = context.read<ChatCubit>();
      final convId = await chatCubit.startDirectChat(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        currentUserFaculty: currentUserFaculty,
        otherUserId: targetUserId,
        otherUserName: targetUserName,
        otherUserAvatar: targetUserAvatar,
        otherUserFaculty: targetUserFaculty,
      );

      if (!mounted) return;

      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: convId,
            otherUserId: targetUserId,
            otherUserName: targetUserName,
            otherUserAvatar: targetUserAvatar,
            otherUserFaculty: targetUserFaculty,
            participantIds: [currentUserId, targetUserId]..sort(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo cuộc trò chuyện: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    final filteredMock = _mockStudents.where((s) {
      if (_searchQuery.isEmpty) return true;
      final name = (s['name'] ?? '').toLowerCase();
      final id = (s['studentId'] ?? '').toLowerCase();
      final faculty = (s['faculty'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || id.contains(_searchQuery) || faculty.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_comment_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cuộc trò chuyện mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Tìm theo Tên hoặc MSSV...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor(context),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.phenikaaStudentsCollection)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, String>> students = filteredMock;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final liveList = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['fullName'] as String? ?? data['name'] as String? ?? 'Sinh viên Phenikaa',
                      'studentId': data['studentId'] as String? ?? '',
                      'faculty': data['faculty'] as String? ?? '',
                      'major': data['major'] as String? ?? '',
                    };
                  }).toList();

                  if (_searchQuery.isNotEmpty) {
                    students = liveList.where((s) {
                      final name = (s['name'] ?? '').toLowerCase();
                      final id = (s['studentId'] ?? '').toLowerCase();
                      final faculty = (s['faculty'] ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          id.contains(_searchQuery) ||
                          faculty.contains(_searchQuery);
                    }).toList();
                  } else {
                    students = liveList;
                  }
                }

                if (students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 48, color: colorScheme.outline),
                          const SizedBox(height: 10),
                          Text(
                            'Không tìm thấy sinh viên phù hợp',
                            style: TextStyle(color: colorScheme.outline, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final name = student['name'] ?? 'Sinh viên';
                    final studentId = student['studentId'] ?? '';
                    final faculty = student['faculty'] ?? '';
                    final targetId = student['id'] ?? studentId;

                    final initials = name.isNotEmpty
                        ? name.trim().split(' ').last[0].toUpperCase()
                        : 'P';

                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.blueContainer(context),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: AppTheme.primaryColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          'MSSV: $studentId • $faculty',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.primaryColor(context),
                          size: 20,
                        ),
                        onTap: () => _startChatWith(
                          targetUserId: targetId,
                          targetUserName: name,
                          targetUserFaculty: faculty,
                        ),
                      ),
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
