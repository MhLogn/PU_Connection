import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroSlideData> _slides = const [
    _IntroSlideData(
      imagePath: 'assets/images/intro_1.jpg',
      badge: 'CỘNG ĐỒNG PHENIKAA',
      title: 'Kết nối sinh viên Phenikaa',
      description:
          'Giao lưu, kết bạn, chia sẻ kinh nghiệm học tập và đời sống sinh viên cùng cộng đồng sinh viên Phenikaa University.',
    ),
    _IntroSlideData(
      imagePath: 'assets/images/intro_2.jpg',
      badge: 'KHO TÀI LIỆU MỞ',
      title: 'Kho Tài Liệu & Trao Đổi Môn Học',
      description:
          'Tra cứu đề cương, slide bài giảng, đề thi phong phú được phân loại trực quan theo từng Viện, Khoa và Mã học phần.',
    ),
    _IntroSlideData(
      imagePath: 'assets/images/intro_3.jpg',
      badge: 'TRỢ LÝ AI & CÂU LẠC BỘ',
      title: 'PU Bot Campus & CLB Năng Động',
      description:
          'Trợ lý ảo giải đáp quy chế tín chỉ 24/7 cùng hàng chục câu lạc bộ học thuật, thể thao và nghệ thuật đang chờ bạn.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _slides.length - 1) {
      context.go('/preference');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo/phenikaa_logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.school_rounded,
                          size: 26,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'PU Connection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor(context),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/preference'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            // Slide Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Realistic Image Container
                        Container(
                          width: double.infinity,
                          height: 230,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: Border.all(
                              color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.isDark(context)
                                    ? Colors.black26
                                    : AppTheme.navyBlue.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Image.asset(
                              slide.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.blueContainer(context),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 50,
                                    color: AppTheme.primaryColor(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeContainer(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accentColor(context).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            slide.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppTheme.accentColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Bar: Indicators & Continue Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        height: 7,
                        width: _currentPage == index ? 26 : 7,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor(context)
                              : colorScheme.onSurface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(context),
                      foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlideData {
  final String imagePath;
  final String badge;
  final String title;
  final String description;

  const _IntroSlideData({
    required this.imagePath,
    required this.badge,
    required this.title,
    required this.description,
  });
}


