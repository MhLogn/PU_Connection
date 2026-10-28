const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, '..', 'docs', 'usecase_groups');
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

function drawActor(x, y, label) {
  return `
    <g class="actor">
      <!-- Head -->
      <circle cx="${x}" cy="${y}" r="12" fill="#ffffff" stroke="#000000" stroke-width="1.5"/>
      <!-- Body -->
      <line x1="${x}" y1="${y + 12}" x2="${x}" y2="${y + 40}" stroke="#000000" stroke-width="1.5"/>
      <!-- Arms -->
      <line x1="${x - 18}" y1="${y + 22}" x2="${x + 18}" y2="${y + 22}" stroke="#000000" stroke-width="1.5"/>
      <!-- Left Leg -->
      <line x1="${x}" y1="${y + 40}" x2="${x - 14}" y2="${y + 64}" stroke="#000000" stroke-width="1.5"/>
      <!-- Right Leg -->
      <line x1="${x}" y1="${y + 40}" x2="${x + 14}" y2="${y + 64}" stroke="#000000" stroke-width="1.5"/>
      <!-- Label -->
      <text x="${x}" y="${y + 80}" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000" text-anchor="middle">${label}</text>
    </g>
  `;
}

function drawSystemActor(x, y, w, h, label) {
  return `
    <g class="system-actor">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="4" fill="#ffffff" stroke="#000000" stroke-width="1.5"/>
      <text x="${x + w / 2}" y="${y + 16}" font-family="Arial, sans-serif" font-size="10" fill="#000000" text-anchor="middle">&lt;&lt;system&gt;&gt;</text>
      <text x="${x + w / 2}" y="${y + 32}" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000" text-anchor="middle">${label}</text>
    </g>
  `;
}

function drawUseCase(x, y, rx, ry, id, title) {
  return `
    <g class="usecase">
      <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#ffffff" stroke="#000000" stroke-width="1.5"/>
      <text x="${x}" y="${y - 4}" font-family="Arial, sans-serif" font-size="11" font-weight="bold" fill="#000000" text-anchor="middle">${id}</text>
      <text x="${x}" y="${y + 12}" font-family="Arial, sans-serif" font-size="11" fill="#000000" text-anchor="middle">${title}</text>
    </g>
  `;
}

function drawLine(x1, y1, x2, y2) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#000000" stroke-width="1.2"/>`;
}

function drawDashedArrow(x1, y1, x2, y2, label) {
  const mx = (x1 + x2) / 2;
  const my = (y1 + y2) / 2;
  let textElem = '';
  if (label) {
    textElem = `
      <rect x="${mx - 32}" y="${my - 14}" width="64" height="16" fill="#ffffff" stroke="none"/>
      <text x="${mx}" y="${my - 2}" font-family="Arial, sans-serif" font-size="10" font-style="italic" fill="#000000" text-anchor="middle">${label}</text>
    `;
  }
  return `
    <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#000000" stroke-width="1.2" stroke-dasharray="5,4" marker-end="url(#arrow)"/>
    ${textElem}
  `;
}

function svgWrap(width, height, title, content) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 9 5 L 0 9 z" fill="#000000" stroke="#000000"/>
    </marker>
  </defs>
  <!-- Nền trắng chuẩn Draw.io -->
  <rect width="100%" height="100%" fill="#ffffff"/>
  
  <!-- Tiêu đề nhóm -->
  <text x="${width / 2}" y="32" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="#000000" text-anchor="middle">${title}</text>
  
  ${content}
</svg>`;
}

// -------------------------------------------------------------
// NHÓM 1: Quản lý định danh và tài khoản người dùng
// -------------------------------------------------------------
const n1 = svgWrap(820, 480, "Sơ đồ Use-case Nhóm 1: Quản lý Định danh và Tài khoản", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="400" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Xác thực &amp; Tài khoản</text>

  <!-- Actors -->
  ${drawActor(100, 150, "Sinh viên (User)")}
  ${drawActor(100, 360, "Quản trị viên (Admin)")}
  ${drawSystemActor(660, 220, 130, 45, "Firebase Auth")}

  <!-- Use Cases -->
  ${drawUseCase(420, 110, 115, 26, "UC01", "Đăng ký tài khoản")}
  ${drawUseCase(420, 175, 115, 26, "UC02", "Đăng nhập hệ thống")}
  ${drawUseCase(420, 240, 115, 26, "UC03", "Quên / Đổi mật khẩu")}
  ${drawUseCase(420, 305, 115, 26, "UC04", "Cập nhật hồ sơ")}
  ${drawUseCase(420, 370, 115, 26, "UC05", "Đăng xuất thiết bị")}
  ${drawUseCase(540, 110, 75, 22, "Verify Email", "Xác thực email")}
  ${drawUseCase(540, 175, 75, 22, "Validate", "Kiểm tra định danh")}

  <!-- Associations Sinh viên -->
  ${drawLine(130, 160, 305, 110)}
  ${drawLine(130, 170, 305, 175)}
  ${drawLine(130, 180, 305, 240)}
  ${drawLine(130, 190, 305, 305)}
  ${drawLine(130, 200, 305, 370)}

  <!-- Associations Admin -->
  ${drawLine(130, 370, 305, 185)}
  ${drawLine(130, 385, 305, 375)}

  <!-- Include / Extend -->
  ${drawDashedArrow(420 + 80, 110, 540 - 75, 110, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(420 + 80, 175, 540 - 75, 175, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(420, 214, 420, 201, "&lt;&lt;extend&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(615, 110, 660, 225)}
  ${drawLine(615, 175, 660, 235)}
  ${drawLine(535, 240, 660, 245)}
  ${drawLine(535, 370, 660, 255)}
`);
fs.writeFileSync(path.join(outDir, 'nhom1_identity_auth.svg'), n1, 'utf8');

