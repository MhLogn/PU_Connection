import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Đăng nhập bằng Email và Password
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Đăng ký tài khoản sinh viên Phenikaa (yêu cầu đuôi @phenikaa-uni.edu.vn)
  Future<UserEntity> signUpWithPhenikaaEmail({
    required String email,
    required String password,
    required String studentId,
    required String displayName,
    required String faculty,
    required String major,
  });

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email);

  /// Gửi lại email xác thực
  Future<void> sendEmailVerification();

  /// Đăng xuất
  Future<void> signOut();

  /// Lấy stream trạng thái người dùng hiện tại
  Stream<UserEntity?> get authStateChanges;

  /// Lấy thông tin chi tiết của người dùng từ Firestore
  Future<UserEntity?> getUserProfile(String uid);

  /// Cập nhật hồ sơ sinh viên
  Future<void> updateUserProfile(UserEntity user);
}
