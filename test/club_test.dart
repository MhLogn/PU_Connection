import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/features/clubs/domain/entities/club_entity.dart';
import 'package:pu_connection/features/clubs/data/models/club_model.dart';
import 'package:pu_connection/features/clubs/domain/entities/club_creation_request_entity.dart';
import 'package:pu_connection/features/clubs/data/models/club_creation_request_model.dart';
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
        'status': 'approved',
      }, 'club_ai');

      expect(model.id, 'club_ai');
      expect(model.name, 'CLB AI');
      expect(model.description, 'CLB nghiên cứu trí tuệ nhân tạo');
      expect(model.isMember('uid_1'), isTrue);
      expect(model.status, 'approved');

      final map = model.toMap();
      expect(map['name'], 'CLB AI');
      expect(map['category'], 'Học thuật');
      expect(map['status'], 'approved');
    });
  });

  group('ClubCreationRequestEntity & Model Tests', () {
    final now = DateTime(2026, 10, 26, 10, 0);
    final request = ClubCreationRequestEntity(
      id: 'req_123',
      clubName: 'CLB Robotics Phenikaa',
      category: 'Học thuật',
      description: 'CLB sáng tạo và chế tạo Robot tự hành',
      reason: 'Phát triển phong trào nghiên cứu khoa học kỹ thuật',
      founderId: 'student_uid_1',
      founderName: 'Lê Hoàng Long',
      founderEmail: 'long.lh@phenikaa-uni.edu.vn',
      founderStudentId: '22010123',
      schedule: 'Thứ 7 hàng tuần, 14h - 17h',
      location: 'Xưởng Maker Space Tòa A9',
      status: 'pending',
      createdAt: now,
    );

    test('Status getters return correct boolean values', () {
      expect(request.isPending, isTrue);
      expect(request.isApproved, isFalse);
      expect(request.isRejected, isFalse);

      final approvedReq = request.copyWith(status: 'approved');
      expect(approvedReq.isApproved, isTrue);
      expect(approvedReq.isPending, isFalse);

      final rejectedReq = request.copyWith(
        status: 'rejected',
        adminFeedback: 'Mục tiêu chưa rõ ràng',
      );
      expect(rejectedReq.isRejected, isTrue);
      expect(rejectedReq.adminFeedback, 'Mục tiêu chưa rõ ràng');
    });

    test('ClubCreationRequestModel serialization to and from Map', () {
      final model = ClubCreationRequestModel.fromEntity(request);
      final map = model.toMap();

      expect(map['clubName'], 'CLB Robotics Phenikaa');
      expect(map['category'], 'Học thuật');
      expect(map['status'], 'pending');
      expect(map['founderId'], 'student_uid_1');

      final reconstructed = ClubCreationRequestModel.fromMap(map, 'req_123');
      expect(reconstructed.id, 'req_123');
      expect(reconstructed.clubName, 'CLB Robotics Phenikaa');
      expect(reconstructed.founderName, 'Lê Hoàng Long');
      expect(reconstructed.founderStudentId, '22010123');
    });
  });

  group('ClubCubit & Request Workflow Tests', () {
    late ClubRepositoryImpl repository;
    late ClubCubit cubit;

    setUp(() {
      ClubRepositoryImpl.enableSeedClubs = true;
      ClubRepositoryImpl.resetMemory();
      repository = ClubRepositoryImpl();
      cubit = ClubCubit(clubRepository: repository);
    });

    tearDown(() {
      cubit.close();
      ClubRepositoryImpl.enableSeedClubs = false;
      ClubRepositoryImpl.resetMemory();
    });

    test('Initial state loads default clubs and filters category', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.status, ClubStatus.loaded);
      expect(cubit.state.clubs.isNotEmpty, isTrue);

      cubit.filterCategory('Thể thao');
      expect(cubit.state.selectedCategory, 'Thể thao');
      expect(
        cubit.state.filteredClubs.every((c) => c.category == 'Thể thao'),
        isTrue,
      );

      cubit.filterCategory('Tất cả');
      expect(cubit.state.filteredClubs.length, cubit.state.clubs.length);
    });

    test('searchClubs filters correctly by keyword and handles unaccented Vietnamese', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      cubit.searchClubs('Basketball');
      expect(
        cubit.state.filteredClubs.any((c) => c.name.contains('Basketball')),
        isTrue,
      );

      // Search without diacritics: 'tin hoc' -> matches 'CLB Tin Học Phenikaa PRO'
      cubit.searchClubs('tin hoc');
      expect(
        cubit.state.filteredClubs.any((c) => c.name.contains('Tin Học')),
        isTrue,
      );

      cubit.searchClubs('');
      expect(cubit.state.filteredClubs.length, cubit.state.clubs.length);
    });

    test('toggleJoinClub handles join and leave without double decrement', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      final firstClub = cubit.state.clubs.first;
      final initialCount = firstClub.effectiveMembersCount;

      // Join
      await cubit.toggleJoinClub(
        club: firstClub,
        userId: 'test_user_temp',
        secondaryId: '23019999',
      );
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.actionSuccessMessage, isNotNull);

      final joinedClub = cubit.state.clubs.firstWhere((c) => c.id == firstClub.id);
      expect(joinedClub.effectiveMembersCount, initialCount + 1);
      expect(joinedClub.isMember('test_user_temp'), isTrue);

      // Double join attempt: does not double count
      await repository.joinClub(clubId: firstClub.id, userId: 'test_user_temp');
      await Future.delayed(const Duration(milliseconds: 100));
      final doubleJoinClub = cubit.state.clubs.firstWhere((c) => c.id == firstClub.id);
      expect(doubleJoinClub.effectiveMembersCount, initialCount + 1);

      // Leave with both userId and secondaryId
      await cubit.toggleJoinClub(
        club: joinedClub,
        userId: 'test_user_temp',
        secondaryId: '23019999',
      );
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.actionSuccessMessage, contains('Đã rời'));

      final leftClub = cubit.state.clubs.firstWhere((c) => c.id == firstClub.id);
      expect(leftClub.effectiveMembersCount, initialCount);
      expect(leftClub.isMember('test_user_temp'), isFalse);
    });

    test('Student submits club creation request successfully with auto ID generation', () async {
      cubit.initMyRequestsStream('student_123');
      cubit.initPendingRequestsStream();

      const newRequest = ClubCreationRequestEntity(
        id: '', // empty ID to test automatic ID generation
        clubName: 'CLB Tranh Biện Phenikaa Debate',
        category: 'Kỹ năng',
        description: 'Môi trường rèn luyện tư duy phản biện và diễn thuyết',
        reason: 'Chưa có CLB nào chuyên về tranh biện tại Phenikaa',
        founderId: 'student_123',
        founderName: 'Nguyễn Văn Minh',
        founderEmail: 'minh.nv@phenikaa-uni.edu.vn',
        founderStudentId: '22019999',
      );

      final success = await cubit.submitClubCreationRequest(newRequest);
      expect(success, isTrue);
      expect(cubit.state.actionSuccessMessage, contains('Đã gửi hồ sơ'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.myRequests.length, 1);
      expect(cubit.state.myRequests.first.id.isNotEmpty, isTrue);
      expect(cubit.state.myRequests.first.clubName, 'CLB Tranh Biện Phenikaa Debate');
      expect(cubit.state.pendingRequests.length, 1);
    });

    test('Validation rejects request with short description or reason', () async {
      const shortRequest = ClubCreationRequestEntity(
        id: '',
        clubName: 'CLB Ngắn',
        category: 'Học thuật',
        description: 'Ngắn',
        reason: 'Ngắn',
        founderId: 'student_short',
        founderName: 'Nguyễn Văn S',
        founderEmail: 's.nv@phenikaa.vn',
      );

      final success = await cubit.submitClubCreationRequest(shortRequest);
      expect(success, isFalse);
      expect(cubit.state.errorMessage, contains('chi tiết hơn'));
    });

    test('Submitting request with duplicate club name is rejected', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      // Try creating club with name identical to default club
      const dupRequest = ClubCreationRequestEntity(
        id: 'req_dup',
        clubName: 'CLB Tin Học Phenikaa PRO',
        category: 'Học thuật',
        description: 'Tên trùng lặp với câu lạc bộ chính thức',
        reason: 'Thử nghiệm kiểm tra trùng lặp tên CLB',
        founderId: 'student_999',
        founderName: 'Hacker',
        founderEmail: 'test@phenikaa.vn',
      );

      final success = await cubit.submitClubCreationRequest(dupRequest);
      expect(success, isFalse);
      expect(cubit.state.errorMessage, contains('đã tồn tại'));
    });

    test('Admin approves club creation request: creates club and updates status', () async {
      cubit.initMyRequestsStream('student_debate');
      cubit.initPendingRequestsStream();

      const req = ClubCreationRequestEntity(
        id: 'req_debate',
        clubName: 'CLB Tranh Biện PU Debate',
        category: 'Kỹ năng',
        description: 'Rèn luyện kỹ năng tư duy và phản biện',
        reason: 'Thành lập môi trường giao lưu học thuật',
        founderId: 'student_debate',
        founderName: 'Trịnh Thảo Ly',
        founderEmail: 'ly.tt@st.phenikaa-uni.edu.vn',
        founderStudentId: '22010888',
      );

      await cubit.submitClubCreationRequest(req);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.pendingRequests.length, 1);

      // Admin approves
      final approved = await cubit.reviewClubRequest(
        requestId: 'req_debate',
        action: 'approve',
        adminId: 'admin_master',
        adminName: 'Trưởng Ban Quản Trị',
      );
      expect(approved, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      // Pending requests count becomes 0
      expect(cubit.state.pendingRequests.length, 0);

      // Club now appears in official clubs list
      expect(
        cubit.state.clubs.any((c) => c.name == 'CLB Tranh Biện PU Debate'),
        isTrue,
      );
      final newClub = cubit.state.clubs.firstWhere(
        (c) => c.name == 'CLB Tranh Biện PU Debate',
      );
      expect(newClub.leaderId, 'student_debate');
      expect(newClub.leaderName, 'Trịnh Thảo Ly');
      expect(newClub.isMember('student_debate'), isTrue);
      expect(newClub.status, 'approved');
    });

    test('Admin rejects club creation request with reason', () async {
      cubit.initPendingRequestsStream();
      cubit.initMyRequestsStream('student_bad');

      const badReq = ClubCreationRequestEntity(
        id: 'req_bad',
        clubName: 'CLB Không Hợp Lệ',
        category: 'Khác',
        description: 'Mô tả nội dung sơ sài không có định hướng hoạt động',
        reason: 'Thích thì lập câu lạc bộ để chơi',
        founderId: 'student_bad',
        founderName: 'Nguyễn Văn C',
        founderEmail: 'c.nv@phenikaa.vn',
      );

      await cubit.submitClubCreationRequest(badReq);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.pendingRequests.length, 1);

      // Admin rejects with feedback
      final rejected = await cubit.reviewClubRequest(
        requestId: 'req_bad',
        action: 'reject',
        rejectionReason: 'Mục đích không phù hợp tôn chỉ sinh viên Phenikaa',
        adminId: 'admin_uid',
        adminName: 'Admin Phòng CTSV',
      );
      expect(rejected, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.pendingRequests.length, 0);

      // In student's requests, request is marked rejected with feedback
      expect(cubit.state.myRequests.first.isRejected, isTrue);
      expect(
        cubit.state.myRequests.first.adminFeedback,
        'Mục đích không phù hợp tôn chỉ sinh viên Phenikaa',
      );
      // Club should NOT be in official clubs list
      expect(
        cubit.state.clubs.any((c) => c.name == 'CLB Không Hợp Lệ'),
        isFalse,
      );
    });

    test('Student cancels their pending club creation request', () async {
      cubit.initMyRequestsStream('student_cancel');
      cubit.initPendingRequestsStream();

      const req = ClubCreationRequestEntity(
        id: 'req_cancel_me',
        clubName: 'CLB Tạm Thời',
        category: 'Học thuật',
        description: 'Câu lạc bộ tạm thời chuẩn bị hủy theo yêu cầu',
        reason: 'Lý do thành lập tạm thời để kiểm thử',
        founderId: 'student_cancel',
        founderName: 'Người Hủy',
        founderEmail: 'cancel@phenikaa.vn',
      );

      await cubit.submitClubCreationRequest(req);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.pendingRequests.length, 1);

      final cancelled = await cubit.cancelClubRequest('req_cancel_me');
      expect(cancelled, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.pendingRequests.length, 0);
      expect(cubit.state.myRequests.length, 0);
    });

    test('Leader updates club details successfully', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      final original = cubit.state.clubs.first;

      final updated = original.copyWith(
        description: 'Mô tả mới đã được cập nhật bởi Ban Chủ Nhiệm',
        schedule: 'Thứ 2 & Thứ 6 hàng tuần',
      );

      final success = await cubit.updateClub(updated);
      expect(success, isTrue);
      expect(cubit.state.actionSuccessMessage, contains('Cập nhật thông tin CLB thành công'));

      await Future.delayed(const Duration(milliseconds: 100));
      final refreshed = cubit.state.clubs.firstWhere((c) => c.id == original.id);
      expect(refreshed.description, 'Mô tả mới đã được cập nhật bởi Ban Chủ Nhiệm');
      expect(refreshed.schedule, 'Thứ 2 & Thứ 6 hàng tuần');
    });
  });
}
