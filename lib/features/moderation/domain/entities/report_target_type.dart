enum ReportTargetType {
  post,
  comment,
  document,
  user;

  String get displayName {
    switch (this) {
      case ReportTargetType.post:
        return 'Bài viết';
      case ReportTargetType.comment:
        return 'Bình luận';
      case ReportTargetType.document:
        return 'Tài liệu học tập';
      case ReportTargetType.user:
        return 'Người dùng';
    }
  }
}
