import 'package:flutter/material.dart';
import '../../domain/entities/notification_type.dart';
import '../cubit/in_app_notifications_state.dart';

class NotificationFilterChips extends StatelessWidget {
  final NotificationType? selectedFilter;
  final InAppNotificationsState state;
  final ValueChanged<NotificationType?> onFilterSelected;

  const NotificationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.state,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'Tất cả',
            count: state.notifications.length,
            isSelected: selectedFilter == null,
            onTap: () => onFilterSelected(null),
            activeColor: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          ...NotificationType.values.map((type) {
            final count = state.countByType(type);
            final isSelected = selectedFilter == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                context: context,
                label: type.displayName,
                icon: type.icon,
                count: count,
                isSelected: isSelected,
                onTap: () => onFilterSelected(type),
                activeColor: type.defaultColor,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
