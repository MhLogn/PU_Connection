import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';

enum DocumentStatus { initial, loading, loaded, error }

class DocumentState extends Equatable {
  final DocumentStatus status;
  final List<DocumentEntity> documents;
  final String selectedFaculty;
  final String searchQuery;
  final bool isUploading;
  final double uploadProgress;
  final String? downloadingDocId;
  final double downloadProgress;
  final String? errorMessage;
  final String? successMessage;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.selectedFaculty = 'Tất cả',
    this.searchQuery = '',
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.downloadingDocId,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.successMessage,
  });

  DocumentState copyWith({
    DocumentStatus? status,
    List<DocumentEntity>? documents,
    String? selectedFaculty,
    String? searchQuery,
    bool? isUploading,
    double? uploadProgress,
    String? downloadingDocId,
    bool clearDownloadingDocId = false,
    double? downloadProgress,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      selectedFaculty: selectedFaculty ?? this.selectedFaculty,
      searchQuery: searchQuery ?? this.searchQuery,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadingDocId: clearDownloadingDocId ? null : (downloadingDocId ?? this.downloadingDocId),
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        documents,
        selectedFaculty,
        searchQuery,
        isUploading,
        uploadProgress,
        downloadingDocId,
        downloadProgress,
        errorMessage,
        successMessage,
      ];
}
