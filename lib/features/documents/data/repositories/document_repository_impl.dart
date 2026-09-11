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
}
