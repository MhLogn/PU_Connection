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

  GeminiService({String apiKey = ''}) : _apiKey = apiKey {
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
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_phenikaaSystemPrompt),
    );
    _chatSession = _model!.startChat();
  }

  Future<String> sendMessage(String prompt) async {
    if (_model == null) {
      return 'Vui lòng cấu hình Gemini API Key để sử dụng Campus Assistant.';
    }

    try {
      _chatSession ??= _model!.startChat();
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      return response.text ?? 'Không thể nhận phản hồi từ AI.';
    } catch (e) {
      return 'Lỗi kết nối AI: ${e.toString()}';
    }
  }

  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }
}
