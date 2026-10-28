import 'package:equatable/equatable.dart';

class DocumentReviewEntity extends Equatable {
  final String id;
  final String documentId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const DocumentReviewEntity({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  DocumentReviewEntity copyWith({
    String? id,
    String? documentId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return DocumentReviewEntity(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    documentId,
    userId,
    userName,
    userAvatar,
    rating,
    comment,
    createdAt,
  ];
}
