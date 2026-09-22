import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/events/domain/entities/event_entity.dart';

void main() {
  group('EventEntity Tests', () {
    final testEvent = EventEntity(
      id: 'test_event_1',
      title: 'Phenikaa Hackathon 2026',
      description: 'AI & IoT Competition',
      category: 'Học thuật',
      location: 'Tòa A9',
      startDate: DateTime(2026, 10, 15, 8, 0),
      endDate: DateTime(2026, 10, 17, 18, 0),
      organizer: 'Khoa CNTT Phenikaa',
      maxParticipants: 100,
      registeredStudentIds: const ['23010390', '23010111'],
    );

    test('isRegistered correctly verifies student ID presence', () {
      expect(testEvent.isRegistered('23010390'), isTrue);
      expect(testEvent.isRegistered('23010111'), isTrue);
      expect(testEvent.isRegistered('99999999'), isFalse);
      expect(testEvent.isRegistered(''), isFalse);
    });

    test('Participants and spots remaining calculated accurately', () {
      expect(testEvent.currentParticipants, equals(2));
      expect(testEvent.spotsRemaining, equals(98));
      expect(testEvent.isFull, isFalse);
    });

    test('isFull is true when currentParticipants reaches or exceeds maxParticipants', () {
      final fullEvent = testEvent.copyWith(
        maxParticipants: 2,
        registeredStudentIds: ['23010390', '23010111'],
      );
      expect(fullEvent.isFull, isTrue);
      expect(fullEvent.spotsRemaining, equals(0));
    });

    test('copyWith properly updates fields without mutating original', () {
      final updated = testEvent.copyWith(
        title: 'New Phenikaa Hackathon',
        registeredStudentIds: ['23010390', '23010111', '22010222'],
      );

      expect(updated.title, equals('New Phenikaa Hackathon'));
      expect(updated.currentParticipants, equals(3));
      expect(updated.spotsRemaining, equals(97));
      expect(testEvent.currentParticipants, equals(2)); // Original untouched
    });
  });
}
