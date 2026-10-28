import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/services/student_qr_service.dart';
import 'package:pu_connection/features/auth/domain/entities/user_entity.dart';
import 'package:pu_connection/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('StudentQrService Tests', () {
    test('generatePayload generates stable, canonical QR data', () {
      final payload1 = StudentQrService.generatePayload(studentId: '23010390');
      expect(payload1, 'pu://student?id=23010390');

      // Second generation with same studentId is 100% identical
      final payload2 = StudentQrService.generatePayload(studentId: '23010390');
      expect(payload2, payload1);

      // Updating student profile fields does not alter the QR payload
      const user = UserEntity(
        uid: 'user_1',
        email: '23010390@st.phenikaa-uni.edu.vn',
        studentId: '23010390',
        displayName: 'Hà Mạnh Long',
        avatarUrl: 'https://example.com/avatar1.jpg',
        bio: 'Bio ban đầu',
      );
      final initialPayload = StudentQrService.generatePayload(
        studentId: user.studentId,
        fallbackUid: user.uid,
      );

      final updatedUser = user.copyWith(
        avatarUrl: 'https://example.com/new_avatar.jpg',
        bio: 'Bio đã chỉnh sửa',
        cohort: 18,
      );
      final updatedPayload = StudentQrService.generatePayload(
        studentId: updatedUser.studentId,
        fallbackUid: updatedUser.uid,
      );

      expect(updatedPayload, initialPayload);
    });

    test('Two different students generate distinct QR payloads', () {
      final qrA = StudentQrService.generatePayload(studentId: '23010390');
      final qrB = StudentQrService.generatePayload(studentId: '23010111');
      expect(qrA, isNot(equals(qrB)));
    });

    test('parseIdentifier extracts student ID from standard URI format', () {
      final id1 = StudentQrService.parseIdentifier('pu://student?id=23010390');
      expect(id1, '23010390');

      final id2 = StudentQrService.parseIdentifier('pu://student/22010222');
      expect(id2, '22010222');
    });

    test(
      'parseIdentifier extracts student ID from versioned prefix and legacy formats',
      () {
        // Prefixed format
        final id1 = StudentQrService.parseIdentifier('pu_student:v1:23010390');
        expect(id1, '23010390');

        // Legacy JSON format
        final jsonRaw =
            '{"app":"pu_connection","type":"student_card","studentId":"23010390","displayName":"Test"}';
        final id2 = StudentQrService.parseIdentifier(jsonRaw);
        expect(id2, '23010390');

        // Direct studentId string
        final id3 = StudentQrService.parseIdentifier('23010390');
        expect(id3, '23010390');
      },
    );

    test('parseIdentifier returns null for invalid or non-PU QR codes', () {
      expect(StudentQrService.parseIdentifier(null), isNull);
      expect(StudentQrService.parseIdentifier(''), isNull);
      expect(StudentQrService.parseIdentifier('   '), isNull);
      expect(
        StudentQrService.parseIdentifier('https://www.google.com'),
        isNull,
      );
      expect(
        StudentQrService.parseIdentifier('WIFI:S:MyWifi;P:password;;'),
        isNull,
      );
      expect(
        StudentQrService.parseIdentifier('Random invalid text with spaces'),
        isNull,
      );

      expect(StudentQrService.isValidPuQr('https://unknown.com'), isFalse);
      expect(StudentQrService.isValidPuQr('pu://student?id=23010390'), isTrue);
    });

    test('QR payload never contains private sensitive information', () {
      const user = UserEntity(
        uid: 'secret_uid_12345',
        email: 'private_email@st.phenikaa-uni.edu.vn',
        studentId: '23010390',
        displayName: 'Sinh viên Phenikaa',
      );

      final qrData = StudentQrService.generatePayload(
        studentId: user.studentId,
        fallbackUid: user.uid,
      );

      // Verify no sensitive tokens or emails leaked
      expect(qrData, isNot(contains('@')));
      expect(qrData, isNot(contains('private_email')));
      expect(qrData, isNot(contains('secret_uid')));
      expect(qrData, 'pu://student?id=23010390');
    });
  });

  group('AuthRepository getUserByStudentId Tests', () {
    late AuthRepositoryImpl repository;

    setUp(() {
      repository = AuthRepositoryImpl();
    });

    test(
      'getUserByStudentId returns valid student from Phenikaa student directory',
      () async {
        final student = await repository.getUserByStudentId('23010390');
        expect(student, isNotNull);
        expect(student!.studentId, '23010390');
        expect(student.displayName, 'Hà Mạnh Long');
        expect(student.faculty, 'Công nghệ thông tin');
        expect(student.major, 'Kỹ thuật phần mềm');
        expect(student.cohort, 17);
      },
    );

    test(
      'getUserByStudentId returns null for non-existent student ID',
      () async {
        final student = await repository.getUserByStudentId(
          '99999999_not_found',
        );
        expect(student, isNull);
      },
    );

    test('getUserByStudentId returns null for empty student ID', () async {
      final student = await repository.getUserByStudentId('');
      expect(student, isNull);
    });
  });
}
