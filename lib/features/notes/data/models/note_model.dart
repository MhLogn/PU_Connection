import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorAvatar = '',
    super.authorFaculty = '',
    required super.content,
    required super.audience,
    super.clubId,
    super.clubName,
    required super.createdAt,
    super.updatedAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel.fromMap(data, doc.id);
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return NoteModel(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Sinh viên PU',
      authorAvatar: map['authorAvatar'] as String? ?? '',
      authorFaculty: map['authorFaculty'] as String? ?? '',
      content: map['content'] as String? ?? '',
      audience: map['audience'] as String? ?? 'friends',
      clubId: map['clubId'] as String?,
      clubName: map['clubName'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorFaculty': authorFaculty,
      'content': content,
      'audience': audience,
      'clubId': clubId,
      'clubName': clubName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
