import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/event_entity.dart';

class EventTicketDialog extends StatelessWidget {
  final EventEntity event;
  final String studentName;
  final String studentId;
  final String faculty;

  const EventTicketDialog({
    super.key,
    required this.event,
    required this.studentName,
    required this.studentId,
    this.faculty = '',
  });

  static void show(
    BuildContext context, {
    required EventEntity event,
    required String studentName,
    required String studentId,
    String faculty = '',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EventTicketDialog(
        event: event,
        studentName: studentName,
        studentId: studentId,
        faculty: faculty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');
    final ticketCode = 'PU-${event.id.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}-${studentId.isNotEmpty ? studentId : "ST"}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ticket Header Banner
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: const BoxDecoration(
                gradient: AppTheme.oceanToOrangeGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/logo/phenikaa_logo.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppTheme.oceanBlue, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PHENIKAA UNIVERSITY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'E-TICKET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Middle Ticket Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // QR Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(110, 110),
                                painter: _SimulatedQrPainter(),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, size: 24, color: AppTheme.oceanBlue),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ticketCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Vé đã xác thực • Hợp lệ khi check-in',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Student & Event info
                  _buildTicketRow('${l10n.full_name}:', studentName.isNotEmpty ? studentName : 'Sinh viên Phenikaa', theme),
                  const SizedBox(height: 6),
                  _buildTicketRow('${l10n.student_id}:', studentId.isNotEmpty ? studentId : 'Chưa cập nhật', theme),
                  if (faculty.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildTicketRow('${l10n.faculty}:', faculty, theme),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildTicketRow('Thời gian:', dateFormat.format(event.startDate), theme),
                  const SizedBox(height: 6),
                  _buildTicketRow('Địa điểm:', event.location, theme),
                ],
              ),
            ),

            // Dashed Divider & Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulatedQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E293B);
    const cellSize = 5.0;
    final cols = (size.width / cellSize).floor();
    final rows = (size.height / cellSize).floor();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Create QR position patterns in 3 corners
        final isTopLeft = r < 5 && c < 5;
        final isTopRight = r < 5 && c >= cols - 5;
        final isBottomLeft = r >= rows - 5 && c < 5;
        final isCenter = (r >= rows / 2 - 2 && r <= rows / 2 + 2) && (c >= cols / 2 - 2 && c <= cols / 2 + 2);

        if (isCenter) continue;

        if (isTopLeft || isTopRight || isBottomLeft) {
          if (r == 0 || r == 4 || c == 0 || c == 4 || (r >= 1 && r <= 3 && c >= 1 && c <= 3 && (r == 2 && c == 2))) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 0.5, cellSize - 0.5),
              paint,
            );
          }
        } else if ((r * 7 + c * 13 + (r % 3)) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 0.5, cellSize - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
