import '../../../auth/domain/entities/phenikaa_student_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../moderation/domain/entities/report_entity.dart';
import '../entities/admin_dashboard_stats.dart';
import '../entities/admin_audit_log_entity.dart';

abstract class AdminRepository {
  /// Lấy số liệu thống kê tổng quan của hệ thống
  Future<AdminDashboardStats> getDashboardStats();

  /// Lấy danh sách các báo cáo vi phạm
  Future<List<ReportEntity>> getReports({String? status});

  /// Xử lý một báo cáo vi phạm
  /// [action]: 'dismiss' (bỏ qua), 'delete_content' (xóa bài/bình luận), 'ban_user' (khóa tài khoản)
  Future<void> resolveReport(
    String reportId, {
    required String action,
    String? note,
  });

  /// Xóa trực tiếp một bài viết vi phạm
  Future<void> deletePost(String postId);

  /// Tra cứu danh sách toàn bộ người dùng / sinh viên
  Future<List<UserEntity>> getAllUsers({String? query, String? faculty});

  /// Khóa hoặc mở khóa tài khoản người dùng
  Future<void> updateUserStatus(
    String userId, {
    required bool isBanned,
    String? banReason,
  });

  /// Đổi vai trò / phân quyền người dùng ('student', 'moderator', 'admin')
  Future<void> updateUserRole(String userId, {required String newRole});

  /// Lấy danh sách tài liệu học tập
  Future<List<DocumentEntity>> getAllDocuments();

  /// Xóa tài liệu vi phạm hoặc không phù hợp
  Future<void> deleteDocument(String documentId);

  /// Phát thông báo khẩn toàn trường đến tất cả sinh viên
  Future<void> broadcastAnnouncement({
    required String title,
    required String content,
    String? targetFaculty,
  });

  /// Lấy danh sách nhật ký quản trị (Audit Logs)
  Future<List<AdminAuditLogEntity>> getAuditLogs({int limit = 50});

  /// Ghi nhật ký thao tác quản trị
  Future<void> logAuditAction({
    required String action,
    required String targetType,
    required String targetId,
    String? details,
  });

  /// Tra cứu danh bạ sinh viên Phenikaa (collection 'phenikaa_students')
  Future<List<PhenikaaStudentEntity>> getPhenikaaStudents({String? query});

  /// Thêm sinh viên vào danh bạ Phenikaa để tiền thẩm định kích hoạt
  Future<void> addPhenikaaStudent(PhenikaaStudentEntity student);

  /// Cập nhật thông tin sinh viên trong danh bạ
  Future<void> updatePhenikaaStudent(PhenikaaStudentEntity student);

  /// Xóa sinh viên khỏi danh bạ Phenikaa
  Future<void> deletePhenikaaStudent(String studentId);
}
