import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/phenikaa_student_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../moderation/domain/entities/report_entity.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_audit_log_entity.dart';

enum AdminStatus { initial, loading, loaded, actionSuccess, error }

class AdminState extends Equatable {
  final AdminStatus status;
  final AdminDashboardStats stats;
  final List<ReportEntity> reports;
  final List<UserEntity> users;
  final List<DocumentEntity> documents;
  final List<AdminAuditLogEntity> auditLogs;
  final List<PhenikaaStudentEntity> phenikaaStudents;
  final String selectedReportStatus;
  final String searchUserQuery;
  final String searchPhenikaaStudentQuery;
  final String selectedFaculty;
  final String? errorMessage;
  final String? successMessage;

  const AdminState({
    this.status = AdminStatus.initial,
    this.stats = const AdminDashboardStats(),
    this.reports = const [],
    this.users = const [],
    this.documents = const [],
    this.auditLogs = const [],
    this.phenikaaStudents = const [],
    this.selectedReportStatus = 'all',
    this.searchUserQuery = '',
    this.searchPhenikaaStudentQuery = '',
    this.selectedFaculty = 'Tất cả',
    this.errorMessage,
    this.successMessage,
  });

  AdminState copyWith({
    AdminStatus? status,
    AdminDashboardStats? stats,
    List<ReportEntity>? reports,
    List<UserEntity>? users,
    List<DocumentEntity>? documents,
    List<AdminAuditLogEntity>? auditLogs,
    List<PhenikaaStudentEntity>? phenikaaStudents,
    String? selectedReportStatus,
    String? searchUserQuery,
    String? searchPhenikaaStudentQuery,
    String? selectedFaculty,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      reports: reports ?? this.reports,
      users: users ?? this.users,
      documents: documents ?? this.documents,
      auditLogs: auditLogs ?? this.auditLogs,
      phenikaaStudents: phenikaaStudents ?? this.phenikaaStudents,
      selectedReportStatus: selectedReportStatus ?? this.selectedReportStatus,
      searchUserQuery: searchUserQuery ?? this.searchUserQuery,
      searchPhenikaaStudentQuery:
          searchPhenikaaStudentQuery ?? this.searchPhenikaaStudentQuery,
      selectedFaculty: selectedFaculty ?? this.selectedFaculty,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    stats,
    reports,
    users,
    documents,
    auditLogs,
    phenikaaStudents,
    selectedReportStatus,
    searchUserQuery,
    searchPhenikaaStudentQuery,
    selectedFaculty,
    errorMessage,
    successMessage,
  ];
}