// -------------------------------------------------------------
// NHÓM 2: Bảng tin học thuật và tương tác cộng đồng
// -------------------------------------------------------------
const n2 = svgWrap(840, 520, "Sơ đồ Use-case Nhóm 2: Bảng tin Học thuật và Tương tác Cộng đồng", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="445" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Bảng tin &amp; Diễn đàn Học thuật</text>

  <!-- Actors -->
  ${drawActor(100, 240, "Sinh viên (User)")}
  ${drawSystemActor(660, 140, 140, 45, "Cloudinary CDN")}
  ${drawSystemActor(660, 320, 140, 45, "Cloud Firestore")}

  <!-- Use Cases -->
  ${drawUseCase(370, 120, 110, 26, "UC06", "Đăng bài thảo luận")}
  ${drawUseCase(370, 190, 110, 26, "UC07", "Xem Feed &amp; Lọc khoa")}
  ${drawUseCase(370, 260, 110, 26, "UC08", "Thích / Bỏ thích")}
  ${drawUseCase(370, 330, 110, 26, "UC09", "Bình luận thảo luận")}
  ${drawUseCase(370, 400, 110, 26, "UC10", "Lưu bài viết (Bookmark)")}
  ${drawUseCase(370, 465, 110, 24, "UC11", "Báo cáo bài vi phạm")}
  ${drawUseCase(545, 120, 75, 22, "Media Upload", "Tải ảnh/tệp")}

  <!-- Associations Sinh vien -->
  ${drawLine(130, 230, 260, 125)}
  ${drawLine(130, 240, 260, 190)}
  ${drawLine(130, 250, 260, 260)}
  ${drawLine(130, 260, 260, 330)}
  ${drawLine(130, 270, 260, 400)}
  ${drawLine(130, 280, 260, 465)}

  <!-- Include / Extend -->
  ${drawDashedArrow(480, 120, 470, 120, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(370, 234, 370, 216, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(370, 304, 370, 216, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(370, 374, 370, 216, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(370, 441, 370, 216, "&lt;&lt;extend&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(545 + 75, 120, 660, 155)}
  ${drawLine(480, 120, 660, 330)}
  ${drawLine(480, 190, 660, 340)}
  ${drawLine(480, 260, 660, 350)}
  ${drawLine(480, 330, 660, 360)}
`);
fs.writeFileSync(path.join(outDir, 'nhom2_academic_feed.svg'), n2, 'utf8');

// -------------------------------------------------------------
// NHÓM 3: Kho học liệu số và Trình đọc PDF
// -------------------------------------------------------------
const n3 = svgWrap(840, 460, "Sơ đồ Use-case Nhóm 3: Kho Học liệu số và Trình đọc PDF", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="385" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Kho Học liệu &amp; PDF Viewer</text>

  <!-- Actors -->
  ${drawActor(100, 220, "Sinh viên (User)")}
  ${drawSystemActor(660, 170, 140, 45, "Cloudinary CDN")}
  ${drawSystemActor(660, 300, 140, 45, "Cloud Firestore")}

  <!-- Use Cases -->
  ${drawUseCase(370, 115, 110, 26, "UC12", "Đăng tải học liệu")}
  ${drawUseCase(370, 185, 110, 26, "UC13", "Tìm kiếm tài liệu học")}
  ${drawUseCase(370, 255, 110, 26, "UC14", "Xem tài liệu In-app PDF")}
  ${drawUseCase(370, 325, 110, 26, "UC15", "Tải tài liệu về máy")}
  ${drawUseCase(370, 395, 110, 26, "UC16", "Đánh giá học liệu")}
  ${drawUseCase(545, 115, 75, 22, "Upload PDF", "Lưu trữ tệp PDF")}
  ${drawUseCase(545, 255, 75, 22, "Stream PDF", "Luồng đọc tệp")}

  <!-- Associations Sinh viên -->
  ${drawLine(130, 210, 260, 120)}
  ${drawLine(130, 220, 260, 185)}
  ${drawLine(130, 230, 260, 255)}
  ${drawLine(130, 240, 260, 325)}
  ${drawLine(130, 250, 260, 395)}

  <!-- Include / Extend -->
  ${drawDashedArrow(480, 115, 470, 115, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(480, 255, 470, 255, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(370, 299, 370, 281, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(370, 369, 370, 281, "&lt;&lt;extend&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(620, 115, 660, 180)}
  ${drawLine(620, 255, 660, 195)}
  ${drawLine(480, 185, 660, 315)}
  ${drawLine(480, 395, 660, 330)}
`);
fs.writeFileSync(path.join(outDir, 'nhom3_digital_library.svg'), n3, 'utf8');

// -------------------------------------------------------------
// NHÓM 4: Trợ lý học vụ trí tuệ nhân tạo (AI Assistant)
// -------------------------------------------------------------
const n4 = svgWrap(820, 380, "Sơ đồ Use-case Nhóm 4: Trợ lý Học vụ Trí tuệ Nhân tạo (Phenikaa AI)", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="305" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Trợ lý Trí tuệ Nhân tạo AI</text>

  <!-- Actors -->
  ${drawActor(100, 180, "Sinh viên (User)")}
  ${drawSystemActor(660, 130, 130, 45, "Google Gemini AI")}
  ${drawSystemActor(660, 250, 130, 45, "Cloud Firestore")}

  <!-- Use Cases -->
  ${drawUseCase(370, 125, 110, 26, "UC17", "Chat hỏi đáp học vụ AI")}
  ${drawUseCase(370, 205, 110, 26, "UC18", "Tóm tắt nội dung tài liệu")}
  ${drawUseCase(370, 285, 110, 26, "UC19", "Quản lý / Xóa lịch sử")}
  ${drawUseCase(545, 125, 75, 22, "NLP Engine", "Xử lý ngôn ngữ")}
  ${drawUseCase(545, 250, 75, 22, "Save History", "Lưu hội thoại")}

  <!-- Associations Sinh viên -->
  ${drawLine(130, 180, 260, 130)}
  ${drawLine(130, 190, 260, 205)}
  ${drawLine(130, 200, 260, 285)}

  <!-- Include / Extend -->
  ${drawDashedArrow(480, 125, 470, 125, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(370, 179, 370, 151, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(480, 140, 500, 230, "&lt;&lt;include&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(620, 125, 660, 145)}
  ${drawLine(620, 250, 660, 270)}
  ${drawLine(480, 285, 660, 280)}
`);
fs.writeFileSync(path.join(outDir, 'nhom4_ai_assistant.svg'), n4, 'utf8');

// -------------------------------------------------------------
// NHÓM 5: Tin nhắn thời gian thực và Nhóm học tập
// -------------------------------------------------------------
const n5 = svgWrap(820, 400, "Sơ đồ Use-case Nhóm 5: Tin nhắn Thời gian thực &amp; Nhóm học tập", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="325" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Tin nhắn &amp; Nhóm học tập</text>

  <!-- Actors -->
  ${drawActor(100, 190, "Sinh viên (User)")}
  ${drawSystemActor(660, 130, 130, 45, "Firestore Realtime")}
  ${drawSystemActor(660, 250, 130, 45, "Cloudinary CDN")}

  <!-- Use Cases -->
  ${drawUseCase(370, 125, 110, 26, "UC20", "Nhắn tin trực tiếp 1-1")}
  ${drawUseCase(370, 215, 110, 26, "UC21", "Tạo &amp; quản lý nhóm")}
  ${drawUseCase(370, 305, 110, 26, "UC22", "Gửi file / ảnh đính kèm")}
  ${drawUseCase(545, 125, 75, 22, "Sync Message", "Đồng bộ tức thời")}
  ${drawUseCase(545, 270, 75, 22, "Upload Media", "Tải ảnh/tệp chat")}

  <!-- Associations Sinh viên -->
  ${drawLine(130, 180, 260, 130)}
  ${drawLine(130, 195, 260, 215)}
  ${drawLine(130, 210, 260, 305)}

  <!-- Include / Extend -->
  ${drawDashedArrow(480, 125, 470, 125, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(480, 215, 495, 150, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(370, 279, 370, 241, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(480, 305, 470, 275, "&lt;&lt;include&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(620, 125, 660, 145)}
  ${drawLine(620, 270, 660, 270)}
`);
fs.writeFileSync(path.join(outDir, 'nhom5_realtime_chat.svg'), n5, 'utf8');

// -------------------------------------------------------------
// NHÓM 6: Mạng lưới sinh viên, CLB và An toàn học đường
// -------------------------------------------------------------
const n6 = svgWrap(820, 520, "Sơ đồ Use-case Nhóm 6: Mạng lưới Sinh viên, CLB &amp; An toàn Học đường", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="445" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Mạng lưới Sinh viên &amp; CLB</text>

  <!-- Actors -->
  ${drawActor(100, 220, "Sinh viên (User)")}
  ${drawActor(720, 280, "Chủ nhiệm CLB / Admin")}

  <!-- Use Cases -->
  ${drawUseCase(420, 115, 115, 26, "UC23", "Tìm sinh viên theo khoa")}
  ${drawUseCase(420, 185, 115, 26, "UC24", "Theo dõi / Bỏ theo dõi")}
  ${drawUseCase(420, 255, 115, 26, "UC25", "Xem CLB &amp; Ứng tuyển")}
  ${drawUseCase(420, 325, 115, 26, "UC26", "Đăng ký tham gia sự kiện")}
  ${drawUseCase(420, 395, 115, 26, "UC27", "Chặn người dùng vi phạm")}
  ${drawUseCase(420, 465, 115, 24, "UC28", "Xem thông báo hệ thống")}

  <!-- Associations Sinh vien -->
  ${drawLine(130, 210, 305, 120)}
  ${drawLine(130, 220, 305, 185)}
  ${drawLine(130, 230, 305, 255)}
  ${drawLine(130, 240, 305, 325)}
  ${drawLine(130, 250, 305, 395)}
  ${drawLine(130, 260, 305, 465)}

  <!-- Associations Chu nhiem CLB -->
  ${drawLine(690, 275, 535, 260)}
  ${drawLine(690, 290, 535, 330)}

  <!-- Include / Extend -->
  ${drawDashedArrow(420, 159, 420, 141, "&lt;&lt;extend&gt;&gt;")}
  ${drawDashedArrow(420, 369, 420, 141, "&lt;&lt;extend&gt;&gt;")}
`);
fs.writeFileSync(path.join(outDir, 'nhom6_student_network.svg'), n6, 'utf8');

// -------------------------------------------------------------
// NHÓM 7: Quản trị hệ thống và Kiểm duyệt nội dung
// -------------------------------------------------------------
const n7 = svgWrap(840, 520, "Sơ đồ Use-case Nhóm 7: Quản trị Hệ thống và Kiểm duyệt Nội dung", `
  <!-- System Boundary -->
  <rect x="220" y="55" width="410" height="445" fill="#ffffff" stroke="#000000" stroke-width="1.5" stroke-dasharray="3,3"/>
  <text x="235" y="75" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#000000">Phân hệ Quản trị Admin Portal</text>

  <!-- Actors -->
  ${drawActor(100, 250, "Quản trị viên (Admin)")}
  ${drawSystemActor(660, 240, 140, 45, "Firestore &amp; Audit DB")}

  <!-- Use Cases -->
  ${drawUseCase(370, 115, 110, 26, "UC29", "Dashboard thống kê")}
  ${drawUseCase(370, 185, 110, 26, "UC30", "Xử lý bài viết vi phạm")}
  ${drawUseCase(370, 255, 110, 26, "UC31", "Quản lý người dùng")}
  ${drawUseCase(370, 325, 110, 26, "UC32", "Quản lý danh mục học phần")}
  ${drawUseCase(370, 395, 110, 26, "UC33", "Phát hành thông báo trường")}
  ${drawUseCase(370, 465, 110, 24, "UC34", "Trích xuất báo cáo dữ liệu")}
  ${drawUseCase(545, 220, 75, 22, "Audit Log", "Ghi nhật ký")}

  <!-- Associations Admin -->
  ${drawLine(130, 230, 260, 120)}
  ${drawLine(130, 240, 260, 185)}
  ${drawLine(130, 250, 260, 255)}
  ${drawLine(130, 260, 260, 325)}
  ${drawLine(130, 270, 260, 395)}
  ${drawLine(130, 280, 260, 465)}

  <!-- Include / Extend -->
  ${drawDashedArrow(480, 185, 470, 220, "&lt;&lt;include&gt;&gt;")}
  ${drawDashedArrow(480, 255, 470, 225, "&lt;&lt;include&gt;&gt;")}

  <!-- External System links -->
  ${drawLine(620, 220, 660, 255)}
  ${drawLine(480, 115, 660, 245)}
  ${drawLine(480, 465, 660, 265)}
`);
fs.writeFileSync(path.join(outDir, 'nhom7_system_admin.svg'), n7, 'utf8');

console.log('Successfully generated all 7 Group Use Case SVGs in docs/usecase_groups/');

