import 'dart:io';
import '../../../../core/models/paginated_result.dart';
import '../entities/document_entity.dart';
import '../entities/document_review_entity.dart';

abstract class DocumentRepository {
  Stream<List<DocumentEntity>> getDocuments({
    String? faculty,
    String? searchQuery,
  });

  Future<PaginatedResult<DocumentEntity>> getDocumentsPaged({
    String? faculty,
    String? searchQuery,
    dynamic lastDocument,
    int limit = 15,
  });

  Future<DocumentEntity> uploadDocument({
    required DocumentEntity document,
    required File file,
  });

  Future<void> incrementDownloads(String documentId);

  Future<File> downloadDocument({
    required String fileUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  });

  Future<void> deleteDocument(String documentId);

  /// Gửi đánh giá & nhận xét tài liệu
  Future<void> submitDocumentReview(DocumentReviewEntity review);

  /// Lắng nghe danh sách đánh giá của tài liệu
  Stream<List<DocumentReviewEntity>> watchDocumentReviews(String documentId);

  /// Lấy danh sách đánh giá của tài liệu
  Future<List<DocumentReviewEntity>> getDocumentReviews(String documentId);
}
