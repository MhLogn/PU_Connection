enum ReportReason {
  inappropriate,
  spam,
  harassment,
  misinformation,
  academicDishonesty,
  hateSpeech,
  impersonation,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Nội dung không phù hợp';
      case ReportReason.spam:
        return 'Spam hoặc quảng cáo';
      case ReportReason.harassment:
        return 'Quấy rối hoặc bắt nạt';
      case ReportReason.misinformation:
        return 'Thông tin sai lệch';
      case ReportReason.academicDishonesty:
        return 'Vi phạm bản quyền / Gian lận học thuật';
      case ReportReason.hateSpeech:
        return 'Phát ngôn thù địch / Kích động';
      case ReportReason.impersonation:
        return 'Mạo danh sinh viên hoặc giảng viên';
      case ReportReason.other:
        return 'Lý do khác';
    }
  }
}
