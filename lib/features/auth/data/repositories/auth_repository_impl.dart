import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/phenikaa_student_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/phenikaa_student_model.dart';
import '../datasources/phenikaa_student_directory.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth? _customFirebaseAuth;
  final FirebaseFirestore? _customFirestore;
  final SharedPreferences? _prefs;

  FirebaseAuth get _firebaseAuth =>
      _customFirebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  FirebaseAuth? get _safeFirebaseAuth {
    try {
      return _customFirebaseAuth ?? FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _safeFirestore {
    try {
      return _customFirestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Bộ lưu UID admin cho môi trường unit test không có kết nối Firebase thực
  static final Set<String> _testVerifiedAdminUids = {};
  static final Map<String, String> _testMockCredentials = {};

  static void registerAdminForTesting({
    required String uid,
    String? email,
    String? password,
  }) {
    _testVerifiedAdminUids.add(uid);
    if (email != null && password != null) {
      _testMockCredentials[email.toLowerCase()] = password;
    }
  }

  static void resetAdminTestingData() {
    _testVerifiedAdminUids.clear();
    _testMockCredentials.clear();
  }

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  }) : _customFirebaseAuth = firebaseAuth,
       _customFirestore = firestore,
       _prefs = prefs;

  @override
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(
    String identifier,
  ) async {
    final trimmed = identifier.trim().toLowerCase();
    String studentId = trimmed;
    if (trimmed.contains('@')) {
      studentId = trimmed.split('@').first;
    }

    PhenikaaStudentModel? student;

    // 1. Ưu tiên tra cứu trực tiếp trên collection phenikaa_students của Firestore
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

    // 2. Fallback sang danh bạ cục bộ nếu chưa có dữ liệu Firestore (hỗ trợ kiểm thử/offline)
    if (student == null) {
      final localMatch = PhenikaaStudentDirectory.defaultStudents.where(
        (s) =>
            s.studentId.toLowerCase() == studentId ||
            s.email.toLowerCase() == trimmed,
      );
      if (localMatch.isNotEmpty) {
        student = localMatch.first;
      }
    }

    if (student == null) {
      throw Exception(
        'Mã sinh viên "$studentId" không tồn tại trong danh sách sinh viên Đại học Phenikaa. Vui lòng kiểm tra lại.',
      );
    }

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
  Future<bool> verifyAdminPrivilege(String uid) async {
    if (uid.isEmpty) return false;

    // 1. Kiểm tra Custom Claims từ Firebase Auth Token (nguồn phân quyền backend bảo mật nhất)
    final safeAuth = _safeFirebaseAuth;
    if (safeAuth?.currentUser != null && safeAuth!.currentUser!.uid == uid) {
      try {
        final tokenResult = await safeAuth.currentUser!.getIdTokenResult(true);
        final claims = tokenResult.claims;
        if (claims != null) {
          if (claims['admin'] == true ||
              claims['role'] == 'admin' ||
              claims['isAdmin'] == true) {
            return true;
          }
        }
      } catch (_) {}
    }

    // 2. Bổ trợ bằng Collection bảo mật `admins/{uid}` trên Firestore
    // Collection này được bảo vệ bởi Firestore Security Rules: client tuyệt đối không có quyền write.
    final safeStore = _safeFirestore;
    if (safeStore != null) {
      try {
        final adminDoc = await safeStore
            .collection(FirebaseConstants.adminsCollection)
            .doc(uid)
            .get()
            .timeout(const Duration(milliseconds: 2500));
        if (adminDoc.exists && adminDoc.data()?['active'] == true) {
          return true;
        }
      } catch (_) {}
    }

    // 3. Quản trị viên hệ thống Phenikaa được cấu hình tin cậy
    if (safeAuth?.currentUser?.email?.toLowerCase() == 'admin@phenikaa-uni.edu.vn' ||
        uid == 'LKcVXxg15RZTeSBxfL8HLODbPSZ2' ||
        _testVerifiedAdminUids.contains(uid)) {
      return true;
    }

    return false;
  }

  @override
  Future<bool> isCurrentUserAdmin() async {
    final uid = _safeFirebaseAuth?.currentUser?.uid;
    if (uid == null) return false;
    return verifyAdminPrivilege(uid);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    String loginEmail = email.trim().toLowerCase();

    // Chuẩn hóa tên đăng nhập nếu người dùng không gõ đầy đủ tên miền @...
    if (!loginEmail.contains('@')) {
      final isNumericId = RegExp(r'^\d+$').hasMatch(loginEmail);
      if (isNumericId) {
        loginEmail = '$loginEmail${FirebaseConstants.studentEmailDomain}';
      } else {
        loginEmail = '$loginEmail${FirebaseConstants.staffEmailDomain}';
      }
    }

    if (!FirebaseConstants.isPhenikaaEmail(loginEmail)) {
      throw Exception(
        'Vui lòng sử dụng email Phenikaa (${FirebaseConstants.studentEmailDomain} hoặc ${FirebaseConstants.staffEmailDomain})',
      );
    }

    final isStudentEmail = loginEmail.endsWith(
      FirebaseConstants.studentEmailDomain,
    );

    // Fallback cho môi trường test khi không có Firebase Auth thực
    final safeAuth = _safeFirebaseAuth;
    if (safeAuth == null && _testMockCredentials.containsKey(loginEmail)) {
      final expectedPw = _testMockCredentials[loginEmail];
      if (expectedPw != password) {
        throw Exception('Mật khẩu sai. Vui lòng kiểm tra lại.');
      }
      final testUid =
          'test_user_${loginEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final isAdmin = await verifyAdminPrivilege(testUid);
      return UserModel(
        uid: testUid,
        email: loginEmail,
        studentId: isStudentEmail ? loginEmail.split('@').first : 'ADMIN',
        displayName: isAdmin ? 'Ban Quản trị Phenikaa' : 'Sinh viên Phenikaa',
        username: loginEmail.split('@').first,
        faculty: isAdmin ? 'Phòng Công tác Sinh viên' : 'Công nghệ thông tin',
        major: isAdmin ? 'Quản trị hệ thống' : 'Kỹ thuật phần mềm',
        cohort: isAdmin ? 0 : 17,
        userType: isAdmin ? 'admin' : 'student',
        isVerified: true,
      );
    }

    // Kiểm tra kích hoạt mã sinh viên (chỉ áp dụng với tài khoản sinh viên)
    if (isStudentEmail) {
      final studentId = loginEmail.split('@').first;
      await isStudentActivated(
        studentId: studentId,
        email: loginEmail,
      );
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

      // Kiểm tra tài khoản có bị khóa không
      try {
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(milliseconds: 2000));
        if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
          await _firebaseAuth.signOut();
          throw Exception(
            'Tài khoản của bạn đã bị khóa do vi phạm chính sách cộng đồng.',
          );
        }
      } catch (e) {
        if (e.toString().contains('bị khóa')) rethrow;
      }

      // Xác thực quyền Admin thực tế từ nguồn tin cậy
      final isAdmin = await verifyAdminPrivilege(firebaseUser.uid);

      // Nếu là sinh viên, kiểm tra trạng thái email verified
      if (!isAdmin && isStudentEmail) {
        try {
          await firebaseUser.reload().timeout(
            const Duration(milliseconds: 1500),
          );
        } catch (_) {}
        final refreshedUser = _firebaseAuth.currentUser ?? firebaseUser;
        if (!refreshedUser.emailVerified) {
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
      }

      // Đọc thông tin người dùng từ Firestore
      final existingProfile = await getUserProfile(firebaseUser.uid);
      if (existingProfile != null) {
        final effectiveUserType = isAdmin
            ? 'admin'
            : (existingProfile.userType == 'admin'
                  ? 'student'
                  : existingProfile.userType);
        return existingProfile.copyWith(userType: effectiveUserType);
      }

      final studentIdStr = isStudentEmail
          ? loginEmail.split('@').first
          : 'ADMIN';
      String fullName =
          firebaseUser.displayName ??
          (isAdmin ? 'Ban Quản trị Phenikaa' : 'Sinh viên Phenikaa');
      String faculty = isAdmin
          ? 'Phòng Công tác Sinh viên'
          : 'Công nghệ thông tin';
      String major = isAdmin ? 'Quản trị hệ thống' : 'Chưa cập nhật';
      int cohort = isAdmin ? 0 : 17;

      if (isStudentEmail) {
        final match = PhenikaaStudentDirectory.defaultStudents.where(
          (s) => s.studentId == studentIdStr || s.email == loginEmail,
        );
        if (match.isNotEmpty) {
          fullName = match.first.fullName;
          faculty = match.first.faculty;
          major = match.first.major;
          cohort = match.first.cohort;
        }
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: loginEmail,
        studentId: studentIdStr,
        displayName: fullName,
        username: studentIdStr,
        faculty: faculty,
        major: major,
        cohort: cohort,
        userType: isAdmin ? 'admin' : 'student',
        isVerified: true,
      );

      try {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(newUser.toMap(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Warning: Could not save new user profile immediately: $e');
      }

      return newUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Mật khẩu sai. Vui lòng kiểm tra lại.');
      } else if (e.code == 'user-not-found') {
        throw Exception(
          'Tài khoản chưa kích hoạt. Vui lòng chuyển sang tab "Kích hoạt tài khoản".',
        );
      }
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
        final googleProvider = GoogleAuthProvider();
        credential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại.');
      }

      final email = (firebaseUser.email ?? '').trim().toLowerCase();

      if (!FirebaseConstants.isPhenikaaEmail(email)) {
        await _firebaseAuth.signOut();
        throw Exception(
          'Tài khoản "$email" không thuộc Đại học Phenikaa. Vui lòng đăng nhập bằng email trường (@st.phenikaa-uni.edu.vn hoặc @phenikaa-uni.edu.vn).',
        );
      }

      final profile = await getUserProfile(firebaseUser.uid);
      if (profile != null) {
        return profile;
      }

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
    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        final safeStore = _safeFirestore;
        if (safeStore != null) {
          await safeStore
              .collection(FirebaseConstants.usersCollection)
              .doc(uid)
              .update({
                'isOnline': false,
                'lastActive': FieldValue.serverTimestamp(),
              })
              .timeout(const Duration(milliseconds: 1500))
              .catchError((_) {});
        }
      }
    } catch (_) {}

    try {
      final currentUser = _firebaseAuth.currentUser;
      final isGoogleUser =
          currentUser?.providerData.any(
            (provider) => provider.providerId == 'google.com',
          ) ??
          false;

      if (isGoogleUser) {
        final googleSignIn = GoogleSignIn(
          hostedDomain: 'st.phenikaa-uni.edu.vn',
          scopes: ['email', 'profile'],
        );
        await googleSignIn.signOut().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      }
    } catch (_) {}

    final safeAuth = _safeFirebaseAuth;
    if (safeAuth != null) {
      try {
        await safeAuth.signOut().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      } catch (_) {}
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    final safeAuth = _safeFirebaseAuth;
    if (safeAuth == null) {
      return const Stream.empty();
    }

    return safeAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;
      final email = firebaseUser.email ?? '';
      final isGoogle = firebaseUser.providerData.any(
        (p) => p.providerId == 'google.com',
      );

      final isAdmin = await verifyAdminPrivilege(uid);

      // Đối với sinh viên, phải xác thực email trước khi cho phép vào
      if (!isAdmin && !isGoogle && !firebaseUser.emailVerified) {
        return null;
      }

      final profile = await getUserProfile(uid);
      if (profile != null) {
        final effectiveUserType = isAdmin
            ? 'admin'
            : (profile.userType == 'admin' ? 'student' : profile.userType);
        return profile.copyWith(userType: effectiveUserType);
      }

      final isStudentEmail = email.endsWith(
        FirebaseConstants.studentEmailDomain,
      );
      final studentId = isStudentEmail && email.contains('@')
          ? email.split('@').first
          : (isAdmin ? 'ADMIN' : '');
      String fullName =
          firebaseUser.displayName ??
          (isAdmin ? 'Ban Quản trị Phenikaa' : 'Sinh viên Phenikaa');
      String faculty = isAdmin
          ? 'Phòng Công tác Sinh viên'
          : 'Công nghệ thông tin';
      String major = isAdmin ? 'Quản trị hệ thống' : 'Kỹ thuật phần mềm';
      int cohort = isAdmin ? 0 : 17;

      if (isStudentEmail) {
        final match = PhenikaaStudentDirectory.defaultStudents.where(
          (s) => s.studentId == studentId || s.email == email,
        );
        if (match.isNotEmpty) {
          fullName = match.first.fullName;
          faculty = match.first.faculty;
          major = match.first.major;
          cohort = match.first.cohort;
        }
      }

      return UserModel(
        uid: uid,
        email: email,
        studentId: studentId,
        displayName: fullName,
        username: studentId,
        faculty: faculty,
        major: major,
        cohort: cohort,
        userType: isAdmin ? 'admin' : 'student',
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
          .timeout(const Duration(milliseconds: 2500));

      if (doc.exists && doc.data() != null) {
        var user = UserModel.fromFirestore(doc);
        final isAdmin = await verifyAdminPrivilege(uid);
        if (!isAdmin && user.userType == 'admin') {
          user = user.copyWith(userType: 'student');
        } else if (isAdmin && user.userType != 'admin') {
          user = user.copyWith(userType: 'admin');
        }
        try {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_user_profile_$uid',
            jsonEncode(user.toMap()),
          );
        } catch (_) {}
        return user;
      }
    } catch (_) {}

    // Fallback sang SharedPreferences cache nếu Firestore timeout hoặc offline
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_user_profile_$uid');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        var user = UserModel.fromMap(map, uid);
        final isAdmin = await verifyAdminPrivilege(uid);
        if (!isAdmin && user.userType == 'admin') {
          user = user.copyWith(userType: 'student');
        } else if (isAdmin && user.userType != 'admin') {
          user = user.copyWith(userType: 'admin');
        }
        return user;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<UserEntity?> getUserByStudentId(String studentId) async {
    final cleanId = studentId.trim();
    if (cleanId.isEmpty) return null;

    // 1. Tìm kiếm trong Firestore theo trường studentId
    try {
      final snap = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('studentId', isEqualTo: cleanId)
          .limit(1)
          .get()
          .timeout(const Duration(milliseconds: 3000));
      if (snap.docs.isNotEmpty) {
        return UserModel.fromFirestore(snap.docs.first);
      }
    } catch (_) {}

    // 2. Tìm kiếm trong Firestore theo document ID (nếu studentId là uid hoặc mã doc)
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(cleanId)
          .get()
          .timeout(const Duration(milliseconds: 2500));
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}

    // 3. Fallback sang danh bạ sinh viên Phenikaa (offline / mock / kiểm thử)
    final match = PhenikaaStudentDirectory.defaultStudents.where(
      (s) => s.studentId == cleanId || s.email.split('@').first == cleanId,
    );
    if (match.isNotEmpty) {
      final s = match.first;
      return UserModel(
        uid: 'user_${s.studentId}',
        email: s.email,
        studentId: s.studentId,
        displayName: s.fullName,
        username: s.studentId,
        faculty: s.faculty,
        major: s.major,
        cohort: s.cohort,
        userType: 'student',
        isVerified: true,
      );
    }

    return null;
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
      createdAt: user.createdAt,
      gpa: user.gpa,
      creditsEarned: user.creditsEarned,
      trainingPoints: user.trainingPoints,
    );

    // Lưu ngay vào SharedPreferences cache để avatar và hồ sơ người dùng luôn hiển thị bền vững
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_profile_${user.uid}',
        jsonEncode(model.toMap()),
      );
    } catch (_) {}

    try {
      final safeStore = _safeFirestore;
      if (safeStore != null) {
        await safeStore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .set(model.toMap(), SetOptions(merge: true))
            .timeout(const Duration(milliseconds: 3500));

        // Tự động đồng bộ Avatar và Tên hiển thị sang tất cả bài viết của người dùng
        if (user.avatarUrl.isNotEmpty || user.displayName.isNotEmpty) {
          try {
            final userPostsSnap = await safeStore
                .collection(FirebaseConstants.postsCollection)
                .where('authorId', isEqualTo: user.uid)
                .get()
                .timeout(const Duration(seconds: 4));

            if (userPostsSnap.docs.isNotEmpty) {
              final batch = safeStore.batch();
              for (final doc in userPostsSnap.docs) {
                final updateMap = <String, dynamic>{};
                if (user.avatarUrl.isNotEmpty) {
                  updateMap['authorAvatar'] = user.avatarUrl;
                }
                if (user.displayName.isNotEmpty) {
                  updateMap['authorName'] = user.displayName;
                }
                batch.update(doc.reference, updateMap);
              }
              await batch.commit().timeout(const Duration(seconds: 4));
            }
          } catch (e) {
            debugPrint('Warning: Could not batch update author info on posts: $e');
          }
        }
      }
    } catch (_) {}

    try {
      final safeAuth = _safeFirebaseAuth;
      if (safeAuth?.currentUser != null) {
        if (user.avatarUrl.isNotEmpty &&
            !user.avatarUrl.startsWith('data:') &&
            user.avatarUrl.length < 2000) {
          await safeAuth!.currentUser!.updatePhotoURL(user.avatarUrl);
        }
        if (user.displayName.isNotEmpty) {
          await safeAuth!.currentUser!.updateDisplayName(user.displayName);
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    final safeAuth = _safeFirebaseAuth;
    final user = safeAuth?.currentUser;

    // Fallback cho môi trường test khi không có phiên Firebase Auth
    if (user == null || user.email == null) {
      for (final entry in _testMockCredentials.entries) {
        if (entry.value == currentPassword) {
          _testMockCredentials[entry.key] = newPassword;
          return;
        }
      }
      throw Exception('Mật khẩu hiện tại không chính xác.');
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Chưa bật Email/Mật khẩu trên Firebase Console. Vui lòng vào Console > Authentication > Sign-in method và BẬT "Email/Password".';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại Internet.';
      case 'user-not-found':
        return 'Tài khoản chưa được kích hoạt hoặc không tồn tại. Vui lòng chuyển sang tab "Kích hoạt tài khoản" để kích hoạt.';
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
