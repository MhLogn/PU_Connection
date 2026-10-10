import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/auth/domain/entities/user_entity.dart';
import 'package:pu_connection/features/auth/domain/entities/phenikaa_student_entity.dart';
import 'package:pu_connection/features/auth/data/models/user_model.dart';
import 'package:pu_connection/features/auth/domain/repositories/auth_repository.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pu_connection/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? currentUser;
  String currentPassword = 'password123';
  final StreamController<UserEntity?> _controller = StreamController<UserEntity?>.broadcast();

  MockAuthRepository({this.currentUser});

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  Future<UserEntity?> getUserProfile(String uid) async => currentUser;

  @override
  Future<void> updateUserProfile(UserEntity user) async {
    currentUser = user;
    _controller.add(user);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (this.currentPassword != currentPassword) {
      throw Exception('Mật khẩu hiện tại không chính xác.');
    }
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải từ 6 ký tự trở lên.');
    }
    this.currentPassword = newPassword;
  }

  @override
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(String identifier) async {
    return const PhenikaaStudentEntity(
      studentId: '23010390',
      fullName: 'Sinh viên Test',
      email: '23010390@st.phenikaa-uni.edu.vn',
      faculty: 'CNTT',
      major: 'KTPM',
      cohort: 17,
    );
  }

  @override
  Future<bool> isStudentActivated({required String studentId, required String email}) async => true;

  @override
  Future<void> registerAndSendVerificationLink({
    required PhenikaaStudentEntity student,
    required String password,
  }) async {}

  @override
  Future<void> resendEmailVerificationLink({required String email, required String password}) async {}

  @override
  Future<UserEntity> signInWithEmailAndPassword({required String email, required String password}) async {
    return currentUser!;
  }

  @override
  Future<UserEntity> signInWithGoogle() async => currentUser!;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }
}

void main() {
  group('UserEntity & UserModel Tests', () {
    test('UserModel serialization with bio, avatarUrl, coverUrl, currentSubjects', () {
      final model = UserModel.fromMap({
        'email': '23010390@st.phenikaa-uni.edu.vn',
        'displayName': 'Nguyễn Văn Test',
        'studentId': '23010390',
        'bio': 'Yêu thích lập trình và AI',
        'avatarUrl': 'https://example.com/avatar.png',
        'coverUrl': 'https://example.com/cover.png',
        'faculty': 'Công nghệ thông tin',
        'major': 'Kỹ thuật phần mềm',
        'cohort': 17,
        'currentSubjects': ['Lập trình mạng', 'Trí tuệ nhân tạo (AI)'],
      }, 'uid_test');

      expect(model.uid, 'uid_test');
      expect(model.bio, 'Yêu thích lập trình và AI');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.coverUrl, 'https://example.com/cover.png');
      expect(model.currentSubjects.length, 2);
      expect(model.currentSubjects, contains('Lập trình mạng'));

      final map = model.toMap();
      expect(map['bio'], 'Yêu thích lập trình và AI');
      expect(map['avatarUrl'], 'https://example.com/avatar.png');
      expect(map['coverUrl'], 'https://example.com/cover.png');
      expect(map['currentSubjects'], contains('Trí tuệ nhân tạo (AI)'));
    });

    test('UserModel copyWith modifies fields cleanly', () {
      const user = UserModel(
        uid: 'uid_1',
        email: 'test@phenikaa-uni.edu.vn',
        displayName: 'Test User',
        bio: 'Old Bio',
        currentSubjects: ['Toán rời rạc'],
      );

      final updated = user.copyWith(
        bio: 'New Bio updated',
        currentSubjects: ['Toán rời rạc', 'Hệ điều hành'],
      );

      expect(updated.bio, 'New Bio updated');
      expect(updated.currentSubjects.length, 2);
      expect(updated.currentSubjects, contains('Hệ điều hành'));
      expect(user.bio, 'Old Bio'); // immutability preserved
    });
  });

  group('AuthCubit Profile & Password Tests', () {
    late MockAuthRepository repository;
    late AuthCubit cubit;

    final initialUser = const UserModel(
      uid: 'user_123',
      email: '23010390@st.phenikaa-uni.edu.vn',
      displayName: 'Nguyễn Văn A',
      bio: 'Sinh viên K17',
      currentSubjects: ['Lập trình di động'],
    );

    setUp(() {
      repository = MockAuthRepository(currentUser: initialUser);
      cubit = AuthCubit(authRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('updateUserProfile updates state to Authenticated with new user', () async {
      final updated = initialUser.copyWith(
        displayName: 'Nguyễn Văn A Updated',
        bio: 'Đam mê nghiên cứu khoa học',
        currentSubjects: ['Lập trình di động', 'Cơ sở dữ liệu'],
      );

      await cubit.updateUserProfile(updated);

      expect(cubit.state, isA<Authenticated>());
      final authState = cubit.state as Authenticated;
      expect(authState.user.displayName, 'Nguyễn Văn A Updated');
      expect(authState.user.bio, 'Đam mê nghiên cứu khoa học');
      expect(authState.user.currentSubjects.length, 2);
    });

    test('changePassword succeeds with correct current password', () async {
      await expectLater(
        cubit.changePassword(
          currentPassword: 'password123',
          newPassword: 'newPassword456',
        ),
        completes,
      );
      expect(repository.currentPassword, 'newPassword456');
    });

    test('changePassword throws exception when current password is wrong', () async {
      await expectLater(
        cubit.changePassword(
          currentPassword: 'wrong_password',
          newPassword: 'newPassword456',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('changePassword throws exception when new password is too short', () async {
      await expectLater(
        cubit.changePassword(
          currentPassword: 'password123',
          newPassword: '123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
