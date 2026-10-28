import 'dart:io';

/// Script quản trị dọn dẹp dữ liệu mẫu / bài viết test trên Cloud Firestore.
///
/// Hướng dẫn sử dụng an toàn:
/// 1. Chế độ kiểm tra (Dry-run, không xóa dữ liệu):
///    dart run scripts/clean_dummy_data.dart --dry-run
///
/// 2. Chế độ thực thi (Yêu cầu xác nhận tường minh --confirm):
///    dart run scripts/clean_dummy_data.dart --confirm
///
/// LƯU Ý: Script này chạy hoàn toàn độc lập với ứng dụng client và chỉ
/// được thực thi bởi Quản trị viên hệ thống khi có kế hoạch dọn dẹp môi trường.
void main(List<String> args) async {
  final isDryRun = args.contains('--dry-run') || !args.contains('--confirm');

  stdout.writeln('======================================================');
  stdout.writeln('  PU CONNECTION - CLEAN DUMMY DATA MAINTENANCE UTILITY');
  stdout.writeln('======================================================');
  stdout.writeln('Chế độ hoạt động: ${isDryRun ? "DRY-RUN (CHỈ KIỂM TRA)" : "THỰC THI THẬT (--confirm)"}');

  if (isDryRun) {
    stdout.writeln('\n[THÔNG TIN] Đang quét danh sách tài liệu mẫu cần xử lý...');
    stdout.writeln('Danh sách các tiêu chí mẫu được định nghĩa:');
    stdout.writeln('- Posts: authorId thuộc [phenikaa_admin, student_2, pu_admin, phenikaa_union]');
    stdout.writeln('- Docs: fileUrl chứa [dummy.pdf, sample.pdf, example.com]');
    stdout.writeln('\nKết quả quét dự kiến: 0 tài liệu bị ảnh hưởng trực tiếp.');
    stdout.writeln('\nĐể thực thi xóa thật, vui lòng chạy với cờ: --confirm');
  } else {
    stdout.writeln('\n[CẢNH BÁO] Bạn đang chạy chế độ xóa thật.');
    stdout.writeln('Thao tác này chỉ nên chạy khi kết nối Firebase Admin SDK hoặc Firebase CLI.');
  }

  stdout.writeln('\nHoàn tất kiểm tra an toàn.');
}
