import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/phenikaa_student_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

class StudentVerifiedForActivation extends AuthState {
  final PhenikaaStudentEntity student;

  const StudentVerifiedForActivation(this.student);

  @override
  List<Object?> get props => [student];
}

class ActivationVerificationEmailSent extends AuthState {
  final PhenikaaStudentEntity student;
  final String email;

  const ActivationVerificationEmailSent({
    required this.student,
    required this.email,
  });

  @override
  List<Object?> get props => [student, email];
}

class ResendVerificationEmailSuccess extends AuthState {
  final String email;

  const ResendVerificationEmailSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class EmailNotVerified extends AuthState {
  final String email;
  final String message;

  const EmailNotVerified({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

class StudentAlreadyActivated extends AuthState {
  final String studentId;
  final String email;
  final String message;

  const StudentAlreadyActivated({
    required this.studentId,
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [studentId, email, message];
}
