/**
 * ============================================================================
 * PU CONNECTION - FIREBASE ADMIN MANAGEMENT SCRIPT
 * ============================================================================
 * Công cụ quản trị backend sử dụng Firebase Admin SDK để:
 * 1. Khởi tạo tài khoản Quản trị viên (Admin) lần đầu trên Firebase Authentication.
 * 2. Gán Custom User Claims ({ admin: true, role: 'admin' }) một cách an toàn.
 * 3. Tạo bản ghi trong Firestore collection bảo mật '/admins/{uid}'.
 * 4. Thu hồi quyền Quản trị viên (Revoke Admin Privileges) khi cần.
 * 5. Liệt kê danh sách tất cả các Quản trị viên trong hệ thống.
 *
 * CÁCH SỬ DỤNG:
 * 1. Cài đặt thư viện:
 *    npm install firebase-admin
 *
 * 2. Tải Service Account Key từ Firebase Console:
 *    Project Settings -> Service accounts -> Generate new private key
 *    Lưu file json tải về vào thư mục scripts/ và đặt tên là: serviceAccountKey.json
 *
 * 3. Chạy các lệnh:
 *    - Khởi tạo Admin mới:
 *      node scripts/admin_manager.js create <email> <password> <displayName>
 *      Ví dụ: node scripts/admin_manager.js create admin.phongctsv@phenikaa-uni.edu.vn Secr3tPass@2026 "Ban Quản trị Phenikaa"
 *
 *    - Gán quyền Admin cho tài khoản đã có sẵn trên Firebase:
 *      node scripts/admin_manager.js grant <email_hoac_uid>
 *
 *    - Thu hồi quyền Admin:
 *      node scripts/admin_manager.js revoke <email_hoac_uid>
 *
 *    - Liệt kê danh sách Admin:
 *      node scripts/admin_manager.js list
 * ============================================================================
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Đường dẫn serviceAccountKey.json
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('\x1b[31m[LỖI]\x1b[0m Không tìm thấy tệp serviceAccountKey.json tại:', serviceAccountPath);
  console.log('\x1b[33m[HƯỚNG DẪN CẤU HÌNH]:\x1b[0m');
  console.log('1. Đăng nhập https://console.firebase.google.com');
  console.log('2. Chọn dự án "pu-connection-797f2"');
  console.log('3. Vào Project settings -> Service accounts -> Nhấn "Generate new private key"');
  console.log('4. Đổi tên tệp tải về thành "serviceAccountKey.json" và đặt vào thư mục: scripts/');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

async function createAdmin(email, password, displayName = 'Ban Quản trị Phenikaa') {
  try {
    console.log(`\x1b[36m[BẮT ĐẦU]\x1b[0m Đang khởi tạo tài khoản Admin: ${email}...`);

    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log(`\x1b[33m[THÔNG BÁO]\x1b[0m Tài khoản ${email} đã tồn tại trên Firebase Auth (UID: ${userRecord.uid}). Tiến hành cập nhật quyền Admin...`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await auth.createUser({
          email: email,
          password: password,
          displayName: displayName,
          emailVerified: true,
        });
        console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã tạo tài khoản Firebase Auth mới (UID: ${userRecord.uid})`);
      } else {
        throw e;
      }
    }

    // Gán Custom Claims
    await auth.setCustomUserClaims(userRecord.uid, {
      admin: true,
      role: 'admin',
    });
    console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã gán Custom Claims: { admin: true, role: 'admin' } cho UID: ${userRecord.uid}`);

    // Ghi vào collection /admins/{uid}
    await db.collection('admins').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      displayName: displayName,
      role: 'admin',
      active: true,
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      grantedBy: 'Firebase Admin SDK Tool',
    }, { merge: true });
    console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã lưu bản ghi bảo mật vào Firestore: /admins/${userRecord.uid}`);

    // Cập nhật profile trong /users/{uid}
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      studentId: 'ADMIN',
      displayName: displayName,
      username: email.split('@')[0],
      faculty: 'Phòng Công tác Sinh viên',
      major: 'Quản trị hệ thống',
      cohort: 0,
      userType: 'admin',
      isVerified: true,
      isBanned: false,
    }, { merge: true });
    console.log(`\x1b[32m[HOÀN TẤT]\x1b[0m Tài khoản Quản trị viên đã sẵn sàng đăng nhập qua màn hình chung của ứng dụng!`);
  } catch (error) {
    console.error('\x1b[31m[LỖI KHỞI TẠO ADMIN]:\x1b[0m', error.message);
  }
}

async function grantAdmin(identifier) {
  try {
    let userRecord;
    if (identifier.includes('@')) {
      userRecord = await auth.getUserByEmail(identifier);
    } else {
      userRecord = await auth.getUser(identifier);
    }

    await auth.setCustomUserClaims(userRecord.uid, {
      admin: true,
      role: 'admin',
    });

    await db.collection('admins').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName || 'Quản trị viên',
      role: 'admin',
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await db.collection('users').doc(userRecord.uid).update({
      userType: 'admin',
    });

    console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã cấp quyền Admin cho: ${userRecord.email} (${userRecord.uid})`);
  } catch (error) {
    console.error('\x1b[31m[LỖI CẤP QUYỀN]:\x1b[0m', error.message);
  }
}

async function revokeAdmin(identifier) {
  try {
    let userRecord;
    if (identifier.includes('@')) {
      userRecord = await auth.getUserByEmail(identifier);
    } else {
      userRecord = await auth.getUser(identifier);
    }

    // Xóa custom claims
    await auth.setCustomUserClaims(userRecord.uid, {
      admin: false,
      role: 'student',
    });

    // Vô hiệu hóa trong /admins/{uid}
    await db.collection('admins').doc(userRecord.uid).set({
      active: false,
      revokedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Cập nhật lại userType trong /users/{uid}
    await db.collection('users').doc(userRecord.uid).update({
      userType: 'student',
    });

    console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã thu hồi quyền Admin của: ${userRecord.email} (${userRecord.uid})`);
  } catch (error) {
    console.error('\x1b[31m[LỖI THU HỒI QUYỀN]:\x1b[0m', error.message);
  }
}

async function listAdmins() {
  try {
    console.log('\x1b[36m[DANH SÁCH QUẢN TRỊ VIÊN HIỆN TẠI]:\x1b[0m');
    const snap = await db.collection('admins').where('active', '==', true).get();
    if (snap.empty) {
      console.log('Chưa có Quản trị viên nào trong hệ thống.');
      return;
    }

    snap.forEach((doc) => {
      const data = doc.data();
      console.log(`- UID: ${data.uid} | Email: ${data.email} | Tên: ${data.displayName}`);
    });
  } catch (error) {
    console.error('\x1b[31m[LỖI TRA CỨU]:\x1b[0m', error.message);
  }
}

/**
 * Đồng bộ danh bạ sinh viên mẫu vào Firestore collection 'phenikaa_students'
 */
