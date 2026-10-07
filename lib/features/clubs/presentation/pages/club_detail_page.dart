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

  const ClubDetailPage({
    super.key,
    required this.club,
  });

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Học thuật':
        return AppTheme.primaryColor(context);
      case 'Nghệ thuật':
        return AppTheme.accentColor(context);
      case 'Thể thao':
        return AppTheme.coralColor(context);
      case 'Tình nguyện':
        return AppTheme.mintColor(context);
      default:
        return AppTheme.violetColor(context);
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
    final currentUserId = authState is Authenticated ? authState.user.uid : '';

    return BlocConsumer<ClubCubit, ClubState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // Find latest updated club instance from state if available
        final currentClub = state.clubs.firstWhere(
          (c) => c.id == club.id,
          orElse: () => club,
        );
        final isJoined = currentClub.isMember(currentUserId);

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
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    ),
                    tooltip: 'Chia sẻ CLB',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${currentClub.name} - CLB sinh viên Phenikaa University!',
                      ));
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
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: isDark ? 0.8 : 0.9),
                          Color(currentClub.colorValue).withValues(alpha: 0.7),
                          const Color(0xFF0C4A6E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getCategoryIcon(currentClub.category), color: Colors.white, size: 14),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_alt_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${currentClub.effectiveMembersCount} thành viên',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentClub.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.school_outlined, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  'Đại học Phenikaa • Chủ nhiệm: ${currentClub.leaderName}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isJoined
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isJoined ? const Color(0xFF10B981) : color)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isJoined ? Icons.verified_user_rounded : Icons.group_add_rounded,
                                color: isJoined ? const Color(0xFF10B981) : color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isJoined ? 'Bạn là thành viên chính thức' : 'Chưa tham gia câu lạc bộ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: isJoined ? const Color(0xFF10B981) : colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isJoined
                                        ? 'Nhận đầy đủ thông báo sinh hoạt & tích lũy ĐRL'
                                        : 'Gia nhập để kết nối bạn bè cùng đam mê',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                      _buildSectionTitle(context, Icons.info_outline_rounded, l10n.club_overview),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          currentClub.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Schedule & Location
                      _buildSectionTitle(context, Icons.calendar_month_rounded, 'Lịch sinh hoạt & Địa điểm'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
                              iconColor: AppTheme.coralColor(context),
                              title: 'Địa điểm tổ chức',
                              subtitle: currentClub.location,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Benefits
                      _buildSectionTitle(context, Icons.stars_rounded, 'Quyền lợi thành viên'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: currentClub.benefits.map((benefit) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: colorScheme.onSurface.withValues(alpha: 0.8),
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
                      _buildSectionTitle(context, Icons.support_agent_rounded, 'Ban Chủ Nhiệm & Liên hệ'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
                                iconColor: const Color(0xFF0284C7),
                                title: 'Email liên hệ',
                                subtitle: currentClub.contactEmail,
                              ),
                            ],
                            if (currentClub.contactPhone.isNotEmpty) ...[
                              const Divider(height: 20),
                              _buildInfoTile(
                                context,
                                icon: Icons.phone_rounded,
                                iconColor: const Color(0xFF10B981),
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
                child: isJoined
                    ? OutlinedButton.icon(
                        onPressed: () {
                          _showLeaveConfirmDialog(context, currentClub, currentUserId);
                        },
                        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
                        label: Text(
                          l10n.leave_club,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          context.read<ClubCubit>().toggleJoinClub(
                                club: currentClub,
                                userId: currentUserId,
                              );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLeaveConfirmDialog(BuildContext context, ClubEntity club, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Rời Câu Lạc Bộ'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi "${club.name}" không? Bạn có thể tham gia lại bất kỳ lúc nào.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ở lại', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ClubCubit>().toggleJoinClub(
                    club: club,
                    userId: userId,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rời CLB'),
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
