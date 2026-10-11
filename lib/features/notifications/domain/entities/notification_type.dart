import 'package:flutter/material.dart';

/// Phân loại thông báo trong ứng dụng PU Connection
enum NotificationType {
  /// Thông báo học tập: Đăng ký tín chỉ, điểm số, lịch thi, học bổng
  academic,

  /// Tương tác xã hội & bạn bè: Lời mời kết bạn, được tag, like, bình luận
  social,

  /// Hoạt động & sự kiện trường/CLB: Sự kiện mới, vé sự kiện, nhắc nhở check-in
  event,

  /// Hệ thống: Cập nhật ứng dụng, an toàn tài khoản, kiểm duyệt nội dung
  system;

  String get displayName {
    switch (this) {
      case NotificationType.academic:
        return 'Học tập';
      case NotificationType.social:
        return 'Bạn bè & Tương tác';
      case NotificationType.event:
        return 'Sự kiện & CLB';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.academic:
        return Icons.school_rounded;
      case NotificationType.social:
        return Icons.people_alt_rounded;
      case NotificationType.event:
        return Icons.event_available_rounded;
      case NotificationType.system:
        return Icons.verified_user_rounded;
    }
  }

  Color get defaultColor {
    switch (this) {
      case NotificationType.academic:
        return const Color(0xFF0284C7); // Sky Blue
      case NotificationType.social:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationType.event:
        return const Color(0xFFF97316); // Phenikaa Orange
      case NotificationType.system:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  static NotificationType fromString(String? typeStr) {
    if (typeStr == null) return NotificationType.system;
    switch (typeStr.toLowerCase()) {
      case 'academic':
      case 'study':
      case 'education':
        return NotificationType.academic;
      case 'social':
      case 'friend':
      case 'comment':
      case 'like':
        return NotificationType.social;
      case 'event':
      case 'club':
        return NotificationType.event;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}
