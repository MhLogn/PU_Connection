import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/phenikaa_student_entity.dart';

class PhenikaaStudentModel extends PhenikaaStudentEntity {
  const PhenikaaStudentModel({
    required super.studentId,
    required super.fullName,
    required super.email,
    required super.faculty,
    required super.major,
    super.cohort,
    super.isActivated,
  });

  factory PhenikaaStudentModel.fromMap(Map<String, dynamic> map, String id) {
    return PhenikaaStudentModel(
      studentId: map['studentId'] as String? ?? id,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      faculty: map['faculty'] as String? ?? '',
      major: map['major'] as String? ?? '',
      cohort: (map['cohort'] as num?)?.toInt() ?? 0,
      isActivated: map['isActivated'] as bool? ?? false,
    );
  }

  factory PhenikaaStudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PhenikaaStudentModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'email': email,
      'faculty': faculty,
      'major': major,
      'cohort': cohort,
      'isActivated': isActivated,
    };
  }

  PhenikaaStudentModel copyWith({
    String? studentId,
    String? fullName,
    String? email,
    String? faculty,
    String? major,
    int? cohort,
    bool? isActivated,
  }) {
    return PhenikaaStudentModel(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      isActivated: isActivated ?? this.isActivated,
    );
  }
}
