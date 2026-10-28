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
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentCubit>().init();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<DocumentCubit>().loadMoreDocuments();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
        } else if (state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.blueContainer(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_copy_rounded,
                    color: AppTheme.primaryColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.docs_title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            elevation: 0,
            scrolledUnderElevation: 1,
            actions: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blueContainer(context),
                  foregroundColor: AppTheme.primaryColor(context),
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                tooltip: l10n.contribute_doc_btn,
                onPressed: () => UploadDocumentBottomSheet.show(context),
              ),
              const SizedBox(width: 12),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => UploadDocumentBottomSheet.show(context),
            backgroundColor: AppTheme.primaryColor(context),
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.contribute_doc_btn,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryColor(context),
            onRefresh: () async {
              await cubit.loadDocuments(refresh: true);
            },
            child: Column(
              children: [
                // Thanh tìm kiếm tài liệu tích hợp chuẩn AppTheme
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.isDark(context)
                            ? Colors.white12
                            : AppTheme.borderLight,
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: AppTheme.isDark(context) ? 0.2 : 0.02,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => cubit.search(val),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.search_docs_hint,
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryColor(context),
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  cubit.search('');
                                },
                              )
                            : null,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Danh sách bộ lọc theo Khoa/Viện chuẩn nhận diện Phenikaa
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _faculties.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final faculty = _faculties[index];
                      final isSelected = faculty == state.selectedFaculty;
                      return GestureDetector(
                        onTap: () => cubit.filterByFaculty(faculty),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor(context)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor(context)
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: AppTheme.isDark(context)
                                          ? 0.35
                                          : 0.5,
                                    ),
                              width: 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                faculty == 'Tất cả'
                                    ? l10n.all_courses
                                    : faculty,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Danh sách tài liệu môn học
                Expanded(
                  child: _buildDocumentsList(
                    context,
                    state,
                    cubit,
                    colorScheme,
                    l10n,
                  ),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor(context).withValues(alpha: 0.15),
                      AppTheme.accentColor(context).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 46,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.no_docs_found,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa có tài liệu nào trong danh mục này.\nHãy là người đầu tiên đóng góp giáo trình hoặc đề thi nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => UploadDocumentBottomSheet.show(context),
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  l10n.contribute_doc_btn,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.uid : '';
    final currentUserStudentId = authState is Authenticated
        ? authState.user.studentId
        : '';

    final showLoadingMore = state.isLoadingMore;
    final showEndReached = !state.hasMore && state.documents.length >= 10;
    final extraCount = (showLoadingMore || showEndReached) ? 1 : 0;

    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
      itemCount: state.documents.length + extraCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.documents.length) {
          if (showLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              ),
            );
          }
          if (showEndReached) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppTheme.mintColor(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đã hiển thị tất cả tài liệu',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final doc = state.documents[index];
        final isDownloading = state.downloadingDocId == doc.id;
        final isOwner =
            (currentUserId.isNotEmpty && doc.authorId == currentUserId) ||
            (currentUserStudentId.isNotEmpty &&
                doc.authorStudentId == currentUserStudentId);

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
