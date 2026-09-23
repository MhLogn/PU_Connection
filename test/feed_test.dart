import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/feed/data/models/post_model.dart';
import 'package:pu_connection/features/feed/domain/entities/post_entity.dart';

void main() {
  group('PostAttachment Tests', () {
    test('converts to Map and from Map correctly', () {
      const att = PostAttachment(
        url: 'https://cloudinary.com/slide.pptx',
        name: 'Slide_Bai_Giang.pptx',
        type: 'pptx',
        sizeBytes: 1048576,
      );

      final map = att.toMap();
      expect(map['url'], 'https://cloudinary.com/slide.pptx');
      expect(map['name'], 'Slide_Bai_Giang.pptx');
      expect(map['type'], 'pptx');
      expect(map['sizeBytes'], 1048576);

      final reconstructed = PostAttachment.fromMap(map);
      expect(reconstructed.url, att.url);
      expect(reconstructed.name, att.name);
      expect(reconstructed.type, att.type);
      expect(reconstructed.sizeBytes, att.sizeBytes);
    });
  });

  group('PostModel & PostEntity Tests', () {
    final now = DateTime(2026, 9, 24, 8, 30);
    final post = PostModel(
      postId: 'post_123',
      authorId: 'user_456',
      authorName: 'Nguyễn Văn A',
      authorStudentId: '23010390',
      authorFaculty: 'Khoa Công nghệ thông tin',
      content: 'Tài liệu ôn thi cuối kỳ Giải tích 1',
      category: 'Tài liệu',
      subjectCode: 'MATH-101',
      attachments: const [
        PostAttachment(
          url: 'https://cloudinary.com/doc.pdf',
          name: 'De_thi_giai_tich.pdf',
          type: 'pdf',
          sizeBytes: 2048,
        ),
      ],
      tags: const ['GiaiTich', 'Phenikaa'],
      likedUsers: const ['user_789'],
      likeCount: 1,
      commentCount: 0,
      createdAt: now,
    );

    test('isLikedBy correctly identifies user like status', () {
      expect(post.isLikedBy('user_789'), isTrue);
      expect(post.isLikedBy('user_999'), isFalse);
    });

    test('copyWith updates specified fields', () {
      final updated = post.copyWith(
        content: 'Tài liệu đã được cập nhật bản mới nhất',
        category: 'Thảo luận',
        likeCount: 2,
      );

      expect(updated.content, 'Tài liệu đã được cập nhật bản mới nhất');
      expect(updated.category, 'Thảo luận');
      expect(updated.likeCount, 2);
      expect(updated.postId, post.postId);
      expect(updated.authorName, post.authorName);
    });

    test('PostModel converts to Map and from Map correctly', () {
      final map = post.toMap();
      expect(map['authorName'], 'Nguyễn Văn A');
      expect(map['subjectCode'], 'MATH-101');
      expect(map['category'], 'Tài liệu');
      expect((map['attachments'] as List).length, 1);

      final fromMap = PostModel.fromMap(map, 'post_123');
      expect(fromMap.postId, 'post_123');
      expect(fromMap.authorName, 'Nguyễn Văn A');
      expect(fromMap.subjectCode, 'MATH-101');
      expect(fromMap.attachments.first.name, 'De_thi_giai_tich.pdf');
    });
  });
}
