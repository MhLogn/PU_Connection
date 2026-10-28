import '../entities/user_entity.dart';
import '../entities/phenikaa_student_entity.dart';

abstract class AuthRepository {
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(String identifier);
  Future<bool> isStudentActivated({
    required String studentId,
    required String email,
  });
  Future<void> registerAndSendVerificationLink({
    required PhenikaaStudentEntity student,
    required String password,
  });
  Future<void> resendEmailVerificationLink({
    required String email,
    required String password,
  });
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserEntity> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> getUserProfile(String uid);
  Future<UserEntity?> getUserByStudentId(String studentId);
  Future<void> updateUserProfile(UserEntity user);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Kiểm tra quyền quản trị viên thực tế từ nguồn tin cậy (Custom Claims hoặc collection admins)
  Future<bool> verifyAdminPrivilege(String uid);

  /// Kiểm tra người dùng hiện tại có quyền Admin không
  Future<bool> isCurrentUserAdmin();
}
