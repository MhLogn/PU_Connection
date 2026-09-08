import 'package:equatable/equatable.dart';

class PhenikaaStudentEntity extends Equatable {
  final String studentId;
  final String fullName;
  final String email;
  final String faculty;
  final String major;
  final int cohort;
  final bool isActivated;

  const PhenikaaStudentEntity({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.faculty,
    required this.major,
    this.cohort = 0,
    this.isActivated = false,
  });

  @override
  List<Object?> get props => [
        studentId,
        fullName,
        email,
        faculty,
        major,
        cohort,
        isActivated,
      ];
}
