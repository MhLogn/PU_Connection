import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/event_repository.dart';
import '../../domain/entities/event_entity.dart';
import '../widgets/event_ticket_dialog.dart';

class EventDetailPage extends StatefulWidget {
  final EventEntity event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late EventEntity _currentEvent;
  final EventRepository _repository = EventRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  Color _getColor(String type) {
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

  Future<void> _toggleRegistration(String studentId, String studentName, String faculty) async {
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập với mã sinh viên để đăng ký!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final isRegistered = _currentEvent.isRegistered(studentId);

    try {
      if (isRegistered) {
        await _repository.unregisterFromEvent(
          eventId: _currentEvent.id,
          studentId: studentId,
        );
        setState(() {
          final updated = List<String>.from(_currentEvent.registeredStudentIds)..remove(studentId);
          _currentEvent = _currentEvent.copyWith(registeredStudentIds: updated);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đăng ký sự kiện.')),
          );
        }
      } else {
        if (_currentEvent.isFull) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sự kiện đã đủ số lượng người đăng ký!')),
          );
          return;
        }

        await _repository.registerForEvent(
          eventId: _currentEvent.id,
          studentId: studentId,
        );
        setState(() {
          final updated = List<String>.from(_currentEvent.registeredStudentIds)..add(studentId);
          _currentEvent = _currentEvent.copyWith(registeredStudentIds: updated);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vé điện tử đã sẵn sàng.'),
              backgroundColor: Colors.green,
            ),
          );
          // Auto open ticket
          EventTicketDialog.show(
            context,
            event: _currentEvent,
            studentName: studentName,
            studentId: studentId,
            faculty: faculty,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = AppTheme.isDark(context);
    final color = _getColor(_currentEvent.colorType);
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy • HH:mm', 'vi');

    final authState = context.watch<AuthCubit>().state;
    final studentId = authState is Authenticated ? authState.user.studentId : '';
    final studentName = authState is Authenticated ? authState.user.displayName : '';
    final faculty = authState is Authenticated ? authState.user.faculty : '';

    final isRegistered = _currentEvent.isRegistered(studentId);
    final percent = (_currentEvent.currentParticipants / _currentEvent.maxParticipants).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Chi tiết sự kiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Chia sẻ',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${_currentEvent.title} - Địa điểm: ${_currentEvent.location}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép link sự kiện!')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              if (isRegistered) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => EventTicketDialog.show(
                              context,
                              event: _currentEvent,
                              studentName: studentName,
                              studentId: studentId,
                              faculty: faculty,
                            ),
                    icon: const Icon(Icons.qr_code_rounded, size: 20),
                    label: const Text('Xem Vé QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor(context),
                      side: BorderSide(color: AppTheme.primaryColor(context)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isLoading ? null : () => _toggleRegistration(studentId, studentName, faculty),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                  tooltip: 'Hủy đăng ký',
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _currentEvent.isFull
                        ? null
                        : () => _toggleRegistration(studentId, studentName, faculty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor(context),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentEvent.isFull ? 'Đã hết chỗ' : 'Đăng Ký Tham Gia',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: isDark ? 0.4 : 0.85),
                    color.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentEvent.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(_currentEvent.icon, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentEvent.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _currentEvent.organizer,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Info Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Registration progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng sinh viên tham gia',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${_currentEvent.currentParticipants}/${_currentEvent.maxParticipants}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people_alt_outlined, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Còn ${_currentEvent.spotsRemaining} suất đăng ký',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const Spacer(),
                            if (isRegistered)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Bạn đã đăng ký',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Event Schedule & Location
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.calendar_today_rounded,
                          color: AppTheme.primaryColor(context),
                          title: 'Thời gian bắt đầu',
                          subtitle: dateFormat.format(_currentEvent.startDate),
                        ),
                        const Divider(height: 20),
                        _buildInfoTile(
                          context,
                          icon: Icons.location_on_rounded,
                          color: AppTheme.coralColor(context),
                          title: 'Địa điểm tổ chức',
                          subtitle: _currentEvent.location,
                        ),
                        const Divider(height: 20),
                        _buildInfoTile(
                          context,
                          icon: Icons.stars_rounded,
                          color: AppTheme.accentColor(context),
                          title: 'Quyền lợi sinh viên',
                          subtitle: 'Cộng điểm rèn luyện (ĐRL) & cấp giấy chứng nhận tham gia sự kiện',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Mô tả chi tiết sự kiện',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentEvent.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mọi thắc mắc về sự kiện xin vui lòng liên hệ Ban Tổ Chức tại Văn phòng Đoàn Thanh niên Tòa A9.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.primaryColor(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 18),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
