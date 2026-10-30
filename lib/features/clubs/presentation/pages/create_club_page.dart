import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/bad_words_filter_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/club_creation_request_entity.dart';
import '../cubit/club_cubit.dart';
import '../cubit/club_state.dart';

class CreateClubPage extends StatefulWidget {
  const CreateClubPage({super.key});

  @override
  State<CreateClubPage> createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateClubPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'Học thuật';
  final List<String> _categories = [
    'Học thuật',
    'Nghệ thuật',
    'Thể thao',
    'Tình nguyện',
    'Kỹ năng',
    'Khác',
  ];

  String? _logoUrl;
  String? _coverUrl;
  bool _isUploadingLogo = false;
  bool _isUploadingCover = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage({required bool isLogo}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isLogo ? 600 : 1200,
        maxHeight: isLogo ? 600 : 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      final name = picked.name.toLowerCase();
      final ext = name.split('.').last;
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Định dạng ảnh không hợp lệ (chỉ hỗ trợ JPG, PNG, WEBP)'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bytesLength = await picked.length();
      if (bytesLength > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dung lượng ảnh vượt quá giới hạn cho phép (tối đa 5MB)'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        if (isLogo) {
          _isUploadingLogo = true;
        } else {
          _isUploadingCover = true;
        }
      });

      final cloudinary = sl<CloudinaryService>();
      final url = await cloudinary.uploadXFile(
        picked,
        folder: 'pu_connection/clubs',
      );

      if (!mounted) return;

      setState(() {
        if (isLogo) {
          _logoUrl = url;
          _isUploadingLogo = false;
        } else {
          _coverUrl = url;
          _isUploadingCover = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogo ? 'Đã tải lên ảnh đại diện CLB!' : 'Đã tải lên ảnh bìa CLB!',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isLogo) {
          _isUploadingLogo = false;
        } else {
          _isUploadingCover = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải ảnh thất bại: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    // Tiền kiểm duyệt ngôn từ vi phạm (Bad Words Filter) các trường đề xuất CLB
    if (sl.isRegistered<BadWordsFilterService>()) {
      final filter = sl<BadWordsFilterService>();

      final nameCheck = filter.check(_nameController.text.trim(), actionLabel: 'gửi đề xuất CLB');
      if (!nameCheck.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tên CLB chứa từ ngữ không phù hợp: ${nameCheck.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final reasonCheck = filter.check(_reasonController.text.trim(), actionLabel: 'gửi đề xuất CLB');
      if (!reasonCheck.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mục đích thành lập CLB chứa từ ngữ không phù hợp: ${reasonCheck.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final descCheck = filter.check(_descriptionController.text.trim(), actionLabel: 'gửi đề xuất CLB');
      if (!descCheck.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mô tả hoạt động CLB chứa từ ngữ không phù hợp: ${descCheck.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final locationCheck = filter.check(_locationController.text.trim(), actionLabel: 'gửi đề xuất CLB');
      if (!locationCheck.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Địa điểm sinh hoạt chứa từ ngữ không phù hợp: ${locationCheck.detectedWords.join(", ")}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để gửi yêu cầu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = authState.user;
    final request = ClubCreationRequestEntity(
      id: '',
      clubName: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      reason: _reasonController.text.trim(),
      schedule: _scheduleController.text.trim(),
      location: _locationController.text.trim(),
      founderId: user.uid,
      founderName: user.displayName.isNotEmpty
          ? user.displayName
          : user.email,
      founderStudentId: user.studentId,
      founderEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : user.email,
      contactEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : user.email,
      contactPhone: _phoneController.text.trim(),
      avatarUrl: _logoUrl ?? '',
      coverUrl: _coverUrl ?? '',
      createdAt: DateTime.now(),
      status: 'pending',
    );

    _showPreviewAndConfirmDialog(request);
  }

  void _showPreviewAndConfirmDialog(ClubCreationRequestEntity request) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.preview_club_proposal_title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.oceanBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.oceanBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryColor(ctx),
                              backgroundImage: request.avatarUrl.isNotEmpty
                                  ? NetworkImage(request.avatarUrl)
                                  : null,
                              child: request.avatarUrl.isEmpty
                                  ? const Icon(Icons.groups_rounded, color: Colors.white, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.clubName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor(ctx),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      request.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPreviewItem('Người sáng lập / Trưởng ban vận động', '${request.founderName} (${request.founderStudentId})'),
                      _buildPreviewItem('Email & Số điện thoại', '${request.founderEmail} • ${request.contactPhone.isNotEmpty ? request.contactPhone : "Chưa cung cấp"}'),
                      _buildPreviewItem('Mô tả tôn chỉ & Hoạt động', request.description),
                      _buildPreviewItem('Lý do thành lập & Kế hoạch 3 tháng', request.reason),
                      _buildPreviewItem('Lịch sinh hoạt dự kiến', request.schedule),
                      _buildPreviewItem('Địa điểm sinh hoạt dự kiến', request.location),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.edit_proposal_btn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await context.read<ClubCubit>().submitClubCreationRequest(request);
                        if (success && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(ctx),
                        foregroundColor: isDark ? Colors.black87 : Colors.white,
                      ),
                      child: Text(
                        l10n.confirm_submit_proposal_btn,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          'Đăng Ký Thành Lập CLB',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<ClubCubit, ClubState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Header Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.oceanBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.oceanBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.oceanBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hồ sơ đăng ký thành lập Câu lạc bộ sinh viên sẽ được gửi tới Ban Quản Trị / Đoàn Thanh Niên Phenikaa xem xét và phê duyệt trước khi công khai.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.85),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Basic Information
                  _buildSectionHeader('1. Thông tin chung câu lạc bộ'),
                  const SizedBox(height: 12),

                  // Club Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Tên câu lạc bộ *',
                    hintText: 'VD: CLB Lập trình Phenikaa (PU CodeClub)',
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên câu lạc bộ';
                      }
                      if (val.trim().length < 4) {
                        return 'Tên câu lạc bộ phải có ít nhất 4 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  Text(
                    'Lĩnh vực hoạt động *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor(context),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.black87 : Colors.white)
                              : colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Mô tả tôn chỉ & Hoạt động chính *',
                    hintText:
                        'Mô tả mục tiêu, định hướng phát triển và các hoạt động cốt lõi của CLB...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả câu lạc bộ';
                      }
                      if (val.trim().length < 20) {
                        return 'Mô tả cần chi tiết hơn (ít nhất 20 ký tự)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Reason
                  _buildTextField(
                    controller: _reasonController,
                    label: 'Lý do thành lập & Kế hoạch ban đầu *',
                    hintText:
                        'Tại sao cần thành lập CLB này? Kế hoạch tuyển thành viên và sinh hoạt trong 3 tháng đầu...',
                    prefixIcon: Icons.lightbulb_outline_rounded,
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nêu lý do thành lập và kế hoạch dự kiến';
                      }
                      if (val.trim().length < 15) {
                        return 'Lý do cần cụ thể hơn (ít nhất 15 ký tự)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Meeting Schedule & Venue
                  _buildSectionHeader('2. Lịch sinh hoạt & Địa điểm dự kiến'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _scheduleController,
                    label: 'Thời gian sinh hoạt *',
                    hintText: 'VD: Thứ 5 hàng tuần, 17:30 - 19:30',
                    prefixIcon: Icons.calendar_month_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập thời gian sinh hoạt dự kiến';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _locationController,
                    label: 'Địa điểm sinh hoạt *',
                    hintText: 'VD: Phòng A9-301 hoặc Khu tự học Giảng đường A9',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập địa điểm sinh hoạt dự kiến';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Contact Details
                  _buildSectionHeader('3. Thông tin liên hệ ban vận động'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email liên hệ CLB',
                    hintText: 'VD: pu.codeclub@phenikaa-uni.edu.vn',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại liên hệ (Trưởng ban vận động)',
                    hintText: 'VD: 0987654321',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Images (Optional)
                  _buildSectionHeader('4. Hình ảnh đại diện & Ảnh bìa (Tùy chọn)'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Logo upload box
                      Expanded(
                        child: _buildImageUploadTile(
                          title: 'Ảnh Logo CLB',
                          imageUrl: _logoUrl,
                          isLoading: _isUploadingLogo,
                          onPick: () => _pickAndUploadImage(isLogo: true),
                          onRemove: () => setState(() => _logoUrl = null),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Cover upload box
                      Expanded(
                        child: _buildImageUploadTile(
                          title: 'Ảnh Bìa CLB',
                          imageUrl: _coverUrl,
                          isLoading: _isUploadingCover,
                          onPick: () => _pickAndUploadImage(isLogo: false),
                          onRemove: () => setState(() => _coverUrl = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: state.isSubmitting ? null : _submitProposal,
                      icon: state.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        state.isSubmitting
                            ? 'Đang gửi hồ sơ...'
                            : 'Xem Trước & Gửi Đề Xuất CLB',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(context),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: isDark ? Colors.white60 : AppTheme.oceanBlue,
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerHighest
                : AppTheme.borderSubtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : AppTheme.borderLight,
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : AppTheme.borderLight,
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppTheme.primaryColor(context),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadTile({
    required String title,
    required String? imageUrl,
    required bool isLoading,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: isLoading ? null : onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white10 : AppTheme.borderLight,
                width: 0.8,
              ),
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : imageUrl != null && imageUrl.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 28,
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Chọn ảnh',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
