import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/student_qr_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'user_profile_page.dart';

class StudentQrScannerPage extends StatefulWidget {
  const StudentQrScannerPage({super.key});

  @override
  State<StudentQrScannerPage> createState() => _StudentQrScannerPageState();
}

class _StudentQrScannerPageState extends State<StudentQrScannerPage> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    await _scannerController.stop();

    final studentId = StudentQrService.parseIdentifier(rawValue);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    if (studentId == null || studentId.isEmpty) {
      _showErrorDialog(
        title: l10n.invalid_qr_title,
        message: l10n.invalid_qr_desc,
        onRetry: _resumeScanning,
      );
      return;
    }

    // Kiểm tra nếu là QR của chính người đang đăng nhập
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      final currentUser = authState.user;
      final isOwnQr =
          (currentUser.studentId.isNotEmpty &&
              currentUser.studentId.toLowerCase() == studentId.toLowerCase()) ||
          currentUser.uid == studentId;

      if (isOwnQr) {
        _showOwnQrDialog(currentUser.uid);
        return;
      }
    }

    // Tra cứu hồ sơ từ AuthRepository (Firestore + fallback danh bạ sinh viên)
    try {
      final authRepo = sl<AuthRepository>();
      final user = await authRepo.getUserByStudentId(studentId);

      if (!mounted) return;

      if (user == null) {
        _showErrorDialog(
          title: l10n.profile_not_found_title,
          message: l10n.profile_not_found_desc(studentId),
          onRetry: _resumeScanning,
        );
        return;
      }

      if (user.isBanned) {
        _showErrorDialog(
          title: 'Hồ sơ bị vô hiệu hóa',
          message:
              'Tài khoản sinh viên này (${user.displayName}) hiện đang bị tạm khóa hoặc vô hiệu hóa bởi Ban Quản trị.',
          onRetry: _resumeScanning,
        );
        return;
      }

      // Điều hướng đến hồ sơ của sinh viên được quét
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              userId: user.uid,
              userName: user.displayName,
              studentId: user.studentId,
              faculty: user.faculty,
              avatarUrl: user.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        title: 'Lỗi kết nối',
        message:
            'Không thể kết nối đến máy chủ để tra cứu hồ sơ: ${e.toString().replaceFirst('Exception: ', '')}',
        onRetry: _resumeScanning,
      );
    }
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  void _showOwnQrDialog(String myUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(l10n.own_qr_title),
            ],
          ),
          content: Text(l10n.own_qr_desc),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resumeScanning();
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Quay về Profile của chính mình
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Đóng trang quét
              },
              child: Text(l10n.close),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              child: Text(l10n.retry),
            ),
          ],
        );
      },
    );
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhập mã sinh viên'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Mã số sinh viên (MSSV)',
            hintText: 'Ví dụ: 23010390',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor(context),
            ),
            onPressed: () {
              final id = textController.text.trim();
              Navigator.pop(ctx);
              if (id.isNotEmpty) {
                _handleBarcode(
                  BarcodeCapture(
                    barcodes: [Barcode(rawValue: 'pu://student?id=$id')],
                  ),
                );
              }
            },
            child: const Text('Tra cứu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Quét mã sinh viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppTheme.accentOrange : Colors.white,
            ),
            tooltip: 'Bật / Tắt đèn flash',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Đổi camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Nhập MSSV thủ công',
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera scanner view
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        color: Colors.white70,
                        size: 54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể truy cập Camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng cấp quyền Camera trong Cài đặt thiết bị hoặc sử dụng nhập mã sinh viên thủ công.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: const Icon(Icons.keyboard_outlined),
                        label: const Text('Nhập MSSV thủ công'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor(context),
                        ),
                        onPressed: _showManualInputDialog,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Scanner Target Frame Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor(context),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruction Text below frame
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Text(
                    'Hướng camera vào mã QR thẻ sinh viên Phenikaa để xem hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: AppTheme.accentOrange,
                  ),
                  label: const Text(
                    'Không quét được? Nhập mã thủ công',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _showManualInputDialog,
                ),
              ],
            ),
          ),

          // Loading indicator when looking up profile
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor(context),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Đang tra cứu hồ sơ sinh viên...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
