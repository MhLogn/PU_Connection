import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../domain/entities/event_entity.dart';

class EventRepository {
  final FirebaseFirestore _firestore;

  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final List<EventEntity> defaultEvents = [
    EventEntity(
      id: 'event_hackathon_2026',
      title: 'Phenikaa IT Hackathon 2026 - AI & Robotics',
      description:
          'Cuộc thi lập trình đổi mới sáng tạo lớn nhất năm của Trường ĐH Phenikaa. Thử thách xây dựng giải pháp AI ứng dụng cho thành phố thông minh và trường học số trong 48 giờ liên tục. Tổng giải thưởng lên tới 100.000.000 VNĐ cùng cơ hội thực tập tại Tập đoàn Phenikaa.',
      category: 'Học thuật',
      location: 'Hội trường Tầng 3 - Tòa A9 (Phenikaa Innovation Hub)',
      startDate: DateTime.now().add(const Duration(days: 3, hours: 8)),
      endDate: DateTime.now().add(const Duration(days: 5, hours: 18)),
      organizer: 'Khoa Công nghệ Thông tin & Đoàn TN Phenikaa',
      maxParticipants: 120,
      registeredStudentIds: ['23010001', '23010002'],
      colorType: 'blue',
      icon: Icons.code_rounded,
    ),
    EventEntity(
      id: 'event_youth_games_2026',
      title: 'Hội Thao Sinh Viên Phenikaa Youth Games',
      description:
          'Đại hội thể thao chào mừng ngày thành lập Đoàn 26/03. Gồm các nội dung thi đấu: Bóng đá nam/nữ, Bóng rổ, Cầu lông, Kéo co và E-Sports (Liên Quân & Tốc Chiến). Điểm rèn luyện cộng tối đa 8 ĐRL cho sinh viên tham gia.',
      category: 'Thể thao',
      location: 'Sân vận động & Nhà thi đấu đa năng Tòa A8',
      startDate: DateTime.now().add(const Duration(days: 7, hours: 7)),
      endDate: DateTime.now().add(const Duration(days: 14, hours: 17)),
      organizer: 'Bộ môn Giáo dục Thể chất & Hội Sinh Viên PU',
      maxParticipants: 350,
      registeredStudentIds: ['23010001'],
      colorType: 'orange',
      icon: Icons.sports_soccer_rounded,
    ),
    EventEntity(
      id: 'event_acoustic_night',
      title: 'Đêm Nhạc Acoustic Night "Giai Điệu Tuổi Trẻ"',
      description:
          'Giao lưu âm nhạc mộc acoustic ngoài trời do CLB Âm nhạc PAC và Guitar Phenikaa tổ chức. Đêm nhạc ấm cúng với các bài hát thanh xuân, tea break miễn phí và bốc thăm may mắn nhận quà lưu niệm Phenikaa.',
      category: 'Văn nghệ',
      location: 'Quảng trường Tòa A2 - Không gian xanh Phenikaa',
      startDate: DateTime.now().add(const Duration(days: 1, hours: 19)),
      endDate: DateTime.now().add(const Duration(days: 1, hours: 22)),
      organizer: 'CLB Âm Nhạc PAC & CLB Phenikaa Guitar',
      maxParticipants: 200,
      registeredStudentIds: [],
      colorType: 'violet',
      icon: Icons.music_note_rounded,
    ),
    EventEntity(
      id: 'event_volunteer_green',
      title: 'Chiến Dịch Sinh Viên Tình Nguyện Mùa Hè Xanh',
      description:
          'Chuỗi hoạt động tình nguyện bảo vệ môi trường khuôn viên ĐH Phenikaa, đổi rác tái chế lấy sen đá và hỗ trợ tân sinh viên K18 làm thủ tục nhập học. Sinh viên tham gia được cấp Giấy chứng nhận tình nguyện cấp Trường.',
      category: 'Tình nguyện',
      location: 'Sảnh chính Tòa A9 & Sân trường Phenikaa',
      startDate: DateTime.now().add(const Duration(days: 10, hours: 8)),
      endDate: DateTime.now().add(const Duration(days: 11, hours: 16)),
      organizer: 'Đội Sinh Viên Tình Nguyện Phenikaa University',
      maxParticipants: 150,
      registeredStudentIds: ['23010003'],
      colorType: 'mint',
      icon: Icons.volunteer_activism_rounded,
    ),
    EventEntity(
      id: 'event_career_fair_2026',
      title: 'Ngày Hội Việc Làm & Thực Tập Phenikaa Career Fair',
      description:
          'Cơ hội kết nối trực tiếp với hơn 50 doanh nghiệp hàng đầu: Phenikaa-X, Viettel, FPT Software, VNPT, Samsung, LG... Hỗ trợ sinh viên sửa CV, phỏng vấn thử 1-1 và nhận offer tuyển dụng ngay tại trường.',
      category: 'Hội thảo',
      location: 'Trung tâm Hội thảo Quốc tế Tòa A9',
      startDate: DateTime.now().add(const Duration(days: 15, hours: 8)),
      endDate: DateTime.now().add(const Duration(days: 15, hours: 17)),
      organizer: 'Trung tâm Hợp tác Doanh nghiệp & Tuyển dụng',
      maxParticipants: 500,
      registeredStudentIds: ['23010002'],
      colorType: 'coral',
      icon: Icons.work_rounded,
    ),
    EventEntity(
      id: 'event_semiconductor_seminar',
      title: 'Hội Thảo Công Nghệ Bán Dẫn & Vi Mạch Tương Lai',
      description:
          'Chuyên đề cập nhật xu hướng nghiên cứu và đào tạo ngành Thiết kế Vi mạch Bán dẫn tại Phenikaa. Diễn giả là các chuyên gia đầu ngành từ Synopsys, Cadence và các Giáo sư Viện Công nghệ Nano Phenikaa.',
      category: 'Học thuật',
      location: 'Giảng đường 302 - Tòa A2',
      startDate: DateTime.now().add(const Duration(days: 5, hours: 14)),
      endDate: DateTime.now().add(const Duration(days: 5, hours: 17)),
      organizer: 'Khoa Điện - Điện tử & Viện Nghiên cứu Phenikaa',
      maxParticipants: 180,
      registeredStudentIds: [],
      colorType: 'blue',
      icon: Icons.memory_rounded,
    ),
  ];

