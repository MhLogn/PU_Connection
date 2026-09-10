import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.title,
    required super.code,
    required super.faculty,
    required super.fileUrl,
    required super.fileType,
    required super.fileSize,
    required super.authorId,
    required super.authorName,
    required super.authorStudentId,
    super.downloads,
    super.rating,
    super.description,
    required super.createdAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      title: map['title'] as String? ?? '',
      code: map['code'] as String? ?? '',
      faculty: map['faculty'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      fileType: map['fileType'] as String? ?? 'pdf',
      fileSize: map['fileSize'] as String? ?? '1.0 MB',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Sinh viên Phenikaa',
      authorStudentId: map['authorStudentId'] as String? ?? '',
      downloads: (map['downloads'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      description: map['description'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DocumentModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'faculty': faculty,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'authorId': authorId,
      'authorName': authorName,
      'authorStudentId': authorStudentId,
      'downloads': downloads,
      'rating': rating,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      title: entity.title,
      code: entity.code,
      faculty: entity.faculty,
      fileUrl: entity.fileUrl,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorStudentId: entity.authorStudentId,
      downloads: entity.downloads,
      rating: entity.rating,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }
}
