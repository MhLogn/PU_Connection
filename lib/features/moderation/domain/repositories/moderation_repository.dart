import '../entities/blocked_user_entity.dart';
import '../entities/report_entity.dart';

abstract class ModerationRepository {
  Future<void> submitReport(ReportEntity report);

  Future<void> blockUser({
    required String currentUserId,
    required BlockedUserEntity blockedUser,
  });

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Stream<List<BlockedUserEntity>> getBlockedUsersStream(String currentUserId);

  Future<List<String>> getBlockedUserIds(String currentUserId);
}
