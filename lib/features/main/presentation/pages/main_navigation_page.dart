import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/database_seeder.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../documents/presentation/pages/docs_hub_page.dart';
import '../../../documents/presentation/cubit/document_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';

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
      BlocProvider(
        create: (_) => sl<DocumentCubit>(),
        child: const DocsHubPage(),
      ),
      const _PuBotChatView(),
      const _ClubsCommunityView(),
      const _StudentProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.blueContainer(context),
          elevation: 0,
          height: 66,
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
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                if (isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.isDark(context)
                              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                              : [const Color(0xFF203864), const Color(0xFF2E5088)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor(context).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF76B1C), Color(0xFFFF8E42)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF76B1C).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF76B1C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.bot_typing,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ActionChip(
                  label: Text(suggestion, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.25)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(suggestion),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (text) => _sendMessage(text),
                      decoration: InputDecoration(
                        hintText: l10n.bot_input_hint,
                        hintStyle: TextStyle(fontSize: 13.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF76B1C), Color(0xFFFF8E42)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF76B1C).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
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
                      _toggleJoinClub(club);
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

  Future<void> _toggleJoinClub(Map<String, dynamic> club) async {
    final currentJoined = club['isJoined'] as bool;
    final authState = context.read<AuthCubit>().state;
    final uid = authState is Authenticated ? authState.user.uid : '';
    final clubId = club['id'] as String?;

    setState(() {
      club['isJoined'] = !currentJoined;
      if (club['isJoined']) {
        club['members'] = (club['members'] as int) + 1;
      } else {
        club['members'] = (club['members'] as int) - 1;
      }
    });

    if (clubId != null && clubId.isNotEmpty && uid.isNotEmpty) {
      final groupRef = FirebaseFirestore.instance.collection(FirebaseConstants.groupsCollection).doc(clubId);
      if (!currentJoined) {
        groupRef.update({
          'members': FieldValue.arrayUnion([uid]),
          'membersCount': FieldValue.increment(1),
        }).catchError((_) {});
      } else {
        groupRef.update({
          'members': FieldValue.arrayRemove([uid]),
          'membersCount': FieldValue.increment(-1),
        }).catchError((_) {});
      }
    }
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(FirebaseConstants.groupsCollection).snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> clubsToDisplay = _clubs;
                final authState = context.watch<AuthCubit>().state;
                final currentUserId = authState is Authenticated ? authState.user.uid : '';

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  clubsToDisplay = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final membersList = List<String>.from(data['members'] as List? ?? []);
                    return {
                      'id': doc.id,
                      'name': data['name'] ?? '',
                      'category': data['category'] ?? 'Học thuật',
                      'members': (data['membersCount'] as num?)?.toInt() ?? membersList.length,
                      'isJoined': currentUserId.isNotEmpty && membersList.contains(currentUserId),
                      'desc': data['desc'] ?? '',
                      'color': (data['color'] as num?)?.toInt() ?? 0xFF203864,
                    };
                  }).toList();
                }

                final filteredClubs = clubsToDisplay.where((club) {
                  return _selectedCategory == 'Tất cả' || club['category'] == _selectedCategory;
                }).toList();

                if (filteredClubs.isEmpty) {
                  return Center(
                    child: Text('Không tìm thấy CLB nào', style: TextStyle(color: colorScheme.outline)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: filteredClubs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final club = filteredClubs[index];
                    final isJoined = club['isJoined'] as bool;
                    final color = _getClubColor(context, club['category'] as String);

                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showClubDetailModal(context, club),
                          borderRadius: BorderRadius.circular(18),
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
                                        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(Icons.group_work_rounded, color: color, size: 24),
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
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _getCategoryLabel(club['category'] as String, l10n),
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.people_alt_rounded, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${club['members']} ${l10n.club_members}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    isJoined
                                        ? OutlinedButton.icon(
                                            onPressed: () => _toggleJoinClub(club),
                                            icon: Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.mintColor(context)),
                                            label: Text(
                                              l10n.joined_club,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.mintColor(context),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: AppTheme.mintColor(context).withValues(alpha: 0.08),
                                              side: BorderSide(color: AppTheme.mintColor(context).withValues(alpha: 0.4)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () => _toggleJoinClub(club),
                                            icon: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                            label: Text(
                                              l10n.join_club,
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor(context),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _showEditProfileModal(context, user),
                    icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryColor(context)),
                    label: Text(
                      'Chỉnh sửa thông tin cá nhân',
                      style: TextStyle(color: AppTheme.primaryColor(context), fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
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
          colors: [Color(0xFF16294A), Color(0xFF203864), Color(0xFF2E5088)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context) ? Colors.black45 : AppTheme.navyBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.university_name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
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
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 25,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFFE082)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black26, width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 12,
                          child: Container(height: 0.8, color: Colors.black38),
                        ),
                        Center(
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black38, width: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _showStudentQrModal(context, user),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
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
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💬 "${user.bio}"',
                        style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            title: l10n.gpa_accumulated,
            value: '3.48',
            unit: '/4.0',
            badge: 'Giỏi',
            color: AppTheme.primaryColor(context),
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            title: l10n.credits_accumulated,
            value: '54',
            unit: '/135',
            badge: 'Tín chỉ',
            color: AppTheme.accentColor(context),
            icon: Icons.menu_book_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            title: l10n.training_points,
            value: '92',
            unit: 'ĐRL',
            badge: l10n.training_excellent,
            color: AppTheme.mintColor(context),
            icon: Icons.military_tech_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required String badge,
    required Color color,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppTheme.isDark(context) ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppTheme.isDark(context) ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final languageName = currentLocale == 'vi' ? l10n.vietnamese : l10n.english;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softViolet.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.dark_mode_rounded, color: isDark ? AppTheme.darkSoftViolet : AppTheme.softViolet, size: 20),
            ),
            title: Text(l10n.dark_theme_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.dark_theme_desc, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
            value: isDark,
            onChanged: (val) {
              context.read<ThemeCubit>().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(context).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.language_rounded, color: AppTheme.primaryColor(context), size: 20),
            ),
            title: Text(l10n.language, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(languageName, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguagePickerModal(context),
          ),
          Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(context).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.info_outline_rounded, color: AppTheme.accentColor(context), size: 20),
            ),
            title: Text(l10n.about_pu, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.app_version, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
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

  void _showEditProfileModal(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);
    final facultyCtrl = TextEditingController(text: user.faculty);
    final majorCtrl = TextEditingController(text: user.major);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
                  const Text(
                    'Chỉnh sửa hồ sơ cá nhân',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Tiểu sử (Bio)',
                  hintText: 'Giới thiệu ngắn về bản thân, sở thích...',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: facultyCtrl,
                decoration: InputDecoration(
                  labelText: 'Khoa / Viện',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: majorCtrl,
                decoration: InputDecoration(
                  labelText: 'Ngành học',
                  prefixIcon: const Icon(Icons.book_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;

                  final updated = UserModel(
                    uid: user.uid,
                    email: user.email,
                    studentId: user.studentId,
                    displayName: newName,
                    username: user.username,
                    avatarUrl: user.avatarUrl,
                    coverUrl: user.coverUrl,
                    bio: bioCtrl.text.trim(),
                    faculty: facultyCtrl.text.trim(),
                    major: majorCtrl.text.trim(),
                    cohort: user.cohort,
                    userType: user.userType,
                    isVerified: user.isVerified,
                    currentSubjects: user.currentSubjects,
                    friendsCount: user.friendsCount,
                    postsCount: user.postsCount,
                    createdAt: user.createdAt,
                  );

                  Navigator.pop(ctx);
                  await context.read<AuthCubit>().updateUserProfile(updated);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật thông tin hồ sơ thành công!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: AppTheme.isDark(context) ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
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

