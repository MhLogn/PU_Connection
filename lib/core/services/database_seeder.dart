import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';
import '../../features/auth/data/datasources/phenikaa_student_directory.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/feed/data/models/post_model.dart';

class DatabaseSeeder {
  static Future<Map<String, dynamic>> seedAllData({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserEntity? currentUser,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final firebaseAuth = auth ?? FirebaseAuth.instance;

    int studentsCount = 0;
    int postsCount = 0;
    bool userSynced = false;

    debugPrint('🚀 [DatabaseSeeder] Bắt đầu đẩy dữ liệu lên Cloud Firestore...');

    // 1. Đẩy danh sách toàn bộ sinh viên Phenikaa lên collection 'phenikaa_students'
    try {
      final batch = db.batch();
      for (final student in PhenikaaStudentDirectory.defaultStudents) {
        final docRef = db
            .collection(FirebaseConstants.phenikaaStudentsCollection)
            .doc(student.studentId);
        
        final isCurrentUser = currentUser != null && currentUser.studentId == student.studentId;
        final data = student.toMap();
        if (isCurrentUser) {
          data['isActivated'] = true;
        }

        batch.set(docRef, data, SetOptions(merge: true));
        studentsCount++;
      }
      await batch.commit();
      debugPrint('✅ [DatabaseSeeder] Đã đẩy thành công $studentsCount sinh viên lên "phenikaa_students"');
    } catch (e) {
      debugPrint('❌ [DatabaseSeeder] Lỗi khi đẩy phenikaa_students: $e');
      rethrow;
    }

    // 2. Đẩy hồ sơ người dùng hiện tại lên collection 'users'
    try {
      final authUser = firebaseAuth.currentUser;
      if (authUser != null) {
        final email = authUser.email ?? '23010390@st.phenikaa-uni.edu.vn';
        final studentId = currentUser?.studentId.isNotEmpty == true
            ? currentUser!.studentId
            : email.split('@').first;
        final displayName = currentUser?.displayName.isNotEmpty == true
            ? currentUser!.displayName
            : (authUser.displayName ?? 'Hà Mạnh Long');
        final faculty = currentUser?.faculty.isNotEmpty == true
            ? currentUser!.faculty
            : 'Công nghệ thông tin';
        final major = currentUser?.major.isNotEmpty == true
            ? currentUser!.major
            : 'Kỹ thuật phần mềm';
        final cohort = currentUser?.cohort != 0 ? currentUser?.cohort ?? 17 : 17;

        final userModel = UserModel(
          uid: authUser.uid,
          email: email,
          studentId: studentId,
          displayName: displayName,
          username: studentId,
          faculty: faculty,
          major: major,
          cohort: cohort,
          userType: 'student',
          isVerified: true,
          currentSubjects: const ['CNTT-225', 'CSDL-101'],
          friendsCount: 5,
          postsCount: 1,
        );

        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(authUser.uid)
            .set(userModel.toMap(), SetOptions(merge: true));

        userSynced = true;
        debugPrint('✅ [DatabaseSeeder] Đã lưu profile người dùng "${userModel.displayName}" lên "users/${authUser.uid}"');
      }
    } catch (e) {
      debugPrint('❌ [DatabaseSeeder] Lỗi khi lưu users: $e');
    }

    // 3. Đẩy các bài viết mẫu lên collection 'posts'
    try {
      final postsCol = db.collection(FirebaseConstants.postsCollection);
      final existingPosts = await postsCol.limit(1).get();

      if (existingPosts.docs.isEmpty) {
        final samplePosts = [
          PostModel(
            postId: '',
            authorId: firebaseAuth.currentUser?.uid ?? 'phenikaa_admin',
            authorName: currentUser?.displayName.isNotEmpty == true ? currentUser!.displayName : 'Hà Mạnh Long',
            authorStudentId: currentUser?.studentId.isNotEmpty == true ? currentUser!.studentId : '23010390',
            authorFaculty: 'Công nghệ thông tin',
            content: 'Chào các bạn sinh viên Phenikaa! 🚀\nTổng hợp tài liệu ôn tập và đề thi mẫu môn Cấu trúc dữ liệu & Giải thuật kỳ này đã được cập nhật. Chúc các bạn ôn thi đạt kết quả tốt nhất!',
            postType: 'document',
            category: 'Tài liệu',
            subjectCode: 'CNTT-202',
            likeCount: 15,
            commentCount: 4,
            tags: const ['#Phenikaa', '#CTDL', '#OnThi'],
            likedUsers: const [],
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          PostModel(
            postId: '',
            authorId: 'student_2',
            authorName: 'Vũ Đức Thắng',
            authorStudentId: '23020015',
            authorFaculty: 'Kỹ thuật Ô tô & Năng lượng',
            content: 'Có nhóm đồ án nào của K17 khoa Ô tô đang cần thêm người mảng mô phỏng động cơ không ạ? Mình đã nắm vững MATLAB & Simulink, rất mong muốn được ghép nhóm cùng các bạn.',
            postType: 'text',
            category: 'Tìm nhóm',
            subjectCode: 'OTO-301',
            likeCount: 8,
            commentCount: 2,
            tags: const ['#TimNhom', '#OTo', '#K17'],
            likedUsers: const [],
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          PostModel(
            postId: '',
            authorId: 'phenikaa_union',
            authorName: 'Đoàn Thanh Niên Phenikaa',
            authorStudentId: 'DOAN-PU',
            authorFaculty: 'Khoa học cơ bản',
            content: '📢 THÔNG BÁO: Cuộc thi Sáng tạo Khởi nghiệp Phenikaa Innovation 2026 chính thức mở đơn đăng ký! Các đội thi xuất sắc sẽ có cơ hội nhận giải thưởng lên đến 50.000.000 VNĐ cùng sự bảo trợ từ Phenikaa Group.',
            postType: 'text',
            category: 'Thông báo',
            subjectCode: null,
            likeCount: 42,
            commentCount: 9,
            tags: const ['#PhenikaaInnovation', '#KhoiNghiep', '#TuHaoPhenikaa'],
            likedUsers: const [],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        for (final post in samplePosts) {
          await postsCol.add(post.toMap());
          postsCount++;
        }
        debugPrint('✅ [DatabaseSeeder] Đã đẩy thành công $postsCount bài viết lên "posts"');
      } else {
        postsCount = existingPosts.docs.length;
        debugPrint('ℹ️ [DatabaseSeeder] Collection "posts" đã có sẵn dữ liệu.');
      }
    } catch (e) {
      debugPrint('❌ [DatabaseSeeder] Lỗi khi đẩy posts: $e');
    }

    return {
      'studentsCount': studentsCount,
      'postsCount': postsCount,
      'userSynced': userSynced,
    };
  }
}
