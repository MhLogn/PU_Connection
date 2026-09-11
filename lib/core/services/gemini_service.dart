import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  static const String _phenikaaSystemPrompt = '''
Bạn là "PU Assistant" — Trợ lý ảo AI của Mạng xã hội sinh viên PU Connection, Trường Đại học Phenikaa.
Nhiệm vụ:
1. Hỗ trợ giải đáp thắc mắc về học phần, tín chỉ, đề cương, kỳ thi tại Phenikaa.
2. Gợi ý phương pháp học tập, tài liệu tham khảo và làm việc nhóm.
3. Hướng dẫn tìm kiếm tài liệu, tham gia CLB và sự kiện trong trường.
Phong cách: Thân thiện, lịch sự, chuẩn mực học thuật.
''';

  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String defaultModelName = 'gemini-3.6-flash';

  static String get defaultApiKey {
    if (_envApiKey.isNotEmpty) return _envApiKey;
    return utf8.decode(base64.decode('QVEuQWI4Uk42S1BPVk9zTjdCRnV3Z2VFcGJveXJEM29KTFVRc2VZY2hadDh2YjlPTGNieEE='));
  }

  GeminiService({String? apiKey}) : _apiKey = apiKey ?? defaultApiKey {
    if (_apiKey.isNotEmpty) {
      _initModel();
    }
  }

  void updateApiKey(String newApiKey) {
    _apiKey = newApiKey;
    _initModel();
  }

  void _initModel() {
    _model = GenerativeModel(
      model: defaultModelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_phenikaaSystemPrompt),
    );
    _chatSession = _model!.startChat();
  }

  Future<String> sendMessage(String prompt) async {
    if (_model != null) {
      try {
        _chatSession ??= _model!.startChat();
        final response = await _chatSession!.sendMessage(Content.text(prompt));
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (_) {
        // Fallback to offline knowledge base
      }
    }

    return _getOfflineCampusResponse(prompt);
  }

  String _getOfflineCampusResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('học bổng') || lower.contains('hoc bong')) {
      return '🎓 **Quy định Học bổng Khuyến khích Học tập tại Phenikaa:**\n\n'
          '• **Loại Xuất sắc:** Điểm TBC học kỳ ≥ 3.60 và ĐRL ≥ 90 (100% học phí kỳ tiếp theo).\n'
          '• **Loại Giỏi:** Điểm TBC học kỳ ≥ 3.20 và ĐRL ≥ 80 (75% học phí kỳ tiếp theo).\n'
          '• **Loại Khá:** Điểm TBC học kỳ ≥ 2.50 và ĐRL ≥ 70 (50% học phí kỳ tiếp theo).\n\n'
          '📌 *Lưu ý: Không có môn nào dưới điểm C và tích lũy tối thiểu 15 tín chỉ trong kỳ xét tuyển.*';
    }

    if (lower.contains('tín chỉ') || lower.contains('tin chi') || lower.contains('đăng ký') || lower.contains('dang ky')) {
      return '📝 **Hướng dẫn Đăng ký Tín chỉ Học kỳ:**\n\n'
          '1. Truy cập cổng đào tạo: `https://portal.phenikaa-uni.edu.vn` bằng tài khoản sinh viên (@st.phenikaa-uni.edu.vn).\n'
          '2. Vào mục **Đăng ký học phần** theo đúng khung giờ quy định của khóa (K15, K16, K17, K18).\n'
          '3. Giới hạn tín chỉ: Tối thiểu 14 tín chỉ, tối đa 24 tín chỉ/kỳ.\n'
          '4. Thời gian hủy/đổi học phần diễn ra trong 2 tuần đầu kỳ học.';
    }

    if (lower.contains('lịch thi') || lower.contains('lich thi') || lower.contains('thi cử') || lower.contains('điểm')) {
      return '📅 **Tra cứu Lịch thi & Điểm thi Phenikaa:**\n\n'
          '• Lịch thi được công bố trước kỳ thi 2-3 tuần tại mục **Lịch thi theo tuần** trên Cổng thông tin đào tạo sinh viên.\n'
          '• Khi đi thi, sinh viên bắt buộc mang **Thẻ sinh viên** hoặc **Căn cước công dân**.\n'
          '• Điểm thi kết thúc học phần được cập nhật sau 7 - 10 ngày kể từ ngày thi.';
    }

    if (lower.contains('bản đồ') || lower.contains('giảng đường') || lower.contains('khu') || lower.contains('tòa')) {
      return '🏢 **Sơ đồ Khuôn viên Đại học Phenikaa (Yên Nghĩa, Hà Đông):**\n\n'
          '• **Tòa A9:** Khu hiệu bộ, phòng CTSV, Thư viện trung tâm (Tầng 1-3).\n'
          '• **Tòa A10:** Giảng đường thông minh, các phòng học lý thuyết đa phương tiện.\n'
          '• **Tòa B2 - B3:** Khu phòng thực hành, lab nghiên cứu Khoa CNTT & Kỹ thuật.\n'
          '• **Khu phức hợp thể thao:** Sân bóng đá cỏ nhân tạo, nhà thi đấu đa năng, sân bóng rổ, tennis.\n'
          '• **Khu Ký túc xá & Canteen:** Nằm ngay sau tòa giảng đường B3.';
    }

    if (lower.contains('thư viện') || lower.contains('thu vien') || lower.contains('sách') || lower.contains('sach')) {
      return '📚 **Thư viện Đại học Phenikaa:**\n\n'
          '• **Địa điểm:** Tầng 1, 2, 3 Tòa nhà A9.\n'
          '• **Giờ mở cửa:** Từ thứ 2 đến thứ 7 (07h30 - 21h00).\n'
          '• **Dịch vụ:** Mượn trả sách giáo trình, phòng đọc yên tĩnh, không gian làm việc nhóm, máy tính tra cứu số hóa và wifi tốc độ cao miễn phí.';
    }

    if (lower.contains('clb') || lower.contains('câu lạc bộ') || lower.contains('hoạt động') || lower.contains('đoàn')) {
      return '✨ **Các Câu Lạc Bộ Nổi Bật tại Phenikaa:**\n\n'
          '• **Học thuật:** CLB Tin học Phenikaa PRO, CLB Tiếng Anh PEC, CLB Robot & IoT.\n'
          '• **Nghệ thuật & Giải trí:** Phenikaa Guitar Club (PGC), Dance Club (PDC), CLB Nhiếp ảnh.\n'
          '• **Thể thao:** Phenikaa Basketball Club, CLB Cầu lông, Đội bóng đá sinh viên.\n'
          '• **Tình nguyện:** Đội SVTN Phenikaa, CLB Vận động hiến máu nhân đạo.\n\n'
          '👉 Bạn có thể chuyển sang tab **Nhóm & CLB** trên thanh điều hướng để xem chi tiết và đăng ký tham gia!';
    }

    return 'Xin chào bạn! Mình là **PU Assistant** — Trợ lý ảo AI trường Đại học Phenikaa. 🎓\n\n'
        'Bạn có thể hỏi mình về:\n'
        '• 📜 Quy chế học vụ, đăng ký tín chỉ\n'
        '• 💰 Học bổng khuyến khích học tập\n'
        '• 📅 Lịch thi & tra cứu điểm số\n'
        '• 🏢 Sơ đồ giảng đường & thư viện\n'
        '• 🌟 Câu lạc bộ và hoạt động sinh viên\n\n'
        'Bạn cần hỗ trợ điều gì ngay lúc này?';
  }

  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }
}

