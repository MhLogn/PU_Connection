import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String authorStudentId;
  final String authorFaculty;
  final String content;
  final DateTime createdAt;
  final List<String> likedUserIds;
  final int likeCount;
  final String? replyToCommentId;
  final String? replyToAuthorName;
  final bool isEdited;

  const CommentEntity({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    this.authorStudentId = '',
    this.authorFaculty = '',
    required this.content,
    required this.createdAt,
    this.likedUserIds = const [],
    this.likeCount = 0,
    this.replyToCommentId,
    this.replyToAuthorName,
    this.isEdited = false,
  });

  bool isLikedBy(String userId) => likedUserIds.contains(userId);

  CommentEntity copyWith({
    String? commentId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorStudentId,
    String? authorFaculty,
    String? content,
    DateTime? createdAt,
    List<String>? likedUserIds,
    int? likeCount,
    String? replyToCommentId,
    String? replyToAuthorName,
    bool? isEdited,
  }) {
    return CommentEntity(
      commentId: commentId ?? this.commentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      authorFaculty: authorFaculty ?? this.authorFaculty,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      likeCount: likeCount ?? this.likeCount,
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      replyToAuthorName: replyToAuthorName ?? this.replyToAuthorName,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorStudentId': authorStudentId,
        'authorFaculty': authorFaculty,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'likedUserIds': likedUserIds,
        'likeCount': likeCount,
        'replyToCommentId': replyToCommentId,
        'replyToAuthorName': replyToAuthorName,
        'isEdited': isEdited,
      };

  factory CommentEntity.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawLikes = map['likedUserIds'];
    List<String> likes = [];
    if (rawLikes is List) {
      likes = rawLikes.map((e) => e.toString()).toList();
    }

    return CommentEntity(
      commentId: id ?? map['commentId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Sinh viên Phenikaa',
      authorAvatar: map['authorAvatar'] as String? ?? '',
      authorStudentId: map['authorStudentId'] as String? ?? '',
      authorFaculty: map['authorFaculty'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now(),
      likedUserIds: likes,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? likes.length,
      replyToCommentId: map['replyToCommentId'] as String?,
      replyToAuthorName: map['replyToAuthorName'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        commentId,
        authorId,
        authorName,
        authorAvatar,
        authorStudentId,
        authorFaculty,
        content,
        createdAt,
        likedUserIds,
        likeCount,
        replyToCommentId,
        replyToAuthorName,
        isEdited,
      ];
}
