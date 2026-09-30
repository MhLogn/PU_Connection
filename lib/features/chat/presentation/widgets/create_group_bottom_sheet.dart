import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../pages/chat_detail_page.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _selectedMembers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  final List<Map<String, String>> _mockStudents = [
    {
      'id': 'pu_student_1',
      'name': 'Nguyễn Văn An',
      'studentId': '23010101',
      'faculty': 'CNTT',
      'major': 'Khoa học máy tính',
      'avatar': '',
    },
    {
      'id': 'pu_student_2',
      'name': 'Trần Thị Mai',
      'studentId': '23010202',
      'faculty': 'Dược - Y',
      'major': 'Dược học',
      'avatar': '',
    },
    {
      'id': 'pu_student_3',
      'name': 'Lê Hoàng Nam',
      'studentId': '23010303',
      'faculty': 'Kinh tế & QTKD',
      'major': 'Quản trị kinh doanh',
      'avatar': '',
    },
    {
      'id': 'pu_student_4',
      'name': 'Phạm Thu Trang',
      'studentId': '23010404',
      'faculty': 'Ngôn ngữ Anh',
      'major': 'Tiếng Anh thương mại',
      'avatar': '',
    },
    {
      'id': 'pu_student_5',
      'name': 'Đỗ Minh Đức',
      'studentId': '23010505',
      'faculty': 'Kỹ thuật Ô tô',
      'major': 'Cơ điện tử ô tô',
      'avatar': '',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleMember(Map<String, String> student) {
    final sId = student['id'] ?? '';
    final existingIndex = _selectedMembers.indexWhere((m) => m['id'] == sId);
    setState(() {
      if (existingIndex >= 0) {
        _selectedMembers.removeAt(existingIndex);
      } else {
        _selectedMembers.add(student);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nhóm trò chuyện')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thành viên cho nhóm')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.uid;
    final currentUserName = authState.user.displayName.isNotEmpty
        ? authState.user.displayName
        : 'Sinh viên Phenikaa';
    final currentUserAvatar = authState.user.avatarUrl;
    final currentUserFaculty = authState.user.faculty;

    setState(() => _isLoading = true);

    try {
      final chatCubit = context.read<ChatCubit>();
      final convId = await chatCubit.createGroupConversation(
        groupName: groupName,
        creatorId: currentUserId,
        creatorName: currentUserName,
        creatorAvatar: currentUserAvatar,
        creatorFaculty: currentUserFaculty,
        members: _selectedMembers,
      );

      if (!mounted) return;

      final allParticipantIds = [
        currentUserId,
        ..._selectedMembers.map((m) => m['id'] ?? ''),
      ];

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: convId,
            isGroup: true,
            groupName: groupName,
            otherUserId: '',
            otherUserName: groupName,
            participantIds: allParticipantIds,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo nhóm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.group_add_rounded,
                        color: AppTheme.primaryColor(context),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tạo nhóm trò chuyện',
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Đặt tên nhóm (vd: K17 CNTT, Đồ án tốt nghiệp...)',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.groups_rounded,
                    color: AppTheme.accentColor(context),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (_selectedMembers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Thành viên đã chọn (${_selectedMembers.length}):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor(context),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final member = _selectedMembers[index];
                  return Chip(
                    backgroundColor: AppTheme.blueContainer(context),
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor(context),
                      child: Text(
                        member['name']?.isNotEmpty == true
                            ? member['name']!.trim().split(' ').last[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    label: Text(
                      member['name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    deleteIconColor: AppTheme.primaryColor(context),
                    onDeleted: () => _toggleMember(member),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sinh viên thêm vào nhóm...',
                  hintStyle: TextStyle(
                    fontSize: 13,
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.phenikaaStudentsCollection)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, String>> students = _mockStudents;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final liveList = snapshot.data!.docs
                      .where((doc) => doc.id != currentUserId)
                      .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['fullName'] as String? ?? data['name'] as String? ?? 'Sinh viên Phenikaa',
                      'studentId': data['studentId'] as String? ?? '',
                      'faculty': data['faculty'] as String? ?? '',
                      'major': data['major'] as String? ?? '',
                      'avatar': data['avatarUrl'] as String? ?? '',
                    };
                  }).toList();

                  students = liveList;
                }

                final filteredList = students.where((s) {
                  if (s['id'] == currentUserId) return false;
                  if (_searchQuery.isEmpty) return true;
                  final name = (s['name'] ?? '').toLowerCase();
                  final id = (s['studentId'] ?? '').toLowerCase();
                  final faculty = (s['faculty'] ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      id.contains(_searchQuery) ||
                      faculty.contains(_searchQuery);
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 44, color: colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Không tìm thấy sinh viên',
                            style: TextStyle(color: colorScheme.outline, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final student = filteredList[index];
                    final sId = student['id'] ?? '';
                    final name = student['name'] ?? 'Sinh viên';
                    final studentId = student['studentId'] ?? '';
                    final faculty = student['faculty'] ?? '';
                    final isSelected = _selectedMembers.any((m) => m['id'] == sId);

                    final initials = name.isNotEmpty
                        ? name.trim().split(' ').last[0].toUpperCase()
                        : 'P';

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor(context).withValues(alpha: 0.06)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor(context).withValues(alpha: 0.5)
                              : colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleMember(student),
                        activeColor: AppTheme.primaryColor(context),
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        secondary: CircleAvatar(
                          radius: 19,
                          backgroundColor: isSelected
                              ? AppTheme.primaryColor(context)
                              : AppTheme.blueContainer(context),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.primaryColor(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'MSSV: $studentId • $faculty',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _nameController.text.trim().isEmpty || _selectedMembers.isEmpty)
                    ? null
                    : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMembers.isEmpty
                                ? 'Tạo nhóm'
                                : 'Tạo nhóm (${_selectedMembers.length} thành viên)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
