import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập Mã SV hoặc Email sinh viên (@st.phenikaa-uni.edu.vn) để nhận liên kết đặt lại mật khẩu:',
              style: TextStyle(fontSize: 14),
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthCubit>().sendPasswordReset(email);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Gửi yêu cầu'),
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
                          tabs: const [
                            Tab(text: 'Đăng nhập'),
                            Tab(text: 'Kích hoạt tài khoản'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _tabController.index == 0
                              ? _buildSignInTab(isLoading, colorScheme)
                              : _buildActivationTab(isLoading, colorScheme);
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

  // ================= TAB 1: ĐĂNG NHẬP =================
  Widget _buildSignInTab(bool isLoading, ColorScheme colorScheme) {
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
              labelText: 'Mã SV hoặc Email trường',
              hintText: 'Ví dụ: 23010390',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mã sinh viên hoặc email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _signInObscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_signInObscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _signInObscurePassword = !_signInObscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Quên mật khẩu?'),
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
                : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _tabController.animateTo(1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Chưa kích hoạt tài khoản? Kích hoạt ngay'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'HOẶC',
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
                const Flexible(
                  child: Text(
                    'Đăng nhập bằng Google sinh viên (@st.phenikaa-uni.edu.vn)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '1 chạm bằng email trường cấp (@st.phenikaa-uni.edu.vn)',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: KÍCH HOẠT TÀI KHOẢN =================
  Widget _buildActivationTab(bool isLoading, ColorScheme colorScheme) {
    switch (_activationStep) {
      case 2:
        return _buildCheckInfoAndSetPasswordStep(isLoading, colorScheme);
      case 3:
        return _buildEmailVerificationSentStep(isLoading, colorScheme);
      case 1:
      default:
        return _buildEnterIdentifierStep(isLoading, colorScheme);
    }
  }

  // Bước 1: Nhập Mã sinh viên để tra cứu danh mục trường
  Widget _buildEnterIdentifierStep(bool isLoading, ColorScheme colorScheme) {
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
                    'Nhập Mã sinh viên để tra cứu dữ liệu trường Phenikaa. Sau khi thiết lập mật khẩu, Firebase sẽ gửi liên kết xác thực chính chủ đến hộp thư của bạn.',
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
              labelText: 'Mã sinh viên hoặc Email Phenikaa',
              hintText: 'Ví dụ: 23010390',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập mã sinh viên của bạn';
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
                : const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'HOẶC',
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
                const Text(
                  'Đăng nhập 1 chạm bằng Google sinh viên',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  // Bước 2: Thẻ sinh viên điện tử & Đặt mật khẩu mới
  Widget _buildCheckInfoAndSetPasswordStep(bool isLoading, ColorScheme colorScheme) {
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
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.orangeAccent, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'THẺ SINH VIÊN PHENIKAA',
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
                      child: const Text(
                        'ĐÃ XÁC THỰC',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  'MSV: ${student.studentId} • Khóa: K${student.cohort}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Text(
                  'Khoa: ${student.faculty}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  'Ngành: ${student.major}',
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
              labelText: 'Thiết lập mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) => (val == null || val.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'Nhập lại mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
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
                : const Text(
                    'Kích hoạt & Nhận link xác thực email',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resetActivationFlow,
            child: const Text('Quay lại tra cứu mã khác'),
          ),
        ],
      ),
    );
  }

  // Bước 3: Đã gửi link xác thực Firebase
  Widget _buildEmailVerificationSentStep(bool isLoading, ColorScheme colorScheme) {
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
          'Liên kết xác thực đã được gửi!',
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
                'Firebase đã gửi email xác thực chính thức đến hộp thư:',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app_outlined, color: AppTheme.accentColor(context), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng mở hộp thư Outlook hoặc Gmail của trường Phenikaa và bấm vào đường link trong email để kích hoạt tài khoản.',
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
          label: const Text(
            'Tôi đã bấm link (Đăng nhập ngay)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
          label: const Text('Gửi lại link xác thực'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _resetActivationFlow,
          child: const Text('Đổi mã sinh viên khác'),
        ),
      ],
    );
  }
}

