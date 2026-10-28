import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/gemini_service.dart';
import 'package:pu_connection/core/services/cloudinary_service.dart';
import 'package:pu_connection/features/chat/domain/entities/conversation_entity.dart';
import 'package:pu_connection/features/chat/domain/repositories/chat_repository.dart';
import 'package:pu_connection/features/chat/domain/entities/message_entity.dart';
import 'package:pu_connection/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:pu_connection/features/clubs/data/repositories/club_repository_impl.dart';
import 'package:pu_connection/features/events/data/event_repository.dart';

class _FakeChatRepository implements ChatRepository {
  @override
  Stream<List<ConversationEntity>> getConversationsStream(String userId) =>
      Stream.value([]);

  @override
  Stream<List<MessageEntity>> getMessagesStream(String conversationId) =>
      Stream.value([]);

  @override
  Stream<Map<String, bool>> getTypingStream(String conversationId) =>
      Stream.value({});

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {}

  @override
  Future<void> deleteConversationForUser({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Remediation Verification Tests', () {
    test('SEC-03: GeminiService operates safely offline when apiKey is empty', () async {
      final service = GeminiService(apiKey: '');
      expect(service.isConfigured, isFalse);

      final reply = await service.sendMessage('Điểm rèn luyện tính như thế nào?');
      expect(reply, contains('Điểm Rèn Luyện (ĐRL)'));
    });

    test('SEC-001: GeminiService defaultApiKey does not leak hardcoded secrets and respects env', () {
      const envKey = String.fromEnvironment('GEMINI_API_KEY');
      expect(GeminiService.defaultApiKey, equals(envKey));
      if (envKey.isEmpty) {
        expect(GeminiService().isConfigured, isFalse);
      }
      final configured = GeminiService(apiKey: 'custom_runtime_key');
      expect(configured.isConfigured, isTrue);
    });

    test('BUG-02: ChatCubit closeCurrentConversation resets active conversation properly', () {
      final cubit = ChatCubit(chatRepository: _FakeChatRepository());
      
      cubit.openConversation('conv_123', 'user_abc');
      expect(cubit.state.activeConversationId, equals('conv_123'));

      // If passing a mismatched conversationId, it does not close prematurely
      cubit.closeCurrentConversation('conv_999');
      expect(cubit.state.activeConversationId, equals('conv_123'));

      // Passing the matching conversationId closes it cleanly
      cubit.closeCurrentConversation('conv_123');
      expect(cubit.state.activeConversationId, isNull);

      cubit.close();
    });

    test('SEC-06: ClubRepository handles join and leave without double increments', () async {
      ClubRepositoryImpl.enableSeedClubs = true;
      ClubRepositoryImpl.resetMemory();
      final repo = ClubRepositoryImpl();

      final clubs = await repo.getClubsStream().first;
      final club = clubs.first;
      final initialCount = club.effectiveMembersCount;

      await repo.joinClub(clubId: club.id, userId: 'test_user_unique');
      final updatedClubs = await repo.getClubsStream().first;
      final updatedClub = updatedClubs.firstWhere((c) => c.id == club.id);
      expect(updatedClub.memberIds.contains('test_user_unique'), isTrue);
      expect(updatedClub.effectiveMembersCount, equals(initialCount + 1));

      // Joining again does not double count
      await repo.joinClub(clubId: club.id, userId: 'test_user_unique');
      final recheckedClubs = await repo.getClubsStream().first;
      final recheckedClub = recheckedClubs.firstWhere((c) => c.id == club.id);
      expect(recheckedClub.effectiveMembersCount, equals(initialCount + 1));

      // Leaving removes user
      await repo.leaveClub(clubId: club.id, userId: 'test_user_unique');
      final leftClubs = await repo.getClubsStream().first;
      final leftClub = leftClubs.firstWhere((c) => c.id == club.id);
      expect(leftClub.memberIds.contains('test_user_unique'), isFalse);
    });

    test('FEAT-01: EventRepository handles registration and cancellation gracefully in memory/offline', () async {
      EventRepository.enableSeedEvents = true;
      final repo = EventRepository();

      final events = await repo.streamEvents().first;
      expect(events, isNotEmpty);
      final event = events.first;

      await repo.registerForEvent(eventId: event.id, studentId: '23019999');
      final reloadedEvents = await repo.streamEvents().first;
      final reloadedEvent = reloadedEvents.firstWhere((e) => e.id == event.id);
      expect(reloadedEvent.registeredStudentIds.contains('23019999'), isTrue);

      await repo.unregisterFromEvent(eventId: event.id, studentId: '23019999');
      final unregisteredEvents = await repo.streamEvents().first;
      final unregisteredEvent = unregisteredEvents.firstWhere((e) => e.id == event.id);
      expect(unregisteredEvent.registeredStudentIds.contains('23019999'), isFalse);
    });

    test('LOGIC-002: EventRepository throws error on duplicate registration', () async {
      EventRepository.enableSeedEvents = true;
      final repo = EventRepository();
      final events = await repo.streamEvents().first;
      final event = events.first;

      await repo.registerForEvent(eventId: event.id, studentId: '23018888');
      expect(
        () => repo.registerForEvent(eventId: event.id, studentId: '23018888'),
        throwsA(isA<Exception>()),
      );
      await repo.unregisterFromEvent(eventId: event.id, studentId: '23018888');
    });

    test('SEC-003: CloudinaryService validates file size and extension boundaries', () async {
      final service = CloudinaryService();

      // Test oversize image > 10MB
      final oversizeBytes = List<int>.filled(11 * 1024 * 1024, 0);
      expect(
        () => service.uploadBytes(
          bytes: oversizeBytes,
          fileName: 'oversize.jpg',
          resourceType: 'image',
        ),
        throwsA(predicate((e) => e.toString().contains('vượt quá giới hạn'))),
      );

      // Test invalid image extension
      final normalBytes = List<int>.filled(100, 0);
      expect(
        () => service.uploadBytes(
          bytes: normalBytes,
          fileName: 'malicious.exe',
          resourceType: 'image',
        ),
        throwsA(predicate((e) => e.toString().contains('không được hỗ trợ'))),
      );
    });
  });
}
