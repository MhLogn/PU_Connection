import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/study_groups/domain/entities/study_group_entity.dart';
import 'package:pu_connection/features/study_groups/data/models/study_group_model.dart';
import 'package:pu_connection/features/study_groups/data/repositories/study_group_repository_impl.dart';
import 'package:pu_connection/features/study_groups/presentation/cubit/study_group_cubit.dart';
import 'package:pu_connection/features/study_groups/presentation/cubit/study_group_state.dart';

void main() {
  group('StudyGroupEntity & Model Tests', () {
    test('computed properties return correct values', () {
      final now = DateTime.now();
      final group = StudyGroupEntity(
        id: 'g_1',
        creatorId: 'lead_1',
        creatorName: 'Trưởng nhóm',
        title: 'Ôn thi Giải tích',
        subject: 'Giải tích 2',
        description: 'Mô tả',
        maxMembers: 3,
        memberIds: const ['lead_1', 'member_2'],
        pendingRequestIds: const ['pending_3'],
        studyTime: now,
        location: 'Thư viện A9',
        createdAt: now,
      );

      expect(group.currentMembersCount, 2);
      expect(group.isFull, isFalse);
      expect(group.isCreator('lead_1'), isTrue);
      expect(group.isCreator('member_2'), isFalse);
      expect(group.isMember('member_2'), isTrue);
      expect(group.isMember('outside_4'), isFalse);
      expect(group.hasRequested('pending_3'), isTrue);
      expect(group.hasRequested('outside_4'), isFalse);

      final fullGroup = group.copyWith(memberIds: ['lead_1', 'member_2', 'member_3']);
      expect(fullGroup.isFull, isTrue);
    });

    test('StudyGroupModel serialization round-trip', () {
      final now = DateTime(2026, 10, 15, 14, 0);
      final model = StudyGroupModel(
        id: 'g_model_1',
        creatorId: 'lead_1',
        creatorName: 'Nguyễn Văn A',
        creatorStudentId: '23010390',
        creatorFaculty: 'CNTT',
        title: 'Nhóm Flutter',
        subject: 'Lập trình Mobile',
        description: 'Code app hay',
        maxMembers: 4,
        memberIds: const ['lead_1'],
        pendingRequestIds: const [],
        studyTime: now,
        location: 'Tòa A2',
        createdAt: now,
        isOpen: true,
      );

      final map = model.toMap();
      expect(map['title'], 'Nhóm Flutter');
      expect(map['subject'], 'Lập trình Mobile');
      expect(map['maxMembers'], 4);

      final deserialized = StudyGroupModel.fromMap(map, 'g_model_1');
      expect(deserialized.id, 'g_model_1');
      expect(deserialized.creatorStudentId, '23010390');
      expect(deserialized.subject, 'Lập trình Mobile');
      expect(deserialized.isOpen, isTrue);
    });
  });

  group('StudyGroupRepositoryImpl Tests', () {
    late StudyGroupRepositoryImpl repository;

    setUp(() {
      repository = StudyGroupRepositoryImpl(); // in-memory with seed data
    });

    test('getStudyGroups returns seed groups', () async {
      final groups = await repository.getStudyGroups();
      expect(groups, isNotEmpty);
      expect(groups.length, greaterThanOrEqualTo(4));
    });

    test('getStudyGroups filters by subject', () async {
      final mathGroups = await repository.getStudyGroups(subject: 'Giải tích 2');
      expect(mathGroups, isNotEmpty);
      expect(mathGroups.every((g) => g.subject == 'Giải tích 2'), isTrue);
    });

    test('requestToJoin and cancelRequest flow', () async {
      final groups = await repository.getStudyGroups();
      final targetGroup = groups.first;

      await repository.requestToJoin(targetGroup.id, 'new_student_99');
      final updated = await repository.getStudyGroups();
      final found = updated.firstWhere((g) => g.id == targetGroup.id);
      expect(found.pendingRequestIds.contains('new_student_99'), isTrue);

      await repository.cancelRequest(targetGroup.id, 'new_student_99');
      final updated2 = await repository.getStudyGroups();
      final found2 = updated2.firstWhere((g) => g.id == targetGroup.id);
      expect(found2.pendingRequestIds.contains('new_student_99'), isFalse);
    });

    test('acceptRequest moves user from pending to members', () async {
      final groups = await repository.getStudyGroups();
      final targetGroup = groups.first;

      await repository.requestToJoin(targetGroup.id, 'accepted_student');
      await repository.acceptRequest(targetGroup.id, 'accepted_student');

      final updated = await repository.getStudyGroups();
      final found = updated.firstWhere((g) => g.id == targetGroup.id);
      expect(found.pendingRequestIds.contains('accepted_student'), isFalse);
      expect(found.memberIds.contains('accepted_student'), isTrue);
    });

    test('leaveGroup removes user from memberIds', () async {
      final groups = await repository.getStudyGroups();
      final targetGroup = groups.first;
      final memberToLeave = targetGroup.memberIds.last;

      await repository.leaveGroup(targetGroup.id, memberToLeave);

      final updated = await repository.getStudyGroups();
      final found = updated.firstWhere((g) => g.id == targetGroup.id);
      expect(found.memberIds.contains(memberToLeave), isFalse);
    });

    test('closeGroup sets isOpen to false', () async {
      final groups = await repository.getStudyGroups();
      final targetGroup = groups.first;

      await repository.closeGroup(targetGroup.id);

      final updated = await repository.getStudyGroups();
      final found = updated.firstWhere((g) => g.id == targetGroup.id);
      expect(found.isOpen, isFalse);
    });
  });

  group('StudyGroupCubit Tests', () {
    late StudyGroupRepositoryImpl repository;
    late StudyGroupCubit cubit;

    setUp(() {
      repository = StudyGroupRepositoryImpl();
      cubit = StudyGroupCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('init loads study groups and emits loaded state', () async {
      cubit.init();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, StudyGroupStatus.loaded);
      expect(cubit.state.groups, isNotEmpty);
    });

    test('setSubjectFilter filters state correctly', () async {
      cubit.init();
      await Future.delayed(const Duration(milliseconds: 50));

      cubit.setSubjectFilter('Giải tích 2');
      expect(cubit.state.selectedSubjectFilter, 'Giải tích 2');
      expect(cubit.state.filteredGroups.every((g) => g.subject == 'Giải tích 2'), isTrue);
    });

    test('createGroup adds group to cubit state', () async {
      cubit.init();
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();
      final newGroup = StudyGroupEntity(
        id: 'new_g_123',
        creatorId: 'me',
        creatorName: 'Sinh viên mới',
        title: 'Nhóm Tự Động Hóa',
        subject: 'Điều khiển tự động',
        description: 'Làm đồ án',
        studyTime: now,
        location: 'Tòa A9',
        createdAt: now,
      );

      await cubit.createGroup(newGroup);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.groups.any((g) => g.id == 'new_g_123'), isTrue);
      expect(cubit.state.successMessage, isNotNull);
    });
  });
}
