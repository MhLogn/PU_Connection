import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepository _documentRepository;

  DocumentCubit({
    required DocumentRepository documentRepository,
  })  : _documentRepository = documentRepository,
        super(const DocumentState());

  void init() {
    loadDocuments();
  }

  Future<void> loadDocuments({
    String? faculty,
    String? query,
    bool refresh = false,
  }) async {
    final targetFaculty = faculty ?? state.selectedFaculty;
    final targetQuery = query ?? state.searchQuery;

    if (!refresh) {
      emit(state.copyWith(
        status: DocumentStatus.loading,
        selectedFaculty: targetFaculty,
        searchQuery: targetQuery,
        clearLastDocument: true,
        hasMore: true,
      ));
    }

    try {
      final result = await _documentRepository.getDocumentsPaged(
        faculty: targetFaculty == 'Tất cả' ? null : targetFaculty,
        searchQuery: targetQuery,
        lastDocument: null,
        limit: 15,
      );

      emit(state.copyWith(
        status: DocumentStatus.loaded,
        documents: result.items,
        selectedFaculty: targetFaculty,
        searchQuery: targetQuery,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: DocumentStatus.error,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> loadMoreDocuments() async {
    if (state.isLoadingMore || !state.hasMore || state.status == DocumentStatus.loading) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final result = await _documentRepository.getDocumentsPaged(
        faculty: state.selectedFaculty == 'Tất cả' ? null : state.selectedFaculty,
        searchQuery: state.searchQuery,
        lastDocument: state.lastDocument,
        limit: 15,
      );

      final existingIds = state.documents.map((d) => d.id).toSet();
      final newUniqueItems =
          result.items.where((d) => !existingIds.contains(d.id)).toList();

      emit(state.copyWith(
        documents: [...state.documents, ...newUniqueItems],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore && newUniqueItems.isNotEmpty,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void filterByFaculty(String faculty) {
    if (state.selectedFaculty == faculty) return;
    loadDocuments(faculty: faculty);
  }

  void search(String query) {
    loadDocuments(query: query);
  }

  Future<bool> uploadDocument({
    required DocumentEntity document,
    required File file,
  }) async {
    try {
      emit(state.copyWith(isUploading: true, clearError: true, clearSuccess: true));
      await _documentRepository.uploadDocument(document: document, file: file);
      emit(state.copyWith(
        isUploading: false,
        successMessage: 'Tải tài liệu lên thành công!',
      ));
      await loadDocuments(refresh: true);
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        errorMessage: 'Lỗi tải tài liệu: ${e.toString()}',
      ));
      return false;
    }
  }

  Future<File?> downloadDocument(
    DocumentEntity doc, {
    bool openAfterDownload = true,
  }) async {
    try {
      emit(state.copyWith(
        downloadingDocId: doc.id,
        downloadProgress: 0.1,
        clearError: true,
      ));

      final extension = doc.fileType.isNotEmpty ? doc.fileType : 'pdf';
      final fileName = '${doc.code}_${doc.title}.$extension'.replaceAll(' ', '_');

      final file = await _documentRepository.downloadDocument(
        fileUrl: doc.fileUrl,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0) {
            emit(state.copyWith(downloadProgress: received / total));
          }
        },
      );

      await _documentRepository.incrementDownloads(doc.id);

      emit(state.copyWith(
        clearDownloadingDocId: true,
        downloadProgress: 1.0,
        successMessage: 'Đã tải thành công: ${doc.title}',
      ));

      if (openAfterDownload && file.existsSync()) {
        await OpenFilex.open(file.path);
      }

      return file;
    } catch (e) {
      emit(state.copyWith(
        clearDownloadingDocId: true,
        errorMessage: 'Không thể tải tài liệu: ${e.toString()}',
      ));
      return null;
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentRepository.deleteDocument(documentId);
      final updated = state.documents.where((d) => d.id != documentId).toList();
      emit(state.copyWith(
        documents: updated,
        successMessage: 'Đã xóa tài liệu thành công',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Lỗi khi xóa tài liệu: ${e.toString()}',
      ));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
