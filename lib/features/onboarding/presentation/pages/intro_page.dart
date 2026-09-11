import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int totalSlides) {
    if (_currentPage == totalSlides - 1) {
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
    final l10n = AppLocalizations.of(context)!;

    final slides = [
      _IntroSlideData(
        imagePath: 'assets/images/intro_1.jpg',
        badge: l10n.intro1_badge,
        title: l10n.intro1_title,
        description: l10n.intro1_desc,
      ),
      _IntroSlideData(
        imagePath: 'assets/images/intro_2.jpg',
        badge: l10n.intro2_badge,
        title: l10n.intro2_title,
        description: l10n.intro2_desc,
      ),
      _IntroSlideData(
        imagePath: 'assets/images/intro_3.jpg',
        badge: l10n.intro3_badge,
        title: l10n.intro3_title,
        description: l10n.intro3_desc,
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
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
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      slides.length,
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
                  ElevatedButton(
                    onPressed: () => _onNext(slides.length),
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
                          _currentPage == slides.length - 1 ? l10n.start_btn : l10n.continue_btn,
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


