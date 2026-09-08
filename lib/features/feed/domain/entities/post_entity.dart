import 'package:equatable/equatable.dart';

class PostAttachment extends Equatable {
  final String url;
  final String name;
  final int sizeBytes;
  final String type; // 'image' | 'pdf' | 'docx' | 'file'

  const PostAttachment({
    required this.url,
    required this.name,
    this.sizeBytes = 0,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'url': url,
        'name': name,
        'sizeBytes': sizeBytes,
        'type': type,
      };

  factory PostAttachment.fromMap(Map<String, dynamic> map) {
    return PostAttachment(
      url: map['url'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? 'image',
    );
  }

  @override
  List<Object?> get props => [url, name, sizeBytes, type];
}

class PostEntity extends Equatable {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String authorStudentId;
  final String authorFaculty;
  final String content;
  final String postType; // 'text' | 'image' | 'document'
  final String category; // 'Thảo luận' | 'Hỏi bài' | 'Tài liệu' | 'Tìm nhóm'
  final String? subjectCode; // Ví dụ: 'CNTT-225', 'CSDL-101'
  final List<PostAttachment> attachments;
  final List<String> tags;
  final List<String> likedUsers;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  const PostEntity({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    this.authorStudentId = '',
    this.authorFaculty = '',
    required this.content,
    this.postType = 'text',
    this.category = 'Thảo luận',
    this.subjectCode,
    this.attachments = const [],
    this.tags = const [],
    this.likedUsers = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  bool isLikedBy(String uid) => likedUsers.contains(uid);

  @override
  List<Object?> get props => [
        postId,
        authorId,
        authorName,
        authorAvatar,
        authorStudentId,
        authorFaculty,
        content,
        postType,
        category,
        subjectCode,
        attachments,
        tags,
        likedUsers,
        likeCount,
        commentCount,
        createdAt,
      ];
}
