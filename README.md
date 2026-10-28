# PU Connection

Nền tảng mạng xã hội và hỗ trợ học tập dành cho sinh viên Trường Đại học Phenikaa.

---

## Mục lục

1. [Giới thiệu dự án](#1-giới-thiệu-dự-án)
   - [Bối cảnh và vấn đề](#bối-cảnh-và-vấn-đề)
   - [Mục tiêu xây dựng](#mục-tiêu-xây-dựng)
   - [Đối tượng sử dụng](#đối-tượng-sử-dụng)
   - [Phạm vi ứng dụng](#phạm-vi-ứng-dụng)
   - [Giá trị thực tiễn](#giá-trị-thực-tiễn)
2. [Chức năng chính](#2-chức-năng-chính)
   - [Xác thực và Quản lý tài khoản sinh viên](#xác-thực-và-quản-lý-tài-khoản-sinh-viên)
   - [Bảng tin và Tương tác cộng đồng](#bảng-tin-và-tương-tác-cộng-đồng)
   - [Kho học liệu số và Đọc tài liệu (DocsHub)](#kho-học-liệu-số-và-đọc-tài-liệu-docshub)
   - [Trợ lý trí tuệ nhân tạo (PU Assistant)](#trợ-lý-trí-tuệ-nhân-tạo-pu-assistant)
   - [Nhắn tin và Trò chuyện thời gian thực](#nhắn-tin-và-trò-chuyện-thời-gian-thực)
   - [Câu lạc bộ và Sự kiện sinh viên](#câu-lạc-bộ-và-sự-kiện-sinh-viên)
   - [Nhóm học tập và Ghi chú cá nhân](#nhóm-học-tập-và-ghi-chú-cá-nhân)
   - [Kiểm duyệt nội dung và An toàn cộng đồng](#kiểm-duyệt-nội-dung-và-an-toàn-cộng-đồng)
   - [Cổng Quản trị viên (Admin Portal)](#cổng-quản-trị-viên-admin-portal)
   - [Đa ngôn ngữ và Giao diện](#đa-ngôn-ngữ-và-giao-diện)
3. [Công nghệ sử dụng](#3-công-nghệ-sử-dụng)
4. [Kiến trúc hệ thống](#4-kiến-trúc-hệ-thống)
   - [Mô hình Clean Architecture](#mô-hình-clean-architecture)
   - [Cấu trúc thư mục mã nguồn](#cấu-trúc-thư-mục-mã-nguồn)
5. [Yêu cầu môi trường](#5-yêu-cầu-môi-trường)
6. [Hướng dẫn cài đặt và chạy dự án](#6-hướng-dẫn-cài-đặt-và-chạy-dự-án)
7. [Cấu hình Firebase và Dịch vụ bên ngoài](#7-cấu-hình-firebase-và-dịch-vụ-bên-ngoài)
8. [Kiểm thử và Phân tích mã nguồn](#8-kiểm-thử-và-phân-tích-mã-nguồn)
9. [Trạng thái hiện tại và Giới hạn](#9-trạng-thái-hiện-tại-và-giới-hạn)
10. [Quy chuẩn đóng góp](#10-quy-chuẩn-đóng-góp)
11. [Tác giả và Giấy phép](#11-tác-giả-và-giấy-phép)

---

## 1. Giới thiệu dự án

### Bối cảnh và vấn đề

Trong môi trường giáo dục đại học hiện đại, việc kết nối thông tin giữa sinh viên, giảng viên và các câu lạc bộ thường bị phân tán qua nhiều kênh không đồng nhất như mạng xã hội bên ngoài, diễn đàn tự phát hoặc email thông báo. Điều này dẫn đến các hạn chế:

- Khó khăn trong việc tìm kiếm tài liệu học tập chính thống theo từng môn học và khoa đào tạo.
- Thiếu không gian trao đổi học thuật lành mạnh, thường bị lẫn tạp với tin tức thương mại và thông tin không được kiểm duyệt.
- Sinh viên mới gặp khó khăn khi tiếp cận thông tin về câu lạc bộ, sự kiện và các hoạt động phong trào trong trường.
- Thiếu công cụ hỗ trợ hỏi đáp tức thời về quy chế đào tạo, tín chỉ và học phần đại học.

### Mục tiêu xây dựng

Dự án **PU Connection** được phát triển nhằm mục đích xây dựng một mạng xã hội nội bộ chuyên biệt, an toàn và tối ưu cho sinh viên Trường Đại học Phenikaa (Phenikaa University). Hệ thống kết hợp giữa tính năng giao lưu kết nối sinh viên với các công cụ học tập thiết thực, hướng tới việc hình thành một hệ sinh thái số văn minh trong nhà trường.

### Đối tượng sử dụng

- **Sinh viên Trường Đại học Phenikaa:** Trao đổi bài tập, chia sẻ học liệu, kết bạn, nhắn tin, tham gia câu lạc bộ, sự kiện và nhận tư vấn từ trợ lý AI.
- **Ban chủ nhiệm Câu lạc bộ:** Đăng tải thông tin hoạt động, tổ chức sự kiện, phát hành vé điện tử và gửi đề xuất thành lập câu lạc bộ mới.
- **Quản trị viên hệ thống (Admin):** Kiểm duyệt nội dung, xử lý báo cáo vi phạm, quản lý người dùng, phê duyệt hồ sơ câu lạc bộ và giám sát an toàn thông tin toàn hệ thống.

### Phạm vi ứng dụng

Ứng dụng hướng tới triển khai đa nền tảng (ưu tiên Android, hỗ trợ iOS và Web Responsive), sử dụng tài nguyên đám mây với cơ chế bảo mật cao và chi phí vận hành tối ưu.

### Giá trị thực tiễn

- Tập trung hóa dữ liệu học tập và thông tin học đường tại một nền tảng duy nhất.
- Nâng cao tính tự giác và văn hóa ứng xử trên mạng thông qua hệ thống lọc ngôn từ vi phạm tự động.
- Ứng dụng công nghệ Generative AI để hỗ trợ giải đáp thắc mắc học vụ 24/7.

---

## 2. Chức năng chính

### Xác thực và Quản lý tài khoản sinh viên

- **Đăng ký và Đăng nhập:** Hỗ trợ đăng nhập qua Email/Mật khẩu hoặc Google Sign-In. Xác thực tên miền email học đường (`@st.phenikaa-uni.edu.vn`, `@phenikaa-uni.edu.vn`).
- **Xác thực thông tin sinh viên:** Đối chiếu mã số sinh viên, họ tên và chuyên ngành với danh bạ sinh viên nội bộ (`phenikaa_students`).
- **Hồ sơ cá nhân:** Cập nhật ảnh đại diện, ảnh bìa (lưu trữ đám mây qua Cloudinary), tiểu sử, chuyên ngành, khóa học và niên khóa.
- **Mã QR sinh viên:** Tạo mã QR định danh cá nhân và hỗ trợ quét mã QR sinh viên trực tiếp bằng camera thiết bị để tra cứu hồ sơ nhanh chóng.
- **Bảo mật tài khoản:** Hỗ trợ đổi mật khẩu, quên mật khẩu và cơ chế ghi nhớ phiên đăng nhập an toàn.

### Bảng tin và Tương tác cộng đồng

- **Đăng bài viết:** Đăng tải nội dung học tập, chia sẻ thông tin, đính kèm hình ảnh và gắn thẻ mã môn học (subject code), hashtag chuyên môn.
- **Gắn thẻ sinh viên:** Cho phép tìm kiếm và gắn thẻ bạn bè, bạn học vào bài viết.
- **Tương tác thời gian thực:** Thả tim (Like/Unlike) và bình luận (Comments) với cơ chế cập nhật trạng thái tức thời.
- **Bộ lọc bảng tin:** Phân loại hiển thị bài viết theo: Toàn trường, Theo môn học quan tâm, Bài viết của bạn bè.
- **Lưu bài viết:** Lưu trữ các bài viết hữu ích vào danh mục bài viết đã lưu để xem lại sau.

### Kho học liệu số và Đọc tài liệu (DocsHub)

- **Đăng tải tài liệu:** Sinh viên có thể chia sẻ tài liệu học tập, giáo trình, đề cương ôn tập (định dạng PDF, DOCX, TXT...).
- **Tìm kiếm và Phân loại:** Lọc tài liệu theo môn học, học kỳ, khoa đào tạo hoặc từ khóa tìm kiếm.
- **Xem trực tiếp (In-App PDF Viewer):** Tích hợp trình đọc tệp PDF trực tiếp trong ứng dụng mà không cần mở phần mềm ngoài.
- **Mở và Tải về thiết bị:** Hỗ trợ tải tài liệu về máy và mở thông qua các ứng dụng văn phòng tương thích.
- **Đánh giá và Nhận xét:** Hệ thống xếp hạng điểm sao (1 đến 5 sao) và bình luận phản hồi về chất lượng tài liệu.

### Trợ lý trí tuệ nhân tạo (PU Assistant)

- **Tích hợp Google Gemini:** Sử dụng mô hình `gemini-1.5-flash` thông qua REST API chuyên dụng.
- **Hỗ trợ học vụ Phenikaa:** Được huấn luyện qua prompt hệ thống chuẩn mực để giải đáp thắc mắc về học phần, quy chế tín chỉ, thang điểm đại học, địa điểm phòng học và hướng dẫn học tập.
- **Hỗ trợ phương pháp:** Gợi ý cách phân chia thời gian, tài liệu tham khảo và kỹ năng làm việc nhóm.

### Nhắn tin và Trò chuyện thời gian thực

- **Trò chuyện trực tiếp (1-1):** Nhắn tin văn bản thời gian thực giữa hai sinh viên qua Cloud Firestore.
- **Nhóm trò chuyện sinh viên:** Khả năng tạo nhóm chat, quản lý thành viên nhóm và cập nhật thông tin nhóm.
- **Đính kèm hình ảnh:** Gửi ảnh trực tiếp trong cuộc hội thoại với dung lượng tối ưu hóa.
- **Chỉ báo trạng thái:** Trạng thái online/offline, thông báo đang soạn tin nhắn (typing indicator) và trạng thái tin nhắn đã đọc (read receipts).

### Câu lạc bộ và Sự kiện sinh viên

- **Danh sách Câu lạc bộ:** Khám phá các câu lạc bộ học thuật, thể thao, tình nguyện và nghệ thuật của Phenikaa University.
- **Trang chi tiết CLB:** Hiển thị thông tin liên hệ, ban chủ nhiệm, tôn chỉ hoạt động và các bài viết liên quan.
- **Đề xuất thành lập CLB mới:** Cho phép đại diện sinh viên điền biểu mẫu xin cấp phép, đính kèm đề án và gửi trực tiếp đến Ban Quản trị xét duyệt.
- **Sự kiện học đường:** Xem lịch sự kiện, thông tin chi tiết và phát hành vé tham dự điện tử (Ticket Dialog).

### Nhóm học tập và Ghi chú cá nhân

- **Nhóm học tập (Study Groups):** Tìm kiếm và tham gia các nhóm ôn tập theo từng môn học cụ thể; theo dõi số lượng thành viên và mục tiêu học tập.
- **Ghi chú học tập (Personal Notes):** Công cụ ghi chú cá nhân hóa cho từng sinh viên, hỗ trợ tạo ghi chú, đánh dấu ghim, chỉnh sửa và quản lý lưu ý môn học bảo mật trên Firestore.

### Kiểm duyệt nội dung và An toàn cộng đồng

- **Bộ lọc từ ngữ không phù hợp (Bad Words Filter):** Service kiểm tra tự động phát hiện và chặn các vi phạm:
  - Từ ngữ tục tĩu, lăng mạ tiếng Việt (kể cả teencode, viết tắt như dkm, vcl, dcm...).
  - Ký tự lách luật chèn dấu chấm, dấu gạch nối (ví dụ: d.m, v-c-l, d_k_m...).
  - Chửi thề tiếng Anh phổ biến (fuck, shit, bitch, asshole...).
  - Hành vi tiêu cực học đường (thi hộ, làm hộ đồ án, sửa điểm portal...).
  - Hoạt động cá cược, cờ bạc trực tuyến.
  - Bảo vệ từ vựng học thuật, không chặn nhầm (zero false positives cho từ như: phân tích, tích lũy, vật lý, học tập...).
- **Chặn và Báo cáo vi phạm:** Người dùng có thể chặn tài khoản gây phiền toái hoặc gửi báo cáo bài viết/người dùng vi phạm kèm lý do chi tiết tới Quản trị viên.

### Cổng Quản trị viên (Admin Portal)

- **Bảo vệ quyền truy cập:** Route `/admin` được bảo vệ độc quyền bằng Router Guard. Chỉ tài khoản có cờ `isAdmin == true` và token xác thực hợp lệ mới được truy cập.
- **Bảng điều khiển thống kê (Dashboard):** Tổng hợp số lượng sinh viên, bài viết, tài liệu, báo cáo vi phạm và yêu cầu thành lập CLB.
- **Quản lý người dùng:** Tìm kiếm hồ sơ, phân quyền, khóa hoặc mở khóa tài khoản người dùng vi phạm.
- **Kiểm duyệt báo cáo:** Xem xét danh sách báo cáo nội dung, thực hiện xóa bài viết hoặc bỏ qua báo cáo kèm ghi nhận nhật ký.
- **Phê duyệt Câu lạc bộ:** Xem xét đề án thành lập CLB, phê duyệt (Approved) hoặc từ chối (Rejected) kèm lý do giải trình.
- **Nhật ký kiểm toán (Admin Audit Logs):** Tự động ghi lại toàn bộ lịch sử thao tác của Quản trị viên để bảo đảm minh bạch.

### Đa ngôn ngữ và Giao diện

- **Hỗ trợ 2 ngôn ngữ:** Tiếng Việt (mặc định) và Tiếng Anh, được xây dựng theo chuẩn `flutter_localizations` và file ARB (`app_vi.arb`, `app_en.arb`).
- **Giao diện đa chế độ:** Hỗ trợ Sáng (Light Mode) và Tối (Dark Mode) với bảng màu nhận diện thương hiệu Đại học Phenikaa (`#203864`, `#C8102E`).

---

## 3. Công nghệ sử dụng

| Công nghệ / Thư viện | Phiên bản | Vai trò trong dự án |
| :--- | :--- | :--- |
| **Flutter SDK** | >= 3.8.1 | Framework phát triển giao diện ứng dụng đa nền tảng |
| **Dart SDK** | ^3.8.1 | Ngôn ngữ lập trình chính của dự án |
| **flutter_bloc** | ^9.1.1 | Quản lý trạng thái hệ thống theo kiến trúc BLoC / Cubit |
| **get_it** | ^9.2.1 | Service Locator phục vụ Dependency Injection (DI) |
| **go_router** | ^17.0.0 | Quản lý điều hướng, phân tuyến và bảo vệ Route Guard (/admin) |
| **firebase_core** | ^4.14.0 | Khởi tạo và liên kết các dịch vụ Firebase |
| **firebase_auth** | ^6.6.1 | Xác thực người dùng qua Email/Mật khẩu và phiên đăng nhập |
| **cloud_firestore** | ^6.9.0 | Cơ sở dữ liệu NoSQL đám mây lưu trữ thời gian thực |
| **firebase_messaging** | ^16.7.0 | Tiếp nhận thông báo đẩy Firebase Cloud Messaging (FCM) |
| **google_sign_in** | ^6.2.2 | Hỗ trợ xác thực đăng nhập qua tài khoản Google |
| **dio** | ^5.8.0+1 | HTTP client gửi yêu cầu tải lên REST API tới Cloudinary |
| **google_generative_ai** | ^0.4.6 | Tích hợp mô hình AI Google Gemini 1.5 Flash cho trợ lý ảo |
| **flutter_local_notifications** | ^20.1.0 | Hiển thị thông báo cục bộ trên thiết bị người dùng |
| **flutter_pdfview** | ^1.4.3 | Trình kết xuất và hiển thị tệp PDF nội tuyến trong app |
| **open_filex** | ^4.5.0 | Mở tệp tin bằng các ứng dụng mặc định của hệ điều hành |
| **qr_flutter** | ^4.1.0 | Kết xuất mã QR định danh sinh viên cá nhân |
| **mobile_scanner** | ^7.4.2 | Quét mã QR sinh viên qua camera thời gian thực |
| **image_picker** | ^1.1.2 | Chọn hình ảnh từ thư viện hoặc chụp từ camera |
| **file_picker** | ^8.1.7 | Chọn tệp tài liệu văn bản để đăng tải lên kho học liệu |
| **shared_preferences** | ^2.5.3 | Lưu trữ cấu hình cục bộ (Theme, Ngôn ngữ, Bộ nhớ đệm offline) |
| **intl** | ^0.20.2 | Định dạng ngày giờ và hỗ trợ bản địa hóa ngôn ngữ |
| **timeago** | ^3.7.0 | Hiển thị mốc thời gian tương đối theo chuẩn tiếng Việt |

---

## 4. Kiến trúc hệ thống

### Mô hình Clean Architecture

Dự án được xây dựng theo mô hình **Clean Architecture**, phân tách độc lập giữa các tầng trách nhiệm theo nguyên lý thiết kế phần mềm SOLID:

1. **Presentation Layer (Tầng Giao diện):**
   - **Pages:** Các màn hình hiển thị chính của ứng dụng.
   - **Widgets:** Các thành phần giao diện nhỏ, tái sử dụng (Card, BottomSheet, Dialog).
   - **Cubit / State:** Quản lý trạng thái giao diện, tiếp nhận tương tác người dùng và phát ra trạng thái tương ứng.

2. **Domain Layer (Tầng Nghiệp vụ):**
   - **Entities:** Đối tượng dữ liệu thuần Dart đại diện cho khái niệm nghiệp vụ lõi (User, Post, Comment, Document, Club...).
   - **Repositories (Abstract Interfaces):** Hợp đồng giao tiếp dữ liệu, độc lập hoàn toàn với nguồn dữ liệu bên ngoài.

3. **Data Layer (Tầng Dữ liệu):**
   - **Models:** Kế thừa từ Entities, bổ sung các phương thức chuyển đổi dữ liệu (`toMap()`, `fromFirestore()`, `toJson()`).
   - **Repositories Implementation:** Cài đặt cụ thể các giao diện từ Domain, thực hiện đọc/ghi dữ liệu từ Cloud Firestore hoặc dịch vụ REST API.
   - **Datasources:** Các nguồn cấp dữ liệu cục bộ hoặc danh bạ sinh viên xác thực.

4. **Core Layer (Tầng Dùng chung):**
   - **Constants:** Hằng số hệ thống, tên các Collection Firestore, cấu hình tên miền email Phenikaa.
   - **DI (Dependency Injection):** Đăng ký dịch vụ, repository và cubit thông qua GetIt container (`injection_container.dart`).
   - **Routes:** Định nghĩa bản đồ tuyến đường ứng dụng và kiểm soát phân quyền (`app_router.dart`).
   - **Services:** Các dịch vụ tiện ích độc lập (Cloudinary, Gemini AI, Bad Words Filter, Offline Cache, Notifications, Student QR).
   - **Theme:** Cấu hình chủ đề sáng/tối chuẩn màu sắc trường học.
   - **Localization:** Cấu hình đa ngôn ngữ và chuyển đổi ngữ cảnh giao diện.

### Cấu trúc thư mục mã nguồn

```text
pu_connection/
├── android/                        # Cấu hình dự án Android Native (Gradle Kotlin DSL)
├── ios/                            # Cấu hình dự án iOS Native
├── assets/                         # Tài nguyên đồ họa, logo Phenikaa
│   ├── images/
│   └── logo/
├── lib/
│   ├── core/                       # Thành phần dùng chung toàn ứng dụng
│   │   ├── constants/              # Hằng số hệ thống và tên collection Firebase
│   │   ├── di/                     # Khởi tạo Dependency Injection (GetIt)
│   │   ├── localization/           # LocaleCubit điều khiển ngôn ngữ
│   │   ├── models/                 # Model dùng chung
│   │   ├── routes/                 # Cấu hình GoRouter và Router Guard
│   │   ├── services/               # Dịch vụ Cloudinary, Gemini, Filter, QR, FCM
│   │   ├── theme/                  # Định nghĩa AppTheme và ThemeCubit
│   │   └── widgets/                # Widget giao diện dùng chung
│   ├── features/                   # Các phân hệ chức năng theo Clean Architecture
│   │   ├── admin/                  # Cổng Quản trị viên (Thống kê, Duyệt CLB, Xử lý vi phạm)
│   │   ├── auth/                   # Xác thực, Đăng nhập, Hồ sơ sinh viên, Mã QR
│   │   ├── chat/                   # Hội thoại nhắn tin 1-1 và Nhóm chat thời gian thực
│   │   ├── clubs/                  # Quản lý Câu lạc bộ và Yêu cầu thành lập CLB
│   │   ├── documents/              # DocsHub - Kho học liệu số và xem PDF
│   │   ├── events/                 # Sự kiện học đường và vé điện tử
│   │   ├── feed/                   # Bảng tin, Bài viết, Bình luận, Tương tác
│   │   ├── friends/                # Quản lý Bạn bè, Lời mời kết bạn
│   │   ├── main/                   # Khung điều hướng chính (MainNavigationPage)
│   │   ├── moderation/             # Chặn người dùng và Báo cáo vi phạm
│   │   ├── notes/                  # Ghi chú học tập cá nhân
│   │   ├── notifications/          # Trung tâm thông báo tương tác trong app
│   │   ├── onboarding/             # Màn hình Splash và Giới thiệu (Intro)
│   │   ├── saved_posts/            # Danh sách bài viết học tập đã lưu
│   │   └── study_groups/           # Nhóm học tập theo môn học
│   ├── l10n/                       # Tệp cấu hình đa ngôn ngữ (ARB và localization sinh tự động)
│   ├── firebase_options.dart       # Cấu hình nền tảng Firebase sinh từ FlutterFire CLI
│   └── main.dart                   # Điểm khởi chạy ứng dụng (Entry Point)
├── test/                           # Bộ kiểm thử tự động (Unit Test & Integration Test)
├── firestore.rules                 # Quy tắc bảo mật dữ liệu Cloud Firestore
├── pubspec.yaml                    # Quản lý thư viện và cấu hình gói Flutter
└── README.md                       # Tài liệu hướng dẫn dự án
```

---

## 5. Yêu cầu môi trường

Để cài đặt và biên dịch dự án PU Connection, môi trường phát triển cần đáp ứng các yêu cầu sau:

- **Hệ điều hành:** Windows 10/11, macOS, hoặc Linux.
- **Flutter SDK:** Phiên bản `>= 3.27.0` (tương thích Dart SDK `^3.8.1`).
- **Dart SDK:** Phiên bản `>= 3.8.1 < 4.0.0`.
- **Java Development Kit (JDK):** Phiên bản `JDK 17` (yêu cầu để tương thích với Android Gradle Plugin và Gradle Kotlin DSL).
- **Android SDK:**
  - `compileSdk`: 36
  - `minSdk`: 23 (Android 6.0 Marshmallow trở lên)
  - `targetSdk`: Mặc định theo Flutter Target SDK
- **Trình soạn thảo khuyến nghị:** Visual Studio Code hoặc Android Studio (đã cài Flutter & Dart plugins).

Kiểm tra tính sẵn sàng của môi trường bằng lệnh:

```bash
flutter doctor
```

---

## 6. Hướng dẫn cài đặt và chạy dự án

### Bước 1: Tải mã nguồn dự án

Sử dụng Git để lấy mã nguồn từ kho lưu trữ:

```bash
git clone https://github.com/your-username/pu_connection.git
cd pu_connection
```

### Bước 2: Cài đặt các gói phụ thuộc (Dependencies)

Chạy lệnh tải và đồng bộ các gói thư viện được khai báo trong `pubspec.yaml`:

```bash
flutter pub get
```

### Bước 3: Cấu hình tệp Firebase

Dự án yêu cầu liên kết với dự án Firebase của bạn:

1. Đặt tệp cấu hình `google-services.json` (dành cho Android) vào đường dẫn:
   ```text
   android/app/google-services.json
   ```
2. Đặt tệp cấu hình `GoogleService-Info.plist` (nếu chạy iOS) vào:
   ```text
   ios/Runner/GoogleService-Info.plist
   ```
3. Nếu sử dụng dự án Firebase riêng, hãy cấu hình lại tệp `lib/firebase_options.dart` thông qua công cụ FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

### Bước 4: Cấu hình biến môi trường và khóa dịch vụ (Tùy chọn)

Để sử dụng đầy đủ tính năng AI (PU Assistant) và Lưu trữ đám mây (Cloudinary), truyền các tham số thông qua cờ `--dart-define` khi chạy ứng dụng:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

*Lưu ý: Không lưu trực tiếp API Key bí mật vào mã nguồn công khai.*

### Bước 5: Chạy ứng dụng trên thiết bị hoặc máy ảo

Kiểm tra danh sách thiết bị đang kết nối:

```bash
flutter devices
```

Khởi chạy ứng dụng ở chế độ Debug:

```bash
flutter run
```

---

## 7. Cấu hình Firebase và Dịch vụ bên ngoài

### 1. Cloud Firestore và Quy tắc bảo mật (`firestore.rules`)

Toàn bộ quyền truy cập dữ liệu được quản lý nghiêm ngặt bởi tệp `firestore.rules` tại thư mục gốc của dự án:

- **Bảo vệ Cổng Quản trị:** Collection `admins` chỉ cho phép đọc bởi tài khoản có quyền Admin và **nghiêm cấm hoàn toàn thao tác ghi từ client-side** (chỉ có thể thiết lập qua Firebase Admin SDK trên Backend).
- **Kiểm soát thông tin người dùng:** Người dùng thông thường không thể tự gán quyền `admin` (`userType != 'admin'`) khi tạo hoặc cập nhật hồ sơ.
- **Bảo vệ bài viết và bình luận:** Chỉ chủ sở hữu mới có quyền chỉnh sửa/xóa bài viết, bình luận của mình; Quản trị viên có toàn quyền xóa nội dung vi phạm.
- **Nhật ký kiểm toán:** Mọi bản ghi trong `admin_audit_logs` chỉ có thể tạo bởi Quản trị viên và không thể bị sửa/xóa.

Cập nhật quy tắc lên Firebase:

```bash
firebase deploy --only firestore:rules
```

### 2. Dịch vụ lưu trữ tệp (Cloudinary REST API)

Dự án sử dụng giải pháp tải lên trực tiếp thông qua Cloudinary Upload Preset mà không cần lưu trữ Private Key trên ứng dụng client:

- Tối ưu hóa giới hạn dung lượng tải lên: Tối đa 10MB cho tệp ảnh (`jpg`, `jpeg`, `png`, `webp`, `gif`, `heic`) và tối đa 25MB cho tệp tài liệu (`pdf`, `doc`, `docx`, `xls`, `xlsx`, `ppt`, `pptx`, `txt`).
- Tự động nén và phân phối qua CDN toàn cầu.

### 3. Dịch vụ Trí tuệ nhân tạo (Google Gemini 1.5 Flash)

Trợ lý học vụ PU Assistant kết nối trực tiếp với Google Generative AI API:

- Sử dụng mô hình `gemini-1.5-flash` phản hồi tốc độ cao.
- Hệ thống duy trì phiên hội thoại liên tục (`ChatSession`) để ghi nhớ ngữ cảnh hỏi đáp của người học.

---

## 8. Kiểm thử và Phân tích mã nguồn

Dự án duy trì bộ kiểm thử tự động toàn diện trong thư mục `test/`, bao gồm 20 tệp kiểm thử chuyên sâu:

| Tệp kiểm thử | Phạm vi kiểm tra |
| :--- | :--- |
| `test/bad_words_filter_test.dart` | Kiểm thử 10 kịch bản lọc ngôn từ xấu tiếng Việt, teencode, tiếng Anh, gian lận học vụ và kiểm tra chống nhận diện nhầm từ học thuật |
| `test/admin_test.dart` | Kiểm tra logic nghiệp vụ bảng điều khiển quản trị, phê duyệt câu lạc bộ và xử lý vi phạm |
| `test/auth_profile_test.dart` | Kiểm tra quy trình xác thực, tính hợp lệ của email học đường và cập nhật hồ sơ |
| `test/feed_test.dart` | Kiểm tra tạo bài viết, thích bài viết, bình luận và lọc bài viết |
| `test/chat_test.dart` | Kiểm tra khởi tạo hội thoại, gửi nhận tin nhắn và trạng thái đọc |
| `test/document_test.dart` | Kiểm tra luồng tải lên, tìm kiếm và xếp hạng tài liệu DocsHub |
| `test/club_test.dart` | Kiểm tra khởi tạo câu lạc bộ và quy trình gửi đơn đề xuất thành lập |
| `test/event_test.dart` | Kiểm tra đăng ký sự kiện và xuất vé điện tử |
| `test/friend_test.dart` | Kiểm tra mối quan hệ bạn bè, gửi lời mời và phản hồi kết bạn |
| `test/gemini_service_test.dart` | Kiểm tra khởi tạo và kết nối dịch vụ Gemini AI |
| `test/moderation_test.dart` | Kiểm tra cơ chế chặn người dùng và lập báo cáo vi phạm |
| `test/notes_test.dart` | Kiểm tra nghiệp vụ tạo, chỉnh sửa và ghim ghi chú học tập |
| `test/notification_center_test.dart` | Kiểm tra lọc thông báo và đánh dấu đã đọc |
| `test/notification_test.dart` | Kiểm tra cấu hình và tiếp nhận thông báo đẩy FCM |
| `test/offline_cache_test.dart` | Kiểm tra lưu và phục hồi dữ liệu đệm ngoại tuyến qua SharedPreferences |
| `test/remediation_verification_test.dart` | Kiểm tra xác minh các bản vá lỗi và hồi quy hệ thống |
| `test/saved_posts_test.dart` | Kiểm tra lưu và bỏ lưu bài viết học tập |
| `test/student_qr_test.dart` | Kiểm tra mã hóa và giải mã thông tin định danh mã QR sinh viên |
| `test/study_group_test.dart` | Kiểm tra thành lập và quản lý nhóm học tập theo môn học |
| `test/widget_test.dart` | Kiểm tra khởi chạy cây widget ứng dụng |

### Lệnh chạy phân tích cú pháp mã nguồn (Linter):

```bash
flutter analyze
```

### Lệnh chạy toàn bộ bài kiểm thử tự động:

```bash
flutter test
```

### Lệnh chạy một bài kiểm thử cụ thể (Ví dụ: Bad Words Filter):

```bash
flutter test test/bad_words_filter_test.dart
```

---

## 9. Trạng thái hiện tại và Giới hạn

### Những phần đã hoàn thiện và hoạt động ổn định

- Toàn bộ luồng xác thực đăng nhập, đăng ký bằng email học đường và Google Sign-In.
- Bảng tin sinh viên, đăng bài viết kèm hình ảnh, thích, bình luận và phân loại môn học.
- Bộ lọc ngôn từ vi phạm tự động trên bài viết và bình luận, ngăn chặn hành vi lách luật.
- Kho học liệu DocsHub, đọc tệp PDF nội tuyến và hệ thống đánh giá tài liệu.
- Trợ lý AI PU Assistant trả lời câu hỏi học vụ Phenikaa bằng Gemini 1.5 Flash.
- Nhắn tin trực tiếp 1-1 và tạo nhóm trò chuyện thời gian thực.
- Cổng Quản trị viên (`/admin`) với khả năng phân quyền nghiêm ngặt, thống kê số liệu và duyệt yêu cầu CLB.
- Hệ thống định danh mã QR sinh viên cá nhân và quét mã QR.
- Hỗ trợ đa ngôn ngữ (Tiếng Việt, Tiếng Anh) và giao diện Sáng / Tối.

### Những phần đang hoàn thiện và Giới hạn hệ thống

- **Kết nối mạng:** Ứng dụng chủ yếu phụ thuộc vào kết nối Internet để đồng bộ với Cloud Firestore; cơ chế ngoại tuyến (Offline Cache) hiện tại chủ yếu áp dụng lưu trữ cấu hình giao diện và một phần danh mục cơ bản.
- **Phạm vi bộ lọc ngôn từ:** Bộ lọc `BadWordsFilterService` hiện tại đã bao phủ hoàn toàn Bảng tin và Bình luận; chưa tích hợp trực tiếp vào luồng trò chuyện tin nhắn riêng (1-1) và mô tả đề xuất CLB.
- **Thông báo đẩy trên Android 13+:** Người dùng cần chủ động cấp quyền nhận thông báo (Notification Permission) trong lần đầu mở ứng dụng để nhận thông báo đẩy qua FCM.

---

## 10. Quy chuẩn đóng góp

Để đảm bảo tính nhất quán và chất lượng mã nguồn của dự án, người tham gia phát triển cần tuân thủ các quy tắc sau:

1. **Tuân thủ Clean Architecture:** Đặt code đúng tầng chức năng (Presentation, Domain, Data). Không gọi trực tiếp dịch vụ dữ liệu ngoài từ Widget mà phải thông qua Cubit/Repository.
2. **Quy chuẩn đặt nhánh Git:**
   - Nhánh tính năng mới: `feature/ten-tinh-nang`
   - Nhánh sửa lỗi: `fix/ten-loi`
   - Nhánh tài liệu: `docs/noi-dung-cap-nhat`
3. **Quy chuẩn thông điệp Commit:** Sử dụng thông điệp rõ ràng, mô tả đúng thay đổi (Ví dụ: `feat: them bo loc tai lieu theo khoa`, `fix: sua loi tran bo dem tai admin portal`).
4. **Kiểm tra trước khi tạo Pull Request:** Bắt buộc chạy `flutter analyze` và `flutter test` bảo đảm không có lỗi cảnh báo hoặc kiểm thử thất bại.

---

## 11. Tác giả và Giấy phép

- **Đơn vị bảo trợ học thuật:** Trường Đại học Phenikaa (Phenikaa University).
- **Mục đích phát triển:** Dự án được nghiên cứu và xây dựng trong khuôn khổ đồ án sinh viên phục vụ cộng đồng học thuật Phenikaa.
- **Giấy phép sử dụng:** Tài liệu và mã nguồn dự án được lưu hành nội bộ phục vụ mục đích nghiên cứu, học tập và phát triển phi thương mại.
