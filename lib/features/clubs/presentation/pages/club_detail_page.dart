import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/club_entity.dart';
import '../cubit/club_cubit.dart';
import '../cubit/club_state.dart';

class ClubDetailPage extends StatelessWidget {
  final ClubEntity club;

  const ClubDetailPage({super.key, required this.club});

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Học thuật':
      case 'Tình nguyện':
        return AppTheme.primaryColor(context);
      case 'Nghệ thuật':
      case 'Thể thao':
      default:
        return AppTheme.accentColor(context);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Học thuật':
        return Icons.psychology_rounded;
      case 'Nghệ thuật':
        return Icons.music_note_rounded;
      case 'Thể thao':
        return Icons.sports_basketball_rounded;
      case 'Tình nguyện':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _getCategoryColor(context, club.category);

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final currentUserId = currentUser?.uid ?? '';
    final currentStudentId = currentUser?.studentId ?? '';
    final isAdmin = currentUser?.isAdmin == true;

    return BlocConsumer<ClubCubit, ClubState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppTheme.primaryColor(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        // Find latest updated club instance from state if available
        final matchingClubs = state.clubs.where((c) => c.id == club.id);
        final currentClub = matchingClubs.isNotEmpty
            ? matchingClubs.first
            : club;
        final isJoined = currentClub.isMember(currentUserId, currentStudentId);
        final isLeader = currentClub.leaderId.isNotEmpty &&
            currentClub.leaderId == currentUserId;
        final canManage = isLeader || isAdmin;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: CustomScrollView(
            slivers: [
              // Custom Silver App Bar with Gradient Banner
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (canManage) ...[
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      tooltip: 'Chỉnh sửa thông tin CLB',
                      onPressed: () =>
                          _showEditClubBottomSheet(context, currentClub),
                    ),
                  ],
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Chia sẻ CLB',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${currentClub.name} - CLB sinh viên Phenikaa University!',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép liên kết giới thiệu CLB!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : AppTheme.deepBlue,
                      image: currentClub.coverUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(currentClub.coverUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.55),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(currentClub.category),
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentClub.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showMembersBottomSheet(
                                      context,
                                      currentClub,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.people_alt_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${currentClub.effectiveMembersCount} thành viên',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (currentClub.avatarUrl.isNotEmpty) ...[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(currentClub.avatarUrl),
                                    backgroundColor: Colors.white24,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    currentClub.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Đại học Phenikaa • ${l10n.club_president_label(currentClub.leaderName)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Join / Joined Hero Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isJoined
                                ? AppTheme.accentColor(
                                    context,
                                  ).withValues(alpha: 0.6)
                                : (isDark
                                      ? Colors.white10
                                      : AppTheme.borderLight),
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06123B63),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    (isJoined
                                            ? AppTheme.accentColor(context)
                                            : color)
                                        .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isJoined
                                    ? Icons.verified_user_rounded
                                    : Icons.group_add_rounded,
                                color: isJoined
                                    ? AppTheme.accentColor(context)
                                    : color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isJoined
                                        ? 'Bạn là thành viên chính thức'
                                        : 'Chưa tham gia câu lạc bộ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: isJoined
                                          ? AppTheme.accentColor(context)
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isJoined
                                        ? 'Nhận đầy đủ thông báo sinh hoạt & tích lũy ĐRL'
                                        : 'Gia nhập để kết nối bạn bè cùng đam mê',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Overview
                      _buildSectionTitle(
                        context,
                        Icons.info_outline_rounded,
                        l10n.club_overview,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : AppTheme.borderLight,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06123B63),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          currentClub.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Schedule & Location
                      _buildSectionTitle(
                        context,
                        Icons.calendar_month_rounded,
                        'Lịch sinh hoạt & Địa điểm',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : AppTheme.borderLight,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06123B63),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              context,
                              icon: Icons.access_time_filled_rounded,
                              iconColor: AppTheme.primaryColor(context),
                              title: 'Thời gian sinh hoạt',
                              subtitle: currentClub.schedule,
                            ),
                            const Divider(height: 20),
                            _buildInfoTile(
                              context,
                              icon: Icons.location_on_rounded,
                              iconColor: AppTheme.accentColor(context),
                              title: 'Địa điểm tổ chức',
                              subtitle: currentClub.location,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Benefits
                      _buildSectionTitle(
                        context,
                        Icons.stars_rounded,
                        'Quyền lợi thành viên',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : AppTheme.borderLight,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06123B63),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: currentClub.benefits.map((benefit) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.accentColor(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 4: Contact & Leader
                      _buildSectionTitle(
                        context,
                        Icons.support_agent_rounded,
                        'Ban Chủ Nhiệm & Liên hệ',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : AppTheme.borderLight,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06123B63),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              context,
                              icon: Icons.person_rounded,
                              iconColor: AppTheme.accentColor(context),
                              title: 'Chủ nhiệm câu lạc bộ',
                              subtitle: currentClub.leaderName,
                            ),
                            if (currentClub.contactEmail.isNotEmpty) ...[
                              const Divider(height: 20),
                              _buildInfoTile(
                                context,
                                icon: Icons.email_rounded,
                                iconColor: AppTheme.primaryColor(context),
                                title: 'Email liên hệ',
                                subtitle: currentClub.contactEmail,
                              ),
                            ],
                            if (currentClub.contactPhone.isNotEmpty) ...[
                              const Divider(height: 20),
                              _buildInfoTile(
                                context,
                                icon: Icons.phone_rounded,
                                iconColor: AppTheme.accentColor(context),
                                title: 'Số điện thoại hỗ trợ',
                                subtitle: currentClub.contactPhone,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: isLeader
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: AppTheme.primaryColor(context),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.club_president_badge,
                              style: TextStyle(
                                color: AppTheme.primaryColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isJoined
                    ? OutlinedButton.icon(
                        onPressed: () {
                          _showLeaveConfirmDialog(
                            context,
                            currentClub,
                            currentUserId,
                            currentStudentId,
                          );
                        },
                        icon: const Icon(
                          Icons.exit_to_app_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        label: Text(
                          l10n.leave_club,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          context.read<ClubCubit>().toggleJoinClub(
                            club: currentClub,
                            userId: currentUserId,
                            secondaryId: currentStudentId,
                          );
                        },
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          l10n.join_club,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor(context),
                          foregroundColor: isDark
                              ? Colors.black87
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditClubBottomSheet(BuildContext context, ClubEntity club) {
    final descCtrl = TextEditingController(text: club.description);
    final scheduleCtrl = TextEditingController(text: club.schedule);
    final locationCtrl = TextEditingController(text: club.location);
    final emailCtrl = TextEditingController(text: club.contactEmail);
    final phoneCtrl = TextEditingController(text: club.contactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final isDark = AppTheme.isDark(ctx);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉnh Sửa Thông Tin CLB',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEditField('Mô tả hoạt động', descCtrl, maxLines: 3),
                const SizedBox(height: 12),
                _buildEditField('Lịch sinh hoạt', scheduleCtrl),
                const SizedBox(height: 12),
                _buildEditField('Địa điểm', locationCtrl),
                const SizedBox(height: 12),
                _buildEditField('Email liên hệ', emailCtrl),
                const SizedBox(height: 12),
                _buildEditField('Số điện thoại', phoneCtrl),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = club.copyWith(
                        description: descCtrl.text.trim(),
                        schedule: scheduleCtrl.text.trim(),
                        location: locationCtrl.text.trim(),
                        contactEmail: emailCtrl.text.trim(),
                        contactPhone: phoneCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      context.read<ClubCubit>().updateClub(updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(ctx),
                      foregroundColor: isDark ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(ctx)!.save_changes_btn,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildEditField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showMembersBottomSheet(BuildContext context, ClubEntity club) {
    final authState = context.read<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final currentUserId = currentUser?.uid ?? '';
    final currentStudentId = currentUser?.studentId ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final isDark = AppTheme.isDark(ctx);

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(ctx)!.club_members_sheet_title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${club.name} • ${club.effectiveMembersCount} thành viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Leader Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(
                    ctx,
                  ).withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryColor(
                      ctx,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor(ctx),
                      foregroundColor: Colors.white,
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                club.leaderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor(ctx),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Chủ nhiệm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            club.contactEmail.isNotEmpty
                                ? club.contactEmail
                                : 'Trưởng ban điều hành câu lạc bộ',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thành viên đã tham gia',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: club.memberIds.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có thành viên nào tham gia.',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: club.memberIds.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final memberId = club.memberIds[index];
                          final isCurrent = memberId == currentUserId || (currentStudentId.isNotEmpty && memberId == currentStudentId);
                          final isClubLeader = memberId == club.leaderId;

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              isCurrent
                                  ? '${currentUser?.displayName.isNotEmpty == true ? currentUser!.displayName : "Bạn"} ($memberId)'
                                  : 'Sinh viên Phenikaa ($memberId)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isClubLeader
                                    ? AppTheme.accentColor(ctx).withValues(alpha: 0.15)
                                    : (isCurrent
                                        ? AppTheme.primaryColor(ctx).withValues(alpha: 0.15)
                                        : Colors.green.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isClubLeader
                                    ? 'Chủ nhiệm'
                                    : (isCurrent ? 'Bạn' : 'Thành viên'),
                                style: TextStyle(
                                  color: isClubLeader
                                      ? AppTheme.accentColor(ctx)
                                      : (isCurrent
                                          ? AppTheme.primaryColor(ctx)
                                          : Colors.green),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveConfirmDialog(
    BuildContext context,
    ClubEntity club,
    String userId,
    String secondaryId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(l10n.confirm_leave_club_title),
          ],
        ),
        content: Text(
          l10n.confirm_leave_club_body(club.name),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.stay_in_club_btn,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ClubCubit>().toggleJoinClub(
                club: club,
                userId: userId,
                secondaryId: secondaryId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.leave_club_btn),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
