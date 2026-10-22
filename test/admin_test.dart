import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_connection/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/auth/data/repositories/auth_repository_impl.dart';

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

    test('getReports returns seed reports and filters by status correctly', () async {
      final allReports = await repository.getReports();
      expect(allReports, isNotEmpty);

      final pendingReports = await repository.getReports(status: 'pending');
      expect(pendingReports, isNotEmpty);
      expect(pendingReports.every((r) => r.status == 'pending'), isTrue);
    });

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
      final targetUser = users.firstWhere((u) => u.uid == targetReport.targetAuthorId || u.studentId == targetReport.targetAuthorId);
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

      await repository.updateUserStatus(user.uid, isBanned: true, banReason: 'Spam');
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
      expect(updated.firstWhere((u) => u.uid == user.uid).userType, equals('moderator'));

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

    test('filterReports updates selectedReportStatus and reports in state', () async {
      await cubit.init();
      await cubit.filterReports('pending');

      expect(cubit.state.selectedReportStatus, equals('pending'));
      expect(cubit.state.reports.every((r) => r.status == 'pending'), isTrue);
    });

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

      await cubit.toggleBanUser(user.uid, isBanned: true, banReason: 'Thử nghiệm');

      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(cubit.state.users.firstWhere((u) => u.uid == user.uid).isBanned, isTrue);
    });

    test('broadcastAnnouncement emits success message', () async {
      await cubit.broadcastAnnouncement(
        title: 'Thông báo khẩn',
        content: 'Nghỉ lễ theo quy định',
      );

      expect(cubit.state.status, equals(AdminStatus.actionSuccess));
      expect(cubit.state.successMessage, contains('phát thông báo'));
    });
  });

  group('Admin Pre-configured Credentials & Self Password Change Tests', () {
    late SharedPreferences prefs;
    late AuthRepositoryImpl authRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authRepo = AuthRepositoryImpl(prefs: prefs);
    });

    test('Admin logs in with default system credentials provided by developer', () async {
      final admin = await authRepo.signInWithEmailAndPassword(
        email: 'admin',
        password: 'Admin@Phenikaa2026',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.userType, equals('admin'));
      expect(admin.email, equals('admin@phenikaa-uni.edu.vn'));
      expect(admin.displayName, equals('Ban Quản trị Phenikaa'));
    });

    test('Admin login fails with wrong password', () async {
      expect(
        () => authRepo.signInWithEmailAndPassword(
          email: 'admin@phenikaa-uni.edu.vn',
          password: 'wrong_password_123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Admin can change password after login, and new password is required on next login', () async {
      // 1. Đăng nhập với mật khẩu mặc định ban đầu do lập trình viên cấp
      final admin = await authRepo.signInWithEmailAndPassword(
        email: 'admin',
        password: 'Admin@Phenikaa2026',
      );
      expect(admin.isAdmin, isTrue);

      // 2. Admin tự đổi mật khẩu sang mật khẩu mới
      const newPassword = 'NewSecretAdminPassword@2026';
      await authRepo.changePassword(
        currentPassword: 'Admin@Phenikaa2026',
        newPassword: newPassword,
      );

      // 3. Đăng xuất
      await authRepo.signOut();

      // 4. Mật khẩu cũ bị từ chối
      expect(
        () => authRepo.signInWithEmailAndPassword(
          email: 'admin',
          password: 'Admin@Phenikaa2026',
        ),
        throwsA(isA<Exception>()),
      );

      // 5. Đăng nhập thành công với mật khẩu mới
      final reloadedAdmin = await authRepo.signInWithEmailAndPassword(
        email: 'admin',
        password: newPassword,
      );
      expect(reloadedAdmin.isAdmin, isTrue);
      expect(reloadedAdmin.email, equals('admin@phenikaa-uni.edu.vn'));
    });

    test('Admin changePassword throws exception if current password is wrong', () async {
      await authRepo.signInWithEmailAndPassword(
        email: 'admin',
        password: 'Admin@Phenikaa2026',
      );

      expect(
        () => authRepo.changePassword(
          currentPassword: 'IncorrectOldPassword',
          newPassword: 'SomeNewPassword123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
