import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/image_crop_preview_dialog.dart';

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
  late TextEditingController _gpaController;
  late TextEditingController _creditsController;
  late TextEditingController _trainingPointsController;
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

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
    _facultyController = TextEditingController(text: widget.user.faculty);
    _majorController = TextEditingController(text: widget.user.major);
    _gpaController = TextEditingController(
      text: widget.user.gpa > 0 ? widget.user.gpa.toStringAsFixed(2) : '',
    );
    _creditsController = TextEditingController(
      text: widget.user.creditsEarned > 0 ? '${widget.user.creditsEarned}' : '',
    );
    _trainingPointsController = TextEditingController(
      text: widget.user.trainingPoints > 0
          ? '${widget.user.trainingPoints}'
          : '',
    );
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
    _gpaController.dispose();
    _creditsController.dispose();
    _trainingPointsController.dispose();
    _newSubjectController.dispose();
    super.dispose();
  }

  void _showImageSourceModal({required bool isAvatar}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cập nhật ${isAvatar ? "ảnh đại diện" : "ảnh bìa"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(
                      context,
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
                title: const Text('Chọn từ thư viện ảnh (Gallery)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(
                    isAvatar: isAvatar,
                    source: ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Chụp ảnh mới (Camera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(
                    isAvatar: isAvatar,
                    source: ImageSource.camera,
                  );
                },
              ),
              if (isAvatar)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.face_rounded, color: Colors.orange),
                  ),
                  title: const Text('Chọn Avatar mẫu Phenikaa'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetAvatarsDialog();
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                title: const Text('Nhập liên kết ảnh trực tiếp (URL)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDirectUrlInputDialog(isAvatar: isAvatar);
                },
              ),
              if ((isAvatar && _avatarUrl.isNotEmpty) ||
                  (!isAvatar && _coverUrl.isNotEmpty))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    'Gỡ ${isAvatar ? "ảnh đại diện" : "ảnh bìa"}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      if (isAvatar) {
                        _avatarUrl = '';
                      } else {
                        _coverUrl = '';
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetAvatarsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(
              Icons.face_retouching_natural_rounded,
              color: Color(0xFF0284C7),
            ),
            SizedBox(width: 8),
            Text(
              'Avatar Phenikaa Mẫu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _presetAvatars.length,
            itemBuilder: (context, index) {
              final url = _presetAvatars[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _avatarUrl = url);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Đã chọn Avatar sinh viên thành công!',
                      ),
                      backgroundColor: AppTheme.primaryColor(context),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _avatarUrl == url
                          ? AppTheme.primaryColor(context)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: AppTheme.imageProvider(url),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDirectUrlInputDialog({required bool isAvatar}) {
    final controller = TextEditingController(
      text: isAvatar ? _avatarUrl : _coverUrl,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Nhập URL ${isAvatar ? "ảnh đại diện" : "ảnh bìa"}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Đường dẫn ảnh (http/https)',
            hintText: 'https://example.com/avatar.jpg',
            prefixIcon: const Icon(Icons.link_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (isAvatar) {
                    _avatarUrl = text;
                  } else {
                    _coverUrl = text;
                  }
                });
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage({
    required bool isAvatar,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: isAvatar ? 1024 : 1920,
        maxHeight: isAvatar ? 1024 : 1080,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh từ thiết bị: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    if (picked == null || !mounted) return;

    final rawBytes = await picked.readAsBytes();
    if (!mounted) return;

    // Hiển thị màn hình / hộp thoại xem trước và căn chỉnh (Pinch to Zoom, Pan) trước khi xác nhận
    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImageCropPreviewDialog(
        imageBytes: rawBytes,
        isAvatar: isAvatar,
      ),
    );

    // Nếu người dùng bấm Hủy (hoặc đóng), giữ nguyên ảnh cũ và không tải lên server
    if (croppedBytes == null || !mounted) return;

    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final fileName = picked.name.isNotEmpty
          ? picked.name.replaceAll(RegExp(r'\.[^.]+$'), '.png')
          : '${isAvatar ? "avatar" : "cover"}_${DateTime.now().millisecondsSinceEpoch}.png';

      final cloudinary = sl<CloudinaryService>();
      final uploadedUrl = await cloudinary.uploadBytes(
        bytes: croppedBytes,
        fileName: fileName,
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
            content: Text(
              'Tải lên ${isAvatar ? "ảnh đại diện" : "ảnh bìa"} thành công!',
            ),
            backgroundColor: AppTheme.primaryColor(context),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải ảnh lên Cloudinary: $e'),
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

    if (sl.isRegistered<BadWordsFilterService>()) {
      final checkResult = sl<BadWordsFilterService>().check(
        trimmed,
        actionLabel: 'thêm môn học',
      );
      if (!checkResult.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tên môn học chứa từ ngữ không phù hợp: ${checkResult.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

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

    // Tiền kiểm duyệt ngôn từ vi phạm (Bad Words Filter) cho tên hiển thị và tiểu sử
    if (sl.isRegistered<BadWordsFilterService>()) {
      final filter = sl<BadWordsFilterService>();
      final name = _nameController.text.trim();
      final bio = _bioController.text.trim();

      final nameResult = filter.check(name, actionLabel: 'cập nhật tên hiển thị');
      if (!nameResult.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tên hiển thị chứa từ ngữ không phù hợp: ${nameResult.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (bio.isNotEmpty) {
        final bioResult = filter.check(bio, actionLabel: 'cập nhật tiểu sử');
        if (!bioResult.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tiểu sử chứa từ ngữ không phù hợp: ${bioResult.detectedWords.join(", ")}',
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

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
        // Dữ liệu học vụ chính thức do Nhà trường quản lý, bảo toàn nguyên vẹn
        gpa: widget.user.gpa,
        creditsEarned: widget.user.creditsEarned,
        trainingPoints: widget.user.trainingPoints,
      );

      await context.read<AuthCubit>().updateUserProfile(updatedUser);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_saved_success),
            backgroundColor: AppTheme.primaryColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_save_failed(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          l10n.edit_profile_title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                title: l10n.basic_info,
                icon: Icons.person_outline_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.full_name,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? l10n.empty_field_err
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.bio_label,
                      hintText: l10n.bio_hint,
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Academic Info Card
              _buildSectionCard(
                context,
                title: l10n.faculty_major_section,
                icon: Icons.school_outlined,
                children: [
                  TextFormField(
                    controller: _facultyController,
                    decoration: InputDecoration(
                      labelText: l10n.faculty,
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _majorController,
                    decoration: InputDecoration(
                      labelText: l10n.major_label,
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Academic Results Card (GPA, Credits, Training Points - Read Only)
              _buildSectionCard(
                context,
                title: l10n.academic_results,
                icon: Icons.auto_awesome_rounded,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueContainer(context).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppTheme.primaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.academic_results_note,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gpaController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: l10n.gpa_label,
                            prefixIcon: const Icon(Icons.grade_outlined),
                            suffixIcon: const Icon(Icons.lock_outline, size: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _creditsController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: l10n.credits_earned_label,
                            prefixIcon: const Icon(Icons.menu_book_outlined),
                            suffixIcon: const Icon(Icons.lock_outline, size: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _trainingPointsController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.training_points_label,
                      prefixIcon: const Icon(Icons.military_tech_outlined),
                      suffixIcon: const Icon(Icons.lock_outline, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                label: Text(
                  l10n.save_changes,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 195,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isUploadingCover
                  ? null
                  : () => _showImageSourceModal(isAvatar: false),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _coverUrl.isNotEmpty
                      ? colorScheme.surfaceContainerHighest
                      : (isDark
                          ? colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6)
                          : AppTheme.blueContainer(context)),
                  border: Border.all(
                    color: _coverUrl.isNotEmpty
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white24
                            : AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.35)),
                    width: _coverUrl.isNotEmpty ? 0 : 1.5,
                  ),
                  image: _coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: AppTheme.imageProvider(_coverUrl)!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (_coverUrl.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.75),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.add_cover_hint,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor(
                                  context,
                                ).withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: FilledButton.tonalIcon(
                          onPressed: _isUploadingCover
                              ? null
                              : () => _showImageSourceModal(isAvatar: false),
                          icon: _isUploadingCover
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined, size: 16),
                          label: Text(
                            _coverUrl.isNotEmpty ? l10n.change_cover : l10n.add_cover,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar
          Positioned(
            bottom: 0,
            left: 20,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _isUploadingAvatar
                  ? null
                  : () => _showImageSourceModal(isAvatar: true),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colorScheme.surface,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.accentColor(context),
                      backgroundImage: AppTheme.imageProvider(_avatarUrl),
                      child: _avatarUrl.isEmpty
                          ? Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? Colors.white10
              : AppTheme.borderLight,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06123B63),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor(context)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? Colors.white10
              : AppTheme.borderLight,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06123B63),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.collections_bookmark_rounded,
                size: 20,
                color: AppTheme.accentColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.current_semester_subjects,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.current_semester_subjects_desc,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),

          // Input + Add Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newSubjectController,
                  decoration: InputDecoration(
                    hintText: l10n.enter_subject_hint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  label: Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _removeSubject(sub),
                  backgroundColor: AppTheme.blueContainer(context),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Quick Suggestions
          Text(
            l10n.popular_subjects_hint,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: AppTheme.primaryColor(
                        context,
                      ).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onPressed: () => _addSubject(suggested),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }
}
