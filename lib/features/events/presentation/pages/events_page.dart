import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/event_repository.dart';
import '../../domain/entities/event_entity.dart';
import 'event_detail_page.dart';
import '../widgets/event_ticket_dialog.dart';

class EventsPage extends StatefulWidget {
  final String? initialCategory;

  const EventsPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventRepository _repository = EventRepository();
  late String _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Tất cả',
    'Học thuật',
    'Thể thao',
    'Văn nghệ',
    'Tình nguyện',
    'Hội thảo',
    'Đã đăng ký',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Tất cả';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Tất cả';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColor(BuildContext context, String type) {
    switch (type) {
      case 'orange':
        return AppTheme.accentColor(context);
      case 'mint':
        return AppTheme.mintColor(context);
      case 'violet':
        return AppTheme.violetColor(context);
      case 'coral':
        return AppTheme.coralColor(context);
      case 'blue':
      default:
        return AppTheme.primaryColor(context);
    }
  }

  String _getCategoryLabel(BuildContext context, String cat) {
    final l10n = AppLocalizations.of(context)!;
    switch (cat) {
      case 'Tất cả':
        return l10n.all_filter;
      case 'Học thuật':
        return l10n.academic_clubs;
      case 'Thể thao':
        return l10n.sports_clubs;
      case 'Văn nghệ':
        return l10n.arts_clubs;
      case 'Tình nguyện':
        return l10n.volunteer_clubs;
      case 'Đã đăng ký':
        return l10n.registered_events;
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = context.watch<AuthCubit>().state;
    final currentStudentId = authState is Authenticated ? authState.user.studentId : '';
    final currentStudentName = authState is Authenticated ? authState.user.displayName : '';
    final currentFaculty = authState is Authenticated ? authState.user.faculty : '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.event_list_title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppTheme.borderLight,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Tìm sự kiện, workshop, giải đấu...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    icon: Icon(Icons.search_rounded, size: 18, color: AppTheme.oceanBlue),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.oceanGradient : null,
                      color: isSelected ? null : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.oceanBlue.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryLabel(context, cat),
                        style: TextStyle(
                          color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Events Stream List
          Expanded(
            child: StreamBuilder<List<EventEntity>>(
              stream: _repository.streamEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEvents = snapshot.data ?? EventRepository.defaultEvents;
                final query = _searchController.text.trim().toLowerCase();

                final filteredEvents = allEvents.where((e) {
                  if (_selectedCategory == 'Đã đăng ký') {
                    if (!e.isRegistered(currentStudentId)) return false;
                  } else if (_selectedCategory != 'Tất cả') {
                    if (e.category != _selectedCategory) return false;
                  }

                  if (query.isNotEmpty) {
                    final matchTitle = e.title.toLowerCase().contains(query);
                    final matchDesc = e.description.toLowerCase().contains(query);
                    final matchLoc = e.location.toLowerCase().contains(query);
                    final matchOrg = e.organizer.toLowerCase().contains(query);
                    return matchTitle || matchDesc || matchLoc || matchOrg;
                  }

                  return true;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 56,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedCategory == 'Đã đăng ký'
                                ? 'Bạn chưa đăng ký tham gia sự kiện nào'
                                : 'Không tìm thấy sự kiện phù hợp',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildEventCard(
                      context,
                      event: event,
                      currentStudentId: currentStudentId,
                      currentStudentName: currentStudentName,
                      currentFaculty: currentFaculty,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required EventEntity event,
    required String currentStudentId,
    required String currentStudentName,
    required String currentFaculty,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _getColor(context, event.colorType);
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');
    final isRegistered = event.isRegistered(currentStudentId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(event: event),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRegistered
                ? Colors.green.withValues(alpha: 0.5)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : AppTheme.borderLight),
            width: isRegistered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0284C7).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(event.icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryLabel(context, event.category),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isRegistered)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code_rounded, size: 12, color: Colors.green),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.view_ticket,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 5),
                Text(
                  dateFormat.format(event.startDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_outlined, size: 14, color: AppTheme.oceanBlue),
                    const SizedBox(width: 4),
                    Text(
                      '${event.currentParticipants}/${event.maxParticipants} ${l10n.registered.toLowerCase()}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (isRegistered)
                  TextButton.icon(
                    onPressed: () => EventTicketDialog.show(
                      context,
                      event: event,
                      studentName: currentStudentName,
                      studentId: currentStudentId,
                      faculty: currentFaculty,
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: Text(l10n.view_ticket),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor(context),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  )
                else
                  Text(
                    'Chi tiết >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
