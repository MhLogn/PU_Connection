import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/notes/domain/entities/note_entity.dart';
import 'package:pu_connection/features/notes/data/models/note_model.dart';
import 'package:pu_connection/features/notes/data/repositories/note_repository_impl.dart';
import 'package:pu_connection/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:pu_connection/features/notes/presentation/cubit/notes_state.dart';

void main() {
  setUp(() {
    NoteRepositoryImpl.resetMemory();
  });

  group('Note Entities and Models Tests', () {
    test('NoteModel serialization to and from Map', () {
      final now = DateTime.now();
      final model = NoteModel(
        id: 'note_1',
        authorId: 'user_1',
        authorName: 'Nguyễn Văn A',
        authorAvatar: 'https://example.com/avatar.jpg',
        authorFaculty: 'CNTT',
        content: 'Hôm nay kiểm tra Giải tích 2 các bạn nhớ mang máy tính nhé!',
        audience: 'friends',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['authorId'], 'user_1');
      expect(map['content'], contains('Giải tích 2'));
      expect(map['audience'], 'friends');

      final deserialized = NoteModel.fromMap(map, 'note_1');
      expect(deserialized.id, 'note_1');
      expect(deserialized.authorId, 'user_1');
      expect(deserialized.content, contains('Giải tích 2'));
      expect(deserialized.audience, 'friends');
    });

    test('NoteModel with club audience serialization', () {
      final now = DateTime.now();
      final model = NoteModel(
        id: 'note_club_1',
        authorId: 'user_leader',
        authorName: 'Leader CLB',
        content: 'Tối nay CLB họp tại phòng A9-301 lúc 19h.',
        audience: 'club',
        clubId: 'club_it',
        clubName: 'CLB Tin Học',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['audience'], 'club');
      expect(map['clubId'], 'club_it');
      expect(map['clubName'], 'CLB Tin Học');

      final deserialized = NoteModel.fromMap(map, 'note_club_1');
      expect(deserialized.clubId, 'club_it');
      expect(deserialized.clubName, 'CLB Tin Học');
    });
  });

  group('NoteRepositoryImpl Tests', () {
    late NoteRepositoryImpl repository;

    setUp(() {
      NoteRepositoryImpl.resetMemory();
      repository = NoteRepositoryImpl();
    });

    test('createNote adds valid note to stream', () async {
      final note = NoteEntity(
        id: 'n_1',
        authorId: 'user_1',
        authorName: 'Sinh viên 1',
        content: 'Học nhóm Thể chất lúc 16h',
        audience: 'friends',
        createdAt: DateTime.now(),
      );

      await repository.createNote(note);
      final list = await repository.getNotesStream().first;
      expect(list.length, 1);
      expect(list.first.content, 'Học nhóm Thể chất lúc 16h');
    });

    test(
      'createNote throws exception for empty or >150 chars content',
      () async {
        final emptyNote = NoteEntity(
          id: 'n_empty',
          authorId: 'user_1',
          authorName: 'Sinh viên 1',
          content: '   ',
          audience: 'friends',
          createdAt: DateTime.now(),
        );

        expect(
          () => repository.createNote(emptyNote),
          throwsA(isA<Exception>()),
        );

        final longContent = 'A' * 151;
        final longNote = NoteEntity(
          id: 'n_long',
          authorId: 'user_1',
          authorName: 'Sinh viên 1',
          content: longContent,
          audience: 'friends',
          createdAt: DateTime.now(),
        );

        expect(
          () => repository.createNote(longNote),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('createNote with club audience requires clubId', () async {
      final invalidClubNote = NoteEntity(
        id: 'n_club_invalid',
        authorId: 'user_1',
        authorName: 'Sinh viên 1',
        content: 'Họp CLB',
        audience: 'club',
        clubId: null,
        createdAt: DateTime.now(),
      );

      expect(
        () => repository.createNote(invalidClubNote),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNote updates content when called by author', () async {
      final note = NoteEntity(
        id: 'n_edit',
        authorId: 'user_author',
        authorName: 'Tác giả',
        content: 'Nội dung ban đầu',
        audience: 'friends',
        createdAt: DateTime.now(),
      );

      await repository.createNote(note);

      await repository.updateNote(
        noteId: 'n_edit',
        currentUserId: 'user_author',
        newContent: 'Nội dung sau khi chỉnh sửa',
      );

      final list = await repository.getNotesStream().first;
      expect(list.first.content, 'Nội dung sau khi chỉnh sửa');
      expect(list.first.updatedAt, isNotNull);
    });

    test('updateNote throws exception when called by non-author', () async {
      final note = NoteEntity(
        id: 'n_edit_2',
        authorId: 'user_author',
        authorName: 'Tác giả',
        content: 'Gốc',
        audience: 'friends',
        createdAt: DateTime.now(),
      );

      await repository.createNote(note);

      expect(
        () => repository.updateNote(
          noteId: 'n_edit_2',
          currentUserId: 'user_stranger',
          newContent: 'Sửa bậy',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Bạn không có quyền chỉnh sửa'),
          ),
        ),
      );
    });

    test(
      'deleteNote allows author and admin to delete, forbids strangers',
      () async {
        final note = NoteEntity(
          id: 'n_del',
          authorId: 'user_author',
          authorName: 'Tác giả',
          content: 'Sẽ xóa',
          audience: 'friends',
          createdAt: DateTime.now(),
        );

        await repository.createNote(note);

        // Stranger cannot delete
        expect(
          () => repository.deleteNote(
            noteId: 'n_del',
            currentUserId: 'user_stranger',
            isAdmin: false,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'msg',
              contains('Bạn không có quyền xóa'),
            ),
          ),
        );

        // Admin can delete
        await repository.deleteNote(
          noteId: 'n_del',
          currentUserId: 'admin_user',
          isAdmin: true,
        );

        final list = await repository.getNotesStream().first;
        expect(list, isEmpty);
      },
    );
  });

  group('NotesCubit and Privacy Filtering Tests', () {
    late NoteRepositoryImpl repository;
    late NotesCubit cubit;

    setUp(() {
      NoteRepositoryImpl.resetMemory();
      repository = NoteRepositoryImpl();
      cubit = NotesCubit(noteRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('getVisibleNotes respects friends and club audience visibility', () {
      final now = DateTime.now();
      final notes = [
        // My note (friends)
        NoteEntity(
          id: '1',
          authorId: 'user_me',
          authorName: 'Tôi',
          content: 'Note của tôi',
          audience: 'friends',
          createdAt: now,
        ),
        // Friend note
        NoteEntity(
          id: '2',
          authorId: 'user_friend',
          authorName: 'Bạn Thân',
          content: 'Note của bạn thân',
          audience: 'friends',
          createdAt: now,
        ),
        // Stranger friend note (should NOT be visible)
        NoteEntity(
          id: '3',
          authorId: 'user_stranger',
          authorName: 'Người Lạ',
          content: 'Note bí mật',
          audience: 'friends',
          createdAt: now,
        ),
        // Club note from a joined club
        NoteEntity(
          id: '4',
          authorId: 'user_member',
          authorName: 'Thành viên CLB',
          content: 'Tin tức CLB Tin Học',
          audience: 'club',
          clubId: 'club_it',
          clubName: 'CLB Tin Học',
          createdAt: now,
        ),
        // Club note from a non-joined club (should NOT be visible)
        NoteEntity(
          id: '5',
          authorId: 'user_other',
          authorName: 'CLB Khác',
          content: 'Tin tức CLB Âm Nhạc',
          audience: 'club',
          clubId: 'club_music',
          clubName: 'CLB Âm Nhạc',
          createdAt: now,
        ),
      ];

      final state = NotesState(notes: notes);

      final visible = state.getVisibleNotes(
        currentUserId: 'user_me',
        friendUserIds: {'user_friend'},
        userClubIds: {'club_it'},
      );

      final ids = visible.map((n) => n.id).toList();
      // Should see: My Note ('1'), Friend Note ('2'), Club Note ('4')
      expect(ids, containsAll(['1', '2', '4']));
      expect(ids, isNot(contains('3')));
      expect(ids, isNot(contains('5')));
    });

    test('getVisibleNotes filters by active NotesFilter tabs', () {
      final now = DateTime.now();
      final notes = [
        NoteEntity(
          id: '1',
          authorId: 'user_me',
          authorName: 'Tôi',
          content: 'Note bạn bè',
          audience: 'friends',
          createdAt: now,
        ),
        NoteEntity(
          id: '2',
          authorId: 'user_friend',
          authorName: 'Bạn Thân',
          content: 'Note bạn bè 2',
          audience: 'friends',
          createdAt: now,
        ),
        NoteEntity(
          id: '3',
          authorId: 'user_member',
          authorName: 'CLB Member',
          content: 'Note CLB',
          audience: 'club',
          clubId: 'club_it',
          createdAt: now,
        ),
      ];

      // Tab 'friends'
      final friendsState = NotesState(
        notes: notes,
        filter: NotesFilter.friends,
      );
      final friendsVisible = friendsState.getVisibleNotes(
        currentUserId: 'user_me',
        friendUserIds: {'user_friend'},
        userClubIds: {'club_it'},
      );
      expect(friendsVisible.length, 2);
      expect(friendsVisible.every((n) => n.audience == 'friends'), isTrue);

      // Tab 'club'
      final clubState = NotesState(notes: notes, filter: NotesFilter.club);
      final clubVisible = clubState.getVisibleNotes(
        currentUserId: 'user_me',
        friendUserIds: {'user_friend'},
        userClubIds: {'club_it'},
      );
      expect(clubVisible.length, 1);
      expect(clubVisible.first.id, '3');
    });

    test('Cubit creates note and emits success', () async {
      await cubit.createNote(
        authorId: 'user_me',
        authorName: 'Tôi',
        authorAvatar: '',
        authorFaculty: 'CNTT',
        content: 'Kiểm tra giải thuật 150 ký tự',
        audience: 'friends',
      );

      expect(cubit.state.actionStatus, NotesActionStatus.success);
      expect(cubit.state.successMessage, isNotNull);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.notes.length, 1);
      expect(cubit.state.notes.first.content, 'Kiểm tra giải thuật 150 ký tự');
    });
  });
}
