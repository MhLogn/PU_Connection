import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/bad_words_filter_service.dart';

void main() {
  group('BadWordsFilterService Tests', () {
    late BadWordsFilterService filterService;

    setUp(() {
      filterService = BadWordsFilterService();
    });

    test('Detects direct and teencode Vietnamese profanity', () {
      expect(
        filterService.containsBadWords('Thằng này nói chuyện vcl thật'),
        isTrue,
      );
      expect(filterService.containsBadWords('Đ.m mày nói gì đấy'), isTrue);
      expect(filterService.containsBadWords('D.k.m bài này khó thế'), isTrue);
      expect(filterService.containsBadWords('Đéo hiểu kiểu gì luôn'), isTrue);
      expect(filterService.containsBadWords('Mày đúng là đồ chó chết'), isTrue);
      expect(filterService.containsBadWords('Đồ óc chó'), isTrue);
      expect(filterService.containsBadWords('Cái thằng dcm này'), isTrue);
      expect(filterService.containsBadWords('V-C-L luôn bạn ơi'), isTrue);
      expect(filterService.containsBadWords('Thằng cặc này'), isTrue);
      expect(filterService.containsBadWords('Con đĩ kia'), isTrue);
    });

    test('Detects English profanities correctly', () {
      expect(filterService.containsBadWords('What the fuck is this?'), isTrue);
      expect(filterService.containsBadWords('This is pure bullshit'), isTrue);
      expect(filterService.containsBadWords('He is an asshole'), isTrue);
      expect(filterService.containsBadWords('Don\'t be a bitch'), isTrue);
      expect(filterService.containsBadWords('Shut up you bastard'), isTrue);
      expect(filterService.containsBadWords('WHAT THE FUCKING HELL'), isTrue);
    });

    test('Detects academic dishonesty and cheating services', () {
      expect(
        filterService.containsBadWords('Nhận làm hộ đồ án tốt nghiệp giá rẻ'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Dịch vụ thi hộ bao đỗ điểm cao'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Cách hack điểm portal sinh viên'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Mua bán đề thi cuối kỳ môn Toán'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Nhận làm hộ bài tập lớn lấy điểm A'),
        isTrue,
      );
    });

    test('Detects gambling and betting scams', () {
      expect(
        filterService.containsBadWords('Tham gia cá độ bóng đá hôm nay'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Web cá cược uy tín nạp rút nhanh'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Chơi lô đề online ăn thưởng lớn'),
        isTrue,
      );
      expect(
        filterService.containsBadWords('Đánh bài tiền thật đổi thưởng uy tín'),
        isTrue,
      );
    });

    test(
      'Does NOT flag standard Vietnamese academic terms (Zero false positives)',
      () {
        // Các từ khóa học thuật cụ thể theo yêu cầu bài toán
        expect(filterService.containsBadWords('phân tích'), isFalse);
        expect(filterService.containsBadWords('tích lũy'), isFalse);
        expect(filterService.containsBadWords('học tập'), isFalse);
        expect(filterService.containsBadWords('vật lý'), isFalse);
        expect(filterService.containsBadWords('báo cáo'), isFalse);
        expect(filterService.containsBadWords('đồ án'), isFalse);
        expect(filterService.containsBadWords('công tác'), isFalse);
        expect(filterService.containsBadWords('hoạt động'), isFalse);

        // Câu hoàn chỉnh trong bối cảnh học tập Phenikaa
        expect(
          filterService.containsBadWords(
            'Chúng ta cần phân tích dữ liệu cho đồ án môn học',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Tích lũy đủ tín chỉ để xét tốt nghiệp',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Nhóm học tập giải tích và vật lý đại cương',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Nộp báo cáo tiến độ tuần này cho thầy cô',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Kế hoạch công tác và hoạt động tình nguyện Phenikaa',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Chào mừng tân sinh viên K18 đến với Phenikaa',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Thảo luận môn Giải tích 2 và Lập trình C++',
          ),
          isFalse,
        );
        expect(
          filterService.containsBadWords(
            'Sinh viên nghiên cứu khoa học tại phòng thực hành tòa B2',
          ),
          isFalse,
        );

        // Chuỗi rỗng và khoảng trắng
        expect(filterService.containsBadWords(''), isFalse);
        expect(filterService.containsBadWords('   '), isFalse);
      },
    );

    test('findViolations returns accurate list of detected terms', () {
      final violations = filterService.findViolations(
        'Bài này khó vcl, đúng là dkm bực mình',
      );
      expect(violations, isNotEmpty);
      expect(violations.length, greaterThanOrEqualTo(2));
    });

    test(
      'check returns detailed BadWordsCheckResult with contextual actionLabel',
      () {
        // Văn bản sạch
        final cleanResult = filterService.check(
          'Hôm nay thời tiết trường Phenikaa rất đẹp',
        );
        expect(cleanResult.isValid, isTrue);
        expect(cleanResult.hasBadWords, isFalse);
        expect(cleanResult.detectedWords, isEmpty);
        expect(cleanResult.suggestionMessage, isNull);

        // Vi phạm mặc định (không truyền actionLabel)
        final violationDefault = filterService.check(
          'Thằng này ăn nói vcl, dkm',
        );
        expect(violationDefault.isValid, isFalse);
        expect(violationDefault.hasBadWords, isTrue);
        expect(violationDefault.detectedWords, isNotEmpty);
        expect(
          violationDefault.suggestionMessage,
          contains('chuẩn mực văn hóa Phenikaa'),
        );
        expect(
          violationDefault.suggestionMessage,
          contains('trước khi tiếp tục'),
        );

        // Vi phạm với actionLabel: gửi tin nhắn (Chat)
        final chatResult = filterService.check(
          'Ăn nói như shit vậy',
          actionLabel: 'gửi tin nhắn',
        );
        expect(chatResult.isValid, isFalse);
        expect(
          chatResult.suggestionMessage,
          contains('để gửi tin nhắn'),
        );

        // Vi phạm với actionLabel: gửi đề xuất CLB
        final clubResult = filterService.check(
          'CLB cá độ bóng đá sinh viên',
          actionLabel: 'gửi đề xuất CLB',
        );
        expect(clubResult.isValid, isFalse);
        expect(
          clubResult.suggestionMessage,
          contains('để gửi đề xuất CLB'),
        );

        // Vi phạm với actionLabel: tạo nhóm học tập
        final groupResult = filterService.check(
          'Nhận làm hộ đồ án qua môn',
          actionLabel: 'tạo nhóm học tập',
        );
        expect(groupResult.isValid, isFalse);
        expect(
          groupResult.suggestionMessage,
          contains('để tạo nhóm học tập'),
        );

        // Vi phạm với actionLabel: tải lên tài liệu
        final docResult = filterService.check(
          'Tài liệu hack điểm portal',
          actionLabel: 'tải lên tài liệu',
        );
        expect(docResult.isValid, isFalse);
        expect(
          docResult.suggestionMessage,
          contains('để tải lên tài liệu'),
        );

        // Vi phạm với actionLabel: chia sẻ ghi chú
        final noteResult = filterService.check(
          'Hôm nay thi như cặc chán vcl',
          actionLabel: 'chia sẻ ghi chú',
        );
        expect(noteResult.isValid, isFalse);
        expect(
          noteResult.suggestionMessage,
          contains('để chia sẻ ghi chú'),
        );

        // Chuỗi rỗng hoặc chỉ có khoảng trắng
        expect(filterService.check('').isValid, isTrue);
        expect(filterService.check('   \t\n  ').isValid, isTrue);
      },
    );

    test('maskBadWords replaces inappropriate words with asterisks', () {
      final masked = filterService.maskBadWords('Bực mình vcl đi mất');
      expect(masked, isNot(contains('vcl')));
      expect(masked, contains('***'));
    });

    test('Multi-field form isolation test (Club Proposal scenario)', () {
      // Giả lập biểu mẫu đề xuất CLB nhiều trường
      final validName = 'CLB Lập trình Thi đấu Phenikaa';
      final invalidReason = 'Tạo CLB để nhận thi hộ và làm hộ đồ án cho sinh viên';
      final validDescription = 'Sinh hoạt định kỳ thứ Năm hàng tuần tại phòng A9-301';

      final nameCheck = filterService.check(validName, actionLabel: 'gửi đề xuất CLB');
      final reasonCheck = filterService.check(invalidReason, actionLabel: 'gửi đề xuất CLB');
      final descCheck = filterService.check(validDescription, actionLabel: 'gửi đề xuất CLB');

      expect(nameCheck.isValid, isTrue, reason: 'Tên CLB hợp lệ không được bị chặn');
      expect(reasonCheck.isValid, isFalse, reason: 'Mục đích chứa từ khóa gian lận phải bị phát hiện');
      expect(reasonCheck.detectedWords, contains('thi hộ'));
      expect(descCheck.isValid, isTrue, reason: 'Mô tả hợp lệ không được bị chặn');
    });

    test('Multi-field form isolation test (User Profile scenario)', () {
      // Giả lập chỉnh sửa hồ sơ
      final invalidDisplayName = 'Nguyễn Văn Đ.m';
      final validBio = 'Sinh viên K17 khoa CNTT, đam mê nghiên cứu AI và Mobile.';

      final nameResult = filterService.check(invalidDisplayName, actionLabel: 'cập nhật tên hiển thị');
      final bioResult = filterService.check(validBio, actionLabel: 'cập nhật tiểu sử');

      expect(nameResult.isValid, isFalse, reason: 'Tên hiển thị chứa từ tục phải bị chặn');
      expect(bioResult.isValid, isTrue, reason: 'Tiểu sử chuẩn mực phải hợp lệ');
    });
  });
}
