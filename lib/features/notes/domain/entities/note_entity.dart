import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String authorFaculty;
  final String content;
  final String audience; // 'friends' | 'club'
  final String? clubId;
  final String? clubName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NoteEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    this.authorFaculty = '',
    required this.content,
    required this.audience,
    this.clubId,
    this.clubName,
    required this.createdAt,
    this.updatedAt,
  });

  NoteEntity copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorFaculty,
    String? content,
    String? audience,
    String? clubId,
    String? clubName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorFaculty: authorFaculty ?? this.authorFaculty,
      content: content ?? this.content,
      audience: audience ?? this.audience,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorAvatar,
    authorFaculty,
    content,
    audience,
    clubId,
    clubName,
    createdAt,
    updatedAt,
  ];
}
