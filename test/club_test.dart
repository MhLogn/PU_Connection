import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/clubs/domain/entities/club_entity.dart';
import 'package:pu_connection/features/clubs/data/models/club_model.dart';
import 'package:pu_connection/features/clubs/data/repositories/club_repository_impl.dart';
import 'package:pu_connection/features/clubs/presentation/cubit/club_cubit.dart';
import 'package:pu_connection/features/clubs/presentation/cubit/club_state.dart';

void main() {
  group('ClubEntity & ClubModel Tests', () {
    const club = ClubEntity(
      id: 'test_club',
      name: 'CLB Test',
      category: 'Học thuật',
      description: 'Mô tả câu lạc bộ thử nghiệm',
      leaderName: 'Nguyễn Văn A',
      memberIds: ['user_1', 'user_2'],
      membersCount: 10,
    );

    test('isMember returns true if userId is in memberIds', () {
      expect(club.isMember('user_1'), isTrue);
      expect(club.isMember('user_99'), isFalse);
      expect(club.isMember(''), isFalse);
    });

    test('effectiveMembersCount returns correct number', () {
      expect(club.effectiveMembersCount, 10);
      final club2 = club.copyWith(membersCount: 1);
      expect(club2.effectiveMembersCount, 2);
    });

    test('ClubModel serialization to and from Map', () {
      final model = ClubModel.fromMap({
        'name': 'CLB AI',
        'category': 'Học thuật',
        'desc': 'CLB nghiên cứu trí tuệ nhân tạo',
        'leaderName': 'Trần Văn B',
        'members': ['uid_1'],
        'membersCount': 50,
      }, 'club_ai');

      expect(model.id, 'club_ai');
      expect(model.name, 'CLB AI');
      expect(model.description, 'CLB nghiên cứu trí tuệ nhân tạo');
      expect(model.isMember('uid_1'), isTrue);

      final map = model.toMap();
      expect(map['name'], 'CLB AI');
      expect(map['category'], 'Học thuật');
    });
  });

  group('ClubCubit Tests', () {
    late ClubRepositoryImpl repository;
    late ClubCubit cubit;

    setUp(() {
      repository = ClubRepositoryImpl();
      cubit = ClubCubit(clubRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state loads default clubs and filters category', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.status, ClubStatus.loaded);
      expect(cubit.state.clubs.isNotEmpty, isTrue);

      cubit.filterCategory('Thể thao');
      expect(cubit.state.selectedCategory, 'Thể thao');
      expect(cubit.state.filteredClubs.every((c) => c.category == 'Thể thao'), isTrue);

      cubit.filterCategory('Tất cả');
      expect(cubit.state.filteredClubs.length, cubit.state.clubs.length);
    });

    test('searchClubs filters correctly by keyword', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      cubit.searchClubs('Basketball');
      expect(cubit.state.filteredClubs.any((c) => c.name.contains('Basketball')), isTrue);

      cubit.searchClubs('');
      expect(cubit.state.filteredClubs.length, cubit.state.clubs.length);
    });

    test('toggleJoinClub handles join and leave', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      final firstClub = cubit.state.clubs.first;

      await cubit.toggleJoinClub(club: firstClub, userId: 'test_user_temp');
      expect(cubit.state.actionSuccessMessage, isNotNull);

      await cubit.toggleJoinClub(
        club: firstClub.copyWith(memberIds: [...firstClub.memberIds, 'test_user_temp']),
        userId: 'test_user_temp',
      );
      expect(cubit.state.actionSuccessMessage, contains('Đã rời'));
    });
  });
}
