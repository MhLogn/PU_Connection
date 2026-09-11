import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinaryService;
  final Dio _dio;

  DocumentRepositoryImpl({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
    Dio? dio,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        _dio = dio ?? Dio();

  CollectionReference get _docsRef =>
      _firestore.collection(FirebaseConstants.studyDocumentsCollection);

  @override
  Stream<List<DocumentEntity>> getDocuments({
    String? faculty,
    String? searchQuery,
  }) {
    Query query = _docsRef.orderBy('createdAt', descending: true);

    if (faculty != null && faculty.isNotEmpty && faculty != 'Tất cả') {
      query = query.where('faculty', isEqualTo: faculty);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

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
    final docType = ['pdf', 'docx', 'doc', 'zip', 'rar', 'xlsx', 'pptx'].contains(ext)
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
  Future<void> seedMockDocumentsIfEmpty() async {
    try {
      final snapshot = await _docsRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final sampleDocs = [
          {
            'title': 'Đề cương & Ngân hàng trắc nghiệm Lập trình Mạng',
            'code': 'CNTT-225',
            'faculty': 'CNTT',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '4.2 MB',
            'authorId': 'pu_admin',
            'authorName': 'Ban Học Tập Khoa CNTT',
            'authorStudentId': 'CNTT-PU',
            'downloads': 1240,
            'rating': 4.9,
            'description': 'Đề cương ôn tập chi tiết gồm 150 câu hỏi trắc nghiệm kèm đáp án và giải thích.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          },
          {
            'title': 'Slide bài giảng Cơ sở dữ liệu & SQL Nâng cao',
            'code': 'CSDL-101',
            'faculty': 'CNTT',
            'fileUrl': 'https://pdfobject.com/pdf/sample.pdf',
            'fileType': 'pdf',
            'fileSize': '8.5 MB',
            'authorId': 'pu_admin',
            'authorName': 'Giảng viên Bộ môn HTTT',
            'authorStudentId': 'GV-012',
            'downloads': 980,
            'rating': 4.8,
            'description': 'Bộ slide trọn gói 12 chương bài giảng CSDL từ thiết kế ERD đến tối ưu hóa truy vấn SQL.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          },
          {
            'title': 'Bộ đề thi thử Xác suất Thống kê có lời giải chi tiết',
            'code': 'XSTK-01',
            'faculty': 'Kinh tế & QTKD',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '2.8 MB',
            'authorId': 'student_3',
            'authorName': 'Lê Phương Thảo',
            'authorStudentId': '23010512',
            'downloads': 1560,
            'rating': 5.0,
            'description': 'Tuyển tập 10 bộ đề thi học kỳ các năm gần nhất có lời giải từng bước.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          },
          {
            'title': 'Dược lý học đại cương & Tổng hợp tương tác thuốc',
            'code': 'DUOC-102',
            'faculty': 'Dược - Y',
            'fileUrl': 'https://pdfobject.com/pdf/sample.pdf',
            'fileType': 'pdf',
            'fileSize': '6.1 MB',
            'authorId': 'student_4',
            'authorName': 'Nguyễn Hoàng Nam',
            'authorStudentId': '22030119',
            'downloads': 620,
            'rating': 4.7,
            'description': 'Sổ tay bỏ túi Dược lý và phân loại nhóm kháng sinh lâm sàng.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          },
          {
            'title': 'Tổng hợp từ vựng & đề thi Tiếng Anh B1 Vstep Phenikaa',
            'code': 'ENG-B1',
            'faculty': 'Ngôn ngữ Anh',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '15.3 MB',
            'authorId': 'pu_admin',
            'authorName': 'Trung tâm Ngoại ngữ Phenikaa',
            'authorStudentId': 'ENG-PU',
            'downloads': 2100,
            'rating': 4.9,
            'description': 'Trọn bộ bí kíp ôn thi chuẩn đầu ra B1 Vstep dành riêng cho sinh viên Phenikaa.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
          },
        ];

        final batch = _firestore.batch();
        for (final doc in sampleDocs) {
          final newRef = _docsRef.doc();
          batch.set(newRef, doc);
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}
