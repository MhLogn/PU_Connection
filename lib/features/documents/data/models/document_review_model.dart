import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/document_review_entity.dart';

class DocumentReviewModel extends DocumentReviewEntity {
  const DocumentReviewModel({
    required super.id,
    required super.documentId,
    required super.userId,
    required super.userName,
    super.userAvatar,
    required super.rating,
    required super.comment,
    required super.createdAt,
  });

  factory DocumentReviewModel.fromEntity(DocumentReviewEntity entity) {
    return DocumentReviewModel(
      id: entity.id,
      documentId: entity.documentId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      rating: entity.rating,
      comment: entity.comment,
      createdAt: entity.createdAt,
    );
  }

  factory DocumentReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DocumentReviewModel.fromMap(data, doc.id);
  }

  factory DocumentReviewModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return DocumentReviewModel(
      id: id,
      documentId: map['documentId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Sinh viên Phenikaa',
      userAvatar: map['userAvatar'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
