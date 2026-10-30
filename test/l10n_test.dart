import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_connection/l10n/app_localizations.dart';

void main() {
  group('Localization Tests - VI & EN Parity and Translation', () {
    testWidgets('AppLocalizations loads vi locale and provides profile keys', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Text(l10n.profile_title);
            },
          ),
        ),
      );

      expect(find.text('Hồ Sơ Sinh Viên'), findsOneWidget);
      expect(l10n.my_student_qr, 'Mã QR sinh viên của tôi');
      expect(l10n.scan_student_qr, 'Quét mã QR sinh viên');
      expect(l10n.share_profile, 'Chia sẻ hồ sơ');
      expect(l10n.add_friend, 'Kết bạn');
      expect(l10n.request_sent, 'Đã gửi lời mời');
      expect(l10n.mark_all_read, 'Đọc tất cả');
      expect(l10n.no_notifications, 'Không có thông báo nào');
      expect(l10n.edit_profile_btn, 'Chỉnh sửa thông tin cá nhân');
      expect(l10n.friends_list_btn(5), 'Danh sách bạn bè (5)');
      expect(l10n.subject_count(3), '3 môn');
      expect(l10n.copied_profile_link('Nguyễn Văn A'), 'Đã sao chép liên kết hồ sơ của Nguyễn Văn A!');
    });

    testWidgets('AppLocalizations loads en locale and provides profile keys in English', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Text(l10n.profile_title);
            },
          ),
        ),
      );

      expect(find.text('Student Profile'), findsOneWidget);
      expect(l10n.my_student_qr, 'My Student QR Code');
      expect(l10n.scan_student_qr, 'Scan Student QR Code');
      expect(l10n.share_profile, 'Share Profile');
      expect(l10n.add_friend, 'Add Friend');
      expect(l10n.request_sent, 'Request Sent');
      expect(l10n.mark_all_read, 'Read All');
      expect(l10n.no_notifications, 'No notifications');
      expect(l10n.edit_profile_btn, 'Edit Personal Profile');
      expect(l10n.friends_list_btn(5), 'Friends List (5)');
      expect(l10n.subject_count(3), '3 subjects');
      expect(l10n.copied_profile_link('John Doe'), 'Copied profile link for John Doe!');
    });

    testWidgets('Dynamic language switching reflects immediately in UI widgets', (tester) async {
      final currentLocale = ValueNotifier<Locale>(const Locale('vi'));

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: currentLocale,
          builder: (context, locale, child) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Column(
                      children: [
                        Text(l10n.profile_title),
                        Text(l10n.tab_posts),
                        Text(l10n.tab_friends),
                        Text(l10n.tab_about),
                        Text(l10n.notification_center_title),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      );

      // Verify Vietnamese initial state
      expect(find.text('Hồ Sơ Sinh Viên'), findsOneWidget);
      expect(find.text('Bài viết'), findsOneWidget);
      expect(find.text('Bạn bè'), findsOneWidget);
      expect(find.text('Thông tin'), findsOneWidget);
      expect(find.text('Trung tâm thông báo'), findsOneWidget);

      // Switch to English
      currentLocale.value = const Locale('en');
      await tester.pumpAndSettle();

      // Verify immediate English translation
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Notification Center'), findsOneWidget);
    });
  });
}
