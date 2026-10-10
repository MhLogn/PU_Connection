import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/blocked_user_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/moderation_repository.dart';
import 'moderation_state.dart';

class ModerationCubit extends Cubit<ModerationState> {
  final ModerationRepository _moderationRepository;
  StreamSubscription<List<BlockedUserEntity>>? _blockedSub;

  ModerationCubit({required ModerationRepository moderationRepository})
      : _moderationRepository = moderationRepository,
        super(const ModerationState());

  void init(String currentUserId) {
    _blockedSub?.cancel();
    if (currentUserId.isEmpty) return;

    _blockedSub = _moderationRepository
        .getBlockedUsersStream(currentUserId)
        .listen((list) {
      final ids = list.map((u) => u.userId).toSet();
      emit(state.copyWith(
        blockedUsers: list,
        blockedUserIds: ids,
      ));
    });
  }

  Future<void> submitReport(ReportEntity report) async {
    emit(state.copyWith(status: ModerationActionStatus.loading));
    try {
      await _moderationRepository.submitReport(report);

      final newHidden = Set<String>.from(state.hiddenPostIds);
      if (report.targetType.name == 'post') {
        newHidden.add(report.targetId);
      }

      emit(state.copyWith(
        status: ModerationActionStatus.success,
        hiddenPostIds: newHidden,
        message: 'Cảm ơn bạn đã báo cáo. Ban quản trị PU Connection sẽ xem xét xử lý trong thời gian sớm nhất!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ModerationActionStatus.failure,
        message: 'Không thể gửi báo cáo: $e',
      ));
    }
  }

  Future<void> blockUser({
    required String currentUserId,
    required BlockedUserEntity blockedUser,
  }) async {
    emit(state.copyWith(status: ModerationActionStatus.loading));
    try {
      await _moderationRepository.blockUser(
        currentUserId: currentUserId,
        blockedUser: blockedUser,
      );

      final newIds = Set<String>.from(state.blockedUserIds)..add(blockedUser.userId);
      emit(state.copyWith(
        status: ModerationActionStatus.success,
        blockedUserIds: newIds,
        message: 'Đã chặn người dùng ${blockedUser.userName}. Bạn sẽ không còn nhìn thấy nội dung từ người này.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ModerationActionStatus.failure,
        message: 'Lỗi khi chặn người dùng: $e',
      ));
    }
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    emit(state.copyWith(status: ModerationActionStatus.loading));
    try {
      await _moderationRepository.unblockUser(
        currentUserId: currentUserId,
        blockedUserId: blockedUserId,
      );

      final newIds = Set<String>.from(state.blockedUserIds)..remove(blockedUserId);
      emit(state.copyWith(
        status: ModerationActionStatus.success,
        blockedUserIds: newIds,
        message: 'Đã bỏ chặn người dùng.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ModerationActionStatus.failure,
        message: 'Lỗi khi bỏ chặn: $e',
      ));
    }
  }

  void hidePostOptimistically(String postId) {
    final updated = Set<String>.from(state.hiddenPostIds)..add(postId);
    emit(state.copyWith(hiddenPostIds: updated));
  }

  void clearMessage() {
    emit(state.copyWith(status: ModerationActionStatus.initial, message: null));
  }

  @override
  Future<void> close() {
    _blockedSub?.cancel();
    return super.close();
  }
}
