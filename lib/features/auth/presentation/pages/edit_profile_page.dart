import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _facultyController;
  late TextEditingController _majorController;
  final TextEditingController _newSubjectController = TextEditingController();

  String _avatarUrl = '';
  String _coverUrl = '';
  late List<String> _subjects;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  final List<String> _suggestedSubjects = [
    'Lập trình mạng',
    'Cấu trúc dữ liệu & Giải thuật',
    'Cơ sở dữ liệu',
    'Trí tuệ nhân tạo (AI)',
    'Công nghệ phần mềm',
    'Phát triển ứng dụng di động',
    'Hệ điều hành',
    'An toàn thông tin',
    'Xác suất thống kê',
    'Kinh tế chính trị Mác - Lênin',
    'Tiếng Anh học thuật',
    'Nhập môn Robotics',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
    _facultyController = TextEditingController(text: widget.user.faculty);
    _majorController = TextEditingController(text: widget.user.major);
    _avatarUrl = widget.user.avatarUrl;
    _coverUrl = widget.user.coverUrl;
    _subjects = List<String>.from(widget.user.currentSubjects);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _newSubjectController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage({required bool isAvatar}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: isAvatar ? 800 : 1600,
    );

    if (picked == null) return;

    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final file = File(picked.path);
      final cloudinary = sl<CloudinaryService>();
      final uploadedUrl = await cloudinary.uploadImage(
        file,
        folder: isAvatar ? 'pu_connection/avatars' : 'pu_connection/covers',
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          if (isAvatar) {
            _avatarUrl = uploadedUrl;
          } else {
            _coverUrl = uploadedUrl;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải lên ${isAvatar ? "ảnh đại diện" : "ảnh bìa"} thành công!'),
            backgroundColor: AppTheme.primaryColor(context),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải ảnh lên: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isAvatar) {
            _isUploadingAvatar = false;
          } else {
            _isUploadingCover = false;
          }
        });
      }
    }
  }

  void _addSubject(String subject) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) return;
    if (_subjects.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Môn học này đã có trong danh sách!')),
      );
      return;
    }
    setState(() {
      _subjects.add(trimmed);
      _newSubjectController.clear();
    });
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        studentId: widget.user.studentId,
        displayName: _nameController.text.trim(),
        username: widget.user.username,
        avatarUrl: _avatarUrl,
        coverUrl: _coverUrl,
        bio: _bioController.text.trim(),
        faculty: _facultyController.text.trim(),
        major: _majorController.text.trim(),
        cohort: widget.user.cohort,
        userType: widget.user.userType,
        isVerified: widget.user.isVerified,
        currentSubjects: _subjects,
        friendsCount: widget.user.friendsCount,
        postsCount: widget.user.postsCount,
        createdAt: widget.user.createdAt,
      );

      await context.read<AuthCubit>().updateUserProfile(updatedUser);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu thông tin hồ sơ thành công!'),
            backgroundColor: AppTheme.primaryColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật hồ sơ: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover & Avatar section
              _buildCoverAndAvatar(context),
              const SizedBox(height: 24),

              // Basic Info Card
              _buildSectionCard(
                context,
                title: 'Thông tin cơ bản',
                icon: Icons.person_outline_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tiểu sử (Bio)',
                      hintText: 'Giới thiệu ngắn về bản thân, chuyên môn hay phương châm học tập...',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Academic Info Card
              _buildSectionCard(
                context,
                title: 'Khoa & Ngành đào tạo',
                icon: Icons.school_outlined,
                children: [
                  TextFormField(
                    controller: _facultyController,
                    decoration: InputDecoration(
                      labelText: 'Khoa / Viện',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _majorController,
                    decoration: InputDecoration(
                      labelText: 'Ngành học / Chuyên ngành',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Subjects (Môn học đang học trong kỳ)
              _buildSubjectsSection(context),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverAndAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Banner
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surfaceContainerHighest,
            image: _coverUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_coverUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: _coverUrl.isEmpty
                ? const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF0C4A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: FilledButton.tonalIcon(
                onPressed: _isUploadingCover ? null : () => _pickAndUploadImage(isAvatar: false),
                icon: _isUploadingCover
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Đổi ảnh bìa', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Avatar
        Positioned(
          bottom: -32,
          left: 20,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: colorScheme.surface,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.accentColor(context),
                  backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                  child: _avatarUrl.isEmpty
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _isUploadingAvatar ? null : () => _pickAndUploadImage(isAvatar: true),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _isUploadingAvatar
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor(context)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubjectsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.collections_bookmark_rounded, size: 20, color: AppTheme.mintColor(context)),
              const SizedBox(width: 8),
              const Text(
                'Môn học đang học trong kỳ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Giúp bạn bè dễ dàng tìm kiếm bạn trong cùng lớp môn học để lập nhóm học tập.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),

          // Input + Add Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newSubjectController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên môn học (vd: Nhập môn AI)...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: _addSubject,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addSubject(_newSubjectController.text),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Subject Chips
          if (_subjects.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects.map((sub) {
                return Chip(
                  label: Text(sub, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _removeSubject(sub),
                  backgroundColor: AppTheme.blueContainer(context),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Quick Suggestions
          const Text(
            'Gợi ý môn học phổ biến:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedSubjects
                .where((s) => !_subjects.contains(s))
                .take(6)
                .map((suggested) {
              return ActionChip(
                label: Text(
                  '+ $suggested',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor(context)),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.3)),
                onPressed: () => _addSubject(suggested),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
