import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../models/phenikaa_student_model.dart';

class PhenikaaStudentDirectory {
  static final List<PhenikaaStudentModel> defaultStudents = [
    const PhenikaaStudentModel(
      studentId: '23010390',
      fullName: 'Hà Mạnh Long',
      email: '23010390@st.phenikaa-uni.edu.vn',
      faculty: 'Công nghệ thông tin',
      major: 'Kỹ thuật phần mềm',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23010111',
      fullName: 'Nguyễn Hoàng Nam',
      email: '23010111@st.phenikaa-uni.edu.vn',
      faculty: 'Công nghệ thông tin',
      major: 'Khoa học máy tính',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '22010222',
      fullName: 'Trần Thị Thanh Mai',
      email: '22010222@st.phenikaa-uni.edu.vn',
      faculty: 'Công nghệ thông tin',
      major: 'Hệ thống thông tin',
      cohort: 16,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23020015',
      fullName: 'Vũ Đức Thắng',
      email: '23020015@st.phenikaa-uni.edu.vn',
      faculty: 'Kỹ thuật Ô tô & Năng lượng',
      major: 'Công nghệ kỹ thuật Ô tô',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '22020088',
      fullName: 'Đỗ Quang Huy',
      email: '22020088@st.phenikaa-uni.edu.vn',
      faculty: 'Kỹ thuật Ô tô & Năng lượng',
      major: 'Kỹ thuật Năng lượng',
      cohort: 16,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23030045',
      fullName: 'Lê Tuấn Anh',
      email: '23030045@st.phenikaa-uni.edu.vn',
      faculty: 'Điện - Điện tử',
      major: 'Điều khiển & Tự động hóa',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23040102',
      fullName: 'Phạm Thu Trang',
      email: '23040102@st.phenikaa-uni.edu.vn',
      faculty: 'Kinh tế & Kinh doanh',
      major: 'Quản trị kinh doanh',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '22040055',
      fullName: 'Hoàng Minh Đức',
      email: '22040055@st.phenikaa-uni.edu.vn',
      faculty: 'Kinh tế & Kinh doanh',
      major: 'Tài chính - Ngân hàng',
      cohort: 16,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23050012',
      fullName: 'Nguyễn Thùy Linh',
      email: '23050012@st.phenikaa-uni.edu.vn',
      faculty: 'Dược',
      major: 'Dược học',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23060008',
      fullName: 'Đặng Quốc Bảo',
      email: '23060008@st.phenikaa-uni.edu.vn',
      faculty: 'Y khoa',
      major: 'Y đa khoa',
      cohort: 17,
      isActivated: false,
    ),
    const PhenikaaStudentModel(
      studentId: '23070034',
      fullName: 'Bùi Phương Thảo',
      email: '23070034@st.phenikaa-uni.edu.vn',
      faculty: 'Ngôn ngữ Hàn Quốc',
      major: 'Ngôn ngữ Hàn Quốc',
      cohort: 17,
      isActivated: false,
    ),
  ];

  static Future<void> seedStudentsIfEmpty(FirebaseFirestore firestore) async {
    try {
      final colRef = firestore.collection(FirebaseConstants.phenikaaStudentsCollection);
      final snapshot = await colRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        for (final student in defaultStudents) {
          await colRef.doc(student.studentId).set(student.toMap());
        }
      }
    } catch (_) {}
  }
}
