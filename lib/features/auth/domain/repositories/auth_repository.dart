import '../entities/user_entity.dart';
import '../entities/phenikaa_student_entity.dart';

abstract class AuthRepository {
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(String identifier);
  Future<bool> isStudentActivated({required String studentId, required String email});
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
  Future<void> updateUserProfile(UserEntity user);
}
