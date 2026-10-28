# HƯỚNG DẪN QUẢN TRỊ VIÊN & PHÂN QUYỀN AN TOÀN (PU CONNECTION)

Tài liệu này hướng dẫn cách cấu hình, khởi tạo tài khoản Quản trị viên (Admin) và thiết lập phân quyền an toàn cho dự án **PU Connection**.

---

## 1. Triết Lý & Cơ Chế Bảo Mật

- **Màn hình đăng nhập chung**: Quản trị viên đăng nhập tại cùng màn hình đăng nhập sinh viên (`LoginPage`), không có giao diện đăng nhập riêng và không yêu cầu chọn vai trò.
- **Không hard-code thông tin nhạy cảm**: Tuyệt đối không lưu email, mật khẩu quản trị hoặc khóa bảo mật trong mã nguồn Flutter.
- **Xác thực quyền qua nguồn tin cậy**:
  1. **Firebase Auth Custom Claims**: Quyền `{ admin: true, role: 'admin' }` được gán trực tiếp vào JWT Token bởi Firebase Admin SDK.
  2. **Collection `/admins/{uid}` trên Cloud Firestore**: Chỉ lưu thông tin admin đã được xác nhận.
  3. **Firestore Security Rules**: Cấm hoàn toàn client-side write vào `/admins` và cấm người dùng tự sửa trường `userType`, `role`, `isBanned` của chính mình.
- **Điều hướng tự động**:
  - Đăng nhập thành công -> Kiểm tra quyền thực tế:
    - Nếu là Admin hợp lệ -> Tự động chuyển đến `/admin` (Admin Dashboard).
    - Nếu là sinh viên thông thường -> Chuyển đến `/home`.
  - Bảo vệ route `/admin`: Chặn người dùng thường hoặc khách vãng lai truy cập trực tiếp bằng URL hay deep link.

---

## 2. Các Bước Cấu Hình Trên Firebase Console

### Bước 2.1: Kích hoạt Email/Password Provider
1. Truy cập [Firebase Console](https://console.firebase.google.com).
2. Chọn dự án `pu-connection-797f2`.
3. Vào **Authentication** -> **Sign-in method**.
4. Đảm bảo provider **Email/Password** đang ở trạng thái **Enabled**.

### Bước 2.2: Tải Service Account Key (Dành cho Backend Script)
1. Trong Firebase Console, vào **Project Settings** (biểu tượng bánh răng ⚙️) -> tab **Service accounts**.
2. Chọn **Node.js** và nhấn nút **Generate new private key**.
3. Lưu tệp JSON tải về vào thư mục `scripts/` trong dự án và đổi tên thành:
   ```
   scripts/serviceAccountKey.json
   ```
   *(Lưu ý: Tệp này chứa khóa bảo mật máy chủ, đã được thêm vào `.gitignore` để tránh commit lên Git).*

### Bước 2.3: Triển khai Firestore Security Rules
1. Trong Firebase Console, vào **Firestore Database** -> tab **Rules**.
2. Sao chép toàn bộ nội dung trong tệp [`firestore.rules`](file:///D:/Study/pu_connection/firestore.rules) dán vào và nhấn **Publish**.
3. Hoặc triển khai qua Firebase CLI:
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## 3. Khởi Tạo & Quản Lý Tài Khoản Admin

Cài đặt thư viện Node.js nếu chưa có:
```bash
npm install firebase-admin
```

### 3.1 Khởi tạo tài khoản Admin lần đầu:
Chạy lệnh:
```bash
node scripts/admin_manager.js create admin.phongctsv@phenikaa-uni.edu.vn MatKhauBaoMat@2026 "Ban Quản trị Phenikaa"
```
*Script sẽ tự động:*
- Tạo tài khoản trên Firebase Authentication với email và mật khẩu an toàn.
- Đánh dấu `emailVerified: true`.
- Gán Custom User Claims: `{ admin: true, role: 'admin' }`.
- Tạo bản ghi trong collection bảo mật `/admins/{uid}`.
- Tạo hồ sơ trong collection `/users/{uid}` với `userType = 'admin'`.

### 3.2 Gán quyền Admin cho tài khoản có sẵn:
```bash
node scripts/admin_manager.js grant admin.phongctsv@phenikaa-uni.edu.vn
```

### 3.3 Thu hồi quyền Admin (Revoke Privileges):
```bash
node scripts/admin_manager.js revoke admin.phongctsv@phenikaa-uni.edu.vn
```
*Khi thu hồi quyền, người dùng sẽ trở về trạng thái sinh viên thông thường và ngay lập tức bị chặn khỏi toàn bộ route `/admin`.*

### 3.4 Xem danh sách Quản trị viên hiện tại:
```bash
node scripts/admin_manager.js list
```

### 3.5 Đồng bộ danh bạ sinh viên mẫu vào Firestore (`phenikaa_students`):
```bash
node scripts/admin_manager.js seed-students
```
*Script sẽ đẩy toàn bộ danh bạ sinh viên chuẩn (bao gồm các sinh viên mới như 23010304, 23010381, 23010389, 23010390,...) lên Firestore `/phenikaa_students/{studentId}` với trạng thái `isActivated: false`, sẵn sàng để sinh viên tự kích hoạt tài khoản.*
