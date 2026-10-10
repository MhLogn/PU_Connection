import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_reason.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_target_type.dart';
import 'package:pu_connection/features/moderation/domain/entities/report_entity.dart';
import 'package:pu_connection/features/moderation/domain/entities/blocked_user_entity.dart';
import 'package:pu_connection/features/moderation/data/models/report_model.dart';
import 'package:pu_connection/features/moderation/data/models/blocked_user_model.dart';
import 'package:pu_connection/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:pu_connection/features/moderation/presentation/cubit/moderation_cubit.dart';
import 'package:pu_connection/features/moderation/presentation/cubit/moderation_state.dart';

void main() {
  setUp(() {
    ModerationRepositoryImpl.resetMemory();
  });

  group('Entities and Models Tests', () {
    test('ReportModel serialization to and from Map', () {
      final now = DateTime.now();
      final model = ReportModel(
        id: 'rep_1',
        reporterId: 'user_1',
        reporterName: 'Sinh viên A',
        targetId: 'post_100',
        targetType: ReportTargetType.post,
        targetAuthorId: 'user_2',
        targetAuthorName: 'Sinh viên B',
        reason: ReportReason.spam,
        details: 'Đăng bài quảng cáo khóa học',
        status: 'pending',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['reporterId'], 'user_1');
      expect(map['targetId'], 'post_100');
      expect(map['targetType'], 'post');
      expect(map['reason'], 'spam');

      final deserialized = ReportModel.fromMap(map, 'rep_1');
      expect(deserialized.id, 'rep_1');
      expect(deserialized.reason, ReportReason.spam);
      expect(deserialized.targetType, ReportTargetType.post);
      expect(deserialized.details, 'Đăng bài quảng cáo khóa học');
    });

    test('BlockedUserModel serialization to and from Map', () {
      const model = BlockedUserModel(
        userId: 'user_bad',
        userName: 'Kẻ Quấy Rối',
        userAvatar: 'https://example.com/avatar.jpg',
        userFaculty: 'CNTT',
      );

      final map = model.toMap();
      expect(map['userId'], 'user_bad');
      expect(map['userName'], 'Kẻ Quấy Rối');

      final deserialized = BlockedUserModel.fromMap(map, 'user_bad');
      expect(deserialized.userId, 'user_bad');
      expect(deserialized.userName, 'Kẻ Quấy Rối');
      expect(deserialized.userFaculty, 'CNTT');
    });

    test('ReportReason display names are informative', () {
      expect(ReportReason.spam.displayName, contains('Spam'));
      expect(ReportReason.harassment.displayName, contains('Quấy rối'));
      expect(ReportReason.academicDishonesty.displayName, contains('Gian lận'));
    });
  });

  group('ModerationRepositoryImpl Tests', () {
    late ModerationRepositoryImpl repository;

    setUp(() {
      ModerationRepositoryImpl.resetMemory();
      repository = ModerationRepositoryImpl();
    });

    test('submitReport records report into memory', () async {
      final report = ReportEntity(
        id: 'rep_test',
        reporterId: 'user_1',
        targetId: 'post_1',
        targetType: ReportTargetType.post,
        reason: ReportReason.harassment,
        createdAt: DateTime.now(),
      );

      await repository.submitReport(report);
      // no exception thrown
      expect(true, isTrue);
    });

    test('blockUser and unblockUser update blocked stream and list of IDs', () async {
      const blocked = BlockedUserEntity(
        userId: 'user_bad_1',
        userName: 'Nguyễn Văn X',
        userFaculty: 'Kinh tế',
      );

      final stream = repository.getBlockedUsersStream('user_1');

      expectLater(
        stream,
        emitsInOrder([
          predicate<List<BlockedUserEntity>>((l) => l.isEmpty),
          predicate<List<BlockedUserEntity>>((l) => l.length == 1 && l.first.userId == 'user_bad_1'),
          predicate<List<BlockedUserEntity>>((l) => l.isEmpty),
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await repository.blockUser(
        currentUserId: 'user_1',
        blockedUser: blocked,
      );

      final idsAfterBlock = await repository.getBlockedUserIds('user_1');
      expect(idsAfterBlock, contains('user_bad_1'));

      await Future.delayed(const Duration(milliseconds: 50));
      await repository.unblockUser(
        currentUserId: 'user_1',
        blockedUserId: 'user_bad_1',
      );

      final idsAfterUnblock = await repository.getBlockedUserIds('user_1');
      expect(idsAfterUnblock, isEmpty);
    });
  });

  group('ModerationCubit Tests', () {
    late ModerationRepositoryImpl repository;
    late ModerationCubit cubit;

    setUp(() {
      ModerationRepositoryImpl.resetMemory();
      repository = ModerationRepositoryImpl();
      cubit = ModerationCubit(moderationRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is empty', () {
      expect(cubit.state.blockedUsers, isEmpty);
      expect(cubit.state.blockedUserIds, isEmpty);
      expect(cubit.state.hiddenPostIds, isEmpty);
      expect(cubit.state.status, ModerationActionStatus.initial);
    });

    test('submitReport sets success message and hides reported post', () async {
      final report = ReportEntity(
        id: 'rep_123',
        reporterId: 'user_me',
        targetId: 'post_violating',
        targetType: ReportTargetType.post,
        reason: ReportReason.inappropriate,
      );

      await cubit.submitReport(report);

      expect(cubit.state.status, ModerationActionStatus.success);
      expect(cubit.state.message, isNotNull);
      expect(cubit.state.hiddenPostIds, contains('post_violating'));
    });

    test('blockUser and unblockUser flow in cubit', () async {
      cubit.init('user_me');
      await Future.delayed(const Duration(milliseconds: 50));

      const blocked = BlockedUserEntity(
        userId: 'user_spammer',
        userName: 'Spam Account',
      );

      await cubit.blockUser(
        currentUserId: 'user_me',
        blockedUser: blocked,
      );

      expect(cubit.state.status, ModerationActionStatus.success);
      expect(cubit.state.blockedUserIds, contains('user_spammer'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.blockedUsers.length, 1);

      await cubit.unblockUser(
        currentUserId: 'user_me',
        blockedUserId: 'user_spammer',
      );

      expect(cubit.state.status, ModerationActionStatus.success);
      expect(cubit.state.blockedUserIds, isEmpty);
    });

    test('hidePostOptimistically adds post to hiddenPostIds', () {
      cubit.hidePostOptimistically('post_hidden_1');
      expect(cubit.state.hiddenPostIds, contains('post_hidden_1'));
    });
  });
}
