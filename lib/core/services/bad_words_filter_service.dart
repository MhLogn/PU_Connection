class BadWordsCheckResult {
  final bool hasBadWords;
  final List<String> detectedWords;
  final String? suggestionMessage;

  const BadWordsCheckResult({
    required this.hasBadWords,
    this.detectedWords = const [],
    this.suggestionMessage,
  });

  bool get isValid => !hasBadWords;
}

/// Service phát hiện và lọc từ ngữ nhạy cảm / không phù hợp (Bad Words Filter)
/// Sử dụng Regex biểu thức chính quy tối ưu, chống teencode/ký tự né bộ lọc,
/// bảo vệ môi trường học tập văn minh tại Đại học Phenikaa.
class BadWordsFilterService {
  BadWordsFilterService();

  // Khẳng định ranh giới từ vựng chuẩn Unicode (bao gồm ký tự Latinh mở rộng & tiếng Việt có dấu)
  static const String _letter = r'[a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]';
  static const String _bBefore = '(?<!$_letter)';
  static const String _bAfter = '(?!$_letter)';
  // Dấu phân cách né bộ lọc: dấu chấm, gạch ngang, khoảng trắng, ký tự đặc biệt (KHÔNG bao gồm chữ cái)
  static const String _sep = '[^a-zA-Z0-9\\u00C0-\\u024F\\u1EA0-\\u1EF9]*';

  static RegExp _p(String inner) {
    return RegExp('$_bBefore$inner$_bAfter', caseSensitive: false);
  }

  // Danh mục biểu thức chính quy (Regex) phân loại theo nhóm vi phạm
  static final List<RegExp> _profanityPatterns = [
    // Tiếng Việt tục tĩu / xúc phạm và biến thể né bộ lọc
    _p('(?:đ|d)$_sep[iìíịỉĩyýỳỵỷỹ]+$_sep[tṭ]'),
    _p('(?:đ|d)$_sep[eéèẹẽẻêếềệểễ]+${_sep}o'),
    _p('l$_sep[oòóọỏõôồốộổỗ]+${_sep}n'),
    _p('c$_sep[ặă]c'),
    _p('bu$_sep[oồòóọỏõôốộổỗ]+${_sep}i'),
    _p('đ$_sep[iĩỉìíị]̃?'),
    _p('ch[oó]$_sep(?:ch[eế]t|đ[eẻ]|d[aạ]i)'),
    _p('[oó]c${_sep}ch[oó]'),
    _p('m[eẹ]$_sep(?:m[aà]y|ki[eế]p)'),

    // Viết tắt / teencode xúc phạm
    _p('(?:đ|d)${_sep}m'),
    _p('(?:đ|d)${_sep}k${_sep}m'),
    _p('(?:đ|d)${_sep}c${_sep}m'),
    _p('(?:đ|d)${_sep}m${_sep}m'),
    _p('v${_sep}c${_sep}l'),
    _p('v${_sep}k${_sep}l'),
    _p('v${_sep}c${_sep}c'),
    _p('c${_sep}l${_sep}g${_sep}t'),
    _p('v${_sep}l${_sep}o${_sep}n'),

    // Tiếng Anh thô tục phổ biến
    _p('(?:fuck(?:ing|er|ed)?|shit|bullshit|bitch|asshole|bastard|dick|cunt|pussy|motherfucker)'),

    // Gian lận học tập tiêu cực
    _p(r'(?:thi\s*h[oộ]|l[aà]m\s*h[oộ]\s*(?:đ[oồ]\s*[aá]n|b[aà]i\s*t[aậ]p)|hack\s*đi[eêềếệểễ]m(?:\s*portal)?|mua\s*b[aá]n\s*đ[eề]\s*thi)'),

    // Cờ bạc, cá cược, lừa đảo
    _p(r'(?:c[aá]\s*đ[oộ]\s*(?:b[oó]ng)?|web\s*c[aá]\s*c[uư][oợ]c|l[oô]\s*đ[eề]\s*online|đ[aá]nh\s*b[aà]i\s*ti[eề]n\s*th[aậ]t)'),
  ];

  /// Kiểm tra nhanh xem chuỗi ký tự có chứa từ ngữ nhạy cảm hay không
  bool containsBadWords(String text) {
    if (text.isEmpty) return false;
    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Trích xuất danh sách các từ hoặc cụm từ vi phạm tìm thấy trong văn bản
  List<String> findViolations(String text) {
    if (text.isEmpty) return const [];
    final violations = <String>{};

    for (final pattern in _profanityPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final matchedStr = match.group(0);
        if (matchedStr != null && matchedStr.trim().isNotEmpty) {
          violations.add(matchedStr.trim());
        }
      }
    }

    return violations.toList();
  }

  /// Kiểm tra chi tiết và trả về kết quả kèm gợi ý điều chỉnh
  BadWordsCheckResult check(String text) {
    if (text.isEmpty) {
      return const BadWordsCheckResult(hasBadWords: false);
    }

    final violations = findViolations(text);
    if (violations.isEmpty) {
      return const BadWordsCheckResult(hasBadWords: false);
    }

    final detectedPreview = violations.take(3).map((w) => '"$w"').join(', ');
    final extraCount = violations.length > 3 ? ' và ${violations.length - 3} từ khác' : '';

    return BadWordsCheckResult(
      hasBadWords: true,
      detectedWords: violations,
      suggestionMessage:
          'Nội dung chứa từ ngữ không phù hợp với chuẩn mực văn hóa Phenikaa ($detectedPreview$extraCount). Vui lòng điều chỉnh để đăng bài.',
    );
  }

  /// Che các từ nhạy cảm bằng chuỗi ký tự thay thế (mặc định: ***)
  String maskBadWords(String text, {String replacement = '***'}) {
    if (text.isEmpty) return text;
    var sanitized = text;

    for (final pattern in _profanityPatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) => replacement);
    }

    return sanitized;
  }
}
