import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/documents/domain/entities/document_entity.dart';
import 'package:pu_connection/features/documents/data/models/document_model.dart';
import 'package:pu_connection/features/documents/domain/repositories/document_repository.dart';
import 'package:pu_connection/features/documents/presentation/cubit/document_cubit.dart';
import 'package:pu_connection/features/documents/presentation/cubit/document_state.dart';

class MockDocumentRepository implements DocumentRepository {
  final List<DocumentEntity> _docs = [
    DocumentEntity(
      id: 'doc_1',
      title: 'Đề cương Lập trình Mạng',
      code: 'CNTT-225',
      faculty: 'CNTT',
      fileUrl: 'https://example.com/test.pdf',
      fileType: 'pdf',
      fileSize: '3.5 MB',
      authorId: 'auth_1',
      authorName: 'Nguyễn Văn A',
      authorStudentId: '23010001',
      downloads: 10,
      rating: 4.8,
      createdAt: DateTime(2026, 1, 1),
    ),
    DocumentEntity(
      id: 'doc_2',
      title: 'Giáo trình Giải tích 1',
      code: 'TOAN-101',
      faculty: 'Khoa học cơ bản',
      fileUrl: 'https://example.com/toan.pdf',
      fileType: 'pdf',
      fileSize: '5.0 MB',
      authorId: 'auth_2',
      authorName: 'Trần Thị B',
      authorStudentId: '23010002',
      downloads: 25,
      rating: 5.0,
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  @override
  Stream<List<DocumentEntity>> getDocuments({String? faculty, String? searchQuery}) {
    var result = _docs;
    if (faculty != null && faculty != 'Tất cả') {
      result = result.where((d) => d.faculty == faculty).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.code.toLowerCase().contains(q) ||
          d.faculty.toLowerCase().contains(q)).toList();
    }
    return Stream.value(result);
  }

  @override
  Future<DocumentEntity> uploadDocument({required DocumentEntity document, required File file}) async {
    final newDoc = document.copyWith(id: 'new_${DateTime.now().millisecondsSinceEpoch}');
    _docs.add(newDoc);
    return newDoc;
  }

  @override
  Future<void> incrementDownloads(String documentId) async {}

  @override
  Future<File> downloadDocument({
    required String fileUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    return File('mock_path/$fileName');
  }
}

void main() {
  group('DocumentModel & DocumentEntity Tests', () {
    test('DocumentModel converts to Map and from Map correctly', () {
      final doc = DocumentModel(
        id: 'test_id',
        title: 'Cơ sở dữ liệu',
        code: 'CSDL-101',
        faculty: 'CNTT',
        fileUrl: 'https://cloudinary.com/sample.pdf',
        fileType: 'pdf',
        fileSize: '4.2 MB',
        authorId: 'user_123',
        authorName: 'Hà Mạnh Long',
        authorStudentId: '23010390',
        downloads: 50,
        rating: 4.9,
        description: 'Tài liệu ôn thi cuối kỳ',
        createdAt: DateTime(2026, 3, 10),
      );

      final map = doc.toMap();
      expect(map['title'], 'Cơ sở dữ liệu');
      expect(map['code'], 'CSDL-101');
      expect(map['faculty'], 'CNTT');
      expect(map['fileType'], 'pdf');
      expect(map['fileSize'], '4.2 MB');
      expect(map['downloads'], 50);
      expect(map['rating'], 4.9);

      final fromMapDoc = DocumentModel.fromMap(map, 'test_id');
      expect(fromMapDoc.id, 'test_id');
      expect(fromMapDoc.title, doc.title);
      expect(fromMapDoc.code, doc.code);
      expect(fromMapDoc.faculty, doc.faculty);
      expect(fromMapDoc.downloads, doc.downloads);
    });

    test('DocumentEntity copyWith updates specified fields', () {
      final entity = DocumentEntity(
        id: '1',
        title: 'Original Title',
        code: 'ORIG-100',
        faculty: 'CNTT',
        fileUrl: 'https://url.com',
        fileType: 'pdf',
        fileSize: '1 MB',
        authorId: 'a1',
        authorName: 'Author',
        authorStudentId: '001',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = entity.copyWith(
        title: 'Updated Title',
        downloads: 99,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.code, 'ORIG-100');
      expect(updated.downloads, 99);
    });
  });

  group('DocumentCubit Tests', () {
    late MockDocumentRepository mockRepo;
    late DocumentCubit cubit;

    setUp(() {
      mockRepo = MockDocumentRepository();
      cubit = DocumentCubit(documentRepository: mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is DocumentStatus.initial', () {
      expect(cubit.state.status, DocumentStatus.initial);
      expect(cubit.state.documents, isEmpty);
      expect(cubit.state.selectedFaculty, 'Tất cả');
    });

    test('loadDocuments fetches and updates state to loaded', () async {
      cubit.loadDocuments();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, DocumentStatus.loaded);
      expect(cubit.state.documents.length, 2);
    });

    test('filterByFaculty filters documents', () async {
      cubit.filterByFaculty('CNTT');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.selectedFaculty, 'CNTT');
      expect(cubit.state.documents.length, 1);
      expect(cubit.state.documents.first.code, 'CNTT-225');
    });

    test('search filters documents by query', () async {
      cubit.search('Giải tích');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.searchQuery, 'Giải tích');
      expect(cubit.state.documents.length, 1);
      expect(cubit.state.documents.first.code, 'TOAN-101');
    });
  });
}
