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

    try {
      final docsCol = db.collection(FirebaseConstants.studyDocumentsCollection);
      final existingDocs = await docsCol.limit(1).get();
      if (existingDocs.docs.isEmpty) {
        final sampleDocs = [
          {
            'title': 'Đề cương & Ngân hàng trắc nghiệm Lập trình Mạng',
            'code': 'CNTT-225',
            'faculty': 'CNTT',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '4.2 MB',
            'authorId': 'pu_admin',
            'authorName': 'Ban Học Tập Khoa CNTT',
            'authorStudentId': 'CNTT-PU',
            'downloads': 1240,
            'rating': 4.9,
            'description': 'Đề cương ôn tập chi tiết gồm 150 câu hỏi trắc nghiệm kèm đáp án và giải thích.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          },
          {
            'title': 'Slide bài giảng Cơ sở dữ liệu & SQL Nâng cao',
            'code': 'CSDL-101',
            'faculty': 'CNTT',
            'fileUrl': 'https://pdfobject.com/pdf/sample.pdf',
            'fileType': 'pdf',
            'fileSize': '8.5 MB',
            'authorId': 'pu_admin',
            'authorName': 'Giảng viên Bộ môn HTTT',
            'authorStudentId': 'GV-012',
            'downloads': 980,
            'rating': 4.8,
            'description': 'Bộ slide trọn gói 12 chương bài giảng CSDL từ thiết kế ERD đến tối ưu hóa truy vấn SQL.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          },
          {
            'title': 'Bộ đề thi thử Xác suất Thống kê có lời giải chi tiết',
            'code': 'XSTK-01',
            'faculty': 'Kinh tế & QTKD',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '2.8 MB',
            'authorId': 'student_3',
            'authorName': 'Lê Phương Thảo',
            'authorStudentId': '23010512',
            'downloads': 1560,
            'rating': 5.0,
            'description': 'Tuyển tập 10 bộ đề thi học kỳ các năm gần nhất có lời giải từng bước.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          },
          {
            'title': 'Dược lý học đại cương & Tổng hợp tương tác thuốc',
            'code': 'DUOC-102',
            'faculty': 'Dược - Y',
            'fileUrl': 'https://pdfobject.com/pdf/sample.pdf',
            'fileType': 'pdf',
            'fileSize': '6.1 MB',
            'authorId': 'student_4',
            'authorName': 'Nguyễn Hoàng Nam',
            'authorStudentId': '22030119',
            'downloads': 620,
            'rating': 4.7,
            'description': 'Sổ tay bỏ túi Dược lý và phân loại nhóm kháng sinh lâm sàng.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          },
          {
            'title': 'Tổng hợp từ vựng & đề thi Tiếng Anh B1 Vstep Phenikaa',
            'code': 'ENG-B1',
            'faculty': 'Ngôn ngữ Anh',
            'fileUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'fileType': 'pdf',
            'fileSize': '15.3 MB',
            'authorId': 'pu_admin',
            'authorName': 'Trung tâm Ngoại ngữ Phenikaa',
            'authorStudentId': 'ENG-PU',
            'downloads': 2100,
            'rating': 4.9,
            'description': 'Trọn bộ bí kíp ôn thi chuẩn đầu ra B1 Vstep dành riêng cho sinh viên Phenikaa.',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
          },
        ];
        for (final doc in sampleDocs) {
          await docsCol.add(doc);
        }
        debugPrint('✅ [DatabaseSeeder] Đã đẩy thành công ${sampleDocs.length} tài liệu lên "study_documents"');
      }
    } catch (e) {
      debugPrint('❌ [DatabaseSeeder] Lỗi khi đẩy study_documents: $e');
    }

    return {
      'studentsCount': studentsCount,
      'postsCount': postsCount,
      'userSynced': userSynced,
    };
  }
}
