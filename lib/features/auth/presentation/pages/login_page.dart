import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/phenikaa_student_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInObscurePassword = true;

  final _activationFormKey = GlobalKey<FormState>();
  final _activationIdentifierController = TextEditingController();
  PhenikaaStudentEntity? _currentStudent;

  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;

  int _activationStep = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _activationIdentifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignInSubmitted() {
    if (_signInFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signIn(
            email: _signInEmailController.text.trim(),
            password: _signInPasswordController.text,
          );
    }
  }

  void _onVerifyStudentSubmitted() {
    if (_activationFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().verifyStudent(
            _activationIdentifierController.text.trim(),
          );
    }
  }

  void _onRegisterWithVerificationLinkSubmitted() {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      if (_currentStudent != null) {
        context.read<AuthCubit>().registerAndSendVerificationLink(
              student: _currentStudent!,
              password: _newPasswordController.text,
            );
      }
    }
  }

  void _resetActivationFlow() {
    setState(() {
      _activationStep = 1;
      _currentStudent = null;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _signInEmailController.text.trim());
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.forgot_password_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.forgot_password_desc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 23010390',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthCubit>().sendPasswordReset(email);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.send_reset_link),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is StudentAlreadyActivated) {
            setState(() {
              _signInEmailController.text = state.studentId;
              _tabController.animateTo(0);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: TextStyle(color: AppTheme.isDark(context) ? Colors.black87 : Colors.white),
                ),
                backgroundColor: AppTheme.primaryColor(context),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is StudentVerifiedForActivation) {
            setState(() {
              _currentStudent = state.student;
              _activationStep = 2;
            });
          } else if (state is ActivationVerificationEmailSent) {
            setState(() {
              _currentStudent = state.student;
              _activationStep = 3;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã gửi liên kết xác thực Firebase tới ${state.email}. Vui lòng mở email để kích hoạt!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ResendVerificationEmailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã gửi lại link xác thực Firebase tới ${state.email}.',
                  style: TextStyle(color: AppTheme.isDark(context) ? Colors.black87 : Colors.white),
                ),
                backgroundColor: AppTheme.primaryColor(context),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is EmailNotVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is Authenticated) {
            context.go('/home');
          } else if (state is PasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã gửi liên kết đặt lại mật khẩu tới ${state.email}.'),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final l10n = AppLocalizations.of(context)!;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/logo/phenikaa_logo.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.school_rounded,
                                  size: 64,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'PU Connection',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor(context),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mạng xã hội sinh viên Trường Đại học Phenikaa',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.primaryColor(context),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor(context).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.65),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          tabs: [
                            Tab(text: l10n.login_tab),
                            Tab(text: l10n.activate_tab),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildSignInTab(isLoading, colorScheme, l10n)
                              : _buildActivationTab(isLoading, colorScheme, l10n);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignInTab(bool isLoading, ColorScheme colorScheme, AppLocalizations l10n) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _signInEmailController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: l10n.student_email_label,
              hintText: l10n.student_email_hint,
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.empty_field_err;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _signInObscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password_label,
              hintText: l10n.password_hint,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_signInObscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _signInObscurePassword = !_signInObscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.empty_field_err;
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(l10n.forgot_password),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading ? null : _onSignInSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor(context),
              foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.sign_in_btn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _tabController.animateTo(1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(l10n.activate_tab),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  l10n.or_divider.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor(context),
              side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.35), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/phenikaa_logo.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => Icon(Icons.school, color: AppTheme.primaryColor(context), size: 22),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.google_sign_in_btn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.google_sign_in_sub,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationTab(bool isLoading, ColorScheme colorScheme, AppLocalizations l10n) {
    switch (_activationStep) {
      case 2:
        return _buildCheckInfoAndSetPasswordStep(isLoading, colorScheme, l10n);
      case 3:
        return _buildEmailVerificationSentStep(isLoading, colorScheme, l10n);
      case 1:
      default:
        return _buildEnterIdentifierStep(isLoading, colorScheme, l10n);
    }
  }

  Widget _buildEnterIdentifierStep(bool isLoading, ColorScheme colorScheme, AppLocalizations l10n) {
    return Form(
      key: _activationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.blueContainer(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor(context), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.activate_step1_desc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _activationIdentifierController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: l10n.student_email_label,
              hintText: l10n.student_email_hint,
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.empty_field_err;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: isLoading ? null : _onVerifyStudentSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.verify_student_btn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  l10n.or_divider.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor(context),
              side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.35), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/phenikaa_logo.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => Icon(Icons.school, color: AppTheme.primaryColor(context), size: 22),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.google_sign_in_btn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Gợi ý mã SV demo: 23010390, 23010111, 23020015',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInfoAndSetPasswordStep(bool isLoading, ColorScheme colorScheme, AppLocalizations l10n) {
    final student = _currentStudent;
    if (student == null) return const SizedBox.shrink();

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF203864), Color(0xFF2A4A85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDark(context) ? Colors.black38 : AppTheme.navyBlue.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppTheme.orangeAccent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'PHENIKAA UNIVERSITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.student_verified_badge.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.student_id}: ${student.studentId} • K${student.cohort}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Text(
                  '${l10n.faculty}: ${student.faculty}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  '${l10n.major}: ${student.major}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  'Email: ${student.email}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFB088)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: l10n.new_password_label,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) => (val == null || val.length < 6) ? l10n.password_length_err : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: l10n.confirm_password_label,
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val != _newPasswordController.text) {
                return l10n.password_mismatch_err;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: isLoading ? null : _onRegisterWithVerificationLinkSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    l10n.send_activation_link_btn,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resetActivationFlow,
            child: Text(l10n.back_to_step1),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationSentStep(bool isLoading, ColorScheme colorScheme, AppLocalizations l10n) {
    final student = _currentStudent;
    final email = student?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.orangeContainer(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor(context).withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: AppTheme.accentColor(context),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.activation_link_sent_title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor(context),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.blueContainer(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase: $email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app_outlined, color: AppTheme.accentColor(context), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.activation_link_sent_desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _signInEmailController.text = student?.studentId ?? email;
              _signInPasswordController.text = _newPasswordController.text;
              _tabController.animateTo(0);
            });
          },
          icon: const Icon(Icons.login, color: Colors.white),
          label: Text(
            l10n.recheck_verified_btn,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor(context),
            foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  if (student != null) {
                    context.read<AuthCubit>().resendVerificationLink(
                          email: student.email,
                          password: _newPasswordController.text,
                        );
                  }
                },
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.retry),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _resetActivationFlow,
          child: Text(l10n.back_to_step1),
        ),
      ],
    );
  }
}

