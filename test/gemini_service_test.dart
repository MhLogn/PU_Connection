import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/gemini_service.dart';

void main() {
  group('GeminiService Tests', () {
    late GeminiService geminiService;

    setUp(() {
      // Initialize with empty key to force offline knowledge base testing
      geminiService = GeminiService(apiKey: '');
    });

    test('Answers Calculus question correctly in campus offline mode', () async {
      final reply = await geminiService.sendMessage('Cho mình xin đề cương môn giải tích 2');
      expect(reply, contains('Giải tích 1 & 2'));
      expect(reply, contains('Tích phân kép'));
      expect(reply, contains('Chuỗi số'));
    });

    test('Answers Computer Science and C++ questions correctly', () async {
      final reply = await geminiService.sendMessage('Đề cương lập trình C++ và cấu trúc dữ liệu');
      expect(reply, contains('Công nghệ Thông tin Phenikaa'));
      expect(reply, contains('Lập trình C/C++'));
      expect(reply, contains('OOP'));
    });

    test('Answers English and TOEIC exemption requirements correctly', () async {
      final reply = await geminiService.sendMessage('Quy định miễn tiếng anh bằng bằng TOEIC thế nào?');
      expect(reply, contains('TOEIC'));
      expect(reply, contains('450'));
      expect(reply, contains('Phòng Đào tạo'));
    });

    test('Answers Training Points (DRL) question correctly', () async {
      final reply = await geminiService.sendMessage('Cách tính điểm rèn luyện đrl');
      expect(reply, contains('Điểm Rèn Luyện (ĐRL)'));
      expect(reply, contains('Xuất sắc'));
    });

    test('Answers Campus Department contacts question correctly', () async {
      final reply = await geminiService.sendMessage('Số điện thoại và phòng ban tòa A1');
      expect(reply, contains('Phòng Đào tạo (P.101 Tòa A1)'));
      expect(reply, contains('Phòng Công tác Sinh viên (P.103 Tòa A1)'));
    });

    test('summarizeDocumentContent returns summarized overview', () async {
      final summary = await geminiService.summarizeDocumentContent(
        'Đề thi Giải tích 2 K16',
        'Nội dung gồm 4 câu hỏi về tích phân mặt và chuỗi Fourier',
      );
      expect(summary, isNotEmpty);
    });

    test('resetChat resets session gracefully', () {
      expect(() => geminiService.resetChat(), returnsNormally);
    });
  });
}
