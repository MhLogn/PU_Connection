import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/document_cubit.dart';
import '../cubit/document_state.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_document_bottom_sheet.dart';

class DocsHubPage extends StatefulWidget {
  const DocsHubPage({super.key});

  @override
  State<DocsHubPage> createState() => _DocsHubPageState();
}

class _DocsHubPageState extends State<DocsHubPage> {
  final _searchController = TextEditingController();

  final List<String> _faculties = [
    'Tất cả',
    'CNTT',
    'Dược - Y',
    'Kinh tế & QTKD',
    'Kỹ thuật Ô tô',
    'Ngôn ngữ Anh',
    'Khoa học cơ bản',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentCubit>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<DocumentCubit, DocumentState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.coralColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DocumentCubit>().clearMessages();
        } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppTheme.primaryColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DocumentCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final cubit = context.read<DocumentCubit>();

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(l10n.docs_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: l10n.contribute_doc_btn,
                onPressed: () => UploadDocumentBottomSheet.show(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => UploadDocumentBottomSheet.show(context),
            backgroundColor: AppTheme.accentColor(context),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.contribute_doc_btn,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              cubit.loadDocuments();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => cubit.search(val),
                      decoration: InputDecoration(
                        hintText: l10n.search_docs_hint,
                        hintStyle: TextStyle(fontSize: 13.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor(context), size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  cubit.search('');
                                },
                              )
                            : null,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _faculties.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final faculty = _faculties[index];
                      final isSelected = faculty == state.selectedFaculty;
                      return ChoiceChip(
                        label: Text(faculty == 'Tất cả' ? l10n.all_courses : faculty),
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
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) cubit.filterByFaculty(faculty);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _buildDocumentsList(context, state, cubit, colorScheme, l10n),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList(
    BuildContext context,
    DocumentState state,
    DocumentCubit cubit,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    if (state.status == DocumentStatus.loading && state.documents.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor(context)),
      );
    }

    if (state.documents.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_rounded, size: 64, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                l10n.no_docs_found,
                style: TextStyle(color: colorScheme.outline, fontSize: 15),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => UploadDocumentBottomSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.contribute_doc_btn),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor(context),
                  side: BorderSide(color: AppTheme.primaryColor(context)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserStudentId = authState is Authenticated ? authState.user.studentId : '';

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: state.documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = state.documents[index];
        final isDownloading = state.downloadingDocId == doc.id;
        final isOwner = (currentUserId.isNotEmpty && doc.authorId == currentUserId) ||
            (currentUserStudentId.isNotEmpty && doc.authorStudentId == currentUserStudentId);

        return DocumentCard(
          document: doc,
          isDownloading: isDownloading,
          downloadProgress: isDownloading ? state.downloadProgress : 0.0,
          onDownload: () => cubit.downloadDocument(doc),
          onDelete: isOwner ? () => cubit.deleteDocument(doc.id) : null,
        );
      },
    );
  }
}
