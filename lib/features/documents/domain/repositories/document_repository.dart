import 'dart:io';
import '../entities/document_entity.dart';

abstract class DocumentRepository {
  Stream<List<DocumentEntity>> getDocuments({
    String? faculty,
    String? searchQuery,
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
}
