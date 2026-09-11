import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document_entity.dart';

class PdfViewerPage extends StatefulWidget {
  final DocumentEntity document;
  final String? localFilePath;

  const PdfViewerPage({
    super.key,
    required this.document,
    this.localFilePath,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  String? _localPath;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.localFilePath != null && File(widget.localFilePath!).existsSync()) {
      _localPath = widget.localFilePath;
      _isLoading = false;
    } else {
      _downloadPdf();
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getTemporaryDirectory();
      final sanitized = widget.document.id.isNotEmpty
          ? widget.document.id
          : widget.document.title.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
      final targetPath = '${dir.path}/${sanitized}_preview.pdf';
      final file = File(targetPath);

      if (await file.exists() && (await file.length()) > 0) {
        if (mounted) {
          setState(() {
            _localPath = targetPath;
            _isLoading = false;
          });
        }
        return;
      }

      final dio = Dio();
      await dio.download(
        widget.document.fileUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _localPath = targetPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _openWithExternal() async {
    if (_localPath != null && File(_localPath!).existsSync()) {
      await OpenFilex.open(_localPath!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.downloading),
        ),
      );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.blueContainer(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.document.code,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.document.faculty,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isReady && _totalPages > 0)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.page_indicator(_currentPage, _totalPages),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: l10n.open_with_external,
            onPressed: _openWithExternal,
          ),
        ],
      ),
      body: _buildBody(context, colorScheme, l10n),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                color: AppTheme.primaryColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                _downloadProgress > 0
                    ? '${l10n.downloading} ${(_downloadProgress * 100).toInt()}%'
                    : l10n.downloading_doc,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                widget.document.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _localPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.coralColor(context)),
              const SizedBox(height: 16),
              Text(
                l10n.error_loading_pdf,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: _localPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = 'Trang $page: $error';
            });
          },
          onViewCreated: (PDFViewController pdfViewController) {
            if (!_controller.isCompleted) {
              _controller.complete(pdfViewController);
            }
          },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = (page ?? 0) + 1;
              _totalPages = total ?? _totalPages;
            });
          },
        ),
        if (!_isReady)
          Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor(context)),
          ),
      ],
    );
  }
}
