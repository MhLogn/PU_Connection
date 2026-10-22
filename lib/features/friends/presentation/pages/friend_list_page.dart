import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';

/// Trang danh sách bạn bè của một user.
///
/// Truy xuất subcollection `users/{userId}/friends` từ Firestore theo thời gian thực.
class FriendListPage extends StatelessWidget {
  final String userId;
  final String displayName;

  const FriendListPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  /// Mở FriendListPage cho chính user đang đăng nhập.
  static void openForCurrentUser(BuildContext context, UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendListPage(
          userId: user.uid,
          displayName: user.displayName,
        ),
      ),
    );
  }

  void _showSearchStudentDialog(BuildContext context) {
    final textController = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_search_rounded, color: Color(0xFF0056B3)),
              SizedBox(width: 8),
              Text('Tìm bạn bằng MSSV / QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập MSSV (VD: 23010390) hoặc dán mã QR sinh viên:',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập MSSV hoặc dán mã QR...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Dán từ bộ nhớ tạm',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
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

                        if (query.startsWith('{') && query.endsWith('}')) {
                          try {
                            final map = jsonDecode(query) as Map<String, dynamic>;
                            targetUid = map['uid'] as String?;
                            targetName = map['displayName'] as String? ?? map['name'] as String?;
                            targetStudentId = map['studentId'] as String?;
                            targetFaculty = map['faculty'] as String?;
                          } catch (_) {}
                        }

                        if (targetUid == null || targetUid.isEmpty) {
                          final querySnap = await FirebaseFirestore.instance
                              .collection(FirebaseConstants.usersCollection)
                              .where('studentId', isEqualTo: query)
                              .limit(1)
                              .get();

                          if (querySnap.docs.isNotEmpty) {
                            final doc = querySnap.docs.first;
                            final data = doc.data();
                            targetUid = doc.id;
                            targetName = data['displayName'] as String? ?? 'Sinh viên Phenikaa';
                            targetStudentId = data['studentId'] as String? ?? query;
                            targetFaculty = data['faculty'] as String? ?? '';
                            targetAvatar = data['avatarUrl'] as String? ?? '';
                          } else {
                            final docSnap = await FirebaseFirestore.instance
                                .collection(FirebaseConstants.usersCollection)
                                .doc(query)
                                .get();
                            if (docSnap.exists) {
                              final data = docSnap.data()!;
                              targetUid = docSnap.id;
                              targetName = data['displayName'] as String? ?? 'Sinh viên Phenikaa';
                              targetStudentId = data['studentId'] as String? ?? '';
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
                              content: Text('Không tìm thấy sinh viên với thông tin: "$query"'),
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isSearching = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi tra cứu: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: const Text('Tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Bạn bè của $displayName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Tìm bạn bằng MSSV hoặc Mã QR',
            onPressed: () => _showSearchStudentDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection(FirebaseConstants.friendsSubcollection)
            .orderBy('connectedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Lỗi tải danh sách bạn bè: ${snapshot.error}'),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 72,
                    color: colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bạn bè nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kết nối với sinh viên PU và xây dựng mạng lưới của bạn!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Count header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: colorScheme.surface,
                child: Text(
                  '${docs.length} bạn bè',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final friendId = data['userId'] as String? ?? doc.id;
                    final friendName = data['displayName'] as String? ?? 'Sinh viên Phenikaa';
                    final friendAvatar = data['avatarUrl'] as String? ?? '';
                    final friendFaculty = data['faculty'] as String? ?? '';
                    final connectedAt = data['connectedAt'] is Timestamp
                        ? (data['connectedAt'] as Timestamp).toDate()
                        : null;

                    return _FriendTile(
                      friendId: friendId,
                      friendName: friendName,
                      avatarUrl: friendAvatar,
                      faculty: friendFaculty,
                      connectedAt: connectedAt,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String friendId;
  final String friendName;
  final String avatarUrl;
  final String faculty;
  final DateTime? connectedAt;

  const _FriendTile({
    required this.friendId,
    required this.friendName,
    required this.avatarUrl,
    required this.faculty,
    this.connectedAt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String connectedLabel = '';
    if (connectedAt != null) {
      final diff = DateTime.now().difference(connectedAt!);
      if (diff.inDays >= 365) {
        connectedLabel = 'Bạn bè từ ${diff.inDays ~/ 365} năm trước';
      } else if (diff.inDays >= 30) {
        connectedLabel = 'Bạn bè từ ${diff.inDays ~/ 30} tháng trước';
      } else if (diff.inDays >= 1) {
        connectedLabel = 'Bạn bè từ ${diff.inDays} ngày trước';
      } else {
        connectedLabel = 'Mới kết bạn hôm nay';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: avatarUrl.isNotEmpty ? AppTheme.imageProvider(avatarUrl) : null,
        backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.15),
        child: avatarUrl.isEmpty
            ? Text(
                friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor(context),
                ),
              )
            : null,
      ),
      title: Text(
        friendName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (faculty.isNotEmpty)
            Text(
              faculty,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          if (connectedLabel.isNotEmpty)
            Text(
              connectedLabel,
              style: TextStyle(fontSize: 11.5, color: AppTheme.primaryColor(context).withValues(alpha: 0.7)),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              userId: friendId,
              userName: friendName,
              faculty: faculty,
              avatarUrl: avatarUrl,
            ),
          ),
        );
      },
    );
  }
}
