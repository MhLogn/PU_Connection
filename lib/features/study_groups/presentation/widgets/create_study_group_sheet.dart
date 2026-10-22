import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/study_group_entity.dart';
import '../cubit/study_group_cubit.dart';

class CreateStudyGroupSheet extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final String currentUserStudentId;
  final String currentUserFaculty;

  const CreateStudyGroupSheet({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    required this.currentUserStudentId,
    required this.currentUserFaculty,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatar,
    String currentUserStudentId = '',
    String currentUserFaculty = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StudyGroupCubit>(),
        child: CreateStudyGroupSheet(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          currentUserAvatar: currentUserAvatar,
          currentUserStudentId: currentUserStudentId,
          currentUserFaculty: currentUserFaculty,
        ),
      ),
    );
  }

  @override
  State<CreateStudyGroupSheet> createState() => _CreateStudyGroupSheetState();
}

class _CreateStudyGroupSheetState extends State<CreateStudyGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(text: 'Thư viện Tòa A9');

  int _maxMembers = 5;
  DateTime _studyTime = DateTime.now().add(const Duration(days: 2, hours: 2));
  bool _isSubmitting = false;

  final List<String> _suggestedSubjects = [
    'Giải tích 2',
    'Lập trình Mobile',
    'Tiếng Anh B1',
    'Kinh tế Vi mô',
    'Vật lý đại cương',
    'Cấu trúc dữ liệu',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _studyTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_studyTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _studyTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newGroup = StudyGroupEntity(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      creatorId: widget.currentUserId,
      creatorName: widget.currentUserName,
      creatorAvatar: widget.currentUserAvatar,
      creatorStudentId: widget.currentUserStudentId,
      creatorFaculty: widget.currentUserFaculty,
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      description: _descController.text.trim(),
      maxMembers: _maxMembers,
      memberIds: [widget.currentUserId],
      pendingRequestIds: const [],
      studyTime: _studyTime,
      location: _locationController.text.trim(),
      createdAt: DateTime.now(),
      isOpen: true,
    );

    await context.read<StudyGroupCubit>().createGroup(newGroup);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text(
                      'Tạo nhóm học tập',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Môn học
                    const Text('Môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên môn học (VD: Giải tích 2)...',
                        prefixIcon: const Icon(Icons.school_rounded, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập môn học' : null,
                    ),
                    const SizedBox(height: 8),

                    // Chip gợi ý môn học
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _suggestedSubjects.map((s) {
                        return ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _subjectController.text = s;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề nhóm học
                    const Text('Tiêu đề bài đăng tìm nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'VD: Tìm 2 bạn cùng ôn thi Giải tích 2 kỳ này...',
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mục tiêu & mô tả
                    const Text('Mô tả mục tiêu & kế hoạch học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Mô tả dạng bài cần giải, mục tiêu điểm số, yêu cầu với thành viên...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập mô tả' : null,
                    ),
                    const SizedBox(height: 16),

                    // Số lượng thành viên tối đa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng thành viên tối đa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('$_maxMembers bạn', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      ],
                    ),
                    Slider(
                      value: _maxMembers.toDouble(),
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: '$_maxMembers người',
                      onChanged: (val) {
                        setState(() {
                          _maxMembers = val.round();
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Thời gian học
                    const Text('Thời gian học dự kiến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_studyTime.hour.toString().padLeft(2, '0')}:${_studyTime.minute.toString().padLeft(2, '0')} ngày ${_studyTime.day}/${_studyTime.month}/${_studyTime.year}',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Text('Thay đổi', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Địa điểm học
                    const Text('Địa điểm học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'VD: Thư viện Tòa A9, Online Google Meet...',
                        prefixIcon: const Icon(Icons.place_rounded, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập địa điểm' : null,
                    ),
                    const SizedBox(height: 24),

                    // Nút Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: const Text('Đăng bài tìm nhóm ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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
