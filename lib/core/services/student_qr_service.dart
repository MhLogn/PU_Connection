import 'dart:convert';

class StudentQrService {
  static const String qrScheme = 'pu';
  static const String qrHost = 'student';
  static const String qrPrefix = 'pu://student?id=';
  static const String legacyPrefix = 'pu_student:v1:';

  /// Tạo chuỗi nội dung QR định danh sinh viên ổn định, không thay đổi khi sửa hồ sơ
  static String generatePayload({
    required String studentId,
    String fallbackUid = '',
  }) {
    final cleanId = studentId.trim().isNotEmpty
        ? studentId.trim()
        : fallbackUid.trim();
    return '$qrPrefix$cleanId';
  }

  /// Phân tích dữ liệu quét được từ camera và trả về mã định danh sinh viên hợp lệ
  static String? parseIdentifier(String? rawData) {
    if (rawData == null || rawData.trim().isEmpty) return null;
    final text = rawData.trim();

    // 1. Định dạng chuẩn URI: pu://student?id=23010390
    if (text.startsWith(qrPrefix)) {
      final id = text.substring(qrPrefix.length).trim();
      if (id.isNotEmpty) return id;
    }

    final uri = Uri.tryParse(text);
    if (uri != null && uri.scheme == qrScheme && uri.host == qrHost) {
      final paramId = uri.queryParameters['id'];
      if (paramId != null && paramId.trim().isNotEmpty) {
        return paramId.trim();
      }
      if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.trim().isNotEmpty) {
        return uri.pathSegments.first.trim();
      }
    }

    // 2. Định dạng có tiền tố phiên bản: pu_student:v1:23010390
    if (text.startsWith(legacyPrefix)) {
      final id = text.substring(legacyPrefix.length).trim();
      if (id.isNotEmpty) return id;
    }

    // 3. Định dạng JSON cũ (backward compatibility)
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final Map<String, dynamic> map = jsonDecode(text);
        final studentId = map['studentId'] as String?;
        if (studentId != null && studentId.trim().isNotEmpty) {
          return studentId.trim();
        }
        final uid = map['uid'] as String?;
        if (uid != null && uid.trim().isNotEmpty) {
          return uid.trim();
        }
      } catch (_) {}
    }

    // 4. Định dạng mã số sinh viên trực tiếp (Ví dụ: 23010390, 8-10 ký tự số/chữ)
    final idRegex = RegExp(r'^[A-Za-z0-9_]{6,16}$');
    if (idRegex.hasMatch(text) && !text.contains(' ') && !text.contains('/')) {
      return text;
    }

    return null;
  }

  /// Kiểm tra chuỗi QR có phải định dạng nhận diện sinh viên PU Connection hợp lệ không
  static bool isValidPuQr(String? rawData) {
    return parseIdentifier(rawData) != null;
  }
}
