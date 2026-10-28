import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../documents/presentation/pages/pdf_viewer_page.dart';
import '../../domain/entities/message_entity.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isGroup;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
  });

  void _viewFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachedFile(BuildContext context) async {
    final fileUrl = message.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) return;

    final fileName = message.fileName ?? 'document';
    final isPdf =
        fileName.toLowerCase().endsWith('.pdf') ||
        (message.fileType != null && message.fileType!.toLowerCase() == 'pdf');

    if (isPdf) {
      final doc = DocumentEntity(
        id: message.messageId.isNotEmpty ? message.messageId : 'chat_doc',
        title: fileName,
        code: 'CHAT_DOC',
        faculty: 'Phenikaa University',
        fileUrl: fileUrl,
        fileType: 'pdf',
        fileSize: message.fileSize ?? 'Tài liệu',
        authorId: message.senderId,
        authorName: message.senderName,
        authorStudentId: message.senderId,
        createdAt: message.createdAt,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerPage(document: doc)),
      );
    } else {
      // Download to cache and open via open_filex
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đang tải tệp về để mở...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/$fileName';
        await Dio().download(fileUrl, savePath);

        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done && context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Không thể mở tệp: ${result.message}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Lỗi khi mở tệp: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    if (isGroup && !isMe) {
      final senderInitials = message.senderName.isNotEmpty
          ? message.senderName.trim().split(' ').last[0].toUpperCase()
          : 'P';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.blueContainer(context),
            child: Text(
              senderInitials,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                ),
                _buildBubble(context, isDark, colorScheme),
              ],
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildBubble(context, isDark, colorScheme),
    );
  }

  Widget _buildFileAttachmentCard(
    BuildContext context,
    bool isMe,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final fileName = message.fileName ?? 'Tài liệu đính kèm';
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';
    final isPdf = ext == 'PDF';
    final isDoc = ext == 'DOC' || ext == 'DOCX';
    final isXls = ext == 'XLS' || ext == 'XLSX';

    Color badgeColor = Colors.orange;
    IconData badgeIcon = Icons.insert_drive_file_rounded;
    if (isPdf) {
      badgeColor = Colors.red.shade600;
      badgeIcon = Icons.picture_as_pdf_rounded;
    } else if (isDoc) {
      badgeColor = const Color(0xFF2563EB);
      badgeIcon = Icons.description_rounded;
    } else if (isXls) {
      badgeColor = const Color(0xFF16A34A);
      badgeIcon = Icons.table_chart_rounded;
    }

    return InkWell(
      onTap: () => _openAttachedFile(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.18)
              : (isDark ? colorScheme.surface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? Colors.white24
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: isMe ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isMe ? Colors.white : colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.fileSize != null && message.fileSize!.isNotEmpty
                        ? '$ext • ${message.fileSize}'
                        : '$ext • Nhấn để xem',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white70
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPdf ? Icons.visibility_rounded : Icons.download_rounded,
              size: 20,
              color: isMe ? Colors.white70 : AppTheme.primaryColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.oceanGradient : null,
          color: isMe
              ? null
              : (isDark
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      )
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _viewFullImage(context, message.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 180,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              if (message.content.isNotEmpty || message.fileUrl != null)
                const SizedBox(height: 8),
            ],
            if (message.fileUrl != null && message.fileUrl!.isNotEmpty)
              _buildFileAttachmentCard(context, isMe, isDark, colorScheme),
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final hasBeenRead = message.isRead ||
                          message.readBy
                              .where((id) => id != message.senderId)
                              .isNotEmpty;
                      final readersCount = message.readBy
                          .where((id) => id != message.senderId)
                          .length;
                      final tooltipText = message.isRead
                          ? 'Đã xem'
                          : (readersCount > 0
                              ? 'Đã xem ($readersCount)'
                              : 'Đã gửi');
                      return Tooltip(
                        message: tooltipText,
                        child: Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: hasBeenRead
                              ? const Color(0xFF22C55E) // Xanh lục sáng khi đã xem (Seen)
                              : Colors.white60, // Trắng mờ khi đã gửi
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
