import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/study_group_cubit.dart';
import '../cubit/study_group_state.dart';
import '../widgets/study_group_card.dart';
import '../widgets/create_study_group_sheet.dart';

class StudyGroupsPage extends StatefulWidget {
  const StudyGroupsPage({super.key});

  @override
  State<StudyGroupsPage> createState() => _StudyGroupsPageState();
}

class _StudyGroupsPageState extends State<StudyGroupsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _subjectFilters = [
    'Tất cả',
    'Giải tích 2',
    'Lập trình Mobile',
    'Tiếng Anh B1 / TOEIC',
    'Kinh tế Vi mô',
    'Vật lý đại cương',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyGroupCubit>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateSheet(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String uid = 'guest';
    String name = 'Sinh viên Phenikaa';
    String? avatar;
    String studentId = '';
    String faculty = '';

    if (authState is Authenticated) {
      uid = authState.user.uid;
      name = authState.user.displayName;
      avatar = authState.user.avatarUrl;
      studentId = authState.user.studentId;
      faculty = authState.user.faculty;
    }

    CreateStudyGroupSheet.show(
      context,
      currentUserId: uid,
      currentUserName: name,
      currentUserAvatar: avatar,
      currentUserStudentId: studentId,
      currentUserFaculty: faculty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.diversity_3_rounded, color: AppTheme.primaryColor(context), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Tìm nhóm học tập',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo nhóm học', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<StudyGroupCubit, StudyGroupState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: colorScheme.error),
            );
            context.read<StudyGroupCubit>().clearMessage();
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
            context.read<StudyGroupCubit>().clearMessage();
          }
        },
        builder: (context, state) {
          final groups = state.filteredGroups;

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<StudyGroupCubit>().setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm nhóm theo môn học, địa điểm, từ khóa...',
                    hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<StudyGroupCubit>().setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _subjectFilters.map((sub) {
                    final isSelected = (state.selectedSubjectFilter == null && sub == 'Tất cả') ||
                        state.selectedSubjectFilter == sub;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(sub, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<StudyGroupCubit>().setSubjectFilter(sub == 'Tất cả' ? null : sub);
                        },
                        selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 12),

              // Content List
              Expanded(
                child: state.status == StudyGroupStatus.loading && state.groups.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : groups.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.group_off_rounded,
                                      size: 36,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Không tìm thấy nhóm học nào',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hãy là người đầu tiên tạo nhóm học tập cho môn này để cùng các bạn Phenikaa ôn thi nhé!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => _openCreateSheet(context),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Tạo nhóm học mới'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              return StudyGroupCard(
                                group: groups[index],
                                currentUserId: currentUserId,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
