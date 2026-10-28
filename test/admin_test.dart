import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_connection/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pu_connection/features/auth/domain/entities/phenikaa_student_entity.dart';

void main() {
  group('AdminRepositoryImpl Tests', () {
    late AdminRepositoryImpl repository;

    setUp(() {
      AdminRepositoryImpl.enableSeeds = true;
      AdminRepositoryImpl.resetMemory();
      repository = AdminRepositoryImpl();
    });

    test('getDashboardStats returns accurate initial system metrics', () async {
      final stats = await repository.getDashboardStats();

      expect(stats.totalStudents, greaterThan(0));
      expect(stats.totalPosts, greaterThan(0));
      expect(stats.totalDocuments, greaterThan(0));
      expect(stats.pendingReports, greaterThan(0));
      expect(stats.facultyDistribution, isNotEmpty);
    });

    test(
      'getReports returns seed reports and filters by status correctly',
      () async {
        final allReports = await repository.getReports();
        expect(allReports, isNotEmpty);

        final pendingReports = await repository.getReports(status: 'pending');
        expect(pendingReports, isNotEmpty);
        expect(pendingReports.every((r) => r.status == 'pending'), isTrue);
      },
    );

    test('resolveReport with dismiss updates status to dismissed', () async {
      final reports = await repository.getReports(status: 'pending');
      final firstReport = reports.first;

      await repository.resolveReport(firstReport.id, action: 'dismiss');

      final updatedReports = await repository.getReports();
      final resolved = updatedReports.firstWhere((r) => r.id == firstReport.id);
      expect(resolved.status, equals('dismissed'));
    });

    test('resolveReport with ban_user bans target author', () async {
      final reports = await repository.getReports(status: 'pending');
      final targetReport = reports.first;

      await repository.resolveReport(
        targetReport.id,
        action: 'ban_user',
        note: 'Tái diễn hành vi vi phạm',
      );

      final users = await repository.getAllUsers();
      final targetUser = users.firstWhere(
        (u) =>
            u.uid == targetReport.targetAuthorId ||
            u.studentId == targetReport.targetAuthorId,
      );
      expect(targetUser.isBanned, isTrue);
    });

    test('getAllUsers searches by name or studentId accurately', () async {
      final all = await repository.getAllUsers();
      expect(all, isNotEmpty);

      final searched = await repository.getAllUsers(query: 'Hà Mạnh Long');
      expect(searched, isNotEmpty);
      expect(searched.first.displayName, contains('Hà Mạnh Long'));

      final byId = await repository.getAllUsers(query: '23010390');
      expect(byId, isNotEmpty);
    });

    test('updateUserStatus toggles ban status successfully', () async {
      final users = await repository.getAllUsers();
      final user = users.first;

      await repository.updateUserStatus(
        user.uid,
        isBanned: true,
        banReason: 'Spam',
      );
      var updated = await repository.getAllUsers();
      expect(updated.firstWhere((u) => u.uid == user.uid).isBanned, isTrue);

      await repository.updateUserStatus(user.uid, isBanned: false);
      updated = await repository.getAllUsers();
      expect(updated.firstWhere((u) => u.uid == user.uid).isBanned, isFalse);
    });

    test('updateUserRole changes role to moderator or admin', () async {
      final users = await repository.getAllUsers();
      final user = users.first;

      await repository.updateUserRole(user.uid, newRole: 'moderator');
      var updated = await repository.getAllUsers();
      expect(
        updated.firstWhere((u) => u.uid == user.uid).userType,
        equals('moderator'),
      );

      await repository.updateUserRole(user.uid, newRole: 'admin');
      updated = await repository.getAllUsers();
      expect(updated.firstWhere((u) => u.uid == user.uid).isAdmin, isTrue);
    });

    test('deleteDocument removes document from repository', () async {
      final docs = await repository.getAllDocuments();
      expect(docs, isNotEmpty);
      final docToDelete = docs.first;

      await repository.deleteDocument(docToDelete.id);

      final remaining = await repository.getAllDocuments();
      expect(remaining.any((d) => d.id == docToDelete.id), isFalse);
    });

    test('broadcastAnnouncement executes gracefully', () async {
      expect(
        () => repository.broadcastAnnouncement(
          title: 'Lịch thi toàn trường',
          content: 'Sinh viên xem lịch thi tại cổng đào tạo',
        ),
        returnsNormally,
      );
    });
    test('deletePost removes post and records audit log', () async {
      await repository.deletePost('violating_post_001');
      final logs = await repository.getAuditLogs();
      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.action == 'delete_post'), isTrue);
    });

    test('audit logging captures operations accurately', () async {
      await repository.logAuditAction(
        action: 'test_action',
        targetType: 'test_target',
        targetId: '12345',
        details: 'Audit log verification test',
      );

      final logs = await repository.getAuditLogs();
      expect(logs.any((l) => l.action == 'test_action'), isTrue);
    });

    test('getPhenikaaStudents returns student directory and filters by query', () async {
      final students = await repository.getPhenikaaStudents();
      expect(students, isNotEmpty);

      final filtered = await repository.getPhenikaaStudents(query: '23010390');
      expect(filtered, isNotEmpty);
      expect(filtered.first.studentId, equals('23010390'));
    });

    test('addPhenikaaStudent adds student and rejects duplicate MSSV or email', () async {
      const newStudent = PhenikaaStudentEntity(
        studentId: '25019999',
        fullName: 'Trần Văn Mới',
        email: '25019999@st.phenikaa-uni.edu.vn',
        faculty: 'Công nghệ thông tin',
        major: 'Trí tuệ nhân tạo',
        cohort: 19,
        isActivated: false,
      );

      await repository.addPhenikaaStudent(newStudent);

      final list = await repository.getPhenikaaStudents(query: '25019999');
      expect(list, isNotEmpty);
      expect(list.first.fullName, equals('Trần Văn Mới'));

      // Check duplicate studentId
      expect(
        () => repository.addPhenikaaStudent(newStudent),
        throwsA(isA<Exception>()),
      );

      // Check duplicate email
      const duplicateEmailStudent = PhenikaaStudentEntity(
        studentId: '25018888',
        fullName: 'Trần Khác',
        email: '25019999@st.phenikaa-uni.edu.vn',
        faculty: 'Khoa học',
        major: 'Vật lý',
      );
      expect(
        () => repository.addPhenikaaStudent(duplicateEmailStudent),
        throwsA(isA<Exception>()),
      );
    });

    test('deletePhenikaaStudent removes student from directory', () async {
      const student = PhenikaaStudentEntity(
        studentId: '25017777',
        fullName: 'Sinh Viên Xóa',
        email: '25017777@st.phenikaa-uni.edu.vn',
        faculty: 'Khoa Y',
        major: 'Dược',
      );
      await repository.addPhenikaaStudent(student);

      await repository.deletePhenikaaStudent('25017777');
      final list = await repository.getPhenikaaStudents(query: '25017777');
      expect(list.any((s) => s.studentId == '25017777'), isFalse);
    });
  });

  group('AdminCubit Tests', () {
    late AdminRepositoryImpl repository;
    late AdminCubit cubit;

    setUp(() {
      AdminRepositoryImpl.resetMemory();
      repository = AdminRepositoryImpl();
      cubit = AdminCubit(adminRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('init loads all statistics, reports, users, and documents', () async {
      expect(cubit.state.status, equals(AdminStatus.initial));

      await cubit.init();

      expect(cubit.state.status, equals(AdminStatus.loaded));
      expect(cubit.state.stats.totalStudents, greaterThan(0));
      expect(cubit.state.reports, isNotEmpty);
      expect(cubit.state.users, isNotEmpty);
      expect(cubit.state.documents, isNotEmpty);
    });

    test(
      'filterReports updates selectedReportStatus and reports in state',
      () async {
        await cubit.init();
        await cubit.filterReports('pending');

        expect(cubit.state.selectedReportStatus, equals('pending'));
        expect(cubit.state.reports.every((r) => r.status == 'pending'), isTrue);
      },
    );

    test('resolveReport resolves report and updates stats', () async {
      await cubit.init();
      final report = cubit.state.reports.first;

      await cubit.resolveReport(report.id, action: 'dismiss');

      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(cubit.state.successMessage, isNotNull);
    });

    test('searchUsers updates filtered users in state', () async {
      await cubit.init();
      await cubit.searchUsers('Nguyễn');

      expect(cubit.state.searchUserQuery, equals('Nguyễn'));
      expect(cubit.state.users, isNotEmpty);
    });

    test('toggleBanUser bans user and updates state', () async {
      await cubit.init();
      final user = cubit.state.users.first;

      await cubit.toggleBanUser(
        user.uid,
        isBanned: true,
        banReason: 'Thử nghiệm',
      );

      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(
        cubit.state.users.firstWhere((u) => u.uid == user.uid).isBanned,
        isTrue,
      );
    });

    test('broadcastAnnouncement emits success message', () async {
      await cubit.broadcastAnnouncement(
        title: 'Thông báo khẩn',
        content: 'Nghỉ lễ theo quy định',
      );

      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(cubit.state.successMessage, contains('phát thông báo'));
    });

    test('searchPhenikaaStudents and addPhenikaaStudent update cubit state', () async {
      await cubit.init();
      expect(cubit.state.phenikaaStudents, isNotEmpty);

      const student = PhenikaaStudentEntity(
        studentId: '25016666',
        fullName: 'Sinh Viên Cubit',
        email: '25016666@st.phenikaa-uni.edu.vn',
        faculty: 'CNTT',
        major: 'KTPM',
      );

      await cubit.addPhenikaaStudent(student);
      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(
        cubit.state.phenikaaStudents.any((s) => s.studentId == '25016666'),
        isTrue,
      );

      await cubit.searchPhenikaaStudents('25016666');
      expect(cubit.state.phenikaaStudents.length, equals(1));
      expect(cubit.state.phenikaaStudents.first.studentId, equals('25016666'));

      await cubit.deletePhenikaaStudent('25016666');
      expect(
        cubit.state.phenikaaStudents.any((s) => s.studentId == '25016666'),
        isFalse,
      );
    });
  });

  group('Admin Role-Based Authentication & Privilege Verification Tests', () {
    late SharedPreferences prefs;
    late AuthRepositoryImpl authRepo;
    const adminEmail = 'admin.phongctsv@phenikaa-uni.edu.vn';
    const adminInitialPassword = 'AdminSecurePassword@2026';
    const adminUid = 'test_user_admin_phongctsv_phenikaa_uni_edu_vn';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authRepo = AuthRepositoryImpl(prefs: prefs);
      AuthRepositoryImpl.resetAdminTestingData();

      // Đăng ký tài khoản Admin đã được backend Admin SDK xác thực
      AuthRepositoryImpl.registerAdminForTesting(
        uid: adminUid,
        email: adminEmail,
        password: adminInitialPassword,
      );
    });

    tearDown(() {
      AuthRepositoryImpl.resetAdminTestingData();
    });

    test(
      'Admin logs in with pre-configured backend credentials and is assigned Admin role',
      () async {
        final admin = await authRepo.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminInitialPassword,
        );

        expect(admin.isAdmin, isTrue);
        expect(admin.userType, equals('admin'));
        expect(admin.email, equals(adminEmail));
        expect(admin.displayName, equals('Ban Quản trị Phenikaa'));
      },
    );

    test('Admin login fails with wrong password', () async {
      expect(
        () => authRepo.signInWithEmailAndPassword(
          email: adminEmail,
          password: 'wrong_password_123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Standard student account logging in cannot gain admin privileges',
      () async {
        const studentEmail = '23010390@st.phenikaa-uni.edu.vn';
        const studentPassword = 'StudentPass@123';
        const studentUid = 'test_user_23010390_st_phenikaa_uni_edu_vn';

        AuthRepositoryImpl.registerAdminForTesting(
          uid: 'other_uid',
          email: studentEmail,
          password: studentPassword,
        );

        final user = await authRepo.signInWithEmailAndPassword(
          email: studentEmail,
          password: studentPassword,
        );

        // Student is NOT verified as admin
        expect(user.isAdmin, isFalse);
        expect(user.userType, equals('student'));
        expect(await authRepo.verifyAdminPrivilege(studentUid), isFalse);
      },
    );

    test(
      'Admin can change password after login, and new password is required on next login',
      () async {
        // 1. Đăng nhập với mật khẩu khởi tạo ban đầu do backend cấp
        final admin = await authRepo.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminInitialPassword,
        );
        expect(admin.isAdmin, isTrue);

        // 2. Admin đổi mật khẩu sang mật khẩu mới
        const newPassword = 'NewSecretAdminPassword@2026';
        await authRepo.changePassword(
          currentPassword: adminInitialPassword,
          newPassword: newPassword,
        );

        // 3. Đăng xuất
        await authRepo.signOut();

        // 4. Mật khẩu cũ bị từ chối
        expect(
          () => authRepo.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminInitialPassword,
          ),
          throwsA(isA<Exception>()),
        );

        // 5. Đăng nhập thành công với mật khẩu mới
        final reloadedAdmin = await authRepo.signInWithEmailAndPassword(
          email: adminEmail,
          password: newPassword,
        );
        expect(reloadedAdmin.isAdmin, isTrue);
        expect(reloadedAdmin.email, equals(adminEmail));
      },
    );

    test(
      'Admin changePassword throws exception if current password is wrong',
      () async {
        expect(
          () => authRepo.changePassword(
            currentPassword: 'IncorrectOldPassword',
            newPassword: 'SomeNewPassword123',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
