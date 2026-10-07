import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/club_entity.dart';
import '../../domain/repositories/club_repository.dart';
import 'club_state.dart';

class ClubCubit extends Cubit<ClubState> {
  final ClubRepository _clubRepository;
  StreamSubscription<List<ClubEntity>>? _clubsSubscription;

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
        emit(state.copyWith(
          status: ClubStatus.loaded,
          clubs: clubs,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ClubStatus.error,
          errorMessage: e.toString(),
        ));
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
  }) async {
    if (userId.isEmpty) {
      emit(state.copyWith(errorMessage: 'Vui lòng đăng nhập để tham gia CLB'));
      return;
    }

    final isCurrentlyMember = club.isMember(userId);

    try {
      if (isCurrentlyMember) {
        await _clubRepository.leaveClub(clubId: club.id, userId: userId);
        emit(state.copyWith(
          actionSuccessMessage: 'Đã rời câu lạc bộ "${club.name}"',
        ));
      } else {
        await _clubRepository.joinClub(clubId: club.id, userId: userId);
        emit(state.copyWith(
          actionSuccessMessage: 'Chào mừng bạn gia nhập "${club.name}"! 🎉',
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Thao tác không thành công: $e'));
    }
  }

  @override
  Future<void> close() {
    _clubsSubscription?.cancel();
    return super.close();
  }
}
