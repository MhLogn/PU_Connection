import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.postId,
    required super.authorId,
    required super.authorName,
    super.authorAvatar,
    super.authorStudentId,
    super.authorFaculty,
    required super.content,
    super.postType,
    super.category,
    super.subjectCode,
    super.attachments,
    super.tags,
    super.likedUsers,
    super.likeCount,
    super.commentCount,
    super.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      postId: id,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Sinh viên Phenikaa',
      authorAvatar: map['authorAvatar'] as String? ?? '',
      authorStudentId: map['authorStudentId'] as String? ?? '',
      authorFaculty: map['authorFaculty'] as String? ?? '',
      content: map['content'] as String? ?? '',
      postType: map['postType'] as String? ?? 'text',
      category: map['category'] as String? ?? 'Thảo luận',
      subjectCode: map['subjectCode'] as String?,
      attachments: (map['attachments'] as List? ?? [])
          .map((item) => PostAttachment.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      tags: List<String>.from(map['tags'] as List? ?? []),
      likedUsers: List<String>.from(map['likedUsers'] as List? ?? []),
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorStudentId': authorStudentId,
      'authorFaculty': authorFaculty,
      'content': content,
      'postType': postType,
      'category': category,
      'subjectCode': subjectCode,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'tags': tags,
      'likedUsers': likedUsers,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PostModel copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorStudentId,
    String? authorFaculty,
    String? content,
    String? postType,
    String? category,
    String? subjectCode,
    List<PostAttachment>? attachments,
    List<String>? tags,
    List<String>? likedUsers,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      authorFaculty: authorFaculty ?? this.authorFaculty,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      category: category ?? this.category,
      subjectCode: subjectCode ?? this.subjectCode,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      likedUsers: likedUsers ?? this.likedUsers,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
