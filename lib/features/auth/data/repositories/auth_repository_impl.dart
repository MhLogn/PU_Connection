import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      final profile = await getUserProfile(firebaseUser.uid);
      if (profile != null) {
        return profile;
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: firebaseUser.displayName ?? '',
        isVerified: firebaseUser.emailVerified,
      );
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserEntity> signUpWithPhenikaaEmail({
    required String email,
    required String password,
    required String studentId,
    required String displayName,
    required String faculty,
    required String major,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!trimmedEmail.endsWith(FirebaseConstants.phenikaaEmailDomain)) {
      throw Exception(
        'Đăng ký yêu cầu email sinh viên Phenikaa (${FirebaseConstants.phenikaaEmailDomain})',
      );
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Không thể tạo tài khoản sinh viên.');
      }

      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.sendEmailVerification();

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: trimmedEmail,
        studentId: studentId.trim(),
        displayName: displayName.trim(),
        username: trimmedEmail.split('@').first,
        faculty: faculty.trim(),
        major: major.trim(),
        userType: 'student',
        isVerified: false,
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null && !currentUser.emailVerified) {
      await currentUser.sendEmailVerification();
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await getUserProfile(firebaseUser.uid);
    });
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UserEntity user) async {
    final model = UserModel(
      uid: user.uid,
      email: user.email,
      studentId: user.studentId,
      displayName: user.displayName,
      username: user.username,
      avatarUrl: user.avatarUrl,
      coverUrl: user.coverUrl,
      bio: user.bio,
      faculty: user.faculty,
      major: user.major,
      cohort: user.cohort,
      userType: user.userType,
      isVerified: user.isVerified,
      currentSubjects: user.currentSubjects,
      friendsCount: user.friendsCount,
      postsCount: user.postsCount,
    );

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid)
        .update(model.toMap());
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại. Vui lòng kiểm tra lại email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu hoặc thông tin đăng nhập không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký tài khoản trước đó.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';
      default:
        return e.message ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
    }
  }
}
