import 'package:equatable/equatable.dart';
import '../../domain/entities/note_entity.dart';

enum NotesFilter {
  all,
  friends,
  club;

  String get displayName {
    switch (this) {
      case NotesFilter.all:
        return 'Tất cả';
      case NotesFilter.friends:
        return 'Bạn bè';
      case NotesFilter.club:
        return 'Câu lạc bộ';
    }
  }
}

enum NotesActionStatus { initial, loading, success, failure }

class NotesState extends Equatable {
  final List<NoteEntity> notes;
  final NotesFilter filter;
  final NotesActionStatus actionStatus;
  final String? errorMessage;
  final String? successMessage;

  const NotesState({
    this.notes = const [],
    this.filter = NotesFilter.all,
    this.actionStatus = NotesActionStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  NotesState copyWith({
    List<NoteEntity>? notes,
    NotesFilter? filter,
    NotesActionStatus? actionStatus,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      filter: filter ?? this.filter,
      actionStatus: actionStatus ?? this.actionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  /// Calculates visible notes for [currentUserId] based on privacy audience and active filter
  List<NoteEntity> getVisibleNotes({
    required String currentUserId,
    required Set<String> friendUserIds,
    required Set<String> userClubIds,
  }) {
    return notes.where((note) {
      // 1. Author can always see their own notes
      final isAuthor = note.authorId == currentUserId;
      if (isAuthor) {
        if (filter == NotesFilter.friends && note.audience != 'friends') {
          return false;
        }
        if (filter == NotesFilter.club && note.audience != 'club') {
          return false;
        }
        return true;
      }

      // 2. Check audience permission
      bool isAccessible = false;
      if (note.audience == 'friends') {
        isAccessible = friendUserIds.contains(note.authorId);
      } else if (note.audience == 'club') {
        isAccessible = note.clubId != null && userClubIds.contains(note.clubId);
      }

      if (!isAccessible) return false;

      // 3. Check active filter tab
      switch (filter) {
        case NotesFilter.all:
          return true;
        case NotesFilter.friends:
          return note.audience == 'friends';
        case NotesFilter.club:
          return note.audience == 'club';
      }
    }).toList();
  }

  @override
  List<Object?> get props => [
    notes,
    filter,
    actionStatus,
    errorMessage,
    successMessage,
  ];
}
