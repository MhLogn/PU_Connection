import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../documents/presentation/pages/docs_hub_page.dart';
import '../../../documents/presentation/cubit/document_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../../core/services/notification_service.dart';
import '../../../onboarding/presentation/widgets/notification_permission_sheet.dart';
import '../../../clubs/presentation/cubit/club_cubit.dart';
import '../../../clubs/presentation/cubit/club_state.dart';
import '../../../clubs/presentation/pages/club_detail_page.dart';
import '../../../clubs/presentation/pages/create_club_page.dart';
import '../../../clubs/domain/entities/club_creation_request_entity.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../../../auth/presentation/pages/change_password_dialog.dart';
import '../../../moderation/presentation/cubit/moderation_cubit.dart';
import '../../../moderation/presentation/pages/blocked_users_page.dart';
import '../../../notifications/presentation/cubit/in_app_notifications_cubit.dart';
import '../../../notifications/presentation/cubit/in_app_notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../friends/presentation/pages/friend_list_page.dart';
import '../../../saved_posts/presentation/cubit/saved_posts_cubit.dart';
import '../../../saved_posts/presentation/cubit/saved_posts_state.dart';
import '../../../saved_posts/presentation/pages/saved_posts_page.dart';
import '../../../study_groups/presentation/pages/study_groups_page.dart';
import '../../../auth/presentation/pages/student_qr_code_page.dart';
import '../../../auth/presentation/pages/student_qr_scanner_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  static MainNavigationPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationPageState>();
  }

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};

  void navigateToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
        _loadedTabs.add(index);
      });
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated && authState.user.uid.isNotEmpty) {
        FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .doc(authState.user.uid)
            .update({
              'isOnline': isOnline,
              'lastActive': FieldValue.serverTimestamp(),
            })
            .catchError((_) {});
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionSheet.checkAndShowPrompt(context);
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        _updateOnlineStatus(true);
        context.read<FeedCubit>().updateCurrentUserId(authState.user.uid);
        context.read<ChatCubit>().initConversations(authState.user.uid);
        context.read<ModerationCubit>().init(authState.user.uid);
        context.read<InAppNotificationsCubit>().init(authState.user.uid);
        context.read<SavedPostsCubit>().init(authState.user.uid);
        sl<NotificationService>().syncUserFcmToken(authState.user.uid);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> pages = [
      const FeedPage(),
      _loadedTabs.contains(1)
          ? BlocProvider(
              create: (_) => sl<DocumentCubit>(),
              child: const DocsHubPage(),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(2)
          ? const _PuBotChatView()
          : const SizedBox.shrink(),
      _loadedTabs.contains(3)
          ? const _ClubsCommunityView()
          : const SizedBox.shrink(),
      _loadedTabs.contains(4)
          ? const _StudentProfileView()
          : const SizedBox.shrink(),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        } else if (state is Authenticated) {
          context.read<FeedCubit>().updateCurrentUserId(state.user.uid);
          context.read<ChatCubit>().initConversations(state.user.uid);
          context.read<ModerationCubit>().init(state.user.uid);
          context.read<InAppNotificationsCubit>().init(state.user.uid);
          context.read<SavedPostsCubit>().init(state.user.uid);
          sl<NotificationService>().syncUserFcmToken(state.user.uid);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.isDark(context)
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : AppTheme.borderLight,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.isDark(context)
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF123B63).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
                _loadedTabs.add(index);
              });
            },
            backgroundColor: Colors.transparent,
            indicatorColor: AppTheme.blueContainer(context),
            elevation: 0,
            height: 64,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppTheme.primaryColor(context),
                ),
                label: l10n.nav_feed,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.primaryColor(context),
                ),
                label: l10n.nav_docs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(
                  Icons.smart_toy_rounded,
                  color: AppTheme.accentColor(context),
                ),
                label: l10n.nav_bot,
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: Icon(
                  Icons.groups_rounded,
                  color: AppTheme.primaryColor(context),
                ),
                label: l10n.nav_clubs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor(context),
                ),
                label: l10n.nav_profile,
              ),
            ],
          ),
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
      _loadHistory(l10n.bot_welcome_msg);
    }
  }

  Future<void> _loadHistory(String defaultWelcome) async {
    try {
      final prefs = sl<SharedPreferences>();
      final jsonStr = prefs.getString('pu_bot_chat_history');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List && decoded.isNotEmpty) {
          _messages.clear();
          for (final item in decoded) {
            _messages.add({
              'role': item['role']?.toString() ?? 'bot',
              'text': item['text']?.toString() ?? '',
            });
          }
          if (mounted) setState(() {});
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    if (_messages.isEmpty) {
      _messages.add({'role': 'bot', 'text': defaultWelcome});
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = sl<SharedPreferences>();
      final limited = _messages.take(40).toList();
      await prefs.setString('pu_bot_chat_history', jsonEncode(limited));
    } catch (_) {}
  }

  List<String> _getSuggestions(AppLocalizations l10n) => [
    '💰 ${l10n.bot_quick_scholarship}',
    '📐 Ôn thi môn Giải tích 2',
    '💻 Đề cương Lập trình C++',
    '📝 ${l10n.bot_quick_regulations}',
    '🌐 Miễn học phần Tiếng Anh (TOEIC)',
    '🌟 Cách tính điểm rèn luyện (ĐRL)',
    '📚 ${l10n.bot_quick_library}',
    '🏢 ${l10n.bot_quick_dorm}',
    '📞 Danh bạ phòng ban Tòa A1',
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
      _saveHistory();
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
            Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.accentColor(context),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(l10n.bot_title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.bot_reset_chat,
            onPressed: () async {
              sl<GeminiService>().resetChat();
              try {
                final prefs = sl<SharedPreferences>();
                await prefs.remove('pu_bot_chat_history');
              } catch (_) {}
              setState(() {
                _messages.clear();
                _messages.add({'role': 'bot', 'text': l10n.bot_reset_done});
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
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06123B63),
                            blurRadius: 4,
                            offset: Offset(0, 1),
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
                          color: AppTheme.accentColor(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor(
                                context,
                              ).withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: AppTheme.isDark(context)
                                  ? Colors.white12
                                  : AppTheme.borderLight,
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06123B63),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: msg['text'] ?? ''),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã sao chép câu trả lời của PU Bot!',
                                        ),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 13,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sao chép',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.isDark(context)
                            ? Colors.white12
                            : AppTheme.borderLight,
                        width: 0.8,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06123B63),
                          blurRadius: 4,
                          offset: Offset(0, 1),
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
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return InkWell(
                  onTap: () => _sendMessage(suggestion),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            )
                          : AppTheme.blueContainer(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor(
                          context,
                        ).withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.isDark(context)
                            ? colorScheme.onSurface
                            : AppTheme.primaryColor(context),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.isDark(context)
                      ? Colors.white10
                      : AppTheme.borderLight,
                  width: 0.8,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06123B63),
                  blurRadius: 6,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            )
                          : AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.isDark(context)
                            ? Colors.white12
                            : AppTheme.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (text) => _sendMessage(text),
                      decoration: InputDecoration(
                        hintText: l10n.bot_input_hint,
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
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
  final TextEditingController _searchController = TextEditingController();
  int _activeSubTab = 0; // 0: Khám phá CLB, 1: Yêu cầu của tôi
  String? _initializedUserId;

  final List<String> _categories = [
    'Tất cả',
    'Đã tham gia',
    'Học thuật',
    'Nghệ thuật',
    'Thể thao',
    'Tình nguyện',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getClubColor(BuildContext context, String category) {
    switch (category) {
      case 'Học thuật':
      case 'Tình nguyện':
        return AppTheme.primaryColor(context);
      case 'Nghệ thuật':
      case 'Thể thao':
      case 'Đã tham gia':
      default:
        return AppTheme.accentColor(context);
    }
  }

  String _getCategoryLabel(
    String cat,
    AppLocalizations l10n, [
    int joinedCount = 0,
  ]) {
    switch (cat) {
      case 'Tất cả':
        return l10n.all_clubs;
      case 'Đã tham gia':
        return 'Đã tham gia${joinedCount > 0 ? ' ($joinedCount)' : ''}';
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Học thuật':
        return Icons.psychology_rounded;
      case 'Nghệ thuật':
        return Icons.music_note_rounded;
      case 'Thể thao':
        return Icons.sports_basketball_rounded;
      case 'Tình nguyện':
        return Icons.volunteer_activism_rounded;
      case 'Đã tham gia':
        return Icons.verified_user_rounded;
      default:
        return Icons.group_work_rounded;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--/--/----';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final currentUserId = currentUser?.uid ?? '';
    final currentStudentId = currentUser?.studentId ?? '';

    if (currentUserId.isNotEmpty && _initializedUserId != currentUserId) {
      _initializedUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ClubCubit>().initMyRequestsStream(currentUserId);
        }
      });
    }

    return BlocConsumer<ClubCubit, ClubState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ClubCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final joinedClubs = state.getJoinedClubs(
          currentUserId,
          currentStudentId,
        );
        final filteredClubs = state.getFilteredClubs(
          currentUserId,
          currentStudentId,
        );

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(l10n.clubs_title),
            elevation: 0,
            actions: [
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateClubPage()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  l10n.create_club_btn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: Column(
            children: [
              // Sub-tab Switcher: Khám phá vs Yêu cầu của tôi
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSubTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeSubTab == 0
                                   ? AppTheme.primaryColor(context)
                                   : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.explore_clubs_tab,
                              style: TextStyle(
                                fontWeight: _activeSubTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                                color: _activeSubTab == 0
                                    ? (isDark ? Colors.black87 : Colors.white)
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSubTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeSubTab == 1
                                  ? AppTheme.primaryColor(context)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.my_club_requests_tab,
                                  style: TextStyle(
                                    fontWeight: _activeSubTab == 1
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13,
                                    color: _activeSubTab == 1
                                        ? (isDark
                                              ? Colors.black87
                                              : Colors.white)
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                ),
                                if (state.myRequests.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _activeSubTab == 1
                                          ? (isDark
                                                ? Colors.black26
                                                : Colors.white24)
                                          : AppTheme.accentColor(context),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${state.myRequests.length}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _activeSubTab == 1
                                            ? (isDark
                                                  ? Colors.black87
                                                  : Colors.white)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab View Content
              Expanded(
                child: _activeSubTab == 0
                    ? _buildExploreClubs(
                        context,
                        state,
                        filteredClubs,
                        joinedClubs,
                        isDark,
                        colorScheme,
                        l10n,
                        currentUserId,
                        currentStudentId,
                      )
                    : _buildMyRequestsTab(
                        context,
                        state,
                        isDark,
                        colorScheme,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreClubs(
    BuildContext context,
    ClubState state,
    List<dynamic> filteredClubs,
    List<dynamic> joinedClubs,
    bool isDark,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    String currentUserId,
    String currentStudentId,
  ) {
    return Column(
      children: [
        // Responsive Search Bar without rigid container overflow
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.search_clubs_hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppTheme.oceanBlue,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ClubCubit>().searchClubs('');
                      },
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              filled: true,
              fillColor: isDark
                  ? colorScheme.surfaceContainerHighest
                  : AppTheme.borderSubtle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
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
                  width: 1.2,
                ),
              ),
            ),
            onChanged: (val) {
              context.read<ClubCubit>().searchClubs(val);
            },
          ),
        ),

        // Category Choice Chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = cat == state.selectedCategory;
              return ChoiceChip(
                label: Text(
                  _getCategoryLabel(
                    cat,
                    l10n,
                    cat == 'Đã tham gia' ? joinedClubs.length : 0,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor(context),
                labelStyle: TextStyle(
                  color: isSelected
                      ? (AppTheme.isDark(context)
                            ? Colors.black87
                            : Colors.white)
                      : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) context.read<ClubCubit>().filterCategory(cat);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Club List
        Expanded(
          child: state.status == ClubStatus.loading && state.clubs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredClubs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.selectedCategory == 'Đã tham gia'
                              ? Icons.groups_outlined
                              : Icons.group_off_rounded,
                          size: 56,
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          state.selectedCategory == 'Đã tham gia'
                              ? l10n.no_joined_clubs
                              : l10n.no_clubs_found,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.selectedCategory == 'Đã tham gia'
                              ? l10n.no_joined_clubs_desc
                              : l10n.no_posts_found,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (state.selectedCategory == 'Đã tham gia') ...[
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () {
                              context.read<ClubCubit>().filterCategory(
                                'Tất cả',
                              );
                            },
                            icon: const Icon(
                              Icons.explore_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.explore_phenikaa_clubs),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor(context),
                              foregroundColor: isDark
                                  ? Colors.black87
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  itemCount: filteredClubs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final club = filteredClubs[index];
                    final isJoined = club.isMember(
                      currentUserId,
                      currentStudentId,
                    );
                    final color = _getClubColor(context, club.category);

                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isJoined
                              ? AppTheme.accentColor(
                                  context,
                                ).withValues(alpha: 0.6)
                              : (isDark
                                    ? Colors.white10
                                    : AppTheme.borderLight),
                          width: 0.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06123B63),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClubDetailPage(club: club),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
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
                                        color: color.withValues(
                                          alpha: isDark ? 0.22 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(club.category),
                                        color: color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            club.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _getCategoryLabel(
                                                    club.category,
                                                    l10n,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.people_alt_rounded,
                                                size: 13,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${club.effectiveMembersCount} ${l10n.club_members}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    isJoined
                                        ? OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ClubDetailPage(
                                                        club: club,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.check_circle_rounded,
                                              size: 14,
                                              color: AppTheme.accentColor(
                                                context,
                                              ),
                                            ),
                                            label: Text(
                                              l10n.joined_club,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accentColor(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.accentColor(
                                                    context,
                                                  ).withValues(alpha: 0.08),
                                              side: BorderSide(
                                                color: AppTheme.accentColor(
                                                  context,
                                                ).withValues(alpha: 0.4),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                            ),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () {
                                              context
                                                  .read<ClubCubit>()
                                                  .toggleJoinClub(
                                                    club: club,
                                                    userId: currentUserId,
                                                    secondaryId:
                                                        currentStudentId,
                                                  );
                                            },
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              l10n.join_club,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor(
                                                    context,
                                                  ),
                                              foregroundColor: isDark
                                                  ? Colors.black87
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                            ),
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  club.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.75,
                                    ),
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 13,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'CN: ${club.leaderName}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.view_club_details,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMyRequestsTab(
    BuildContext context,
    ClubState state,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state.myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.post_add_rounded,
                size: 60,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.no_club_requests,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.no_club_requests_desc,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateClubPage()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.register_new_club_btn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.myRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = state.myRequests[index];
        final isPending = req.status == 'pending';
        final isApproved = req.status == 'approved';
        final isRejected = req.status == 'rejected';

        Color statusColor;
        String statusText;
        IconData statusIcon;

        if (isApproved) {
          statusColor = const Color(0xFF10B981);
          statusText = l10n.status_approved;
          statusIcon = Icons.check_circle_rounded;
        } else if (isRejected) {
          statusColor = Colors.redAccent;
          statusText = l10n.status_rejected;
          statusIcon = Icons.cancel_rounded;
        } else {
          statusColor = Colors.orange;
          statusText = l10n.status_pending;
          statusIcon = Icons.hourglass_top_rounded;
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06123B63),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.clubName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor(
                                  context,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                req.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Gửi ngày: ${_formatDate(req.createdAt)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                req.description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                      : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lý do & Kế hoạch: ${req.reason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lịch SH: ${req.schedule} • Địa điểm: ${req.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isRejected && req.adminFeedback != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lý do từ chối: ${req.adminFeedback}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showCancelRequestDialog(context, req);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      l10n.cancel_request_btn_text,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 0.8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCancelRequestDialog(
    BuildContext context,
    ClubCreationRequestEntity req,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.cancel_club_request_title),
        content: Text(l10n.cancel_club_request_confirm(req.clubName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ClubCubit>().cancelClubRequest(req.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(l10n.profile_title),
          actions: [
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is! Authenticated) return const SizedBox.shrink();
                final user = state.user;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_rounded),
                      tooltip: l10n.my_student_qr,
                      onPressed: () =>
                          StudentQrCodePage.show(context, user: user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      tooltip: l10n.scan_student_qr,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentQrScannerPage(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: user),
                        ),
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.primaryColor(context),
                      ),
                      label: Text(
                        l10n.edit_profile_btn,
                        style: TextStyle(
                          color: AppTheme.primaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          FriendListPage.openForCurrentUser(context, user),
                      icon: Icon(
                        Icons.people_outline_rounded,
                        size: 16,
                        color: AppTheme.accentColor(context),
                      ),
                      label: Text(
                        l10n.friends_list_btn(user.friendsCount),
                        style: TextStyle(
                          color: AppTheme.accentColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.accentColor(
                            context,
                          ).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAcademicOverviewCard(context, user),
                    if (user.currentSubjects.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCurrentSubjectsCard(context, user),
                    ],
                    const SizedBox(height: 16),
                    _buildJoinedClubsCard(context, user),
                    const SizedBox(height: 16),
                    _buildSettingsSection(context, colorScheme),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildDigitalStudentCard(BuildContext context, UserEntity user) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF1E293B)
            : AppTheme.deepBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context)
                ? Colors.black54
                : AppTheme.deepBlue.withValues(alpha: 0.18),
            blurRadius: 14,
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
                  Image.asset(
                    'assets/logo/phenikaa_logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, color: Colors.white, size: 28),
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
                        style: const TextStyle(
                          color: Color(0xFFFFB088),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
                        colors: [
                          Color(0xFFFFD54F),
                          Color(0xFFFFB300),
                          Color(0xFFFFE082),
                        ],
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
                              border: Border.all(
                                color: Colors.black38,
                                width: 0.6,
                              ),
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
                      child: const Icon(
                        Icons.qr_code_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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
                backgroundImage: AppTheme.imageProvider(user.avatarUrl),
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.student_id}: ${user.studentId.isNotEmpty ? user.studentId : '--'}${user.cohort != 0 ? ' • K${user.cohort}' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${l10n.faculty}: ${user.faculty.isNotEmpty ? user.faculty : l10n.not_updated}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💬 "${user.bio}"',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
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
              Expanded(
                child: Text(
                  user.email,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.accentColor(context),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isAdmin
                        ? l10n.admin_badge
                        : l10n.student_verified_badge.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.accentColor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicOverviewCard(BuildContext context, UserEntity user) {
    final l10n = AppLocalizations.of(context)!;

    // Compute GPA badge label
    String gpaBadge;
    if (user.gpa >= 3.6) {
      gpaBadge = l10n.grade_excellent;
    } else if (user.gpa >= 3.2) {
      gpaBadge = l10n.grade_very_good;
    } else if (user.gpa >= 2.5) {
      gpaBadge = l10n.grade_good;
    } else if (user.gpa > 0) {
      gpaBadge = l10n.grade_average;
    } else {
      gpaBadge = '--';
    }

    // Compute training points badge
    String drlBadge;
    if (user.trainingPoints >= 90) {
      drlBadge = l10n.training_excellent;
    } else if (user.trainingPoints >= 80) {
      drlBadge = l10n.grade_drl_good;
    } else if (user.trainingPoints >= 65) {
      drlBadge = l10n.grade_good;
    } else if (user.trainingPoints > 0) {
      drlBadge = l10n.grade_average;
    } else {
      drlBadge = '--';
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            title: l10n.gpa_accumulated,
            value: user.gpa > 0 ? user.gpa.toStringAsFixed(2) : '--',
            unit: '/4.0',
            badge: gpaBadge,
            color: AppTheme.primaryColor(context),
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            title: l10n.credits_accumulated,
            value: user.creditsEarned > 0 ? '${user.creditsEarned}' : '--',
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
            value: user.trainingPoints > 0 ? '${user.trainingPoints}' : '--',
            unit: 'ĐRL',
            badge: drlBadge,
            color: AppTheme.primaryColor(context),
            icon: Icons.military_tech_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSubjectsCard(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? Colors.white10
              : AppTheme.borderLight,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06123B63),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.collections_bookmark_rounded,
                size: 18,
                color: AppTheme.accentColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.semester_courses,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                l10n.subject_count(user.currentSubjects.length),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.currentSubjects.map((subject) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.blueContainer(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor(
                      context,
                    ).withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedClubsCard(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ClubCubit, ClubState>(
      builder: (context, state) {
        final joinedClubs = state.getJoinedClubs(user.uid, user.studentId);
        if (joinedClubs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.isDark(context)
                  ? Colors.white10
                  : AppTheme.borderLight,
              width: 0.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06123B63),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 18,
                    color: AppTheme.accentColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.joined_clubs_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        MainNavigationPage.of(context)?.navigateToTab(3),
                    child: Text(
                      l10n.joined_clubs_view_all(joinedClubs.length),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: joinedClubs.map((club) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClubDetailPage(club: club),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.isDark(context)
                              ? colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                )
                              : AppTheme.primaryColor(
                                  context,
                                ).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.15),
                              child: Text(
                                club.name.isNotEmpty
                                    ? club.name[0].toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor(context),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    club.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.club_category_members(club.category, club.membersCount),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppTheme.primaryColor(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? Colors.white10
              : AppTheme.borderLight,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06123B63),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: AppTheme.isDark(context) ? 0.22 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: AppTheme.isDark(context) ? 0.25 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAdmin = currentUser?.isAdmin == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.borderLight,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06123B63),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey<bool>(isDark),
                  color: AppTheme.primaryColor(context),
                  size: 20,
                ),
              ),
            ),
            title: Text(
              l10n.dark_theme_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.dark_theme_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: isDark,
            activeColor: AppTheme.primaryColor(context),
            onChanged: (val) {
              context.read<ThemeCubit>().setThemeMode(
                val ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.language_rounded,
                color: AppTheme.primaryColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.language,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              languageName,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguagePickerModal(context),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.accentColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.notifications_settings_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.notifications_settings_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    size: 20,
                    color: AppTheme.accentColor(context),
                  ),
                  tooltip: 'Sao chép FCM Token thiết bị',
                  onPressed: () async {
                    final token = await sl<NotificationService>().getFcmToken();
                    if (context.mounted) {
                      if (token != null && token.isNotEmpty) {
                        await Clipboard.setData(ClipboardData(text: token));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã sao chép FCM Token: ${token.substring(0, 12)}...',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.primaryColor(context),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'FCM Token chưa sẵn sàng trên nền tảng này.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: AppTheme.primaryColor(context),
                  ),
                  tooltip: l10n.test_notification_btn,
                  onPressed: () async {
                    await sl<NotificationService>().sendTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã gửi thông báo thử nghiệm! Vui lòng kiểm tra thanh thông báo thiết bị.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            onTap: () => NotificationPermissionSheet.checkAndShowPrompt(
              context,
              force: true,
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF0284C7,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
            ),
            title: Text(
              l10n.notification_center_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.notification_center_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing:
                BlocBuilder<InAppNotificationsCubit, InAppNotificationsState>(
                  builder: (context, notifState) {
                    if (notifState.unreadCount > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          notifState.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const Icon(Icons.chevron_right_rounded);
                  },
                ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bookmark_rounded,
                color: AppTheme.primaryColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.saved_posts_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.saved_posts_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: BlocBuilder<SavedPostsCubit, SavedPostsState>(
              builder: (context, savedState) {
                if (savedState.unviewedCount > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      savedState.unviewedCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Icon(Icons.chevron_right_rounded);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedPostsPage()),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF0284C7,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.diversity_3_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
            ),
            title: Text(
              l10n.study_groups_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.study_groups_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudyGroupsPage()),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: AppTheme.accentColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.clubs_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.clubs_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: BlocBuilder<ClubCubit, ClubState>(
              builder: (context, clubState) {
                final authState = context.watch<AuthCubit>().state;
                if (authState is Authenticated) {
                  final joined = clubState.getJoinedClubs(
                    authState.user.uid,
                    authState.user.studentId,
                  );
                  if (joined.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        joined.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                }
                return const Icon(Icons.chevron_right_rounded);
              },
            ),
            onTap: () => MainNavigationPage.of(context)?.navigateToTab(3),
          ),
          if (isAdmin) ...[
            Divider(
              height: 1,
              indent: 56,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            ListTile(
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(
                    context,
                  ).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.primaryColor(context),
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.admin_portal_title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PORTAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                l10n.admin_portal_desc,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin'),
            ),
          ],
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: AppTheme.accentColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.change_password_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.change_password_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => ChangePasswordDialog.show(context),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_flipped,
                color: Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              l10n.blocked_users_title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.blocked_users_desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor(
                  context,
                ).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppTheme.accentColor(context),
                size: 20,
              ),
            ),
            title: Text(
              l10n.about_pu,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.app_version,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                  title: Text(l10n.vietnamese),
                  trailing: currentLocale == 'vi'
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor(context),
                        )
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
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor(context),
                        )
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
    StudentQrCodePage.show(context, user: user);
  }
  /*
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0056B3)),
              SizedBox(width: 8),
              Text(
                'Quét / Nhập mã bạn bè',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dán nội dung mã QR đã quét hoặc nhập Mã số sinh viên (MSSV) của bạn bè:',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập MSSV (VD: 23010390) hoặc dán mã QR...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Dán từ bộ nhớ tạm',
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        textController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
              if (isSearching) ...[
                const SizedBox(height: 14),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isSearching
                  ? null
                  : () async {
                      final query = textController.text.trim();
                      if (query.isEmpty) return;

                      setDialogState(() => isSearching = true);

                      try {
                        String? targetUid;
                        String? targetName;
                        String? targetStudentId;
                        String? targetFaculty;
                        String? targetAvatar;

                        // Trường hợp 1: Chuỗi là JSON từ mã QR của PU Connection
                        if (query.startsWith('{') && query.endsWith('}')) {
                          try {
                            final map =
                                jsonDecode(query) as Map<String, dynamic>;
                            targetUid = map['uid'] as String?;
                            targetName =
                                map['displayName'] as String? ??
                                map['name'] as String?;
                            targetStudentId = map['studentId'] as String?;
                            targetFaculty = map['faculty'] as String?;
                          } catch (_) {}
                        }

                        // Trường hợp 2: Tra cứu Firestore theo MSSV hoặc UID
                        if (targetUid == null || targetUid.isEmpty) {
                          // Tìm theo studentId
                          final querySnap = await FirebaseFirestore.instance
                              .collection(FirebaseConstants.usersCollection)
                              .where('studentId', isEqualTo: query)
                              .limit(1)
                              .get();

                          if (querySnap.docs.isNotEmpty) {
                            final doc = querySnap.docs.first;
                            final data = doc.data();
                            targetUid = doc.id;
                            targetName =
                                data['displayName'] as String? ??
                                'Sinh viên Phenikaa';
                            targetStudentId =
                                data['studentId'] as String? ?? query;
                            targetFaculty = data['faculty'] as String? ?? '';
                            targetAvatar = data['avatarUrl'] as String? ?? '';
                          } else {
                            // Thử tìm theo document ID (uid)
                            final docSnap = await FirebaseFirestore.instance
                                .collection(FirebaseConstants.usersCollection)
                                .doc(query)
                                .get();
                            if (docSnap.exists) {
                              final data = docSnap.data()!;
                              targetUid = docSnap.id;
                              targetName =
                                  data['displayName'] as String? ??
                                  'Sinh viên Phenikaa';
                              targetStudentId =
                                  data['studentId'] as String? ?? '';
                              targetFaculty = data['faculty'] as String? ?? '';
                              targetAvatar = data['avatarUrl'] as String? ?? '';
                            }
                          }
                        }

                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);

                        if (targetUid != null && targetUid.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                userId: targetUid!,
                                userName: targetName ?? 'Sinh viên Phenikaa',
                                studentId: targetStudentId ?? '',
                                faculty: targetFaculty ?? '',
                                avatarUrl: targetAvatar ?? '',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Không tìm thấy sinh viên với thông tin: "$query"',
                              ),
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isSearching = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi tra cứu: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }
*/

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authCubit = context.read<AuthCubit>();
    final chatCubit = context.read<ChatCubit>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.logout_confirm_title),
        content: Text(l10n.logout_confirm_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      chatCubit.reset();
      if (context.mounted) {
        context.go('/login');
      }
      await authCubit.signOut();
    }
  }
}
