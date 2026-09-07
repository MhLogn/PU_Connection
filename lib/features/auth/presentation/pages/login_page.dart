import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Sign In
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInObscurePassword = true;

  // Controllers for Sign Up
  final _signUpFormKey = GlobalKey<FormState>();
  final _signUpNameController = TextEditingController();
  final _signUpStudentIdController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  String _selectedFaculty = 'Công nghệ thông tin';
  final _signUpMajorController = TextEditingController();
  bool _signUpObscurePassword = true;

  final List<String> _faculties = [
    'Công nghệ thông tin',
    'Kỹ thuật Ô tô & Năng lượng',
    'Điện - Điện tử',
    'Cơ khí - Cơ điện tử',
    'Kinh tế & Kinh doanh',
    'Ngôn ngữ Hàn Quốc',
    'Ngôn ngữ Trung Quốc',
    'Ngôn ngữ Anh',
    'Dược',
    'Điều dưỡng',
    'Y khoa',
    'Khoa học cơ bản',
  ];

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
    _signUpNameController.dispose();
    _signUpStudentIdController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signUpMajorController.dispose();
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

  void _onSignUpSubmitted() {
    if (_signUpFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUp(
            email: _signUpEmailController.text.trim(),
            password: _signUpPasswordController.text,
            studentId: _signUpStudentIdController.text.trim(),
            displayName: _signUpNameController.text.trim(),
            faculty: _selectedFaculty,
            major: _signUpMajorController.text.trim(),
          );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email sinh viên (@phenikaa-uni.edu.vn) để nhận liên kết đặt lại mật khẩu:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'mã_sv@phenikaa-uni.edu.vn',
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
              if (email.isNotEmpty && email.endsWith(FirebaseConstants.phenikaaEmailDomain)) {
                context.read<AuthCubit>().sendPasswordReset(email);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đúng email @phenikaa-uni.edu.vn'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Gửi email'),
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
          } else if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chào mừng ${state.user.displayName}!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo/phenikaa_logo.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school,
                                size: 80,
                                color: AppTheme.navyBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'PU Connection',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mạng xã hội sinh viên Phenikaa',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Bar (Đăng nhập / Đăng ký)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.navyBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade700,
                          tabs: const [
                            Tab(text: 'Đăng nhập'),
                            Tab(text: 'Đăng ký'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab Views
                      SizedBox(
                        height: 520,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSignInTab(isLoading),
                            _buildSignUpTab(isLoading),
                          ],
                        ),
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

  Widget _buildSignInTab(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email sinh viên',
              hintText: 'mã_sv@phenikaa-uni.edu.vn',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.trim().endsWith(FirebaseConstants.phenikaaEmailDomain)) {
                return 'Phải là email @phenikaa-uni.edu.vn';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _onSignInSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Đăng nhập', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Chỉ hỗ trợ tài khoản email trường Phenikaa',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab(bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _signUpNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _signUpStudentIdController,
                    decoration: InputDecoration(
                      labelText: 'Mã SV/GV',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Nhập mã SV' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _signUpMajorController,
                    decoration: InputDecoration(
                      labelText: 'Chuyên ngành',
                      prefixIcon: const Icon(Icons.book_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFaculty,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Khoa / Viện',
                prefixIcon: const Icon(Icons.domain_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _faculties.map((faculty) {
                return DropdownMenuItem(value: faculty, child: Text(faculty, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFaculty = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Phenikaa',
                hintText: 'mã_sv@phenikaa-uni.edu.vn',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                if (!val.trim().endsWith(FirebaseConstants.phenikaaEmailDomain)) {
                  return 'Bắt buộc dùng đuôi @phenikaa-uni.edu.vn';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _signUpObscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_signUpObscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _signUpObscurePassword = !_signUpObscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => (val == null || val.length < 6) ? 'Tối thiểu 6 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: _signUpObscurePassword,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val != _signUpPasswordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _onSignUpSubmitted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Đăng ký tài khoản', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
