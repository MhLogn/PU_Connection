import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final NoteRepository _noteRepository;
  StreamSubscription<List<NoteEntity>>? _notesSubscription;

  NotesCubit({required NoteRepository noteRepository})
    : _noteRepository = noteRepository,
      super(const NotesState()) {
    init();
  }

  void init() {
    _notesSubscription?.cancel();
    _notesSubscription = _noteRepository.getNotesStream().listen(
      (notes) {
        emit(state.copyWith(notes: notes));
      },
      onError: (err) {
        emit(
          state.copyWith(
            actionStatus: NotesActionStatus.failure,
            errorMessage: err.toString(),
          ),
        );
      },
    );
  }

  void setFilter(NotesFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> createNote({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String authorFaculty,
    required String content,
    required String audience,
    String? clubId,
    String? clubName,
  }) async {
    emit(
      state.copyWith(
        actionStatus: NotesActionStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final note = NoteEntity(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}_$authorId',
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorFaculty: authorFaculty,
      content: content.trim(),
      audience: audience,
      clubId: clubId,
      clubName: clubName,
      createdAt: DateTime.now(),
    );

    try {
      await _noteRepository.createNote(note);
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.success,
          successMessage: 'Đã chia sẻ ghi chú thành công!',
        ),
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.failure,
          errorMessage: cleanMsg,
        ),
      );
      rethrow;
    }
  }

  Future<void> updateNote({
    required String noteId,
    required String currentUserId,
    required String newContent,
  }) async {
    emit(
      state.copyWith(
        actionStatus: NotesActionStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _noteRepository.updateNote(
        noteId: noteId,
        currentUserId: currentUserId,
        newContent: newContent,
      );
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.success,
          successMessage: 'Đã cập nhật ghi chú thành công!',
        ),
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.failure,
          errorMessage: cleanMsg,
        ),
      );
      rethrow;
    }
  }

  Future<void> deleteNote({
    required String noteId,
    required String currentUserId,
    bool isAdmin = false,
  }) async {
    emit(
      state.copyWith(
        actionStatus: NotesActionStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _noteRepository.deleteNote(
        noteId: noteId,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
      );
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.success,
          successMessage: 'Đã xóa ghi chú!',
        ),
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          actionStatus: NotesActionStatus.failure,
          errorMessage: cleanMsg,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel();
    return super.close();
  }
}
