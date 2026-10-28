import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/theme/app_theme.dart';

/// Hộp thoại xem trước và căn chỉnh ảnh (Pinch to Zoom, Pan) trước khi tải lên
class ImageCropPreviewDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final bool isAvatar;

  const ImageCropPreviewDialog({
    super.key,
    required this.imageBytes,
    required this.isAvatar,
  });

  @override
  State<ImageCropPreviewDialog> createState() => _ImageCropPreviewDialogState();
}

class _ImageCropPreviewDialogState extends State<ImageCropPreviewDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetTransform() {
    _transformController.value = Matrix4.identity();
  }

  Future<void> _confirmCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Đợi frame hoàn tất render
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _cropKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      // Render với tỉ lệ pixelRatio = 2.5 để ảnh sắc nét chất lượng cao
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final croppedBytes = byteData?.buffer.asUint8List();

      if (mounted) {
        Navigator.of(context).pop(croppedBytes);
      }
    } catch (e) {
      debugPrint('Lỗi crop ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xử lý ảnh: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double cropWidth;
    final double cropHeight;

    if (widget.isAvatar) {
      cropWidth = (screenWidth - 48).clamp(240.0, 300.0);
      cropHeight = cropWidth;
    } else {
      cropWidth = screenWidth - 32;
      cropHeight = (cropWidth * 9 / 18).clamp(140.0, 190.0);
    }

    final title =
        widget.isAvatar ? 'Căn chỉnh ảnh đại diện' : 'Căn chỉnh ảnh bìa';
    final subtitle =
        widget.isAvatar
            ? 'Thu phóng và di chuyển ảnh vào khung tròn'
            : 'Thu phóng và di chuyển ảnh vào khung hiển thị ảnh bìa';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF121418),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(
                        context,
                      ).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isAvatar
                          ? Icons.crop_free_rounded
                          : Icons.panorama_rounded,
                      color: AppTheme.primaryColor(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Viewport & Interactive Cropper
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: cropWidth,
                  height: cropHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Vùng ảnh tương tác được chụp lại (RepaintBoundary)
                      RepaintBoundary(
                        key: _cropKey,
                        child: Container(
                          color: Colors.black,
                          child: ClipRRect(
                            borderRadius:
                                widget.isAvatar
                                    ? BorderRadius.circular(cropWidth / 2)
                                    : BorderRadius.circular(12),
                            child: InteractiveViewer(
                              transformationController: _transformController,
                              boundaryMargin: const EdgeInsets.all(200),
                              minScale: 0.6,
                              maxScale: 5.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Center(
                                child: Image.memory(
                                  widget.imageBytes,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Khung viền chỉ dẫn trực quan (không bị chụp vào ảnh lưu)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape:
                                widget.isAvatar
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                            borderRadius:
                                widget.isAvatar
                                    ? null
                                    : BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.8),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Toolbar căn chỉnh nhanh (Đặt lại zoom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _resetTransform,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Đặt lại kích thước',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing
                              ? null
                              : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _confirmCrop,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon:
                          _isProcessing
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isProcessing ? 'Đang xử lý...' : 'Xác nhận & Tải lên',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
