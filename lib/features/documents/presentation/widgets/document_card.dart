import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document_entity.dart';
import '../pages/pdf_viewer_page.dart';

class DocumentCard extends StatelessWidget {
  final DocumentEntity document;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    required this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final ext = document.fileType.toLowerCase().trim();
    final isPdf = ext == 'pdf';
    final isZip = ['zip', 'rar', '7z'].contains(ext);
    final isDoc = ['doc', 'docx', 'txt', 'rtf'].contains(ext);
    final isSlide = ['ppt', 'pptx'].contains(ext);
    final isSheet = ['xls', 'xlsx', 'csv'].contains(ext);

    final Color fileSolidColor = isPdf
        ? const Color(0xFFEF4444)
        : isZip
        ? AppTheme.accentColor(context)
        : isDoc
        ? AppTheme.primaryColor(context)
        : isSlide
        ? const Color(0xFFEA580C)
        : isSheet
        ? const Color(0xFF059669)
        : AppTheme.primaryColor(context);

    final IconData fileIcon = isPdf
        ? Icons.picture_as_pdf_rounded
        : isZip
        ? Icons.folder_zip_rounded
        : isDoc
        ? Icons.description_rounded
        : isSlide
        ? Icons.slideshow_rounded
        : isSheet
        ? Icons.table_chart_rounded
        : Icons.insert_drive_file_rounded;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isPdf && document.fileUrl.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerPage(document: document),
                ),
              );
            } else {
              onDownload();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: fileSolidColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(fileIcon, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.blueContainer(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  document.code,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor(context),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (document.originPostId != null &&
                                  document.originPostId!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orangeContainer(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.dynamic_feed_rounded,
                                        size: 10.5,
                                        color: AppTheme.accentColor(context),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Bảng tin',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  '• ${document.faculty}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.65,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            document.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              height: 1.3,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (document.description != null &&
                              document.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              document.description!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ext.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                document.fileSize,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.file_download_outlined,
                                    size: 13.5,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    '${document.downloads} ${l10n.downloads_count}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (document.authorName.isNotEmpty) ...[
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 13,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      document.authorName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDownloading)
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            value: downloadProgress > 0
                                ? downloadProgress
                                : null,
                            strokeWidth: 2.5,
                            color: AppTheme.primaryColor(context),
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.blueContainer(context),
                              foregroundColor: AppTheme.primaryColor(context),
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(36, 36),
                            ),
                            icon: Icon(
                              isPdf
                                  ? Icons.menu_book_rounded
                                  : Icons.download_rounded,
                              size: 18,
                            ),
                            tooltip: isPdf
                                ? l10n.pdf_viewer_title
                                : l10n.download,
                            onPressed: () {
                              if (isPdf && document.fileUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PdfViewerPage(document: document),
                                  ),
                                );
                              } else {
                                onDownload();
                              }
                            },
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.coralColor(
                                  context,
                                ).withValues(alpha: 0.1),
                                foregroundColor: AppTheme.coralColor(context),
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(36, 36),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              tooltip: 'Xóa tài liệu',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận xóa tài liệu'),
                                    content: Text(
                                      'Bạn có chắc muốn xóa tài liệu "${document.title}"? Thao tác này không thể hoàn tác.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(l10n.cancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          onDelete!();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.coralColor(
                                            context,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      color: AppTheme.primaryColor(context),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
