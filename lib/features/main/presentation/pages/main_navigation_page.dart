import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/database_seeder.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
            label: l10n.nav_feed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor(context)),
            label: l10n.nav_docs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded, color: AppTheme.accentColor(context)),
            label: l10n.nav_bot,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: AppTheme.primaryColor(context)),
            label: l10n.nav_clubs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor(context)),
            label: l10n.nav_profile,
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

  void _showUploadDocModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    String selectedFaculty = _faculties[1]; // CNTT
    String selectedType = 'pdf';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final colorScheme = Theme.of(ctx).colorScheme;
          final keyboardBottom = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardBottom),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.file_upload_rounded, color: AppTheme.accentColor(context), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            l10n.contribute_dialog_title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.doc_title_label,
                      hintText: l10n.doc_title_hint,
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeController,
                          decoration: InputDecoration(
                            labelText: l10n.course_code_label,
                            hintText: l10n.course_code_hint,
                            prefixIcon: const Icon(Icons.code_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: l10n.doc_type_label,
                            prefixIcon: const Icon(Icons.insert_drive_file_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                            DropdownMenuItem(value: 'docx', child: Text('Word / DOCX')),
                            DropdownMenuItem(value: 'zip', child: Text('ZIP / RAR')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedFaculty,
                    decoration: InputDecoration(
                      labelText: l10n.faculty_label,
                      prefixIcon: const Icon(Icons.apartment_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _faculties
                        .where((f) => f != 'Tất cả')
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedFaculty = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final code = codeController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.doc_name_required)),
                        );
                        return;
                      }

                      setState(() {
                        _documents.insert(0, {
                          'title': title,
                          'code': code.isNotEmpty ? code : 'PU-2026',
                          'faculty': selectedFaculty,
                          'type': selectedType,
                          'size': '3.5 MB',
                          'downloads': 1,
                          'rating': 5.0,
                        });
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.doc_upload_success}: "$title"'),
                          backgroundColor: AppTheme.primaryColor(context),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                    label: Text(l10n.upload_btn, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _downloadDoc(Map<String, dynamic> doc) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.downloading_rounded, color: AppTheme.accentColor(context), size: 26),
            const SizedBox(width: 8),
            Text(l10n.downloading_doc, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Dung lượng: ${doc['size']} • Mã: ${doc['code']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            LinearProgressIndicator(color: AppTheme.primaryColor(context)),
            const SizedBox(height: 8),
            Text(l10n.download_saving, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          doc['downloads'] = (doc['downloads'] as int) + 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.download_complete}: ${doc['title']}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.open_file,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
        title: Text(l10n.docs_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: l10n.contribute_doc_btn,
            onPressed: () => _showUploadDocModal(context),
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
                hintText: l10n.search_docs_hint,
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
                  label: Text(faculty == 'Tất cả' ? l10n.all_courses : faculty),
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
                        Text(l10n.no_docs_found, style: TextStyle(color: colorScheme.outline)),
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
                                          '${doc['downloads']} ${l10n.downloads_count}',
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
                                tooltip: l10n.download,
                                onPressed: () => _downloadDoc(doc),
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
  bool _initialized = false;

  final List<Map<String, String>> _messages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final l10n = AppLocalizations.of(context)!;
      _messages.add({
        'role': 'bot',
        'text': l10n.bot_welcome_msg,
      });
    }
  }

  List<String> _getSuggestions(AppLocalizations l10n) => [
    '💰 ${l10n.bot_quick_scholarship}',
    '📝 ${l10n.bot_quick_regulations}',
    '📚 ${l10n.bot_quick_library}',
    '🏢 ${l10n.bot_quick_dorm}',
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
    final l10n = AppLocalizations.of(context)!;
    final suggestions = _getSuggestions(l10n);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppTheme.accentColor(context), size: 24),
            const SizedBox(width: 8),
            Text(l10n.bot_title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.bot_reset_chat,
            onPressed: () {
              sl<GeminiService>().resetChat();
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'bot',
                  'text': l10n.bot_reset_done,
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
                      l10n.bot_typing,
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
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
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
                      hintText: l10n.bot_input_hint,
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

  String _getCategoryLabel(String cat, AppLocalizations l10n) {
    switch (cat) {
      case 'Tất cả':
        return l10n.all_clubs;
      case 'Học thuật':
        return l10n.academic_clubs;
      case 'Nghệ thuật':
        return l10n.arts_clubs;
      case 'Thể thao':
        return l10n.sports_clubs;
      case 'Tình nguyện':
        return l10n.volunteer_clubs;
      default:
        return cat;
    }
  }

  void _showClubDetailModal(BuildContext context, Map<String, dynamic> club) {
    final color = _getClubColor(context, club['category'] as String);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentJoined = club['isJoined'] as bool;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.diversity_3_rounded, color: color, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            l10n.club_details,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group_work_rounded, color: color, size: 36),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    club['name'] as String,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getCategoryLabel(club['category'] as String, l10n),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${club['members']} ${l10n.club_members}',
                                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.club_overview, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          club['desc'] as String,
                          style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface.withValues(alpha: 0.8), height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        Text(l10n.club_schedule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _buildClubInfoRow(Icons.schedule_rounded, 'Tối Thứ 4 & Chủ Nhật hàng tuần (18h30 - 20h30)', colorScheme),
                        const SizedBox(height: 6),
                        _buildClubInfoRow(Icons.location_on_outlined, 'Tòa A9 (Phòng Hội thảo 2) & Sân thể thao Phenikaa', colorScheme),
                        const SizedBox(height: 18),
                        Text(l10n.club_benefits, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _buildClubInfoRow(Icons.verified_outlined, 'Cộng điểm rèn luyện (ĐRL) tiêu chí Hoạt động phong trào', colorScheme),
                        const SizedBox(height: 6),
                        _buildClubInfoRow(Icons.card_membership_rounded, 'Cấp chứng nhận thành viên và cơ hội thi đấu cấp toàn quốc', colorScheme),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setModalState(() {
                        club['isJoined'] = !currentJoined;
                        if (club['isJoined']) {
                          club['members'] = (club['members'] as int) + 1;
                        } else {
                          club['members'] = (club['members'] as int) - 1;
                        }
                      });
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            club['isJoined']
                                ? l10n.join_success
                                : '${l10n.leave_club}: "${club['name']}".',
                          ),
                          backgroundColor: club['isJoined'] ? Colors.green : Colors.grey.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentJoined ? Colors.red.shade700 : AppTheme.accentColor(context),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      currentJoined ? l10n.leave_club : l10n.join_club,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubInfoRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final filteredClubs = _clubs.where((club) {
      return _selectedCategory == 'Tất cả' || club['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.clubs_title),
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
                  label: Text(_getCategoryLabel(cat, l10n)),
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
                  child: InkWell(
                    onTap: () => _showClubDetailModal(context, club),
                    borderRadius: BorderRadius.circular(16),
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
                                    '${_getCategoryLabel(club['category'] as String, l10n)} • ${club['members']} ${l10n.club_members}',
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
                                isJoined ? l10n.joined_club : l10n.join_club,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.profile_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.logout,
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
                    label: Text(l10n.logout, style: const TextStyle(color: Colors.white)),
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
          return Center(child: Text(l10n.not_logged_in));
        },
      ),
    );
  }

  Widget _buildDigitalStudentCard(BuildContext context, UserEntity user) {
    final l10n = AppLocalizations.of(context)!;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.university_name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        l10n.digital_student_card,
                        style: const TextStyle(color: Color(0xFFFFB088), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showStudentQrModal(context, user),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 28),
                ),
              ),
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
                      '${l10n.student_id}: ${user.studentId.isNotEmpty ? user.studentId : '23010390'} • K${user.cohort != 0 ? user.cohort : 17}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    Text(
                      '${l10n.faculty}: ${user.faculty.isNotEmpty ? user.faculty : 'Công nghệ thông tin'}',
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
                    l10n.student_verified_badge.toUpperCase(),
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
    final l10n = AppLocalizations.of(context)!;

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
            _buildStatItem(l10n.gpa_accumulated, '3.48', '/4.0', AppTheme.primaryColor(context)),
            Container(height: 36, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            _buildStatItem(l10n.credits_accumulated, '54', '/135', AppTheme.accentColor(context)),
            Container(height: 36, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            _buildStatItem(l10n.training_points, '92', l10n.training_excellent, AppTheme.mintColor(context)),
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final languageName = currentLocale == 'vi' ? l10n.vietnamese : l10n.english;

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
            title: Text(l10n.dark_theme_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.dark_theme_desc, style: const TextStyle(fontSize: 12)),
            value: isDark,
            onChanged: (val) {
              context.read<ThemeCubit>().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.language_rounded, color: AppTheme.primaryColor(context)),
            title: Text(l10n.language, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(languageName, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePickerModal(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor(context)),
            title: Text(l10n.about_pu, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.app_version, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePickerModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.select_language,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                  title: Text(l10n.vietnamese),
                  trailing: currentLocale == 'vi'
                      ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor(context))
                      : null,
                  onTap: () {
                    context.read<LocaleCubit>().setLocale(const Locale('vi'));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: Text(l10n.english),
                  trailing: currentLocale == 'en'
                      ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor(context))
                      : null,
                  onTap: () {
                    context.read<LocaleCubit>().setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStudentQrModal(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/phenikaa_logo.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.university_name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 160, color: Color(0xFF203864)),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.student_id}: ${user.studentId.isNotEmpty ? user.studentId : '23010390'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF203864)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${user.faculty.isNotEmpty ? user.faculty : 'Công nghệ thông tin'} • K${user.cohort != 0 ? user.cohort : 17}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.blueContainer(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.student_qr_desc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor(context), height: 1.3),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.close, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout_confirm_title),
        content: Text(l10n.logout_confirm_desc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(l10n.logout, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

