import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepository _documentRepository;
  StreamSubscription<List<DocumentEntity>>? _docsSubscription;

  DocumentCubit({
    required DocumentRepository documentRepository,
  })  : _documentRepository = documentRepository,
        super(const DocumentState());

  void init() {
    _documentRepository.seedMockDocumentsIfEmpty();
    loadDocuments();
  }

  void loadDocuments({String? faculty, String? query}) {
    final targetFaculty = faculty ?? state.selectedFaculty;
    final targetQuery = query ?? state.searchQuery;

    emit(state.copyWith(
      status: DocumentStatus.loading,
      selectedFaculty: targetFaculty,
      searchQuery: targetQuery,
    ));

    _docsSubscription?.cancel();
    _docsSubscription = _documentRepository
        .getDocuments(
          faculty: targetFaculty == 'Tất cả' ? null : targetFaculty,
          searchQuery: targetQuery,
        )
        .listen(
      (docs) {
        emit(state.copyWith(
          status: DocumentStatus.loaded,
          documents: docs,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: DocumentStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
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

      // Tăng lượt tải
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

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _docsSubscription?.cancel();
    return super.close();
  }
}
