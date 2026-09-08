import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/database_seeder.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSeedData();
    });
  }

  void _autoSeedData() {
    final authState = context.read<AuthCubit>().state;
    UserEntity? user;
    if (authState is Authenticated) {
      user = authState.user;
    }
    DatabaseSeeder.seedAllData(currentUser: user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> pages = [
      const FeedPage(),
      const _DocsHubView(),
      const _PuBotChatView(),
      const _ClubsCommunityView(),
      const _StudentProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: colorScheme.surface,
        indicatorColor: AppTheme.blueContainer(context),
        elevation: 3,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryColor(context)),
            label: 'Bảng tin',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor(context)),
            label: 'Tài liệu',
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded, color: AppTheme.accentColor(context)),
            label: 'PU Bot',
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: AppTheme.primaryColor(context)),
            label: 'Nhóm & CLB',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor(context)),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// ================= TAB 1: KHO TÀI LIỆU (DOCS HUB) =================
class _DocsHubView extends StatefulWidget {
  const _DocsHubView();

  @override
  State<_DocsHubView> createState() => _DocsHubViewState();
}

class _DocsHubViewState extends State<_DocsHubView> {
  String _selectedFaculty = 'Tất cả';
  final _searchController = TextEditingController();

  final List<String> _faculties = [
    'Tất cả',
    'CNTT',
    'Dược - Y',
    'Kinh tế & QTKD',
    'Kỹ thuật Ô tô',
    'Ngôn ngữ Anh',
  ];

  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Đề cương & Ngân hàng trắc nghiệm Lập trình Mạng',
      'code': 'CNTT-225',
      'faculty': 'CNTT',
      'type': 'pdf',
      'size': '4.2 MB',
      'downloads': 1240,
      'rating': 4.9,
    },
    {
      'title': 'Slide bài giảng Cơ sở dữ liệu & SQL Nâng cao',
      'code': 'CSDL-101',
      'faculty': 'CNTT',
      'type': 'docx',
      'size': '8.5 MB',
      'downloads': 980,
      'rating': 4.8,
    },
    {
      'title': 'Bộ đề thi thử Xác suất Thống kê có lời giải chi tiết',
      'code': 'XSTK-01',
      'faculty': 'Kinh tế & QTKD',
      'type': 'pdf',
      'size': '2.8 MB',
      'downloads': 1560,
      'rating': 5.0,
    },
    {
      'title': 'Dược lý học đại cương & Tổng hợp tương tác thuốc',
      'code': 'DUOC-102',
      'faculty': 'Dược - Y',
      'type': 'pdf',
      'size': '6.1 MB',
      'downloads': 620,
      'rating': 4.7,
    },
    {
      'title': 'Tổng hợp từ vựng & đề thi Tiếng Anh B1 Vstep Phenikaa',
      'code': 'ENG-B1',
      'faculty': 'Ngôn ngữ Anh',
      'type': 'zip',
      'size': '15.3 MB',
      'downloads': 2100,
      'rating': 4.9,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredDocs = _documents.where((doc) {
      final matchesFaculty = _selectedFaculty == 'Tất cả' || doc['faculty'] == _selectedFaculty;
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          (doc['title'] as String).toLowerCase().contains(query) ||
          (doc['code'] as String).toLowerCase().contains(query);
      return matchesFaculty && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Kho Tài Liệu Học Tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Đóng góp tài liệu',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng đóng góp tài liệu: Vui lòng chọn tệp từ thiết bị.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm giáo trình, slide, đề thi theo môn...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _faculties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final faculty = _faculties[index];
                final isSelected = faculty == _selectedFaculty;
                return ChoiceChip(
                  label: Text(faculty),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor(context),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (AppTheme.isDark(context) ? Colors.black87 : Colors.white)
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedFaculty = faculty);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredDocs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('Không tìm thấy tài liệu phù hợp', style: TextStyle(color: colorScheme.outline)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final isPdf = doc['type'] == 'pdf';
                      final isZip = doc['type'] == 'zip';
                      final iconColor = isPdf
                          ? AppTheme.coralColor(context)
                          : isZip
                              ? AppTheme.accentColor(context)
                              : AppTheme.primaryColor(context);
                      final containerBg = isZip
                          ? AppTheme.orangeContainer(context)
                          : isPdf
                              ? AppTheme.coralColor(context).withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.1)
                              : AppTheme.blueContainer(context);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        color: colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: containerBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : isZip
                                          ? Icons.folder_zip_rounded
                                          : Icons.description_rounded,
                                  color: iconColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.blueContainer(context),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            doc['code'] as String,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor(context),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${doc['faculty']}',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      doc['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          doc['size'] as String,
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${doc['downloads']}',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.star_rounded, size: 14, color: AppTheme.amberColor(context)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${doc['rating']}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.download_for_offline_rounded, color: AppTheme.primaryColor(context), size: 28),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đang tải "${doc['title']}" về máy...'),
                                      backgroundColor: AppTheme.primaryColor(context),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 2: PU BOT (CAMPUS AI ASSISTANT) =================
class _PuBotChatView extends StatefulWidget {
  const _PuBotChatView();

  @override
  State<_PuBotChatView> createState() => _PuBotChatViewState();
}

class _PuBotChatViewState extends State<_PuBotChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text':
          'Chào bạn! Mình là **PU Assistant** — Trợ lý ảo sinh viên Trường Đại học Phenikaa. 🎓\n\nMình có thể hỗ trợ bạn về quy chế tín chỉ, học bổng, lịch thi, khuôn viên trường hoặc các CLB sinh viên.',
    },
  ];

  final List<String> _suggestions = [
    '💰 Học bổng kỳ này',
    '📝 Cách đăng ký tín chỉ',
    '📅 Lịch thi & tra điểm',
    '🏢 Sơ đồ giảng đường A9-A10',
    '📚 Giờ mở cửa thư viện',
    '✨ Các CLB tại Phenikaa',
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _msgController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isTyping = true;
    });

    _scrollToBottom();

    final geminiService = sl<GeminiService>();
    final reply = await geminiService.sendMessage(query);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'bot', 'text': reply});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppTheme.accentColor(context), size: 24),
            const SizedBox(width: 8),
            const Text('PU Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới đoạn chat',
            onPressed: () {
              sl<GeminiService>().resetChat();
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'bot',
                  'text': 'Đã làm mới phiên hội thoại. Mình có thể giúp gì cho bạn?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (AppTheme.isDark(context) ? const Color(0xFF1D4ED8) : AppTheme.primaryBlue)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isUser ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor(context)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PU Assistant đang trả lời...',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ActionChip(
                  label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.25)),
                  onPressed: () => _sendMessage(suggestion),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            color: colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (text) => _sendMessage(text),
                    decoration: InputDecoration(
                      hintText: 'Hỏi PU Assistant bất kỳ câu hỏi nào...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor(context),
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_msgController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 3: NHÓM & CLB (COMMUNITY) =================
class _ClubsCommunityView extends StatefulWidget {
  const _ClubsCommunityView();

  @override
  State<_ClubsCommunityView> createState() => _ClubsCommunityViewState();
}

class _ClubsCommunityViewState extends State<_ClubsCommunityView> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Học thuật',
    'Nghệ thuật',
    'Thể thao',
    'Tình nguyện',
  ];

  final List<Map<String, dynamic>> _clubs = [
    {
      'name': 'CLB Tin Học Phenikaa PRO',
      'category': 'Học thuật',
      'members': 480,
      'isJoined': true,
      'desc': 'Cộng đồng đam mê lập trình phần mềm, an toàn thông tin & AI trường Phenikaa.',
      'color': 0xFF203864,
    },
    {
      'name': 'Phenikaa English Club (PEC)',
      'category': 'Học thuật',
      'members': 620,
      'isJoined': false,
      'desc': 'Môi trường giao tiếp tiếng Anh tự tin, workshop IELTS và săn học bổng du học.',
      'color': 0xFF203864,
    },
    {
      'name': 'Phenikaa Guitar Club (PGC)',
      'category': 'Nghệ thuật',
      'members': 350,
      'isJoined': false,
      'desc': 'Nơi hội tụ những tâm hồn yêu âm nhạc acoustic, biểu diễn trong các đêm gala trường.',
      'color': 0xFFF76B1C,
    },
    {
      'name': 'Phenikaa Basketball Club',
      'category': 'Thể thao',
      'members': 290,
      'isJoined': false,
      'desc': 'Luyện tập thể lực, thi đấu giao hữu các giải bóng rổ sinh viên toàn Hà Nội.',
      'color': 0xFF203864,
    },
    {
      'name': 'Đội Sinh Viên Tình Nguyện PU',
      'category': 'Tình nguyện',
      'members': 540,
      'isJoined': false,
      'desc': 'Tiếp sức mùa thi, Mùa hè xanh và các chiến dịch thiện nguyện vì cộng đồng.',
      'color': 0xFFF76B1C,
    },
  ];

  Color _getClubColor(BuildContext context, String category) {
    switch (category) {
      case 'Học thuật':
        return AppTheme.primaryColor(context);
      case 'Nghệ thuật':
        return AppTheme.accentColor(context);
      case 'Thể thao':
        return AppTheme.coralColor(context);
      case 'Tình nguyện':
        return AppTheme.mintColor(context);
      default:
        return AppTheme.violetColor(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredClubs = _clubs.where((club) {
      return _selectedCategory == 'Tất cả' || club['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Nhóm & Câu Lạc Bộ'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor(context),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (AppTheme.isDark(context) ? Colors.black87 : Colors.white)
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: filteredClubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final club = filteredClubs[index];
                final isJoined = club['isJoined'] as bool;
                final color = _getClubColor(context, club['category'] as String);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group_work_rounded, color: color, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    club['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    '${club['category']} • ${club['members']} thành viên',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  club['isJoined'] = !isJoined;
                                  if (club['isJoined']) {
                                    club['members'] = (club['members'] as int) + 1;
                                  } else {
                                    club['members'] = (club['members'] as int) - 1;
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isJoined
                                    ? AppTheme.primaryColor(context).withValues(
                                        alpha: AppTheme.isDark(context) ? 0.2 : 0.08,
                                      )
                                    : null,
                                side: BorderSide(
                                  color: AppTheme.primaryColor(context).withValues(alpha: isJoined ? 0.4 : 1.0),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text(
                                isJoined ? 'Đã tham gia' : 'Tham gia',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          club['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 4: HỒ SƠ & THẺ SINH VIÊN (PROFILE) =================
class _StudentProfileView extends StatelessWidget {
  const _StudentProfileView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Hồ Sơ Sinh Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDigitalStudentCard(context, user),
                  const SizedBox(height: 16),
                  _buildAcademicOverviewCard(context),
                  const SizedBox(height: 16),
                  _buildSettingsSection(context, colorScheme),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const Center(child: Text('Chưa đăng nhập'));
        },
      ),
    );
  }

  Widget _buildDigitalStudentCard(BuildContext context, UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF203864), Color(0xFF162846)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context) ? Colors.black38 : AppTheme.navyBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  Image.asset(
                    'assets/logo/phenikaa_logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐẠI HỌC PHENIKAA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'THẺ SINH VIÊN ĐIỆN TỬ',
                        style: TextStyle(color: Color(0xFFFFB088), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.qr_code_rounded, color: Colors.white70, size: 36),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.accentColor(context),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã SV: ${user.studentId.isNotEmpty ? user.studentId : '23010390'} • K${user.cohort != 0 ? user.cohort : 17}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    Text(
                      'Khoa: ${user.faculty.isNotEmpty ? user.faculty : 'Công nghệ thông tin'}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.email,
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.mintColor(context), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'ĐÃ XÁC THỰC',
                    style: TextStyle(color: AppTheme.mintColor(context), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicOverviewCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('GPA Tích lũy', '3.48', '/4.0', AppTheme.primaryColor(context)),
            Container(height: 36, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            _buildStatItem('Tín chỉ', '54', '/135', AppTheme.accentColor(context)),
            Container(height: 36, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            _buildStatItem('Điểm rèn luyện', '92', 'Xuất sắc', AppTheme.mintColor(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      color: colorScheme.surface,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: AppTheme.primaryColor(context)),
            title: const Text('Giao diện tối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Chuyển đổi giao diện sáng / tối', style: TextStyle(fontSize: 12)),
            value: isDark,
            onChanged: (val) {
              context.read<ThemeCubit>().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.language_rounded, color: AppTheme.primaryColor(context)),
            title: const Text('Ngôn ngữ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Tiếng Việt (Mặc định)', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.read<LocaleCubit>().setLocale(const Locale('vi'));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor(context)),
            title: const Text('Về PU Connection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Phiên bản 1.0.0 • Phenikaa University', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

