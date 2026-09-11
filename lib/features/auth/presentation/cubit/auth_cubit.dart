import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/phenikaa_student_entity.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        if (state is! AuthInitial &&
            state is! StudentVerifiedForActivation &&
            state is! ActivationVerificationEmailSent) {
          emit(Unauthenticated());
        }
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(Authenticated(user));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('EMAIL_NOT_VERIFIED:')) {
        final cleanMsg = errorMsg.replaceAll('EMAIL_NOT_VERIFIED:', '').trim();
        emit(EmailNotVerified(email: email, message: cleanMsg));
      } else {
        emit(AuthError(errorMsg));
      }
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> verifyStudent(String identifier) async {
    emit(AuthLoading());
    try {
      final student = await _authRepository.verifyStudentIdentifier(identifier);
      emit(StudentVerifiedForActivation(student));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('ALREADY_ACTIVATED:')) {
        final cleanMsg = errorMsg.replaceAll('ALREADY_ACTIVATED:', '').trim();
        final cleanId = identifier.contains('@') ? identifier.split('@').first : identifier;
        emit(StudentAlreadyActivated(
          studentId: cleanId,
          email: identifier,
          message: cleanMsg,
        ));
      } else {
        emit(AuthError(errorMsg));
      }
    }
  }

  Future<void> registerAndSendVerificationLink({
    required PhenikaaStudentEntity student,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.registerAndSendVerificationLink(
        student: student,
        password: password,
      );
      emit(ActivationVerificationEmailSent(
        student: student,
        email: student.email,
      ));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> resendVerificationLink({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.resendEmailVerificationLink(
        email: email,
        password: password,
      );
      emit(ResendVerificationEmailSuccess(email));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(PasswordResetSent(email));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void resetToUnauthenticated() {
    emit(Unauthenticated());
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
