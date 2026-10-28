import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/phenikaa_student_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository _adminRepository;

  AdminCubit({required AdminRepository adminRepository})
    : _adminRepository = adminRepository,
      super(const AdminState());

  /// Tải dữ liệu toàn diện cho Bảng điều khiển Quản trị viên
  Future<void> init() async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      final stats = await _adminRepository.getDashboardStats();
      final reports = await _adminRepository.getReports(
        status: state.selectedReportStatus,
      );
      final users = await _adminRepository.getAllUsers(
        query: state.searchUserQuery,
        faculty: state.selectedFaculty,
      );
      final docs = await _adminRepository.getAllDocuments();
      final logs = await _adminRepository.getAuditLogs();
      final pStudents = await _adminRepository.getPhenikaaStudents(
        query: state.searchPhenikaaStudentQuery,
      );

      emit(
        state.copyWith(
          status: AdminStatus.loaded,
          stats: stats,
          reports: reports,
          users: users,
          documents: docs,
          auditLogs: logs,
          phenikaaStudents: pStudents,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminStatus.error,
          errorMessage: 'Lỗi tải dữ liệu quản trị: $e',
        ),
      );
    }
  }

  /// Lọc danh sách báo cáo theo trạng thái ('all', 'pending', 'resolved', 'dismissed')
  Future<void> filterReports(String status) async {
    emit(state.copyWith(selectedReportStatus: status));
    try {
      final reports = await _adminRepository.getReports(status: status);
      emit(state.copyWith(reports: reports));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi lọc báo cáo: $e'));
    }
  }

  /// Xử lý báo cáo vi phạm
  Future<void> resolveReport(
    String reportId, {
    required String action,
    String? note,
  }) async {
    try {
      await _adminRepository.resolveReport(
        reportId,
        action: action,
        note: note,
      );

      final updatedReports = await _adminRepository.getReports(
        status: state.selectedReportStatus,
      );
      final updatedStats = await _adminRepository.getDashboardStats();

      String message = 'Đã xử lý báo cáo thành công!';
      if (action == 'delete_content') {
        message = 'Đã gỡ bài viết vi phạm và lưu biên bản kiểm duyệt!';
      } else if (action == 'ban_user') {
        message = 'Đã khóa tài khoản người dùng vi phạm quy chuẩn!';
      } else if (action == 'dismiss') {
        message = 'Đã bỏ qua báo cáo không hợp lệ.';
      }

      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          reports: updatedReports,
          stats: updatedStats,
          successMessage: message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể xử lý báo cáo: $e'));
    }
  }

  /// Tìm kiếm sinh viên theo tên hoặc MSSV
  Future<void> searchUsers(String query) async {
    emit(state.copyWith(searchUserQuery: query));
    try {
      final users = await _adminRepository.getAllUsers(
        query: query,
        faculty: state.selectedFaculty,
      );
      emit(state.copyWith(users: users));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi tìm kiếm: $e'));
    }
  }

  /// Lọc sinh viên theo Khoa
  Future<void> filterUsersByFaculty(String faculty) async {
    emit(state.copyWith(selectedFaculty: faculty));
    try {
      final users = await _adminRepository.getAllUsers(
        query: state.searchUserQuery,
        faculty: faculty,
      );
      emit(state.copyWith(users: users));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi lọc khoa: $e'));
    }
  }

  /// Khóa hoặc mở khóa tài khoản sinh viên
  Future<void> toggleBanUser(
    String userId, {
    required bool isBanned,
    String? banReason,
  }) async {
    try {
      await _adminRepository.updateUserStatus(
        userId,
        isBanned: isBanned,
        banReason: banReason,
      );

      final updatedUsers = await _adminRepository.getAllUsers(
        query: state.searchUserQuery,
        faculty: state.selectedFaculty,
      );
      final updatedStats = await _adminRepository.getDashboardStats();

      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          users: updatedUsers,
          stats: updatedStats,
          successMessage: isBanned
              ? 'Đã đình chỉ tài khoản sinh viên thành công!'
              : 'Đã mở khóa và khôi phục quyền truy cập cho sinh viên!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Lỗi cập nhật trạng thái tài khoản: $e'),
      );
    }
  }

  /// Thay đổi vai trò người dùng ('student', 'moderator', 'admin')
  Future<void> changeUserRole(String userId, {required String newRole}) async {
    try {
      await _adminRepository.updateUserRole(userId, newRole: newRole);

      final updatedUsers = await _adminRepository.getAllUsers(
        query: state.searchUserQuery,
        faculty: state.selectedFaculty,
      );

      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          users: updatedUsers,
          successMessage: 'Đã cập nhật vai trò người dùng thành "$newRole"!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi cập nhật vai trò: $e'));
    }
  }

  /// Xóa tài liệu học tập
  Future<void> deleteDocument(String documentId) async {
    try {
      await _adminRepository.deleteDocument(documentId);

      final updatedDocs = await _adminRepository.getAllDocuments();
      final updatedStats = await _adminRepository.getDashboardStats();

      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          documents: updatedDocs,
          stats: updatedStats,
          successMessage: 'Đã xóa tài liệu khỏi DocsHub trường!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi xóa tài liệu: $e'));
    }
  }

  /// Phát thông báo toàn trường
  Future<void> broadcastAnnouncement({
    required String title,
    required String content,
    String? targetFaculty,
  }) async {
    try {
      await _adminRepository.broadcastAnnouncement(
        title: title,
        content: content,
        targetFaculty: targetFaculty,
      );

      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          successMessage:
              'Đã phát thông báo khẩn đến toàn bộ sinh viên Phenikaa!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi phát thông báo: $e'));
    }
  }

  /// Tải lại danh sách nhật ký quản trị
  Future<void> loadAuditLogs() async {
    try {
      final logs = await _adminRepository.getAuditLogs();
      emit(state.copyWith(auditLogs: logs));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi tải nhật ký: $e'));
    }
  }

  /// Xóa bài viết vi phạm
  Future<void> deletePost(String postId) async {
    try {
      await _adminRepository.deletePost(postId);
      final stats = await _adminRepository.getDashboardStats();
      final logs = await _adminRepository.getAuditLogs();
      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          stats: stats,
          auditLogs: logs,
          successMessage: 'Đã gỡ bài viết vi phạm tiêu chuẩn!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi gỡ bài viết: $e'));
    }
  }

  /// Tìm kiếm sinh viên trong danh bạ Phenikaa
  Future<void> searchPhenikaaStudents(String query) async {
    emit(state.copyWith(searchPhenikaaStudentQuery: query));
    try {
      final list = await _adminRepository.getPhenikaaStudents(query: query);
      emit(state.copyWith(phenikaaStudents: list));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi tìm kiếm danh bạ: $e'));
    }
  }

  /// Thêm sinh viên mới vào danh bạ Phenikaa để tiền thẩm định kích hoạt
  Future<void> addPhenikaaStudent(PhenikaaStudentEntity student) async {
    try {
      await _adminRepository.addPhenikaaStudent(student);
      final list = await _adminRepository.getPhenikaaStudents(
        query: state.searchPhenikaaStudentQuery,
      );
      final stats = await _adminRepository.getDashboardStats();
      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          phenikaaStudents: list,
          stats: stats,
          successMessage:
              'Đã thêm sinh viên ${student.fullName} (${student.studentId}) vào danh bạ thành công!',
        ),
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(errorMessage: cleanMsg));
      rethrow;
    }
  }

  /// Xóa sinh viên khỏi danh bạ Phenikaa
  Future<void> deletePhenikaaStudent(String studentId) async {
    try {
      await _adminRepository.deletePhenikaaStudent(studentId);
      final list = await _adminRepository.getPhenikaaStudents(
        query: state.searchPhenikaaStudentQuery,
      );
      emit(
        state.copyWith(
          status: AdminStatus.actionSuccess,
          phenikaaStudents: list,
          successMessage: 'Đã xóa sinh viên khỏi danh bạ Phenikaa!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi xóa sinh viên: $e'));
    }
  }
}
