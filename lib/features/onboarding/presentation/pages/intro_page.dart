import 'package:flutter/material.dart';
import 'package:pu_connection/features/auth/presentation/pages/login_page.dart';

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
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    icon: Icons.people_alt_outlined,
                    title: 'Kết nối sinh viên Phenikaa',
                    description:
                        'Mạng xã hội dành riêng cho sinh viên Phenikaa, giúp bạn dễ dàng kết nối và trao đổi kinh nghiệm.',
                  ),
                  _buildIntroContent(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    title: 'Chia sẻ tài liệu học tập',
                    description:
                        'Chia sẻ thông tin, bài giảng, slide và tài liệu học tập một cách thông minh và tiện lợi.',
                  ),
                  _buildIntroContent(
                    context: context,
                    icon: Icons.group_work_outlined,
                    title: 'Cộng đồng & Nhóm học tập',
                    description:
                        'Tạo nhóm riêng tư, quản lý bảng tin nhóm và được hỗ trợ bởi Chatbot Campus Assistant.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.secondary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onNext,
                    child: Text(_currentPage == 2 ? 'Bắt đầu' : 'Tiếp tục'),
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
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: colorScheme.primary),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
