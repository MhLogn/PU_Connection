import 'package:equatable/equatable.dart';

class AdminDashboardStats extends Equatable {
  final int totalStudents;
  final int totalPosts;
  final int totalDocuments;
  final int pendingReports;
  final int bannedUsersCount;
  final Map<String, int> facultyDistribution;

  const AdminDashboardStats({
    this.totalStudents = 0,
    this.totalPosts = 0,
    this.totalDocuments = 0,
    this.pendingReports = 0,
    this.bannedUsersCount = 0,
    this.facultyDistribution = const {},
  });

  AdminDashboardStats copyWith({
    int? totalStudents,
    int? totalPosts,
    int? totalDocuments,
    int? pendingReports,
    int? bannedUsersCount,
    Map<String, int>? facultyDistribution,
  }) {
    return AdminDashboardStats(
      totalStudents: totalStudents ?? this.totalStudents,
      totalPosts: totalPosts ?? this.totalPosts,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      pendingReports: pendingReports ?? this.pendingReports,
      bannedUsersCount: bannedUsersCount ?? this.bannedUsersCount,
      facultyDistribution: facultyDistribution ?? this.facultyDistribution,
    );
  }

  @override
  List<Object?> get props => [
    totalStudents,
    totalPosts,
    totalDocuments,
    pendingReports,
    bannedUsersCount,
    facultyDistribution,
  ];
}
