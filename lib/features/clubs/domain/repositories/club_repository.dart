import '../entities/club_entity.dart';

abstract class ClubRepository {
  Stream<List<ClubEntity>> getClubsStream();
  Future<ClubEntity?> getClubById(String clubId);
  Future<void> joinClub({required String clubId, required String userId});
  Future<void> leaveClub({required String clubId, required String userId});
}