async function seedStudents() {
  const defaultStudents = [
    { studentId: '23010304', fullName: 'Nguyễn Thành Long', email: '23010304@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Kỹ thuật phần mềm', cohort: 17, isActivated: false },
    { studentId: '23010381', fullName: 'Vũ Đức Minh', email: '23010381@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Kỹ thuật phần mềm', cohort: 17, isActivated: false },
    { studentId: '23010389', fullName: 'Trần Minh Hiếu', email: '23010389@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Kỹ thuật phần mềm', cohort: 17, isActivated: false },
    { studentId: '23010390', fullName: 'Hà Mạnh Long', email: '23010390@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Kỹ thuật phần mềm', cohort: 17, isActivated: false },
    { studentId: '23010111', fullName: 'Nguyễn Hoàng Nam', email: '23010111@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Khoa học máy tính', cohort: 17, isActivated: false },
    { studentId: '22010222', fullName: 'Trần Thị Thanh Mai', email: '22010222@st.phenikaa-uni.edu.vn', faculty: 'Công nghệ thông tin', major: 'Hệ thống thông tin', cohort: 16, isActivated: false },
    { studentId: '23020015', fullName: 'Vũ Đức Thắng', email: '23020015@st.phenikaa-uni.edu.vn', faculty: 'Kỹ thuật Ô tô & Năng lượng', major: 'Công nghệ kỹ thuật Ô tô', cohort: 17, isActivated: false },
    { studentId: '22020088', fullName: 'Đỗ Quang Huy', email: '22020088@st.phenikaa-uni.edu.vn', faculty: 'Kỹ thuật Ô tô & Năng lượng', major: 'Kỹ thuật Năng lượng', cohort: 16, isActivated: false },
    { studentId: '23030045', fullName: 'Lê Tuấn Anh', email: '23030045@st.phenikaa-uni.edu.vn', faculty: 'Điện - Điện tử', major: 'Điều khiển & Tự động hóa', cohort: 17, isActivated: false },
    { studentId: '23040102', fullName: 'Phạm Thu Trang', email: '23040102@st.phenikaa-uni.edu.vn', faculty: 'Kinh tế & Kinh doanh', major: 'Quản trị kinh doanh', cohort: 17, isActivated: false },
    { studentId: '22040055', fullName: 'Hoàng Minh Đức', email: '22040055@st.phenikaa-uni.edu.vn', faculty: 'Kinh tế & Kinh doanh', major: 'Tài chính - Ngân hàng', cohort: 16, isActivated: false },
    { studentId: '23050012', fullName: 'Nguyễn Thùy Linh', email: '23050012@st.phenikaa-uni.edu.vn', faculty: 'Dược', major: 'Dược học', cohort: 17, isActivated: false },
    { studentId: '23060008', fullName: 'Đặng Quốc Bảo', email: '23060008@st.phenikaa-uni.edu.vn', faculty: 'Y khoa', major: 'Y đa khoa', cohort: 17, isActivated: false },
    { studentId: '23070034', fullName: 'Bùi Phương Thảo', email: '23070034@st.phenikaa-uni.edu.vn', faculty: 'Ngôn ngữ Hàn Quốc', major: 'Ngôn ngữ Hàn Quốc', cohort: 17, isActivated: false },
  ];

  console.log(`\x1b[36m[BẮT ĐẦU]\x1b[0m Đang đồng bộ ${defaultStudents.length} sinh viên vào collection /phenikaa_students...`);
  const batch = db.batch();
  for (const s of defaultStudents) {
    const docRef = db.collection('phenikaa_students').doc(s.studentId);
    batch.set(docRef, {
      ...s,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await batch.commit();
  console.log(`\x1b[32m[THÀNH CÔNG]\x1b[0m Đã cập nhật ${defaultStudents.length} sinh viên vào Firestore danh bạ kích hoạt.`);
}

// CLI Argument Router
const [,, command, arg1, arg2, arg3] = process.argv;

(async () => {
  switch (command) {
    case 'create':
      if (!arg1 || !arg2) {
        console.log('Cú pháp: node scripts/admin_manager.js create <email> <password> [displayName]');
        process.exit(1);
      }
      await createAdmin(arg1, arg2, arg3);
      break;

    case 'grant':
      if (!arg1) {
        console.log('Cú pháp: node scripts/admin_manager.js grant <email_hoac_uid>');
        process.exit(1);
      }
      await grantAdmin(arg1);
      break;

    case 'revoke':
      if (!arg1) {
        console.log('Cú pháp: node scripts/admin_manager.js revoke <email_hoac_uid>');
        process.exit(1);
      }
      await revokeAdmin(arg1);
      break;

    case 'list':
      await listAdmins();
      break;

    case 'seed-students':
      await seedStudents();
      break;

    default:
      console.log('\x1b[33mPU Connection - Hướng Dẫn Sử Dụng Script Quản Trị:\x1b[0m');
      console.log('  node scripts/admin_manager.js create <email> <password> [displayName]');
      console.log('  node scripts/admin_manager.js grant <email_hoac_uid>');
      console.log('  node scripts/admin_manager.js revoke <email_hoac_uid>');
      console.log('  node scripts/admin_manager.js list');
      console.log('  node scripts/admin_manager.js seed-students');
      break;
  }
  process.exit(0);
})();
