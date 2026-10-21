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

  FirebaseAuth get _firebaseAuth => _customFirebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

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

  static const String defaultAdminEmail = 'admin@phenikaa-uni.edu.vn';
  static const String defaultAdminInitialPassword = 'Admin@Phenikaa2026';
  static const String adminPasswordPrefKey = 'system_admin_custom_password';

  final StreamController<UserEntity?> _adminStateController =
      StreamController<UserEntity?>.broadcast();
  UserEntity? _cachedAdminUser;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _customFirebaseAuth = firebaseAuth,
        _customFirestore = firestore,
        _prefs = prefs;

  @override
  Future<PhenikaaStudentEntity> verifyStudentIdentifier(String identifier) async {
    final trimmed = identifier.trim().toLowerCase();
    String studentId = trimmed;
    if (trimmed.contains('@')) {
      studentId = trimmed.split('@').first;
    }

    PhenikaaStudentModel? student;

    final localMatch = PhenikaaStudentDirectory.defaultStudents.where(
      (s) => s.studentId.toLowerCase() == studentId || s.email.toLowerCase() == trimmed,
    );
    if (localMatch.isNotEmpty) {
      student = localMatch.first;
    }

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
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    String loginEmail = email.trim().toLowerCase();

    if (!loginEmail.contains('@')) {
      if (loginEmail == 'admin' || loginEmail.startsWith('admin')) {
        loginEmail = '$loginEmail${FirebaseConstants.staffEmailDomain}';
      } else {
        loginEmail = '$loginEmail${FirebaseConstants.studentEmailDomain}';
      }
    }

    if (!FirebaseConstants.isPhenikaaEmail(loginEmail)) {
      throw Exception('Vui lòng sử dụng email Phenikaa (${FirebaseConstants.studentEmailDomain} hoặc ${FirebaseConstants.staffEmailDomain})');
    }

    final isStaffOrAdmin = loginEmail.endsWith(FirebaseConstants.staffEmailDomain) ||
        loginEmail.startsWith('admin');
    final isAdminAccount = loginEmail == defaultAdminEmail || loginEmail.startsWith('admin');

    // === XỬ LÝ ĐĂNG NHẬP RIÊNG CHO TÀI KHOẢN ADMIN HỆ THỐNG CÓ SẴN ===
    if (isAdminAccount) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final currentAdminPassword = prefs.getString(adminPasswordPrefKey) ?? defaultAdminInitialPassword;

      bool isPasswordValid = (password == currentAdminPassword);
      UserCredential? credential;

      final safeAuth = _safeFirebaseAuth;
      if (safeAuth != null) {
        try {
          credential = await safeAuth.signInWithEmailAndPassword(
            email: defaultAdminEmail,
            password: password,
          );
          isPasswordValid = true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            if (isPasswordValid) {
              try {
                credential = await safeAuth.createUserWithEmailAndPassword(
                  email: defaultAdminEmail,
                  password: password,
                );
                await credential.user?.updateDisplayName('Ban Quản trị Phenikaa');
              } catch (_) {}
            }
          } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            if (!isPasswordValid) {
              throw Exception(
                'Mật khẩu Admin không chính xác. Mật khẩu khởi tạo ban đầu do hệ thống cấp là "$defaultAdminInitialPassword" (hoặc mật khẩu mới nếu bạn đã từng đổi).',
              );
            }
          }
        } catch (_) {}
      }

      if (!isPasswordValid) {
        throw Exception(
          'Mật khẩu Admin không chính xác. Mật khẩu khởi tạo ban đầu do hệ thống cấp là "$defaultAdminInitialPassword" (hoặc mật khẩu mới nếu bạn đã từng đổi).',
        );
      }

      final adminUser = UserModel(
        uid: credential?.user?.uid ?? safeAuth?.currentUser?.uid ?? 'phenikaa_system_admin_uid',
        email: defaultAdminEmail,
        studentId: 'ADMIN',
        displayName: 'Ban Quản trị Phenikaa',
        username: 'admin',
        faculty: 'Phòng Công tác Sinh viên',
        major: 'Quản trị hệ thống',
        cohort: 0,
        userType: 'admin',
        isVerified: true,
      );

      _cachedAdminUser = adminUser;
      _adminStateController.add(adminUser);

      final safeStore = _safeFirestore;
      if (safeStore != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          safeStore
              .collection(FirebaseConstants.usersCollection)
              .doc(adminUser.uid)
              .set(adminUser.toMap(), SetOptions(merge: true))
              .catchError((_) {});
        });
      }

      return adminUser;
    }

    if (!isStaffOrAdmin) {
      final studentId = loginEmail.split('@').first;
      final isActivated = await isStudentActivated(
        studentId: studentId,
        email: loginEmail,
      );
      if (!isActivated) {
        throw Exception('Tài khoản chưa kích hoạt. Vui lòng chuyển sang tab "Kích hoạt tài khoản" để kích hoạt.');
      }
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

      try {
        await firebaseUser.reload().timeout(const Duration(milliseconds: 1500));
      } catch (_) {}
      final refreshedUser = _firebaseAuth.currentUser ?? firebaseUser;

      if (!refreshedUser.emailVerified && !isStaffOrAdmin) {
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

      // Kiểm tra tài khoản có bị khóa không
      try {
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(milliseconds: 2000));
        if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
          await _firebaseAuth.signOut();
          throw Exception('Tài khoản của bạn đã bị khóa do vi phạm chính sách cộng đồng.');
        }
      } catch (e) {
        if (e.toString().contains('bị khóa')) rethrow;
      }

      final studentIdStr = loginEmail.split('@').first;
      String fullName = firebaseUser.displayName ?? (isStaffOrAdmin ? 'Ban Quản trị Phenikaa' : 'Sinh viên Phenikaa');
      String faculty = isStaffOrAdmin ? 'Phòng Công tác Sinh viên' : 'Công nghệ thông tin';
      String major = isStaffOrAdmin ? 'Quản trị hệ thống' : 'Chưa cập nhật';
      int cohort = isStaffOrAdmin ? 0 : 17;
      String userType = isStaffOrAdmin ? 'admin' : 'student';

      final match = PhenikaaStudentDirectory.defaultStudents.where(
        (s) => s.studentId == studentIdStr || s.email == loginEmail,
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
        studentId: studentIdStr,
        displayName: fullName,
        username: studentIdStr,
        faculty: faculty,
        major: major,
        cohort: cohort,
        userType: userType,
        isVerified: true,
      );

      // Đồng bộ thông tin người dùng lên Firestore một cách bất đồng bộ
      // Tránh nghẽn Main Thread hoặc tranh chấp tài nguyên mạng khi đang chuyển màn hình
      Future.delayed(const Duration(milliseconds: 800), () {
        _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(restoredUser.toMap(), SetOptions(merge: true))
            .catchError((_) {});
      });

      return restoredUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Mật khẩu sai. Vui lòng kiểm tra lại.');
      } else if (e.code == 'user-not-found') {
        throw Exception('Tài khoản chưa kích hoạt. Vui lòng chuyển sang tab "Kích hoạt tài khoản".');
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
    _cachedAdminUser = null;
    _adminStateController.add(null);

    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        final safeStore = _safeFirestore;
        if (safeStore != null) {
          await safeStore.collection(FirebaseConstants.usersCollection).doc(uid).update({
            'isOnline': false,
            'lastActive': FieldValue.serverTimestamp(),
          }).timeout(const Duration(milliseconds: 1500)).catchError((_) {});
        }
      }
    } catch (_) {}

    try {
      final currentUser = _firebaseAuth.currentUser;
      final isGoogleUser = currentUser?.providerData.any(
        (provider) => provider.providerId == 'google.com',
      ) ?? false;

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
    final controller = StreamController<UserEntity?>.broadcast();

    if (_cachedAdminUser != null) {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(_cachedAdminUser);
        }
      });
    }

    final adminSub = _adminStateController.stream.listen((admin) {
      if (!controller.isClosed) {
        controller.add(admin);
      }
    });

    StreamSubscription? firebaseSub;
    final safeAuth = _safeFirebaseAuth;
    if (safeAuth != null) {
      firebaseSub = safeAuth.authStateChanges().asyncMap((firebaseUser) async {
        if (_cachedAdminUser != null) return _cachedAdminUser;
        if (firebaseUser == null) return null;

        final isGoogle = firebaseUser.providerData.any((p) => p.providerId == 'google.com');
        final email = firebaseUser.email ?? '';
        final isStaffOrAdmin = email.endsWith(FirebaseConstants.staffEmailDomain) || email.startsWith('admin');

        // Chỉ phát trạng thái đăng nhập nếu là Google, Admin/Cán bộ, hoặc email đã được xác thực
        if (!isGoogle && !firebaseUser.emailVerified && !isStaffOrAdmin) {
          return null;
        }

        final profile = await getUserProfile(firebaseUser.uid);
        if (profile != null) {
          return profile;
        }

        final studentId = email.contains('@') ? email.split('@').first : '';
        String fullName = firebaseUser.displayName ?? (isStaffOrAdmin ? 'Ban Quản trị Phenikaa' : 'Sinh viên Phenikaa');
        String faculty = isStaffOrAdmin ? 'Phòng Công tác Sinh viên' : 'Công nghệ thông tin';
        String major = isStaffOrAdmin ? 'Quản trị hệ thống' : 'Kỹ thuật phần mềm';
        int cohort = isStaffOrAdmin ? 0 : 17;

        final match = PhenikaaStudentDirectory.defaultStudents.where(
          (s) => s.studentId == studentId || s.email == email,
        );
        if (match.isNotEmpty) {
          fullName = match.first.fullName;
          faculty = match.first.faculty;
          major = match.first.major;
          cohort = match.first.cohort;
        }

        final fallbackUser = UserModel(
          uid: firebaseUser.uid,
          email: email,
          studentId: studentId,
          displayName: fullName,
          username: studentId,
          faculty: faculty,
          major: major,
          cohort: cohort,
          userType: isStaffOrAdmin ? 'admin' : 'student',
          isVerified: true,
        );

        return fallbackUser;
      }).listen((user) {
        if (!controller.isClosed && _cachedAdminUser == null) {
          controller.add(user);
        }
      });
    }

    controller.onCancel = () {
      adminSub.cancel();
      firebaseSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    if (_cachedAdminUser != null && _cachedAdminUser!.uid == uid) {
      return _cachedAdminUser;
    }

    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromFirestore(doc);
        try {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setString('cached_user_profile_$uid', jsonEncode(user.toMap()));
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
        return UserModel.fromMap(map, uid);
      }
    } catch (_) {}

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
      await prefs.setString('cached_user_profile_${user.uid}', jsonEncode(model.toMap()));
    } catch (_) {}

    // Đồng bộ vào tài khoản Admin cached nếu đang là phiên Admin
    if (_cachedAdminUser != null && _cachedAdminUser!.uid == user.uid) {
      _cachedAdminUser = model;
      _adminStateController.add(model);
    }

    try {
      final safeStore = _safeFirestore;
      if (safeStore != null) {
        await safeStore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .set(model.toMap(), SetOptions(merge: true))
            .timeout(const Duration(milliseconds: 3500));
      }
    } catch (_) {}

    try {
      final safeAuth = _safeFirebaseAuth;
      if (safeAuth?.currentUser != null) {
        if (user.avatarUrl.isNotEmpty && !user.avatarUrl.startsWith('data:') && user.avatarUrl.length < 2000) {
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
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final storedAdminPassword = prefs.getString(adminPasswordPrefKey) ?? defaultAdminInitialPassword;

    final safeAuth = _safeFirebaseAuth;
    final isCurrentAdmin = (_cachedAdminUser?.isAdmin == true) ||
        (safeAuth?.currentUser?.email?.toLowerCase() == defaultAdminEmail) ||
        (currentPassword == storedAdminPassword);

    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    // === XỬ LÝ ĐỔI MẬT KHẨU RIÊNG CHO ADMIN HỆ THỐNG ===
    if (isCurrentAdmin) {
      bool isOldPasswordValid = (currentPassword == storedAdminPassword);

      if (!isOldPasswordValid && safeAuth?.currentUser != null) {
        try {
          final cred = EmailAuthProvider.credential(
            email: defaultAdminEmail,
            password: currentPassword,
          );
          await safeAuth!.currentUser!.reauthenticateWithCredential(cred);
          isOldPasswordValid = true;
        } catch (_) {}
      }

      if (!isOldPasswordValid) {
        throw Exception('Mật khẩu hiện tại không chính xác.');
      }

      // Lưu mật khẩu quản trị mới vào SharedPreferences
      await prefs.setString(adminPasswordPrefKey, newPassword);

      // Cập nhật mật khẩu trên Firebase Auth nếu đang có phiên đăng nhập
      if (safeAuth?.currentUser != null) {
        try {
          await safeAuth!.currentUser!.updatePassword(newPassword);
        } catch (_) {}
      }
      return;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Vui lòng đăng nhập để thực hiện đổi mật khẩu.');
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
