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

  const CommentEntity({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    this.authorStudentId = '',
    this.authorFaculty = '',
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorStudentId': authorStudentId,
        'authorFaculty': authorFaculty,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommentEntity.fromMap(Map<String, dynamic> map, {String? id}) {
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
      ];
}
