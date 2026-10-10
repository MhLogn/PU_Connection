enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  inappropriate,
  academicDishonesty,
  impersonation,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam / Quảng cáo rác';
      case ReportReason.harassment:
        return 'Quấy rối / Đe dọa / Xúc phạm';
      case ReportReason.hateSpeech:
        return 'Phát ngôn thù địch / Kích động';
      case ReportReason.inappropriate:
        return 'Nội dung phản cảm / Đồi trụy';
      case ReportReason.academicDishonesty:
        return 'Gian lận học tập / Mua bán bài tập';
      case ReportReason.impersonation:
        return 'Mạo danh sinh viên hoặc giảng viên';
      case ReportReason.other:
        return 'Lý do khác';
    }
  }
}
