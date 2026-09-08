import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/phenikaa_student_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/phenikaa_student_model.dart';
import '../datasources/phenikaa_student_directory.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(String identifier) async {
    final trimmed = identifier.trim().toLowerCase();
    String studentId = trimmed;
    if (trimmed.contains('@')) {
      studentId = trimmed.split('@').first;
    }

    PhenikaaStudentModel? student;

    // 1. Tra cứu trong danh bạ nội bộ
    final localMatch = PhenikaaStudentDirectory.defaultStudents.where(
      (s) => s.studentId.toLowerCase() == studentId || s.email.toLowerCase() == trimmed,
    );
    if (localMatch.isNotEmpty) {
      student = localMatch.first;
    }

    // 2. Tra cứu trong Firestore collection 'phenikaa_students'
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .doc(studentId)
          .get()
          .timeout(const Duration(milliseconds: 3000));

      if (doc.exists && doc.data() != null) {
        student = PhenikaaStudentModel.fromFirestore(doc);
      }
    } catch (_) {}

    // 3. Nếu không tìm thấy trong danh sách sinh viên
    if (student == null) {
      throw Exception(
        'Mã sinh viên "$studentId" không tồn tại trong danh sách sinh viên Đại học Phenikaa. Vui lòng kiểm tra lại.',
      );
    }

    // 4. Kiểm tra tài khoản đã kích hoạt hay chưa
    final isActivated = await isStudentActivated(
      studentId: student.studentId,
      email: student.email,
    );

    if (isActivated) {
      throw Exception(
        'ALREADY_ACTIVATED: Tài khoản của sinh viên "${student.fullName}" (MSV: ${student.studentId}) đã được kích hoạt. Vui lòng chuyển sang tab Đăng nhập.',
      );
    }

    return student;
  }

  @override
  Future<bool> isStudentActivated({
    required String studentId,
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanId = studentId.trim().toLowerCase();

    // Kiểm tra Firestore 'phenikaa_students'
    try {
      final studentDoc = await _firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .doc(cleanId)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (studentDoc.exists && studentDoc.data()?['isActivated'] == true) {
        return true;
      }
    } catch (_) {}

    // Kiểm tra Firestore 'users'
    try {
      final userQuery = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('studentId', isEqualTo: cleanId)
          .limit(1)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (userQuery.docs.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // Kiểm tra Firestore 'users' theo email
    try {
      final emailQuery = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (emailQuery.docs.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  @override
  @override
  Future<void> registerAndSendVerificationLink({
    required PhenikaaStudentEntity student,
    required String password,
  }) async {
    final cleanEmail = student.email.trim().toLowerCase();

    UserCredential credential;
    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          credential = await _firebaseAuth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
        } catch (_) {
          throw Exception(
            'Email ${student.email} đã được đăng ký. Vui lòng chuyển sang tab Đăng nhập để sử dụng hoặc chọn Quên mật khẩu.',
          );
        }
      } else {
        throw _handleFirebaseAuthError(e);
      }
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Không thể khởi tạo tài khoản sinh viên.');
    }

    await firebaseUser.updateDisplayName(student.fullName);

    await firebaseUser.sendEmailVerification();

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: cleanEmail,
      studentId: student.studentId,
      displayName: student.fullName,
      username: student.studentId,
      faculty: student.faculty,
      major: student.major,
      cohort: student.cohort,
      userType: 'student',
      isVerified: false,
      currentSubjects: const [],
      friendsCount: 0,
      postsCount: 0,
    );

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(firebaseUser.uid)
        .set(userModel.toMap(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));

    await _firestore
        .collection(FirebaseConstants.phenikaaStudentsCollection)
        .doc(student.studentId)
        .set({'isActivated': true}, SetOptions(merge: true))
        .timeout(const Duration(seconds: 4))
        .catchError((_) {});

    await _firebaseAuth.signOut();
  }

  @override
  Future<void> resendEmailVerificationLink({
    required String email,
    required String password,
  }) async {
    String loginEmail = email.trim().toLowerCase();
    if (!loginEmail.contains('@')) {
      loginEmail = '$loginEmail${FirebaseConstants.studentEmailDomain}';
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await _firebaseAuth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    String loginEmail = email.trim().toLowerCase();

    // Hỗ trợ đăng nhập bằng Mã sinh viên (ví dụ 23010390)
    if (!loginEmail.contains('@')) {
      loginEmail = '$loginEmail${FirebaseConstants.studentEmailDomain}';
    }

    if (!FirebaseConstants.isPhenikaaEmail(loginEmail)) {
      throw Exception('Vui lòng sử dụng email sinh viên Phenikaa (${FirebaseConstants.studentEmailDomain})');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      // Kiểm tra trạng thái xác thực link email
      await firebaseUser.reload();
      final refreshedUser = _firebaseAuth.currentUser ?? firebaseUser;

      if (!refreshedUser.emailVerified) {
        // Tự động gửi lại link nếu chưa bấm
        try {
          await refreshedUser.sendEmailVerification();
        } catch (_) {}
        await _firebaseAuth.signOut();
        throw Exception(
          'EMAIL_NOT_VERIFIED: Tài khoản của bạn chưa được xác thực email. '
          'Firebase đã gửi lại link kích hoạt tới $loginEmail. '
          'Vui lòng mở hòm thư của bạn và nhấn vào đường link để tiếp tục.',
        );
      }

      // Cập nhật isVerified: true lên Firestore nếu đã xác thực
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(refreshedUser.uid)
          .set({'isVerified': true}, SetOptions(merge: true))
          .catchError((_) {});

      // Lấy hồ sơ từ Firestore
      final profile = await getUserProfile(refreshedUser.uid);
      if (profile != null) {
        return profile;
      }

      // Nếu hồ sơ Firestore chưa tồn tại (tự phục hồi từ danh bạ trường)
      final studentId = loginEmail.split('@').first;
      String fullName = firebaseUser.displayName ?? 'Sinh viên Phenikaa';
      String faculty = 'Công nghệ thông tin';
      String major = 'Chưa cập nhật';
      int cohort = 17;

      final match = PhenikaaStudentDirectory.defaultStudents.where(
        (s) => s.studentId == studentId || s.email == loginEmail,
      );
      if (match.isNotEmpty) {
        fullName = match.first.fullName;
        faculty = match.first.faculty;
        major = match.first.major;
        cohort = match.first.cohort;
      }

      final restoredUser = UserModel(
        uid: firebaseUser.uid,
        email: loginEmail,
        studentId: studentId,
        displayName: fullName,
        username: studentId,
        faculty: faculty,
        major: major,
        cohort: cohort,
        userType: 'student',
        isVerified: true,
      );

      // Lưu lại vào Firestore để lần sau không bị thiếu thông tin
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(restoredUser.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4))
          .catchError((_) {});

      return restoredUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'hd': 'st.phenikaa-uni.edu.vn'});
        credential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          hostedDomain: 'st.phenikaa-uni.edu.vn',
          scopes: ['email', 'profile'],
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Bạn đã hủy đăng nhập bằng tài khoản Google.');
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _firebaseAuth.signInWithCredential(authCredential);
      } else {
        // Windows Desktop / Linux / macOS
        final googleProvider = GoogleAuthProvider();
        credential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại.');
      }

      final email = (firebaseUser.email ?? '').trim().toLowerCase();

      // RÀNG BUỘC PHƯƠNG ÁN 2: CHỈ CHẤP NHẬN TÀI KHOẢN TRƯỜNG PHENIKAA
      if (!FirebaseConstants.isPhenikaaEmail(email)) {
        await _firebaseAuth.signOut();
        throw Exception(
          'Tài khoản "$email" không thuộc Đại học Phenikaa. Vui lòng đăng nhập bằng email trường (@st.phenikaa-uni.edu.vn hoặc @phenikaa-uni.edu.vn).',
        );
      }

      // 1. Kiểm tra nếu hồ sơ đã có trên Firestore
      final profile = await getUserProfile(firebaseUser.uid);
      if (profile != null) {
        return profile;
      }

      // 2. Nếu đăng nhập lần đầu: Tự động khởi tạo hồ sơ sinh viên
      final studentId = email.split('@').first;
      String fullName = firebaseUser.displayName ?? 'Sinh viên Phenikaa';
      String faculty = 'Công nghệ thông tin';
      String major = 'Kỹ thuật phần mềm';
      int cohort = 17;

      final match = PhenikaaStudentDirectory.defaultStudents.where(
        (s) => s.studentId == studentId || s.email.toLowerCase() == email,
      );
      if (match.isNotEmpty) {
        fullName = match.first.fullName;
        faculty = match.first.faculty;
        major = match.first.major;
        cohort = match.first.cohort;
      }

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        studentId: studentId,
        displayName: fullName,
        username: studentId,
        faculty: faculty,
        major: major,
        cohort: cohort,
        userType: 'student',
        isVerified: true,
        avatarUrl: firebaseUser.photoURL ?? '',
        currentSubjects: const [],
        friendsCount: 0,
        postsCount: 0,
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4))
          .catchError((_) {});

      await _firestore
          .collection(FirebaseConstants.phenikaaStudentsCollection)
          .doc(studentId)
          .set({'isActivated': true}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4))
          .catchError((_) {});

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    String resetEmail = email.trim().toLowerCase();
    if (!resetEmail.contains('@')) {
      resetEmail = '$resetEmail${FirebaseConstants.studentEmailDomain}';
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: resetEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
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

      // Chỉ phát trạng thái đăng nhập nếu email đã được xác thực (Google Sign-In luôn là true)
      if (!firebaseUser.emailVerified) {
        return null;
      }
      
      final profile = await getUserProfile(firebaseUser.uid);
      if (profile != null) return profile;

      // Trả về UserEntity tạm thời dựa trên FirebaseUser để tránh bị logout nhầm khi Firestore đang ghi dữ liệu
      final email = firebaseUser.email ?? '';
      final studentId = email.contains('@') ? email.split('@').first : '';
      return UserModel(
        uid: firebaseUser.uid,
        email: email,
        studentId: studentId,
        displayName: firebaseUser.displayName ?? 'Sinh viên Phenikaa',
        username: studentId,
        isVerified: true,
      );
    });
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(milliseconds: 4000));

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

    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .update(model.toMap())
          .timeout(const Duration(milliseconds: 3500));
    } catch (_) {}
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Chưa bật Email/Mật khẩu trên Firebase Console. Vui lòng vào Console > Authentication > Sign-in method và BẬT "Email/Password".';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại Internet.';
      case 'user-not-found':
        return 'Tài khoản chưa được kích hoạt hoặc không tồn tại.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email sinh viên này đã được đăng ký tài khoản.';
      case 'invalid-email':
        return 'Định dạng email sinh viên không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'too-many-requests':
        return 'Bạn đã thao tác quá nhiều lần. Vui lòng đợi trong giây lát.';
      default:
        return e.message ?? 'Đã xảy ra lỗi (${e.code}). Vui lòng thử lại sau.';
    }
  }
}
