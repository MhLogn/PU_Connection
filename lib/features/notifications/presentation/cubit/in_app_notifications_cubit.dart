import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/in_app_notification_repository.dart';
import 'in_app_notifications_state.dart';

class InAppNotificationsCubit extends Cubit<InAppNotificationsState> {
  final InAppNotificationRepository _repository;
  StreamSubscription<List<NotificationEntity>>? _subscription;
  String? _currentUserId;

  InAppNotificationsCubit({
    required InAppNotificationRepository repository,
  })  : _repository = repository,
        super(const InAppNotificationsState());

  String? get currentUserId => _currentUserId;

  void init(String userId) {
    if (userId.isEmpty) return;
    if (_currentUserId == userId && _subscription != null) return;

    _currentUserId = userId;
    _subscription?.cancel();

    emit(state.copyWith(status: NotificationsStatus.loading));

    _subscription = _repository.watchNotifications(userId).listen(
      (notifications) {
        emit(state.copyWith(
          status: NotificationsStatus.loaded,
          notifications: notifications,
        ));
      },
      onError: (err) {
        emit(state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: err.toString(),
        ));
      },
    );
  }

  void setFilter(NotificationType? filter) {
    emit(state.copyWith(selectedFilter: () => filter));
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      await _repository.markAsRead(userId, notificationId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể đánh dấu đã đọc: $e'));
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      await _repository.markAllAsRead(userId);
      emit(state.copyWith(successMessage: 'Đã đánh dấu tất cả là đã đọc'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể cập nhật thông báo: $e'));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      await _repository.deleteNotification(userId, notificationId);
      emit(state.copyWith(successMessage: 'Đã xóa thông báo'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể xóa thông báo: $e'));
    }
  }

  Future<void> sendNotification(NotificationEntity notification) async {
    try {
      await _repository.sendNotification(notification);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể gửi thông báo: $e'));
    }
  }

  void clearMessage() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
