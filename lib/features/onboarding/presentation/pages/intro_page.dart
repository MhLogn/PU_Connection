import 'package:flutter/material.dart';
import 'package:pu_connection/l10n/app_localizations.dart';
import 'preference_page.dart';

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

  void _onNext() {
    if (_currentPage == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PreferencePage()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildIntroContent(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    title: t.intro1_title,
                    description: t.intro1_desc,
                  ),
                  _buildIntroContent(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    title: t.intro2_title,
                    description: t.intro2_desc,
                  ),
                  _buildIntroContent(
                    context: context,
                    icon: Icons.group_work_rounded,
                    title: t.intro3_title,
                    description: t.intro3_desc,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.secondary
                              : colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      key: ValueKey<int>(_currentPage),
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: _currentPage == 2 ? 4 : 0,
                      ),
                      child: Text(
                        _currentPage == 2 ? t.start_btn : t.continue_btn,
                      ),
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

  Widget _buildIntroContent({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 96, color: colorScheme.primary),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
