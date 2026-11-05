import 'package:flutter/material.dart';
import 'package:pu_connection/core/theme/app_theme.dart';

/// Hộp thoại xác nhận thao tác quản trị an toàn (Admin Confirmation Dialog)
class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    this.icon,
    this.isDestructive = false,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    IconData? icon,
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AdminConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDestructive: isDestructive,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryActionColor =
        isDestructive ? AppTheme.coralColor(context) : AppTheme.primaryColor(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryActionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryActionColor, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: primaryActionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
