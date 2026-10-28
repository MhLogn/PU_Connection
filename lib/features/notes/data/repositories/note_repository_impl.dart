import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final FirebaseFirestore? _customFirestore;

  NoteRepositoryImpl({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  // --- In-memory fallback for offline, integration & unit tests ---
  static final List<NoteEntity> _memoryNotes = [];
  static final StreamController<void> _notifier =
      StreamController<void>.broadcast();

  static void resetMemory() {
    _memoryNotes.clear();
  }

  static void seedMemoryNotes(List<NoteEntity> notes) {
    _memoryNotes.clear();
    _memoryNotes.addAll(notes);
  }

  @override
  Stream<List<NoteEntity>> getNotesStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.multi((controller) {
        void emitNotes() {
          final sorted = List<NoteEntity>.from(_memoryNotes)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          controller.add(sorted);
        }

        emitNotes();
        final sub = _notifier.stream.listen((_) => emitNotes());
        controller.onCancel = () => sub.cancel();
      });
    }

    return firestore
        .collection(FirebaseConstants.notesCollection)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NoteModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> createNote(NoteEntity note) async {
    final trimmed = note.content.trim();
    if (trimmed.isEmpty || trimmed.length > 150) {
      throw Exception('Nội dung ghi chú phải từ 1 đến 150 ký tự.');
    }

    if (note.audience == 'club' &&
        (note.clubId == null || note.clubId!.trim().isEmpty)) {
      throw Exception('Vui lòng chọn Câu lạc bộ để chia sẻ ghi chú.');
    }

    final firestore = _firestore;
    if (firestore != null) {
      final model = NoteModel(
        id: note.id.isNotEmpty
            ? note.id
            : firestore.collection(FirebaseConstants.notesCollection).doc().id,
        authorId: note.authorId,
        authorName: note.authorName,
        authorAvatar: note.authorAvatar,
        authorFaculty: note.authorFaculty,
        content: trimmed,
        audience: note.audience,
        clubId: note.clubId,
        clubName: note.clubName,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );

      await firestore
          .collection(FirebaseConstants.notesCollection)
          .doc(model.id)
          .set(model.toMap());
      return;
    }

    // In-memory fallback
    _memoryNotes.removeWhere((n) => n.id == note.id);
    _memoryNotes.add(note.copyWith(content: trimmed));
    _notifier.add(null);
  }

  @override
  Future<void> updateNote({
    required String noteId,
    required String currentUserId,
    required String newContent,
  }) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed.length > 150) {
      throw Exception('Nội dung ghi chú phải từ 1 đến 150 ký tự.');
    }

    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore
          .collection(FirebaseConstants.notesCollection)
          .doc(noteId);
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Ghi chú không tồn tại hoặc đã bị xóa.');
      }

      final data = doc.data() ?? {};
      if (data['authorId'] != currentUserId) {
        throw Exception('Bạn không có quyền chỉnh sửa ghi chú này.');
      }

      await docRef.update({'content': trimmed, 'updatedAt': Timestamp.now()});
      return;
    }

    // In-memory fallback
    final index = _memoryNotes.indexWhere((n) => n.id == noteId);
    if (index == -1) {
      throw Exception('Ghi chú không tồn tại hoặc đã bị xóa.');
    }

    if (_memoryNotes[index].authorId != currentUserId) {
      throw Exception('Bạn không có quyền chỉnh sửa ghi chú này.');
    }

    _memoryNotes[index] = _memoryNotes[index].copyWith(
      content: trimmed,
      updatedAt: DateTime.now(),
    );
    _notifier.add(null);
  }

  @override
  Future<void> deleteNote({
    required String noteId,
    required String currentUserId,
    bool isAdmin = false,
  }) async {
    final firestore = _firestore;
    if (firestore != null) {
      final docRef = firestore
          .collection(FirebaseConstants.notesCollection)
          .doc(noteId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      if (data['authorId'] != currentUserId && !isAdmin) {
        throw Exception('Bạn không có quyền xóa ghi chú này.');
      }

      await docRef.delete();
      return;
    }

    // In-memory fallback
    final index = _memoryNotes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      if (_memoryNotes[index].authorId != currentUserId && !isAdmin) {
        throw Exception('Bạn không có quyền xóa ghi chú này.');
      }
      _memoryNotes.removeAt(index);
      _notifier.add(null);
    }
  }
}
