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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isPdf = document.fileType.toLowerCase() == 'pdf';
    final isZip = ['zip', 'rar', '7z'].contains(document.fileType.toLowerCase());

    final List<Color> gradientColors = isPdf
        ? [const Color(0xFFE53935), const Color(0xFFFF7043)]
        : isZip
            ? [const Color(0xFFF76B1C), const Color(0xFFFFB03A)]
            : [AppTheme.primaryColor(context), const Color(0xFF3865A8)];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_rounded
                              : isZip
                                  ? Icons.folder_zip_rounded
                                  : Icons.description_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  document.code,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '• ${document.faculty}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                document.fileSize,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                '${document.downloads} ${l10n.downloads_count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.star_rounded, size: 14, color: AppTheme.amberColor(context)),
                              const SizedBox(width: 2),
                              Text(
                                '${document.rating}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDownloading)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            value: downloadProgress > 0 ? downloadProgress : null,
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
                              backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                              foregroundColor: AppTheme.primaryColor(context),
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(36, 36),
                            ),
                            icon: Icon(
                              isPdf ? Icons.visibility_rounded : Icons.download_rounded,
                              size: 18,
                            ),
                            tooltip: isPdf ? l10n.pdf_viewer_title : l10n.download,
                            onPressed: () {
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
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.08),
                                foregroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(36, 36),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              tooltip: 'Xóa tài liệu',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận xóa tài liệu'),
                                    content: Text('Bạn có chắc muốn xóa tài liệu "${document.title}"? Thao tác này không thể hoàn tác.'),
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
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
