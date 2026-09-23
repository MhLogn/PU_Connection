import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/feed_cubit.dart';

class CreatePostBottomSheet extends StatefulWidget {
  final PostEntity? postToEdit;

  const CreatePostBottomSheet({
    super.key,
    this.postToEdit,
  });

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
  final List<PostAttachment> _existingAttachments = [];

  bool get isEditing => widget.postToEdit != null;

  final List<String> _categories = [
    'Thảo luận',
    'Hỏi bài',
    'Tài liệu',
    'Tìm nhóm',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final post = widget.postToEdit!;
      _contentController.text = post.content;
      _subjectCodeController.text = post.subjectCode ?? '';
      _selectedCategory = _categories.contains(post.category) ? post.category : 'Thảo luận';
      _existingAttachments.addAll(post.attachments);
    }
  }

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
      allowedExtensions: [
        'pdf',
        'docx',
        'doc',
        'pptx',
        'ppt',
        'xlsx',
        'xls',
        'txt',
        'zip',
        'rar',
      ],
      allowMultiple: true,
    );
    if (result != null) {
      for (final f in result.files) {
        if (f.path != null) {
          setState(() {
            _selectedDocs.add(File(f.path!));
          });
        }
      }
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(BuildContext context, String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFEA580C);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF10B981);
      case 'zip':
      case 'rar':
        return const Color(0xFFD97706);
      default:
        return AppTheme.primaryColor(context);
    }
  }

  Future<void> _submitPost() async {
    final l10n = AppLocalizations.of(context)!;
    final content = _contentController.text.trim();
    if (content.isEmpty &&
        _selectedImages.isEmpty &&
        _selectedDocs.isEmpty &&
        _existingAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.post_empty_error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
      if (isEditing) {
        await context.read<FeedCubit>().updatePost(
              postId: widget.postToEdit!.postId,
              content: content,
              category: _selectedCategory,
              subjectCode: _subjectCodeController.text.trim(),
              existingAttachments: _existingAttachments,
              newImageFiles: _selectedImages,
              newDocFiles: _selectedDocs,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.edit_post_success),
              backgroundColor: AppTheme.primaryColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
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
            SnackBar(
              content: Text(l10n.success),
              backgroundColor: AppTheme.primaryColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final categoryLabels = {
      'Thảo luận': l10n.discussions_filter,
      'Hỏi bài': l10n.questions_filter,
      'Tài liệu': l10n.docs_filter,
      'Tìm nhóm': l10n.groups_filter,
    };

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                      color: AppTheme.accentColor(context),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? l10n.edit_post : l10n.create_post_title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n.close,
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
                  backgroundColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.85),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
              style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Mã môn học (CNTT-225, CSDL-101)...',
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                prefixIcon: Icon(Icons.menu_book_rounded, size: 19, color: AppTheme.primaryColor(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.primaryColor(context), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content text area with AppTheme styling and anti-overflow
            TextField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              textAlignVertical: TextAlignVertical.top,
              scrollPhysics: const ClampingScrollPhysics(),
              style: TextStyle(
                fontSize: 14.5,
                color: colorScheme.onSurface,
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: l10n.post_content_hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  height: 1.45,
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor(context),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Existing Attachments (when editing)
            if (_existingAttachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.existing_attachments,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 6),
              Column(
                children: _existingAttachments.map((att) {
                  final ext = att.type.toLowerCase();
                  final isImg = ext == 'image';
                  final icon = isImg ? Icons.image_rounded : _getFileIcon(ext);
                  final iconColor = isImg ? AppTheme.primaryColor(context) : _getFileColor(context, ext);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                          : AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            att.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _existingAttachments.remove(att)),
                          child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Newly selected images
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

            // Newly selected documents
            if (_selectedDocs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: _selectedDocs.map((doc) {
                  final ext = doc.path.split('.').last.toLowerCase();
                  final icon = _getFileIcon(ext);
                  final color = _getFileColor(context, ext);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                          : AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.path.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

            // Action buttons row
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
                      : Text(
                          isEditing ? l10n.save_changes : l10n.post_btn,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
