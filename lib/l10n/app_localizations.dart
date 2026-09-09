import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @app_name.
  ///
  /// In vi, this message translates to:
  /// **'PU Connection'**
  String get app_name;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra'**
  String get error;

  /// No description provided for @success.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get system;

  /// No description provided for @continue_btn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continue_btn;

  /// No description provided for @vietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get english;

  /// No description provided for @select_language.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get select_language;

  /// No description provided for @skip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get skip;

  /// No description provided for @start_btn.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get start_btn;

  /// No description provided for @intro1_badge.
  ///
  /// In vi, this message translates to:
  /// **'CỘNG ĐỒNG PHENIKAA'**
  String get intro1_badge;

  /// No description provided for @intro1_title.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối sinh viên Phenikaa'**
  String get intro1_title;

  /// No description provided for @intro1_desc.
  ///
  /// In vi, this message translates to:
  /// **'Giao lưu, kết bạn, chia sẻ kinh nghiệm học tập và đời sống sinh viên cùng cộng đồng sinh viên Phenikaa University.'**
  String get intro1_desc;

  /// No description provided for @intro2_badge.
  ///
  /// In vi, this message translates to:
  /// **'KHO TÀI LIỆU MỞ'**
  String get intro2_badge;

  /// No description provided for @intro2_title.
  ///
  /// In vi, this message translates to:
  /// **'Kho Tài Liệu & Trao Đổi Môn Học'**
  String get intro2_title;

  /// No description provided for @intro2_desc.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu đề cương, slide bài giảng, đề thi phong phú được phân loại trực quan theo từng Viện, Khoa và Mã học phần.'**
  String get intro2_desc;

  /// No description provided for @intro3_badge.
  ///
  /// In vi, this message translates to:
  /// **'TRỢ LÝ AI & CÂU LẠC BỘ'**
  String get intro3_badge;

  /// No description provided for @intro3_title.
  ///
  /// In vi, this message translates to:
  /// **'PU Bot Campus & CLB Năng Động'**
  String get intro3_title;

  /// No description provided for @intro3_desc.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý ảo giải đáp quy chế tín chỉ 24/7 cùng hàng chục câu lạc bộ học thuật, thể thao và nghệ thuật đang chờ bạn.'**
  String get intro3_desc;

  /// No description provided for @setup_title.
  ///
  /// In vi, this message translates to:
  /// **'Thiết Lập Cá Nhân'**
  String get setup_title;

  /// No description provided for @setup_subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy biến ngôn ngữ và giao diện hiển thị'**
  String get setup_subtitle;

  /// No description provided for @app_language_section.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ ứng dụng'**
  String get app_language_section;

  /// No description provided for @theme_mode_section.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ giao diện'**
  String get theme_mode_section;

  /// No description provided for @light_theme_title.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện Sáng'**
  String get light_theme_title;

  /// No description provided for @light_theme_desc.
  ///
  /// In vi, this message translates to:
  /// **'Tone trắng & Navy thanh lịch, dễ đọc ban ngày'**
  String get light_theme_desc;

  /// No description provided for @dark_theme_title.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện Tối'**
  String get dark_theme_title;

  /// No description provided for @dark_theme_desc.
  ///
  /// In vi, this message translates to:
  /// **'Tone đen than dịu mắt, tiết kiệm pin ban đêm'**
  String get dark_theme_desc;

  /// No description provided for @system_theme_title.
  ///
  /// In vi, this message translates to:
  /// **'Tự động theo hệ thống'**
  String get system_theme_title;

  /// No description provided for @system_theme_desc.
  ///
  /// In vi, this message translates to:
  /// **'Tự động đồng bộ theo cài đặt thiết bị'**
  String get system_theme_desc;

  /// No description provided for @continue_to_login.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đến Đăng nhập'**
  String get continue_to_login;

  /// No description provided for @default_label.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get default_label;

  /// No description provided for @international_label.
  ///
  /// In vi, this message translates to:
  /// **'Quốc tế'**
  String get international_label;

  /// No description provided for @login_tab.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login_tab;

  /// No description provided for @activate_tab.
  ///
  /// In vi, this message translates to:
  /// **'Kích hoạt tài khoản'**
  String get activate_tab;

  /// No description provided for @login_welcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng bạn trở lại!'**
  String get login_welcome;

  /// No description provided for @login_subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng tài khoản sinh viên Phenikaa'**
  String get login_subtitle;

  /// No description provided for @student_email_label.
  ///
  /// In vi, this message translates to:
  /// **'Email sinh viên hoặc Mã SV'**
  String get student_email_label;

  /// No description provided for @student_email_hint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 23010390 hoặc 23010390@st.phenikaa-uni.edu.vn'**
  String get student_email_hint;

  /// No description provided for @password_label.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password_label;

  /// No description provided for @password_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu của bạn'**
  String get password_hint;

  /// No description provided for @forgot_password.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgot_password;

  /// No description provided for @forgot_password_title.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgot_password_title;

  /// No description provided for @forgot_password_desc.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Mã SV hoặc Email sinh viên (@st.phenikaa-uni.edu.vn) để nhận liên kết đặt lại mật khẩu:'**
  String get forgot_password_desc;

  /// No description provided for @send_reset_link.
  ///
  /// In vi, this message translates to:
  /// **'Gửi liên kết'**
  String get send_reset_link;

  /// No description provided for @reset_link_sent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư!'**
  String get reset_link_sent;

  /// No description provided for @sign_in_btn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get sign_in_btn;

  /// No description provided for @or_divider.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc'**
  String get or_divider;

  /// No description provided for @google_sign_in_btn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập nhanh với Google Sinh viên'**
  String get google_sign_in_btn;

  /// No description provided for @google_sign_in_sub.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chấp nhận đuôi @st.phenikaa-uni.edu.vn'**
  String get google_sign_in_sub;

  /// No description provided for @activate_step1_title.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh danh tính sinh viên'**
  String get activate_step1_title;

  /// No description provided for @activate_step1_desc.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Mã SV hoặc Email sinh viên để hệ thống đối chiếu với hồ sơ sinh viên Phenikaa.'**
  String get activate_step1_desc;

  /// No description provided for @verify_student_btn.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra mã sinh viên'**
  String get verify_student_btn;

  /// No description provided for @activate_step2_title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mật khẩu & Kích hoạt'**
  String get activate_step2_title;

  /// No description provided for @student_verified_badge.
  ///
  /// In vi, this message translates to:
  /// **'Sinh viên hợp lệ'**
  String get student_verified_badge;

  /// No description provided for @full_name.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get full_name;

  /// No description provided for @student_id.
  ///
  /// In vi, this message translates to:
  /// **'Mã sinh viên'**
  String get student_id;

  /// No description provided for @faculty.
  ///
  /// In vi, this message translates to:
  /// **'Khoa / Viện'**
  String get faculty;

  /// No description provided for @major.
  ///
  /// In vi, this message translates to:
  /// **'Ngành đào tạo'**
  String get major;

  /// No description provided for @class_name.
  ///
  /// In vi, this message translates to:
  /// **'Lớp hành chính'**
  String get class_name;

  /// No description provided for @new_password_label.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mật khẩu mới'**
  String get new_password_label;

  /// No description provided for @confirm_password_label.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get confirm_password_label;

  /// No description provided for @send_activation_link_btn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi link kích hoạt qua Email'**
  String get send_activation_link_btn;

  /// No description provided for @activation_link_sent_title.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi liên kết xác thực!'**
  String get activation_link_sent_title;

  /// No description provided for @activation_link_sent_desc.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng mở hộp thư sinh viên và nhấp vào liên kết để hoàn tất kích hoạt tài khoản.'**
  String get activation_link_sent_desc;

  /// No description provided for @recheck_verified_btn.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã xác thực xong'**
  String get recheck_verified_btn;

  /// No description provided for @back_to_step1.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mã sinh viên khác'**
  String get back_to_step1;

  /// No description provided for @empty_field_err.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng không để trống'**
  String get empty_field_err;

  /// No description provided for @password_length_err.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải từ 6 ký tự trở lên'**
  String get password_length_err;

  /// No description provided for @password_mismatch_err.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get password_mismatch_err;

  /// No description provided for @nav_feed.
  ///
  /// In vi, this message translates to:
  /// **'Bảng tin'**
  String get nav_feed;

  /// No description provided for @nav_docs.
  ///
  /// In vi, this message translates to:
  /// **'Kho tài liệu'**
  String get nav_docs;

  /// No description provided for @nav_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Câu lạc bộ'**
  String get nav_clubs;

  /// No description provided for @nav_bot.
  ///
  /// In vi, this message translates to:
  /// **'PU Bot'**
  String get nav_bot;

  /// No description provided for @nav_profile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get nav_profile;

  /// No description provided for @feed_title.
  ///
  /// In vi, this message translates to:
  /// **'Bảng tin Sinh viên'**
  String get feed_title;

  /// No description provided for @search_posts_hint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm bài viết, tác giả...'**
  String get search_posts_hint;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @official_announcements.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo từ Nhà trường'**
  String get official_announcements;

  /// No description provided for @all_filter.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get all_filter;

  /// No description provided for @docs_filter.
  ///
  /// In vi, this message translates to:
  /// **'Tài liệu'**
  String get docs_filter;

  /// No description provided for @questions_filter.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi bài'**
  String get questions_filter;

  /// No description provided for @groups_filter.
  ///
  /// In vi, this message translates to:
  /// **'Tìm nhóm'**
  String get groups_filter;

  /// No description provided for @discussions_filter.
  ///
  /// In vi, this message translates to:
  /// **'Thảo luận'**
  String get discussions_filter;

  /// No description provided for @announcements_filter.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get announcements_filter;

  /// No description provided for @create_post_hint.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang có thắc mắc hay tài liệu gì muốn chia sẻ?'**
  String get create_post_hint;

  /// No description provided for @create_post_title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bài viết mới'**
  String get create_post_title;

  /// No description provided for @post_content_hint.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ tài liệu, kinh nghiệm ôn thi, tìm nhóm học phần...'**
  String get post_content_hint;

  /// No description provided for @choose_category.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chủ đề:'**
  String get choose_category;

  /// No description provided for @attach_image.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đính kèm'**
  String get attach_image;

  /// No description provided for @attach_file.
  ///
  /// In vi, this message translates to:
  /// **'Tệp tài liệu'**
  String get attach_file;

  /// No description provided for @post_btn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng bài'**
  String get post_btn;

  /// No description provided for @comments_title.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận'**
  String get comments_title;

  /// No description provided for @no_comments_yet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bình luận nào. Hãy là người đầu tiên thảo luận!'**
  String get no_comments_yet;

  /// No description provided for @write_comment_hint.
  ///
  /// In vi, this message translates to:
  /// **'Viết bình luận với tư cách...'**
  String get write_comment_hint;

  /// No description provided for @like.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @download.
  ///
  /// In vi, this message translates to:
  /// **'Tải về'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get downloading;

  /// No description provided for @download_complete.
  ///
  /// In vi, this message translates to:
  /// **'Tải xuống hoàn tất'**
  String get download_complete;

  /// No description provided for @no_posts_found.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bài viết nào phù hợp'**
  String get no_posts_found;

  /// No description provided for @no_posts_empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài viết nào trong mục này'**
  String get no_posts_empty;

  /// No description provided for @docs_title.
  ///
  /// In vi, this message translates to:
  /// **'Kho Tài Liệu Học Phần'**
  String get docs_title;

  /// No description provided for @search_docs_hint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm đề thi, slide, giáo trình...'**
  String get search_docs_hint;

  /// No description provided for @contribute_doc_btn.
  ///
  /// In vi, this message translates to:
  /// **'Đóng góp tài liệu'**
  String get contribute_doc_btn;

  /// No description provided for @contribute_dialog_title.
  ///
  /// In vi, this message translates to:
  /// **'Đóng góp tài liệu môn học'**
  String get contribute_dialog_title;

  /// No description provided for @doc_title_label.
  ///
  /// In vi, this message translates to:
  /// **'Tên tài liệu'**
  String get doc_title_label;

  /// No description provided for @course_code_label.
  ///
  /// In vi, this message translates to:
  /// **'Mã học phần'**
  String get course_code_label;

  /// No description provided for @faculty_label.
  ///
  /// In vi, this message translates to:
  /// **'Khoa phụ trách'**
  String get faculty_label;

  /// No description provided for @doc_type_label.
  ///
  /// In vi, this message translates to:
  /// **'Loại tài liệu'**
  String get doc_type_label;

  /// No description provided for @select_file_btn.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp từ máy'**
  String get select_file_btn;

  /// No description provided for @upload_btn.
  ///
  /// In vi, this message translates to:
  /// **'Tải lên ngay'**
  String get upload_btn;

  /// No description provided for @upload_success.
  ///
  /// In vi, this message translates to:
  /// **'Đóng góp tài liệu thành công!'**
  String get upload_success;

  /// No description provided for @all_courses.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả học phần'**
  String get all_courses;

  /// No description provided for @downloads_count.
  ///
  /// In vi, this message translates to:
  /// **'lượt tải'**
  String get downloads_count;

  /// No description provided for @clubs_title.
  ///
  /// In vi, this message translates to:
  /// **'Cộng Đồng Câu Lạc Bộ'**
  String get clubs_title;

  /// No description provided for @search_clubs_hint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm câu lạc bộ...'**
  String get search_clubs_hint;

  /// No description provided for @all_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả CLB'**
  String get all_clubs;

  /// No description provided for @academic_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Học thuật'**
  String get academic_clubs;

  /// No description provided for @sports_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Thể thao'**
  String get sports_clubs;

  /// No description provided for @arts_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Nghệ thuật'**
  String get arts_clubs;

  /// No description provided for @volunteer_clubs.
  ///
  /// In vi, this message translates to:
  /// **'Tình nguyện'**
  String get volunteer_clubs;

  /// No description provided for @join_club.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get join_club;

  /// No description provided for @joined_club.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia'**
  String get joined_club;

  /// No description provided for @club_members.
  ///
  /// In vi, this message translates to:
  /// **'thành viên'**
  String get club_members;

  /// No description provided for @club_details.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin Câu lạc bộ'**
  String get club_details;

  /// No description provided for @club_contact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ CLB'**
  String get club_contact;

  /// No description provided for @join_success.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu tham gia câu lạc bộ!'**
  String get join_success;

  /// No description provided for @leave_club.
  ///
  /// In vi, this message translates to:
  /// **'Rời câu lạc bộ'**
  String get leave_club;

  /// No description provided for @bot_title.
  ///
  /// In vi, this message translates to:
  /// **'Trợ Lý AI Campus'**
  String get bot_title;

  /// No description provided for @bot_status_online.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến 24/7'**
  String get bot_status_online;

  /// No description provided for @bot_welcome_msg.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào! Mình là PU Bot - Trợ lý ảo sinh viên Phenikaa. Bạn cần hỗ trợ gì về học phần, quy chế tín chỉ hay địa điểm trường không?'**
  String get bot_welcome_msg;

  /// No description provided for @bot_input_hint.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi PU Bot bất cứ điều gì về Phenikaa...'**
  String get bot_input_hint;

  /// No description provided for @bot_quick_regulations.
  ///
  /// In vi, this message translates to:
  /// **'Quy chế tín chỉ & cảnh báo học tập'**
  String get bot_quick_regulations;

  /// No description provided for @bot_quick_scholarship.
  ///
  /// In vi, this message translates to:
  /// **'Điều kiện xét học bổng khuyến khích'**
  String get bot_quick_scholarship;

  /// No description provided for @bot_quick_library.
  ///
  /// In vi, this message translates to:
  /// **'Giờ mở cửa thư viện & phòng tự học'**
  String get bot_quick_library;

  /// No description provided for @bot_quick_dorm.
  ///
  /// In vi, this message translates to:
  /// **'Thủ tục đăng ký ký túc xá'**
  String get bot_quick_dorm;

  /// No description provided for @profile_title.
  ///
  /// In vi, this message translates to:
  /// **'Hồ Sơ Sinh Viên'**
  String get profile_title;

  /// No description provided for @student_card_qr.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR Sinh viên'**
  String get student_card_qr;

  /// No description provided for @student_qr_desc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để điểm danh sự kiện, ra vào thư viện và ký túc xá'**
  String get student_qr_desc;

  /// No description provided for @student_status_active.
  ///
  /// In vi, this message translates to:
  /// **'Đang học tập'**
  String get student_status_active;

  /// No description provided for @app_settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt ứng dụng'**
  String get app_settings;

  /// No description provided for @about_pu.
  ///
  /// In vi, this message translates to:
  /// **'Về PU Connection'**
  String get about_pu;

  /// No description provided for @app_version.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản 1.0.0 • Phenikaa University'**
  String get app_version;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @logout_confirm_title.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đăng xuất'**
  String get logout_confirm_title;

  /// No description provided for @logout_confirm_desc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'**
  String get logout_confirm_desc;

  /// No description provided for @university_name.
  ///
  /// In vi, this message translates to:
  /// **'TRƯỜNG ĐẠI HỌC PHENIKAA'**
  String get university_name;

  /// No description provided for @student_slogan.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối tri thức • Tương lai vững bước'**
  String get student_slogan;

  /// No description provided for @student_network.
  ///
  /// In vi, this message translates to:
  /// **'Mạng xã hội sinh viên Phenikaa'**
  String get student_network;

  /// No description provided for @digital_student_card.
  ///
  /// In vi, this message translates to:
  /// **'THẺ SINH VIÊN ĐIỆN TỬ'**
  String get digital_student_card;

  /// No description provided for @bot_typing.
  ///
  /// In vi, this message translates to:
  /// **'PU Bot đang trả lời...'**
  String get bot_typing;

  /// No description provided for @bot_reset_chat.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới đoạn chat'**
  String get bot_reset_chat;

  /// No description provided for @bot_reset_done.
  ///
  /// In vi, this message translates to:
  /// **'Đã làm mới phiên hội thoại. Mình có thể giúp gì cho bạn?'**
  String get bot_reset_done;

  /// No description provided for @no_docs_found.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tài liệu phù hợp'**
  String get no_docs_found;

  /// No description provided for @open_file.
  ///
  /// In vi, this message translates to:
  /// **'Mở tệp'**
  String get open_file;

  /// No description provided for @downloading_doc.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải tài liệu...'**
  String get downloading_doc;

  /// No description provided for @download_saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu vào thư mục Downloads...'**
  String get download_saving;

  /// No description provided for @doc_title_hint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Đề thi cuối kỳ Giải tích 1 có đáp án'**
  String get doc_title_hint;

  /// No description provided for @course_code_hint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: CNTT-225'**
  String get course_code_hint;

  /// No description provided for @doc_name_required.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên tài liệu'**
  String get doc_name_required;

  /// No description provided for @doc_upload_success.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng góp tài liệu thành công vào Kho tài liệu!'**
  String get doc_upload_success;

  /// No description provided for @club_overview.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu chung'**
  String get club_overview;

  /// No description provided for @club_schedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sinh hoạt & Địa điểm'**
  String get club_schedule;

  /// No description provided for @club_benefits.
  ///
  /// In vi, this message translates to:
  /// **'Quyền lợi thành viên'**
  String get club_benefits;

  /// No description provided for @gpa_accumulated.
  ///
  /// In vi, this message translates to:
  /// **'GPA Tích lũy'**
  String get gpa_accumulated;

  /// No description provided for @credits_accumulated.
  ///
  /// In vi, this message translates to:
  /// **'Tín chỉ'**
  String get credits_accumulated;

  /// No description provided for @training_points.
  ///
  /// In vi, this message translates to:
  /// **'Điểm rèn luyện'**
  String get training_points;

  /// No description provided for @training_excellent.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc'**
  String get training_excellent;

  /// No description provided for @not_logged_in.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập'**
  String get not_logged_in;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
