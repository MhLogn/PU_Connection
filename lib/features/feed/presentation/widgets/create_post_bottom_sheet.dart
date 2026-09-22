import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/feed_cubit.dart';

class CreatePostBottomSheet extends StatefulWidget {
  const CreatePostBottomSheet({super.key});

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final _contentController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  String _selectedCategory = 'Thảo luận';
  bool _isUploading = false;

  final List<File> _selectedImages = [];
  final List<File> _selectedDocs = [];

  final List<String> _categories = [
    'Thảo luận',
    'Hỏi bài',
    'Tài liệu',
    'Tìm nhóm',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'zip'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocs.add(File(result.files.single.path!));
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty && _selectedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung bài viết hoặc đính kèm tệp.')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    String uid = '';
    String name = 'Sinh viên Phenikaa';
    String studentId = '';
    String faculty = 'Công nghệ thông tin';
    String avatar = '';

    if (authState is Authenticated) {
      uid = authState.user.uid;
      name = authState.user.displayName.isNotEmpty ? authState.user.displayName : name;
      studentId = authState.user.studentId;
      if (studentId.isEmpty && authState.user.email.contains('@')) {
        studentId = authState.user.email.split('@').first;
      }
      faculty = authState.user.faculty.isNotEmpty ? authState.user.faculty : faculty;
      avatar = authState.user.avatarUrl;
    }

    setState(() => _isUploading = true);

    try {
      await context.read<FeedCubit>().createPost(
            authorId: uid,
            authorName: name,
            authorAvatar: avatar,
            authorStudentId: studentId,
            authorFaculty: faculty,
            content: content,
            category: _selectedCategory,
            subjectCode: _subjectCodeController.text.trim(),
            imageFiles: _selectedImages,
            docFiles: _selectedDocs,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng bài thất bại: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final categoryLabels = {
      'Thảo luận': l10n.discussions_filter,
      'Hỏi bài': l10n.questions_filter,
      'Tài liệu': l10n.docs_filter,
      'Tìm nhóm': l10n.groups_filter,
    };

    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: 18,
        right: 18,
        bottom: bottomInset + 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.create_post_title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(categoryLabels[cat] ?? cat),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: AppTheme.primaryColor(context),
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCodeController,
              decoration: InputDecoration(
                hintText: 'Mã môn học (CNTT-225, CSDL-101)...',
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                prefixIcon: Icon(Icons.menu_book_rounded, size: 19, color: AppTheme.primaryColor(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.primaryColor(context), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.post_content_hint,
                  hintStyle: TextStyle(fontSize: 13.5, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[index],
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (_selectedDocs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: _selectedDocs.map((doc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: AppTheme.accentColor(context), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.path.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDocs.remove(doc)),
                          child: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                    foregroundColor: AppTheme.primaryColor(context),
                    padding: const EdgeInsets.all(10),
                  ),
                  tooltip: l10n.attach_image,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  onPressed: _isUploading ? null : _pickImage,
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentColor(context).withValues(alpha: 0.08),
                    foregroundColor: AppTheme.accentColor(context),
                    padding: const EdgeInsets.all(10),
                  ),
                  tooltip: l10n.attach_file,
                  icon: const Icon(Icons.attach_file_rounded, size: 20),
                  onPressed: _isUploading ? null : _pickDocument,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isUploading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.post_btn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
