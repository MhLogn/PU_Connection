import '../entities/study_group_entity.dart';

abstract class StudyGroupRepository {
  /// Lắng nghe danh sách các nhóm học tập theo thời gian thực
  Stream<List<StudyGroupEntity>> watchStudyGroups({String? subject});

  /// Lấy danh sách nhóm học tập một lần
  Future<List<StudyGroupEntity>> getStudyGroups({String? subject});

  /// Tạo nhóm học tập mới
  Future<void> createStudyGroup(StudyGroupEntity group);

  /// Gửi yêu cầu tham gia nhóm học tập
  Future<void> requestToJoin(String groupId, String userId);

  /// Hủy yêu cầu tham gia nhóm
  Future<void> cancelRequest(String groupId, String userId);

  /// Trưởng nhóm chấp nhận yêu cầu của sinh viên
  Future<void> acceptRequest(String groupId, String userId);

  /// Trưởng nhóm từ chối yêu cầu của sinh viên
  Future<void> rejectRequest(String groupId, String userId);

  /// Rời nhóm học tập
  Future<void> leaveGroup(String groupId, String userId);

  /// Đóng nhóm học tập (không nhận thêm thành viên)
  Future<void> closeGroup(String groupId);
}
