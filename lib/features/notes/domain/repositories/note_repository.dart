import '../entities/note_entity.dart';

abstract class NoteRepository {
  Stream<List<NoteEntity>> getNotesStream();
  Future<void> createNote(NoteEntity note);
  Future<void> updateNote({
    required String noteId,
    required String currentUserId,
    required String newContent,
  });
  Future<void> deleteNote({
    required String noteId,
    required String currentUserId,
    bool isAdmin = false,
  });
}
