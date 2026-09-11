import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/document_entity.dart';
import '../cubit/document_cubit.dart';

class UploadDocumentBottomSheet extends StatefulWidget {
  const UploadDocumentBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final docCubit = context.read<DocumentCubit>();
    final authCubit = context.read<AuthCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: docCubit),
          BlocProvider.value(value: authCubit),
        ],
        child: const UploadDocumentBottomSheet(),
      ),
    );
  }

  @override
  State<UploadDocumentBottomSheet> createState() => _UploadDocumentBottomSheetState();
}

class _UploadDocumentBottomSheetState extends State<UploadDocumentBottomSheet> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();

  File? _selectedFile;
  String _selectedFileName = '';
  String _selectedFileSize = '';
  String _selectedFileType = 'pdf';
  String _selectedFaculty = 'CNTT';
  bool _isUploading = false;

  final List<String> _faculties = [
    'CNTT',
    'Dược - Y',
    'Kinh tế & QTKD',
    'Kỹ thuật Ô tô',
    'Ngôn ngữ Anh',
    'Khoa học cơ bản',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'zip', 'rar', 'xlsx', 'pptx'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final fileName = result.files.single.name;
        final sizeBytes = result.files.single.size;

        String displaySize = '';
        if (sizeBytes < 1024 * 1024) {
          displaySize = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
        } else {
          displaySize = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }

        final ext = fileName.split('.').last.toLowerCase();

        setState(() {
          _selectedFile = file;
          _selectedFileName = fileName;
          _selectedFileSize = displaySize;
          _selectedFileType = ext;
          if (_titleController.text.trim().isEmpty) {
            final dotIdx = fileName.lastIndexOf('.');
            _titleController.text = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn tệp: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.doc_name_required)),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.no_file_selected)),
      );
      return;
    }

    setState(() => _isUploading = true);

    final authState = context.read<AuthCubit>().state;
    String authorId = 'pu_anonymous';
    String authorName = 'Sinh viên Phenikaa';
    String authorStudentId = '';

    if (authState is Authenticated) {
      authorId = authState.user.uid;
      authorName = authState.user.displayName.isNotEmpty ? authState.user.displayName : 'Sinh viên Phenikaa';
      authorStudentId = authState.user.studentId;
    }

    final newDoc = DocumentEntity(
      id: '',
      title: title,
      code: code.isNotEmpty ? code : 'PU-2026',
      faculty: _selectedFaculty,
      fileUrl: '',
      fileType: _selectedFileType,
      fileSize: _selectedFileSize.isNotEmpty ? _selectedFileSize : '2.0 MB',
      authorId: authorId,
      authorName: authorName,
      authorStudentId: authorStudentId,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    final success = await context.read<DocumentCubit>().uploadDocument(
          document: newDoc,
          file: _selectedFile!,
        );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.doc_upload_success}: "$title"'),
            backgroundColor: AppTheme.primaryColor(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardBottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.file_upload_rounded, color: AppTheme.accentColor(context), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      l10n.contribute_dialog_title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppTheme.primaryColor(context)
                        : colorScheme.outlineVariant,
                    width: _selectedFile != null ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedFile != null
                      ? AppTheme.blueContainer(context)
                      : colorScheme.surfaceContainerLowest,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedFile != null
                            ? AppTheme.primaryColor(context)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedFile != null
                            ? (_selectedFileType == 'pdf'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded)
                            : Icons.upload_file_rounded,
                        color: _selectedFile != null ? Colors.white : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile != null
                                ? _selectedFileName
                                : l10n.select_file_btn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedFile != null
                                  ? AppTheme.primaryColor(context)
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedFile != null
                                ? '$_selectedFileSize • .${_selectedFileType.toUpperCase()}'
                                : 'PDF, Word (DOCX), ZIP, RAR, Excel',
                            style: TextStyle(fontSize: 12, color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedFile != null)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        tooltip: 'Chọn lại tệp',
                        onPressed: _pickFile,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.doc_title_label,
                hintText: l10n.doc_title_hint,
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: l10n.course_code_label,
                      hintText: l10n.course_code_hint,
                      prefixIcon: const Icon(Icons.code_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFaculty,
                    decoration: InputDecoration(
                      labelText: l10n.faculty_label,
                      prefixIcon: const Icon(Icons.apartment_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _faculties
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFaculty = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _submit,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
              label: Text(
                _isUploading ? l10n.uploading_to_cloud : l10n.upload_btn,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
