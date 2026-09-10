import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String title;
  final String code;
  final String faculty;
  final String fileUrl;
  final String fileType;
  final String fileSize;
  final String authorId;
  final String authorName;
  final String authorStudentId;
  final int downloads;
  final double rating;
  final String? description;
  final DateTime createdAt;

  const DocumentEntity({
    required this.id,
    required this.title,
    required this.code,
    required this.faculty,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.authorId,
    required this.authorName,
    required this.authorStudentId,
    this.downloads = 0,
    this.rating = 5.0,
    this.description,
    required this.createdAt,
  });

  DocumentEntity copyWith({
    String? id,
    String? title,
    String? code,
    String? faculty,
    String? fileUrl,
    String? fileType,
    String? fileSize,
    String? authorId,
    String? authorName,
    String? authorStudentId,
    int? downloads,
    double? rating,
    String? description,
    DateTime? createdAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      faculty: faculty ?? this.faculty,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      downloads: downloads ?? this.downloads,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        code,
        faculty,
        fileUrl,
        fileType,
        fileSize,
        authorId,
        authorName,
        authorStudentId,
        downloads,
        rating,
        description,
        createdAt,
      ];
}