  Stream<List<EventEntity>> streamEvents() {
    return _firestore
        .collection(FirebaseConstants.eventsCollection)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultEvents;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawReg = data['registeredStudentIds'] as List<dynamic>? ?? [];
        return EventEntity(
          id: doc.id,
          title: data['title'] as String? ?? 'Sự kiện Phenikaa',
          description: data['description'] as String? ?? '',
          category: data['category'] as String? ?? 'Học thuật',
          location: data['location'] as String? ?? 'Phenikaa University',
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          organizer: data['organizer'] as String? ?? 'Đại học Phenikaa',
          maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 100,
          registeredStudentIds: rawReg.map((e) => e.toString()).toList(),
          colorType: data['colorType'] as String? ?? 'blue',
          icon: _mapIcon(data['iconName'] as String?),
          isOnline: data['isOnline'] as bool? ?? false,
        );
      }).toList();
    }).handleError((_) => defaultEvents);
  }

  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'volunteer':
        return Icons.volunteer_activism_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'memory':
        return Icons.memory_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Future<void> registerForEvent({
    required String eventId,
    required String studentId,
  }) async {
    if (eventId.isEmpty || studentId.isEmpty) return;
    try {
      final docRef = _firestore.collection(FirebaseConstants.eventsCollection).doc(eventId);
      final doc = await docRef.get();
      if (!doc.exists) {
        // Initialize doc with default if missing
        final defaultEvent = defaultEvents.firstWhere(
          (e) => e.id == eventId,
          orElse: () => defaultEvents.first,
        );
        await docRef.set({
          'title': defaultEvent.title,
          'description': defaultEvent.description,
          'category': defaultEvent.category,
          'location': defaultEvent.location,
          'startDate': Timestamp.fromDate(defaultEvent.startDate),
          'endDate': Timestamp.fromDate(defaultEvent.endDate),
          'organizer': defaultEvent.organizer,
          'maxParticipants': defaultEvent.maxParticipants,
          'colorType': defaultEvent.colorType,
          'registeredStudentIds': [studentId],
        });
      } else {
        await docRef.update({
          'registeredStudentIds': FieldValue.arrayUnion([studentId]),
        });
      }
    } catch (_) {
      // Local fallback in memory
      for (final e in defaultEvents) {
        if (e.id == eventId && !e.registeredStudentIds.contains(studentId)) {
          e.registeredStudentIds.add(studentId);
        }
      }
    }
  }

  Future<void> unregisterFromEvent({
    required String eventId,
    required String studentId,
  }) async {
    if (eventId.isEmpty || studentId.isEmpty) return;
    try {
      final docRef = _firestore.collection(FirebaseConstants.eventsCollection).doc(eventId);
      await docRef.update({
        'registeredStudentIds': FieldValue.arrayRemove([studentId]),
      });
    } catch (_) {
      for (final e in defaultEvents) {
        if (e.id == eventId) {
          e.registeredStudentIds.remove(studentId);
        }
      }
    }
  }
}
