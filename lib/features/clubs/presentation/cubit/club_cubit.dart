import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/club_entity.dart';
import '../../domain/entities/club_creation_request_entity.dart';
import '../../domain/repositories/club_repository.dart';
import 'club_state.dart';

class ClubCubit extends Cubit<ClubState> {
  final ClubRepository _clubRepository;
  StreamSubscription<List<ClubEntity>>? _clubsSubscription;
  StreamSubscription<List<ClubCreationRequestEntity>>? _myRequestsSubscription;
  StreamSubscription<List<ClubCreationRequestEntity>>? _pendingRequestsSubscription;

  ClubCubit({required ClubRepository clubRepository})
    : _clubRepository = clubRepository,
      super(const ClubState()) {
    initClubsStream();
  }

  void initClubsStream() {
    emit(state.copyWith(status: ClubStatus.loading));
    _clubsSubscription?.cancel();
    _clubsSubscription = _clubRepository.getClubsStream().listen(
      (clubs) {
        emit(state.copyWith(status: ClubStatus.loaded, clubs: clubs));
      },
      onError: (e) {
        emit(
          state.copyWith(status: ClubStatus.error, errorMessage: e.toString()),
        );
      },
    );
  }

  void initMyRequestsStream(String founderId) {
    if (founderId.isEmpty) return;
    _myRequestsSubscription?.cancel();
    _myRequestsSubscription = _clubRepository
        .getClubRequestsStream(founderId: founderId)
        .listen(
      (requests) {
        emit(state.copyWith(myRequests: requests));
      },
      onError: (e) {
        // Log or silently keep existing state
      },
    );
  }

  void initPendingRequestsStream() {
    _pendingRequestsSubscription?.cancel();
    _pendingRequestsSubscription = _clubRepository
        .getClubRequestsStream(status: 'pending')
        .listen(
      (requests) {
        emit(state.copyWith(pendingRequests: requests));
      },
      onError: (e) {
        // Log or silently keep existing state
      },
    );
  }

  void filterCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void searchClubs(String query) {
    emit(state.copyWith(searchQuery: query.trim()));
  }

  Future<void> toggleJoinClub({
    required ClubEntity club,
    required String userId,
    String? secondaryId,
  }) async {
    if (userId.isEmpty && (secondaryId == null || secondaryId.isEmpty)) {
      emit(state.copyWith(errorMessage: 'Vui lòng đăng nhập để tham gia CLB'));
      return;
    }

    final isCurrentlyMember = club.isMember(userId, secondaryId);

    try {
      if (isCurrentlyMember) {
        await _clubRepository.leaveClub(
          clubId: club.id,
          userId: userId,
          secondaryId: secondaryId,
        );
        emit(
          state.copyWith(
            actionSuccessMessage: 'Đã rời câu lạc bộ "${club.name}"',
          ),
        );
      } else {
        await _clubRepository.joinClub(clubId: club.id, userId: userId);
        emit(
          state.copyWith(
            actionSuccessMessage: 'Chào mừng bạn gia nhập "${club.name}"! 🎉',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Thao tác không thành công: $e'));
    }
  }

  Future<bool> submitClubCreationRequest(ClubCreationRequestEntity request) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _clubRepository.submitClubCreationRequest(request);
      emit(
        state.copyWith(
          isSubmitting: false,
          actionSuccessMessage:
              'Đã gửi hồ sơ thành lập "${request.clubName}" tới Ban Quản Trị phê duyệt! 🎉',
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return false;
    }
  }

  Future<bool> reviewClubRequest({
    required String requestId,
    required String action,
    String? rejectionReason,
    required String adminId,
    required String adminName,
  }) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _clubRepository.reviewClubRequest(
        requestId: requestId,
        action: action,
        rejectionReason: rejectionReason,
        adminId: adminId,
        adminName: adminName,
      );
      final actionText = action == 'approve' ? 'phê duyệt' : 'từ chối';
      emit(
        state.copyWith(
          isSubmitting: false,
          actionSuccessMessage: 'Đã $actionText yêu cầu thành lập CLB thành công.',
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return false;
    }
  }

  Future<bool> cancelClubRequest(String requestId) async {
    try {
      await _clubRepository.cancelClubRequest(requestId);
      emit(
        state.copyWith(actionSuccessMessage: 'Đã hủy yêu cầu thành lập CLB.'),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(errorMessage: msg));
      return false;
    }
  }

  Future<bool> updateClub(ClubEntity club) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _clubRepository.updateClub(club);
      emit(
        state.copyWith(
          isSubmitting: false,
          actionSuccessMessage: 'Cập nhật thông tin CLB thành công! ✅',
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearActionMessage: true));
  }

  @override
  Future<void> close() {
    _clubsSubscription?.cancel();
    _myRequestsSubscription?.cancel();
    _pendingRequestsSubscription?.cancel();
    return super.close();
  }
}
