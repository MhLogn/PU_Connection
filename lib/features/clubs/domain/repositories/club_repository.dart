import '../entities/club_creation_request_entity.dart';
import '../entities/club_entity.dart';

abstract class ClubRepository {
  Stream<List<ClubEntity>> getClubsStream();
  Future<ClubEntity?> getClubById(String clubId);
  Future<void> joinClub({required String clubId, required String userId});
  Future<void> leaveClub({
    required String clubId,
    required String userId,
    String? secondaryId,
  });
  Future<void> updateClub(ClubEntity club);

  /// Đề xuất thành lập CLB & xét duyệt
  Stream<List<ClubCreationRequestEntity>> getClubRequestsStream({
    String? status,
    String? founderId,
  });
  Future<void> submitClubCreationRequest(ClubCreationRequestEntity request);
  Future<void> reviewClubRequest({
    required String requestId,
    required String action, // 'approve', 'reject'
    String? rejectionReason,
    required String adminId,
    required String adminName,
  });
  Future<void> cancelClubRequest(String requestId);
}
