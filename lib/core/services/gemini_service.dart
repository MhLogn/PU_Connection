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

    // 1. Điểm rèn luyện (ĐRL)
    if (lower.contains('rèn luyện') || lower.contains('ren luyen') || lower.contains('đrl') || lower.contains('drl')) {
      return '🌟 **Hướng dẫn Đánh giá Điểm Rèn Luyện (ĐRL) Phenikaa:**\n\n'
          '• **Thang điểm 100 gồm 5 tiêu chí:**\n'
          '  1. Ý thức học tập (tối đa 20 điểm) — không thi hộ, không nợ học phí.\n'
          '  2. Ý thức chấp hành nội quy, quy chế trường (tối đa 25 điểm).\n'
          '  3. Tham gia hoạt động chính trị, văn hóa, xã hội, CLB, thể thao (tối đa 20 điểm).\n'
          '  4. Phẩm chất công dân và quan hệ cộng đồng (tối đa 25 điểm).\n'
          '  5. Ý thức tham gia công tác lớp, đoàn thể, ban cán sự (tối đa 10 điểm).\n\n'
          '🏅 **Xếp loại:** Xuất sắc (≥ 90), Giỏi (80–89), Khá (65–79), Trung bình (50–64).';
    }

    // 2. Danh bạ phòng ban & liên hệ
    if (lower.contains('phòng ban') || lower.contains('phong ban') || lower.contains('liên hệ') || lower.contains('lien he') || lower.contains('hotline')) {
      return '📞 **Danh bạ Phòng ban Hỗ trợ Sinh viên Phenikaa:**\n\n'
          '• **Phòng Đào tạo (P.101 Tòa A1):** Giải quyết đăng ký tín chỉ, bảng điểm, xét tốt nghiệp.\n'
          '• **Phòng Công tác Sinh viên (P.103 Tòa A1):** Thẻ sinh viên, chế độ chính sách, học bổng, giấy xác nhận sinh viên.\n'
          '• **Đoàn Thanh niên - Hội Sinh viên (P.204 Tòa A1):** Hoạt động phong trào, ĐRL, đăng ký tình nguyện.\n'
          '• **Ban Quản lý Ký túc xá:** Văn phòng tầng 1 KTX, hotline hỗ trợ 24/7.\n'
          '• **Trạm Y tế trường:** Tầng 1 Tòa A5 (sơ cấp cứu và bảo hiểm y tế).';
    }

    // 3. Ngoại ngữ & Miễn giảm TOEIC/IELTS
    if (lower.contains('tiếng anh') || lower.contains('tieng anh') || lower.contains('toeic') || lower.contains('ielts') || lower.contains('miễn')) {
      return '🌐 **Quy định Miễn giảm & Chuẩn đầu ra Ngoại ngữ Phenikaa:**\n\n'
          '• **Chứng chỉ TOEIC Quốc tế (hoặc nội bộ):**\n'
          '  - Đạt TOEIC ≥ 450 (hoặc B1): Miễn học phần Tiếng Anh 1.\n'
          '  - Đạt TOEIC ≥ 550: Miễn Tiếng Anh 1 & 2.\n'
          '  - Đạt TOEIC ≥ 650: Đạt chuẩn đầu ra Ngoại ngữ tốt nghiệp Đại học.\n'
          '• **Chứng chỉ IELTS:**\n'
          '  - IELTS ≥ 4.5: Tương đương B1, được xét miễn Tiếng Anh cơ bản.\n'
          '  - IELTS ≥ 5.5: Đạt chuẩn đầu ra Đại học khối kỹ thuật & kinh tế.\n\n'
          '📌 *Nộp chứng chỉ trực tiếp tại Phòng Đào tạo (P.101 Tòa A1) trong 4 tuần đầu kỳ học.*';
    }

    // 4. Giải tích & Toán cao cấp
    if (lower.contains('giải tích') || lower.contains('giai tich') || lower.contains('toán') || lower.contains('toan cao cap')) {
      return '📐 **Trọng tâm Ôn tập Môn Giải tích 1 & 2 (Khoa KHCB Phenikaa):**\n\n'
          '• **Giải tích 1:**\n'
          '  - Giới hạn & Khảo sát hàm số (quy tắc L\'Hôpital, khai triển Maclaurin).\n'
          '  - Đạo hàm, vi phân và ứng dụng tìm cực trị.\n'
          '  - Tích phân bất định & tích phân suy rộng loại 1, loại 2.\n'
          '• **Giải tích 2:**\n'
          '  - Hàm nhiều biến: Đạo hàm riêng, vi phân toàn phần, cực trị có điều kiện (Lagrange).\n'
          '  - Tích phân kép (tọa độ cực) & Tích phân bội ba (tọa độ trụ, cầu).\n'
          '  - Tích phân đường & mặt: Công thức Green, Gauss-Ostrogradsky, Stokes.\n'
          '  - Chuỗi số & chuỗi hàm: Tiêu chuẩn D\'Alembert, Cauchy, chuỗi lũy thừa và bán kính hội tụ.\n\n'
          '💡 *Mẹo: Vào mục "Kho tài liệu (DocsHub)" tìm mã MAT101 / MAT102 để tải đề thi thử các kỳ trước nhé!*';
    }

    // 5. Lập trình & CNTT
    if (lower.contains('lập trình') || lower.contains('lap trinh') || lower.contains('c++') || lower.contains('java') || lower.contains('cntt')) {
      return '💻 **Đề cương Cốt lõi Khoa Công nghệ Thông tin Phenikaa:**\n\n'
          '• **Lập trình C/C++ & Cấu trúc Dữ liệu:**\n'
          '  - Quản lý bộ nhớ động (`malloc`/`free`, `new`/`delete`), con trỏ và mảng con trỏ.\n'
          '  - Danh sách liên kết đơn/kép, Ngăn xếp (Stack), Hàng đợi (Queue).\n'
          '  - Cây nhị phân tìm kiếm (BST), Đồ thị (DFS/BFS, Dijkstra).\n'
          '• **Lập trình Hướng đối tượng (OOP):**\n'
          '  - 4 trụ cột: Đóng gói (Encapsulation), Kế thừa (Inheritance), Đa hình (Polymorphism), Trừu tượng (Abstraction).\n'
          '  - Nạp chồng toán tử, hàm ảo (`virtual function`) và interface.\n\n'
          '🎯 *Tham gia CLB Tin học Phenikaa PRO hoặc nhóm học tập trong app để luyện code cùng nhau nhé!*';
    }

    // 6. Học bổng
    if (lower.contains('học bổng') || lower.contains('hoc bong')) {
      return '🎓 **Quy định Học bổng Khuyến khích Học tập tại Phenikaa:**\n\n'
          '• **Loại Xuất sắc:** Điểm TBC học kỳ ≥ 3.60 và ĐRL ≥ 90 (100% học phí kỳ tiếp theo).\n'
          '• **Loại Giỏi:** Điểm TBC học kỳ ≥ 3.20 và ĐRL ≥ 80 (75% học phí kỳ tiếp theo).\n'
          '• **Loại Khá:** Điểm TBC học kỳ ≥ 2.50 và ĐRL ≥ 70 (50% học phí kỳ tiếp theo).\n\n'
          '📌 *Lưu ý: Không có môn nào dưới điểm C và tích lũy tối thiểu 15 tín chỉ trong kỳ xét tuyển.*';
    }

    // 7. Tín chỉ & Đăng ký môn
    if (lower.contains('tín chỉ') || lower.contains('tin chi') || lower.contains('đăng ký') || lower.contains('dang ky')) {
      return '📝 **Hướng dẫn Đăng ký Tín chỉ Học kỳ:**\n\n'
          '1. Truy cập cổng đào tạo: `https://portal.phenikaa-uni.edu.vn` bằng tài khoản sinh viên (@st.phenikaa-uni.edu.vn).\n'
          '2. Vào mục **Đăng ký học phần** theo đúng khung giờ quy định của khóa (K15, K16, K17, K18).\n'
          '3. Giới hạn tín chỉ: Tối thiểu 14 tín chỉ, tối đa 24 tín chỉ/kỳ.\n'
          '4. Thời gian hủy/đổi học phần diễn ra trong 2 tuần đầu kỳ học.';
    }

    // 8. Thư viện
    if (lower.contains('thư viện') || lower.contains('thu vien') || lower.contains('sách') || lower.contains('sach')) {
      return '📚 **Thư viện Đại học Phenikaa:**\n\n'
          '• **Địa điểm:** Tầng 1, 2, 3 Tòa nhà A9.\n'
          '• **Giờ mở cửa:** Từ thứ 2 đến thứ 7 (07h30 - 21h00).\n'
          '• **Dịch vụ:** Mượn trả sách giáo trình, phòng đọc yên tĩnh, không gian làm việc nhóm, máy tính tra cứu số hóa và wifi tốc độ cao miễn phí.';
    }

    // 9. Câu lạc bộ & Đoàn hội
    if (lower.contains('clb') || lower.contains('câu lạc bộ') || lower.contains('hoạt động') || lower.contains('đoàn')) {
      return '✨ **Các Câu Lạc Bộ Nổi Bật tại Phenikaa:**\n\n'
          '• **Học thuật:** CLB Tin học Phenikaa PRO, CLB Tiếng Anh PEC, CLB Robot & IoT.\n'
          '• **Nghệ thuật & Giải trí:** Phenikaa Guitar Club (PGC), Dance Club (PDC), CLB Nhiếp ảnh.\n'
          '• **Thể thao:** Phenikaa Basketball Club, CLB Cầu lông, Đội bóng đá sinh viên.\n'
          '• **Tình nguyện:** Đội SVTN Phenikaa, CLB Vận động hiến máu nhân đạo.\n\n'
          '👉 Bạn có thể chuyển sang tab **Nhóm & CLB** trên thanh điều hướng để xem chi tiết và đăng ký tham gia!';
    }

    // 10. Lịch thi & Điểm thi
    if (lower.contains('lịch thi') || lower.contains('lich thi') || lower.contains('thi cử') || lower.contains('điểm thi') || lower.contains('bảng điểm') || lower.contains('kết quả thi')) {
      return '📅 **Tra cứu Lịch thi & Điểm thi Phenikaa:**\n\n'
          '• Lịch thi được công bố trước kỳ thi 2-3 tuần tại mục **Lịch thi theo tuần** trên Cổng thông tin đào tạo sinh viên.\n'
          '• Khi đi thi, sinh viên bắt buộc mang **Thẻ sinh viên** hoặc **Căn cước công dân**.\n'
          '• Điểm thi kết thúc học phần được cập nhật sau 7 - 10 ngày kể từ ngày thi.';
    }

    // 11. Sơ đồ khuôn viên & Giảng đường
    if (lower.contains('bản đồ') || lower.contains('giảng đường') || lower.contains('khuôn viên') || lower.contains('tòa nhà') || lower.contains('khu') || lower.contains('tòa')) {
      return '🏢 **Sơ đồ Khuôn viên Đại học Phenikaa (Yên Nghĩa, Hà Đông):**\n\n'
          '• **Tòa A9:** Khu hiệu bộ, phòng CTSV, Thư viện trung tâm (Tầng 1-3).\n'
          '• **Tòa A10:** Giảng đường thông minh, các phòng học lý thuyết đa phương tiện.\n'
          '• **Tòa B2 - B3:** Khu phòng thực hành, lab nghiên cứu Khoa CNTT & Kỹ thuật.\n'
          '• **Khu phức hợp thể thao:** Sân bóng đá cỏ nhân tạo, nhà thi đấu đa năng, sân bóng rổ, tennis.\n'
          '• **Khu Ký túc xá & Canteen:** Nằm ngay sau tòa giảng đường B3.';
    }

    return 'Xin chào bạn! Mình là **PU Assistant** — Trợ lý ảo AI trường Đại học Phenikaa. 🎓\n\n'
        'Bạn có thể hỏi mình về:\n'
        '• 📜 Quy chế học vụ, đăng ký tín chỉ & miễn giảm tiếng Anh\n'
        '• 💰 Học bổng khuyến khích học tập & Điểm rèn luyện (ĐRL)\n'
        '• 📐 Trọng tâm đề cương ôn thi Giải tích, Lập trình C++, Triết học\n'
        '• 📅 Lịch thi & tra cứu điểm số\n'
        '• 🏢 Sơ đồ giảng đường, thư viện A9 & danh bạ phòng ban A1\n'
        '• 🌟 Câu lạc bộ và hoạt động sinh viên\n\n'
        'Bạn cần hỗ trợ điều gì ngay lúc này?';
  }

  /// Tóm tắt nhanh tài liệu hoặc bài viết học tập
  Future<String> summarizeDocumentContent(String title, String content) async {
    final prompt = 'Hãy tóm tắt ngắn gọn và nêu 3 điểm cốt lõi của tài liệu học tập sau đây cho sinh viên Phenikaa:\n'
        'Tiêu đề: $title\n'
        'Nội dung: $content';
    return sendMessage(prompt);
  }

  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }
}

