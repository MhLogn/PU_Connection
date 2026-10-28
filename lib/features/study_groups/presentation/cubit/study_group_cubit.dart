import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/study_group_entity.dart';
import '../../domain/repositories/study_group_repository.dart';
import 'study_group_state.dart';

class StudyGroupCubit extends Cubit<StudyGroupState> {
  final StudyGroupRepository _repository;
  StreamSubscription<List<StudyGroupEntity>>? _subscription;

  StudyGroupCubit({required StudyGroupRepository repository})
    : _repository = repository,
      super(const StudyGroupState());

  void init() {
    _subscription?.cancel();
    emit(state.copyWith(status: StudyGroupStatus.loading));

    _subscription = _repository.watchStudyGroups().listen(
      (groups) {
        emit(state.copyWith(status: StudyGroupStatus.loaded, groups: groups));
      },
      onError: (err) {
        emit(
          state.copyWith(
            status: StudyGroupStatus.error,
            errorMessage: 'Lỗi tải danh sách nhóm học: $err',
          ),
        );
      },
    );
  }

  void setSubjectFilter(String? subject) {
    emit(state.copyWith(selectedSubjectFilter: () => subject));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> createGroup(StudyGroupEntity group) async {
    try {
      await _repository.createStudyGroup(group);
      emit(
        state.copyWith(
          successMessage: 'Đã tạo nhóm học tập "${group.title}" thành công!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể tạo nhóm học: $e'));
    }
  }

  Future<void> requestToJoin(String groupId, String userId) async {
    try {
      await _repository.requestToJoin(groupId, userId);
      emit(
        state.copyWith(successMessage: 'Đã gửi yêu cầu tham gia nhóm học tập!'),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi xin gia nhập nhóm: $e'));
    }
  }

  Future<void> cancelRequest(String groupId, String userId) async {
    try {
      await _repository.cancelRequest(groupId, userId);
      emit(state.copyWith(successMessage: 'Đã hủy yêu cầu tham gia nhóm!'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi hủy yêu cầu: $e'));
    }
  }

  Future<void> acceptRequest(String groupId, String userId) async {
    try {
      await _repository.acceptRequest(groupId, userId);
      emit(
        state.copyWith(successMessage: 'Đã phê duyệt thành viên vào nhóm học!'),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi duyệt thành viên: $e'));
    }
  }

  Future<void> rejectRequest(String groupId, String userId) async {
    try {
      await _repository.rejectRequest(groupId, userId);
      emit(state.copyWith(successMessage: 'Đã từ chối yêu cầu tham gia'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi từ chối yêu cầu: $e'));
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _repository.leaveGroup(groupId, userId);
      emit(state.copyWith(successMessage: 'Đã rời khỏi nhóm học tập'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi rời nhóm: $e'));
    }
  }

  Future<void> closeGroup(String groupId) async {
    try {
      await _repository.closeGroup(groupId);
      emit(
        state.copyWith(
          successMessage: 'Đã đóng nhóm học tập (Ngừng nhận thành viên mới)',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi khi đóng nhóm: $e'));
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
