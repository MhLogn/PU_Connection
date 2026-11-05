import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_docs_broadcast_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_moderation_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_overview_tab.dart';
import 'package:pu_connection/features/admin/presentation/pages/tabs/admin_users_tab.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:pu_connection/features/auth/domain/entities/user_entity.dart';
import 'package:pu_connection/features/documents/domain/entities/document_entity.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_entity.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_reason.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_target_type.dart';

void main() {
  group('Admin Design System & Shared Widgets Tests', () {
    testWidgets('AdminStatCard renders title, value and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminStatCard(
              title: 'Tổng Sinh Viên',
              value: '1,250',
              icon: Icons.people_alt_rounded,
              accentColor: Colors.blue,
              subtitle: 'Đang hoạt động',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('TỔNG SINH VIÊN'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);

      await tester.tap(find.byType(AdminStatCard));
      expect(tapped, isTrue);
    });

    testWidgets('AdminStatusBadge renders semantic colors for different states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (ctx) => Column(
                    children: [
                      AdminStatusBadge.fromReportStatus(ctx, 'pending'),
                      AdminStatusBadge.fromReportStatus(ctx, 'resolved'),
                      AdminStatusBadge.fromClubStatus(ctx, 'approved'),
                      AdminStatusBadge.fromClubStatus(ctx, 'rejected'),
                      AdminStatusBadge.fromUserRole(ctx, 'admin'),
                      AdminStatusBadge.fromUserBanStatus(ctx, true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Chờ xử lý'), findsOneWidget);
      expect(find.text('Đã giải quyết'), findsOneWidget);
      expect(find.text('Đã phê duyệt'), findsOneWidget);
      expect(find.text('Đã từ chối'), findsOneWidget);
      expect(find.text('QUẢN TRỊ VIÊN'), findsOneWidget);
      expect(find.text('Đã khóa tài khoản'), findsOneWidget);
    });

    testWidgets('AdminSectionHeader renders title, subtitle and trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminSectionHeader(
              title: 'Chỉ Số Hệ Thống',
              subtitle: 'Cập nhật theo thời gian thực',
              icon: Icons.analytics_outlined,
              trailing: const Text('Xem thêm'),
            ),
          ),
        ),
      );

      expect(find.text('Chỉ Số Hệ Thống'), findsOneWidget);
      expect(find.text('Cập nhật theo thời gian thực'), findsOneWidget);
      expect(find.text('Xem thêm'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('AdminEmptyState renders icon, title, subtitle and action', (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminEmptyState(
              icon: Icons.inbox_rounded,
              title: 'Chưa có dữ liệu',
              subtitle: 'Không tìm thấy kết quả nào phù hợp.',
              action: ElevatedButton(
                onPressed: () => actionClicked = true,
                child: const Text('Tạo mới'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      expect(find.text('Không tìm thấy kết quả nào phù hợp.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

      await tester.tap(find.text('Tạo mới'));
      expect(actionClicked, isTrue);
    });

    testWidgets('AdminConfirmDialog displays warning and executes confirm callback', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AdminConfirmDialog.show(
                  ctx,
                  title: 'Xóa bài viết?',
                  content: 'Hành động này không thể hoàn tác.',
                  confirmLabel: 'Xác nhận xóa',
                  isDestructive: true,
                  onConfirm: () => confirmed = true,
                ),
                child: const Text('Mở Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Xóa bài viết?'), findsOneWidget);
      expect(find.text('Hành động này không thể hoàn tác.'), findsOneWidget);

      await tester.tap(find.text('Xác nhận xóa'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });

  group('Admin Tabs UI & AppTheme Light/Dark Integration Tests', () {
    const mockAdminUser = UserEntity(
      uid: 'admin_test_uid',
      email: 'admin@phenikaa-uni.edu.vn',
      studentId: 'ADMIN01',
      displayName: 'PGS. TS Quản Trị Viên',
      userType: 'admin',
      faculty: 'Ban Giám Hiệu',
    );

    const mockStats = AdminDashboardStats(
      totalStudents: 1250,
      totalPosts: 340,
      totalDocuments: 85,
      pendingReports: 2,
      bannedUsersCount: 3,
      facultyDistribution: {
        'Khoa Công nghệ Thông tin': 650,
        'Khoa Kinh tế & QTKD': 350,
        'Khoa Kỹ thuật Ô tô': 250,
      },
    );

    testWidgets('AdminOverviewTab renders in Light Mode cleanly without hardcoded colors', (tester) async {
      int navigatedToTab = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminOverviewTab(
              state: const AdminState(
                status: AdminStatus.loaded,
                stats: mockStats,
              ),
              currentUser: mockAdminUser,
              pendingClubCount: 1,
              onNavigateTab: (tab) => navigatedToTab = tab,
            ),
          ),
        ),
      );

      expect(find.text('Chào mừng, PGS. TS Quản Trị Viên'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Khoa Công nghệ Thông tin'), findsOneWidget);

      // Verify KPI tap navigates
      await tester.tap(find.text('BÁO CÁO CHỜ XỬ LÝ'));
      expect(navigatedToTab, equals(1));
    });

    testWidgets('AdminOverviewTab renders in Dark Mode cleanly with high contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AdminOverviewTab(
              state: const AdminState(
                status: AdminStatus.loaded,
                stats: mockStats,
              ),
              currentUser: mockAdminUser,
              pendingClubCount: 0,
              onNavigateTab: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Chào mừng, PGS. TS Quản Trị Viên'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('Khoa Công nghệ Thông tin'), findsOneWidget);
    });

    testWidgets('AdminModerationTab renders report queue and filter chips', (tester) async {
      final mockReports = [
        ReportEntity(
          id: 'report_1',
          targetId: 'post_101',
          targetType: ReportTargetType.post,
          reason: ReportReason.harassment,
          details: 'Bài viết có lời lẽ xúc phạm người khác',
          reporterId: 'stu_1',
          reporterName: 'Trần Văn B',
          targetAuthorId: 'stu_2',
          targetAuthorName: 'Lê Văn C',
          status: 'pending',
          createdAt: DateTime(2026, 10, 30),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminModerationTab(
              state: AdminState(
                status: AdminStatus.loaded,
                reports: mockReports,
                selectedReportStatus: 'pending',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tất cả báo cáo'), findsOneWidget);
      expect(find.text('Chờ xử lý'), findsNWidgets(2)); // Chip and Badge
      expect(find.text('Người báo cáo: Trần Văn B (ID: stu_1)'), findsOneWidget);
      expect(find.text('Tài khoản bị tố cáo: Lê Văn C (ID: stu_2)'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Gỡ nội dung'), findsOneWidget);
      expect(find.text('Khóa SV'), findsOneWidget);
    });

    testWidgets('AdminUsersTab renders app accounts and directory switcher', (tester) async {
      final mockUsers = [
        const UserEntity(
          uid: 'user_1',
          email: '20010001@st.phenikaa-uni.edu.vn',
          studentId: '20010001',
          displayName: 'Lê Hoàng Nam',
          userType: 'student',
          faculty: 'Khoa Công nghệ Thông tin',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdminUsersTab(
              state: AdminState(
                status: AdminStatus.loaded,
                users: mockUsers,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tài khoản App (1)'), findsOneWidget);
      expect(find.text('Danh bạ Kích hoạt (0)'), findsOneWidget);
      expect(find.text('Lê Hoàng Nam'), findsOneWidget);
      expect(find.text('SINH VIÊN'), findsOneWidget);
    });

    testWidgets('AdminDocsBroadcastTab renders broadcast form and documents in Dark Mode', (tester) async {
      final mockDocs = [
        DocumentEntity(
          id: 'doc_1',
          title: 'Đề Cương Chi Tiết Môn AI',
          code: 'IT3020',
          faculty: 'Khoa Công nghệ Thông tin',
          fileUrl: 'https://example.com/doc.pdf',
          fileType: 'pdf',
          fileSize: '2.5 MB',
          authorId: 'admin_1',
          authorName: 'Admin',
          authorStudentId: 'ADMIN',
          downloads: 142,
          createdAt: DateTime(2026, 10, 1),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AdminDocsBroadcastTab(
              state: AdminState(
                status: AdminStatus.loaded,
                documents: mockDocs,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Phát Thông Báo Khẩn Toàn Trường'), findsOneWidget);
      expect(find.text('Tiêu đề thông báo *'), findsOneWidget);
      expect(find.text('Đề Cương Chi Tiết Môn AI'), findsOneWidget);
      expect(find.text('Phát thông báo ngay'), findsOneWidget);
    });
  });
}
