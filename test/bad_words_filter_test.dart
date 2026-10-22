import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/bad_words_filter_service.dart';

void main() {
  group('BadWordsFilterService Tests', () {
    late BadWordsFilterService filterService;

    setUp(() {
      filterService = BadWordsFilterService();
    });

    test('Detects direct and teencode Vietnamese profanity', () {
      expect(filterService.containsBadWords('Thằng này nói chuyện vcl thật'), isTrue);
      expect(filterService.containsBadWords('Đ.m mày nói gì đấy'), isTrue);
      expect(filterService.containsBadWords('D.k.m bài này khó thế'), isTrue);
      expect(filterService.containsBadWords('Đéo hiểu kiểu gì luôn'), isTrue);
      expect(filterService.containsBadWords('Mày đúng là đồ chó chết'), isTrue);
      expect(filterService.containsBadWords('Đồ óc chó'), isTrue);
      expect(filterService.containsBadWords('Cái thằng dcm này'), isTrue);
    });

    test('Detects English profanities correctly', () {
      expect(filterService.containsBadWords('What the fuck is this?'), isTrue);
      expect(filterService.containsBadWords('This is pure bullshit'), isTrue);
      expect(filterService.containsBadWords('He is an asshole'), isTrue);
      expect(filterService.containsBadWords('Don\'t be a bitch'), isTrue);
    });

    test('Detects academic dishonesty and cheating services', () {
      expect(filterService.containsBadWords('Nhận làm hộ đồ án tốt nghiệp giá rẻ'), isTrue);
      expect(filterService.containsBadWords('Dịch vụ thi hộ bao đỗ điểm cao'), isTrue);
      expect(filterService.containsBadWords('Cách hack điểm portal sinh viên'), isTrue);
      expect(filterService.containsBadWords('Mua bán đề thi cuối kỳ môn Toán'), isTrue);
    });

    test('Detects gambling and betting scams', () {
      expect(filterService.containsBadWords('Tham gia cá độ bóng đá hôm nay'), isTrue);
      expect(filterService.containsBadWords('Web cá cược uy tín nạp rút nhanh'), isTrue);
      expect(filterService.containsBadWords('Chơi lô đề online ăn thưởng lớn'), isTrue);
    });

    test('Does NOT flag standard Vietnamese academic and campus text (Zero false positives)', () {
      expect(filterService.containsBadWords('Chào mừng tân sinh viên K18 đến với Phenikaa'), isFalse);
      expect(filterService.containsBadWords('Cộng đồng sinh viên hành động vì môi trường'), isFalse);
      expect(filterService.containsBadWords('Tìm nhóm học tập môn Giải tích 2 và Lập trình C++'), isFalse);
      expect(filterService.containsBadWords('Các bạn ơi cho mình xin tài liệu ôn thi môn Mạng máy tính'), isFalse);
      expect(filterService.containsBadWords('Chúc mừng bạn đã hoàn thành bài tập lớn xuất sắc'), isFalse);
      expect(filterService.containsBadWords('Tiến độ dự án đang rất tốt và đúng kế hoạch'), isFalse);
      expect(filterService.containsBadWords('Thảo luận về bài toán con lắc đơn trong môn Vật lý đại cương'), isFalse);
      expect(filterService.containsBadWords('Trường Đại học Phenikaa tuyển sinh các ngành kỹ thuật công nghệ'), isFalse);
      expect(filterService.containsBadWords('Sinh viên nghiên cứu khoa học tại phòng thực hành tòa B2'), isFalse);
      expect(filterService.containsBadWords(''), isFalse);
    });

    test('findViolations returns accurate list of detected terms', () {
      final violations = filterService.findViolations('Bài này khó vcl, đúng là dkm bực mình');
      expect(violations, isNotEmpty);
      expect(violations.length, greaterThanOrEqualTo(2));
    });

    test('check returns detailed BadWordsCheckResult with friendly message', () {
      final cleanResult = filterService.check('Hôm nay thời tiết trường Phenikaa rất đẹp');
      expect(cleanResult.isValid, isTrue);
      expect(cleanResult.hasBadWords, isFalse);
      expect(cleanResult.detectedWords, isEmpty);

      final violationResult = filterService.check('Thằng này ăn nói vcl, dkm');
      expect(violationResult.isValid, isFalse);
      expect(violationResult.hasBadWords, isTrue);
      expect(violationResult.detectedWords, isNotEmpty);
      expect(violationResult.suggestionMessage, contains('chuẩn mực văn hóa Phenikaa'));
    });

    test('maskBadWords replaces inappropriate words with asterisks', () {
      final masked = filterService.maskBadWords('Bực mình vcl đi mất');
      expect(masked, isNot(contains('vcl')));
      expect(masked, contains('***'));
    });
  });
}
