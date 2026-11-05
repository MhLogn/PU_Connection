import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pu_connection/core/theme/app_theme.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_cubit.dart';
import 'package:pu_connection/features/admin/presentation/cubit/admin_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_search_field.dart';
import 'package:pu_connection/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:pu_connection/features/auth/domain/entities/phenikaa_student_entity.dart';
import 'package:pu_connection/features/auth/domain/entities/user_entity.dart';

/// Tab 2: Quản lý danh sách người dùng & Danh bạ sinh viên Phenikaa
class AdminUsersTab extends StatefulWidget {
  final AdminState state;

  const AdminUsersTab({
    super.key,
    required this.state,
  });

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  int _subTabIndex = 0; // 0: Tài khoản app, 1: Danh bạ kích hoạt
  final _searchUserCtrl = TextEditingController();
  final _searchPhenikaaCtrl = TextEditingController();

  @override
  void dispose() {
    _searchUserCtrl.dispose();
    _searchPhenikaaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final users = widget.state.users;
    final phenikaaStudents = widget.state.phenikaaStudents;

    return Column(
      children: [
        // Sub-tabs: Tài khoản app vs Danh bạ sinh viên Phenikaa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : AppTheme.borderLight,
                width: 0.8,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                  label: Text('Tài khoản App (${users.length})'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: const Icon(Icons.badge_rounded, size: 18),
                  label: Text('Danh bạ Kích hoạt (${phenikaaStudents.length})'),
                ),
              ],
              selected: {_subTabIndex},
              onSelectionChanged: (set) {
                setState(() => _subTabIndex = set.first);
              },
            ),
          ),
        ),

        // Sub-view 0: Tài khoản ứng dụng
        if (_subTabIndex == 0) ...[
          Expanded(
            child: _buildAppUsersView(context, users, isDark, colorScheme),
          ),
        ] else ...[
          // Sub-view 1: Danh bạ kích hoạt Phenikaa
          Expanded(
            child: _buildPhenikaaDirectoryView(
              context,
              phenikaaStudents,
              isDark,
              colorScheme,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppUsersView(
    BuildContext context,
    List<UserEntity> users,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: AdminSearchField(
            controller: _searchUserCtrl,
            hintText: 'Tìm theo MSSV, Họ tên hoặc Email...',
            onChanged: (val) => context.read<AdminCubit>().searchUsers(val),
            onClear: () => context.read<AdminCubit>().searchUsers(''),
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? AdminEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Không tìm thấy tài khoản người dùng',
                  subtitle: 'Thử kiểm tra lại từ khóa tìm kiếm hoặc lọc theo điều kiện khác.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, idx) {
                    final u = users[idx];
                    return _buildAppUserCard(context, u, isDark, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppUserCard(
    BuildContext context,
    UserEntity u,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: u.isBanned
              ? AppTheme.coralColor(context).withValues(alpha: 0.3)
              : (isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : AppTheme.borderLight),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: u.isBanned
                ? (isDark ? const Color(0xFF475569) : Colors.grey.shade400)
                : AppTheme.primaryColor(context),
            backgroundImage: u.avatarUrl.isNotEmpty
                ? AppTheme.imageProvider(u.avatarUrl)
                : null,
            child: u.avatarUrl.isEmpty
                ? Text(
                    u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        u.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: u.isBanned ? TextDecoration.lineThrough : null,
                          color: u.isBanned
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusBadge.fromUserRole(context, u.userType),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'MSSV: ${u.studentId.isNotEmpty ? u.studentId : 'N/A'} • ${u.faculty.isNotEmpty ? u.faculty : 'Chưa phân khoa'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (u.isBanned) ...[
                  const SizedBox(height: 4),
                  AdminStatusBadge.fromUserBanStatus(context, true),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'ban') {
                context.read<AdminCubit>().toggleBanUser(
                  u.uid,
                  isBanned: !u.isBanned,
                );
              } else if (val == 'role_mod') {
                context.read<AdminCubit>().changeUserRole(
                  u.uid,
                  newRole: 'moderator',
                );
              } else if (val == 'role_admin') {
                context.read<AdminCubit>().changeUserRole(
                  u.uid,
                  newRole: 'admin',
                );
              } else if (val == 'role_student') {
                context.read<AdminCubit>().changeUserRole(
                  u.uid,
                  newRole: 'student',
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(
                      u.isBanned ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      size: 18,
                      color: u.isBanned
                          ? AppTheme.mintColor(context)
                          : AppTheme.coralColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      u.isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản (Ban)',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'role_student',
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Đặt làm: Sinh viên (Student)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'role_mod',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Đặt làm: Kiểm duyệt viên (Mod)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'role_admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Đặt làm: Quản trị viên (Admin)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhenikaaDirectoryView(
    BuildContext context,
    List<PhenikaaStudentEntity> phenikaaStudents,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: AdminSearchField(
                  controller: _searchPhenikaaCtrl,
                  hintText: 'Tìm theo MSSV, Họ tên hoặc Email...',
                  onChanged: (val) =>
                      context.read<AdminCubit>().searchPhenikaaStudents(val),
                  onClear: () =>
                      context.read<AdminCubit>().searchPhenikaaStudents(''),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Thêm SV'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: phenikaaStudents.isEmpty
              ? AdminEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'Chưa có sinh viên nào trong danh bạ',
                  subtitle: 'Bấm "+ Thêm SV" để thêm sinh viên tiền thẩm định kích hoạt.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddStudentDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm sinh viên mới'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(context),
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: phenikaaStudents.length,
                  itemBuilder: (context, idx) {
                    final s = phenikaaStudents[idx];
                    return _buildPhenikaaStudentCard(
                      context,
                      s,
                      isDark,
                      colorScheme,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhenikaaStudentCard(
    BuildContext context,
    PhenikaaStudentEntity s,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : AppTheme.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: s.isActivated
                ? AppTheme.mintColor(context)
                : AppTheme.primaryColor(context),
            child: Text(
              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (s.cohort > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'K${s.cohort}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor(context),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'MSSV: ${s.studentId} • ${s.email}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.faculty}${s.major.isNotEmpty ? " • ${s.major}" : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AdminStatusBadge.fromActivationStatus(context, s.isActivated),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => AdminConfirmDialog.show(
                  context,
                  title: 'Xóa sinh viên khỏi danh bạ?',
                  content:
                      'Bạn có chắc chắn muốn xóa sinh viên ${s.fullName} (${s.studentId}) khỏi danh bạ tiền thẩm định Phenikaa?',
                  confirmLabel: 'Xác nhận xóa',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                  onConfirm: () =>
                      context.read<AdminCubit>().deletePhenikaaStudent(s.studentId),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppTheme.coralColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final facultyCtrl = TextEditingController();
    final majorCtrl = TextEditingController();
    final cohortCtrl = TextEditingController(text: '17');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(ctx).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: AppTheme.primaryColor(ctx),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Thêm Sinh Viên Danh Bạ',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên sinh viên *',
                      hintText: 'VD: Nguyễn Văn A',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập họ tên' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: studentIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã số sinh viên (MSSV) *',
                      hintText: 'VD: 20010001',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập MSSV' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email sinh viên Phenikaa *',
                      hintText: 'VD: 20010001@st.phenikaa-uni.edu.vn',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập Email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: facultyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Khoa / Viện đào tạo',
                      hintText: 'VD: Khoa Công nghệ Thông tin',
                      prefixIcon: Icon(Icons.domain_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: majorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Chuyên ngành',
                            hintText: 'VD: Kỹ thuật Phần mềm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: cohortCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Khóa',
                            hintText: '17',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(ctx),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newStudent = PhenikaaStudentEntity(
                    studentId: studentIdCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().toLowerCase(),
                    faculty: facultyCtrl.text.trim().isNotEmpty
                        ? facultyCtrl.text.trim()
                        : 'Khoa Công nghệ Thông tin',
                    major: majorCtrl.text.trim(),
                    cohort: int.tryParse(cohortCtrl.text.trim()) ?? 17,
                    isActivated: false,
                  );
                  Navigator.pop(ctx);
                  await context.read<AdminCubit>().addPhenikaaStudent(newStudent);
                }
              },
              child: const Text('Lưu vào danh bạ'),
            ),
          ],
        );
      },
    );
  }
}
