import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/document_review_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_model.dart';
import '../models/document_review_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinaryService;
  final Dio _dio;

  DocumentRepositoryImpl({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
    Dio? dio,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cloudinaryService = cloudinaryService ?? CloudinaryService(),
       _dio = dio ?? Dio();

  CollectionReference get _docsRef =>
      _firestore.collection(FirebaseConstants.studyDocumentsCollection);

  /// Nhận diện và loại bỏ các tệp PDF mẫu / có sẵn được tạo trước đây
  bool _isSeedOrDummyDocument(DocumentEntity doc) {
    final url = doc.fileUrl.toLowerCase().trim();
    if (url.contains('dummy.pdf') ||
        url.contains('sample.pdf') ||
        url.contains('example.com') ||
        url.isEmpty) {
      return true;
    }
    if (doc.authorId == 'pu_admin' ||
        doc.authorId == 'admin_phenikaa_01' ||
        doc.authorId == 'student_3' ||
        doc.authorId == 'student_4' ||
        doc.authorStudentId == 'CNTT-PU' ||
        doc.authorStudentId == 'ENG-PU' ||
        doc.authorStudentId == 'GV-012' ||
        doc.authorStudentId == 'KHCB-01' ||
        doc.id.startsWith('doc_admin_')) {
      return true;
    }
    const dummyTitleKeywords = [
      'đề cương & ngân hàng trắc nghiệm lập trình mạng',
      'slide bài giảng cơ sở dữ liệu & sql nâng cao',
      'bộ đề thi thử xác suất thống kê có lời giải chi tiết',
      'dược lý học đại cương & tổng hợp tương tác thuốc',
      'tổng hợp từ vựng & đề thi tiếng anh b1 vstep phenikaa',
      'giáo trình giải tích 1 & 2 chuẩn phenikaa',
      'slide bài giảng lập trình hướng đối tượng oop (c++)',
      'tài liệu không rõ nguồn gốc vi phạm bản quyền',
    ];
    final titleLower = doc.title.toLowerCase().trim();
    for (final dummy in dummyTitleKeywords) {
      if (titleLower.contains(dummy)) return true;
    }
    return false;
  }

  @override
  Future<PaginatedResult<DocumentEntity>> getDocumentsPaged({
    String? faculty,
    String? searchQuery,
    dynamic lastDocument,
    int limit = 15,
  }) async {
    Query query = _docsRef.orderBy('createdAt', descending: true);

    final hasFaculty =
        faculty != null && faculty.isNotEmpty && faculty != 'Tất cả';

    if (hasFaculty) {
      query = query.where('faculty', isEqualTo: faculty);
    }

    if (lastDocument is DocumentSnapshot) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    try {
      final snapshot = await query.get();
      var docs = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      // Lọc các tài liệu mẫu nếu có
      docs = docs.where((doc) => !_isSeedOrDummyDocument(doc)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        docs = docs.where((doc) {
          final matchTitle = doc.title.toLowerCase().contains(q);
          final matchCode = doc.code.toLowerCase().contains(q);
          final matchFaculty = doc.faculty.toLowerCase().contains(q);
          return matchTitle || matchCode || matchFaculty;
        }).toList();
      }

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length >= limit;

      return PaginatedResult<DocumentEntity>(
        items: docs,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (_) {
      Query fallbackQuery = _docsRef.orderBy('createdAt', descending: true);
      if (lastDocument is DocumentSnapshot) {
        fallbackQuery = fallbackQuery.startAfterDocument(lastDocument);
      }
      fallbackQuery = fallbackQuery.limit(limit * 2);

      final snapshot = await fallbackQuery.get();
      var docs = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      // Lọc các tài liệu mẫu nếu có
      docs = docs.where((doc) => !_isSeedOrDummyDocument(doc)).toList();

      if (hasFaculty) {
        docs = docs
            .where((doc) => doc.faculty.toLowerCase() == faculty.toLowerCase())
            .toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        docs = docs.where((doc) {
          final matchTitle = doc.title.toLowerCase().contains(q);
          final matchCode = doc.code.toLowerCase().contains(q);
          final matchFaculty = doc.faculty.toLowerCase().contains(q);
          return matchTitle || matchCode || matchFaculty;
        }).toList();
      }

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length >= (limit * 2);

      return PaginatedResult<DocumentEntity>(
        items: docs,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    }
  }

  @override
  Stream<List<DocumentEntity>> getDocuments({
    String? faculty,
    String? searchQuery,
  }) {
    return _docsRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      var list = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      // Bỏ các file pdf có sẵn đã tạo và dọn sạch trên Firestore
      list = list.where((doc) {
        if (_isSeedOrDummyDocument(doc)) {
          if (doc.id.isNotEmpty) {
            _docsRef.doc(doc.id).delete().catchError((_) {});
          }
          return false;
        }
        return true;
      }).toList();

      if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
        list = list
            .where((doc) => doc.faculty.toLowerCase() == faculty.toLowerCase())
            .toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((doc) {
          final matchTitle = doc.title.toLowerCase().contains(q);
          final matchCode = doc.code.toLowerCase().contains(q);
          final matchFaculty = doc.faculty.toLowerCase().contains(q);
          return matchTitle || matchCode || matchFaculty;
        }).toList();
      }

      return list;
    });
  }

  @override
  Future<DocumentEntity> uploadDocument({
    required DocumentEntity document,
    required File file,
  }) async {
    String fileUrl = document.fileUrl;

    if (file.existsSync()) {
      final uploadedUrl = await _cloudinaryService.uploadDocument(file);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        fileUrl = uploadedUrl;
      }
    }

    final bytes = await file.length();
    String calculatedSize = document.fileSize;
    if (bytes > 0) {
      if (bytes < 1024 * 1024) {
        calculatedSize = '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        calculatedSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    final ext = file.path.split('.').last.toLowerCase();
    final docType =
        ['pdf', 'docx', 'doc', 'zip', 'rar', 'xlsx', 'pptx'].contains(ext)
        ? ext
        : document.fileType;

    final model = DocumentModel(
      id: '',
      title: document.title,
      code: document.code,
      faculty: document.faculty,
      fileUrl: fileUrl,
      fileType: docType,
      fileSize: calculatedSize,
      authorId: document.authorId,
      authorName: document.authorName,
      authorStudentId: document.authorStudentId,
      downloads: 0,
      rating: 5.0,
      description: document.description,
      createdAt: DateTime.now(),
    );

    final docRef = await _docsRef.add(model.toMap());
    return DocumentModel.fromMap(model.toMap(), docRef.id);
  }

  @override
  Future<void> incrementDownloads(String documentId) async {
    if (documentId.isEmpty) return;
    try {
      await _docsRef.doc(documentId).update({
        'downloads': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  @override
  Future<File> downloadDocument({
    required String fileUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '${dir.path}/$sanitizedFileName';

    final response = await _dio.download(
      fileUrl,
      filePath,
      onReceiveProgress: onProgress,
    );

    if (response.statusCode != 200 && response.statusCode != 206) {
      throw Exception('Tải tài liệu thất bại với mã: ${response.statusCode}');
    }

    return File(filePath);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    if (documentId.isEmpty) return;
    await _docsRef.doc(documentId).delete();
  }

  // In-memory fallback cho reviews
  final Map<String, List<DocumentReviewEntity>> _inMemoryReviews = {};

  @override
  Future<void> submitDocumentReview(DocumentReviewEntity review) async {
    if (review.documentId.isEmpty) return;

    // 1. Lưu In-memory
    final list = _inMemoryReviews.putIfAbsent(review.documentId, () => []);
    list.removeWhere((r) => r.userId == review.userId);
    list.insert(0, review);

    // 2. Lưu Firestore
    try {
      final docRef = _docsRef.doc(review.documentId);
      final model = DocumentReviewModel.fromEntity(review);

      await docRef
          .collection(FirebaseConstants.documentReviewsSubcollection)
          .doc(review.userId)
          .set(model.toMap());

      // Tính toán lại average rating
      final allReviews = await docRef
          .collection(FirebaseConstants.documentReviewsSubcollection)
          .get();

      if (allReviews.docs.isNotEmpty) {
        final total = allReviews.docs.fold<double>(
          0.0,
          (acc, doc) =>
              acc + ((doc.data()['rating'] as num?)?.toDouble() ?? 5.0),
        );
        final avg = total / allReviews.docs.length;
        await docRef.update({'rating': double.parse(avg.toStringAsFixed(1))});
      }
    } catch (_) {}
  }

  @override
  Stream<List<DocumentReviewEntity>> watchDocumentReviews(String documentId) {
    if (documentId.isEmpty) return Stream.value([]);

    try {
      return _docsRef
          .doc(documentId)
          .collection(FirebaseConstants.documentReviewsSubcollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final reviews = snapshot.docs
                .map((doc) => DocumentReviewModel.fromFirestore(doc))
                .toList();
            _inMemoryReviews[documentId] = reviews;
            return reviews;
          })
          .handleError((_) {
            return _inMemoryReviews[documentId] ?? [];
          });
    } catch (_) {
      return Stream.value(_inMemoryReviews[documentId] ?? []);
    }
  }

  @override
  Future<List<DocumentReviewEntity>> getDocumentReviews(
    String documentId,
  ) async {
    if (documentId.isEmpty) return [];

    try {
      final snapshot = await _docsRef
          .doc(documentId)
          .collection(FirebaseConstants.documentReviewsSubcollection)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final reviews = snapshot.docs
            .map((doc) => DocumentReviewModel.fromFirestore(doc))
            .toList();
        _inMemoryReviews[documentId] = reviews;
        return reviews;
      }
    } catch (_) {}

    return _inMemoryReviews[documentId] ?? [];
  }
}
