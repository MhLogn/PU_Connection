const fs = require('fs');

const width = 1400;
const height = 1100;

function classBox(x, y, w, h, name, attrs, methods) {
  const headerHeight = 28;
  const attrHeight = attrs.length * 16 + 10;
  
  let attrText = attrs.map((a, i) => 
    `<text x="${x + 8}" y="${y + headerHeight + 14 + i * 16}" font-family="Consolas, monospace" font-size="11" fill="#000">${a}</text>`
  ).join('\n');

  let methodText = methods.map((m, i) => 
    `<text x="${x + 8}" y="${y + headerHeight + attrHeight + 14 + i * 16}" font-family="Consolas, monospace" font-size="11" fill="#000">${m}</text>`
  ).join('\n');

  return `
    <g class="uml-class">
      <!-- Box -->
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#ffffff" stroke="#000000" stroke-width="1.5"/>
      <!-- Header Background -->
      <rect x="${x}" y="${y}" width="${w}" height="${headerHeight}" fill="#f1f5f9" stroke="#000000" stroke-width="1.5"/>
      <text x="${x + w / 2}" y="${y + 19}" font-family="Arial, sans-serif" font-size="13" font-weight="bold" text-anchor="middle">${name}</text>
      <!-- Separator between attrs and methods -->
      <line x1="${x}" y1="${y + headerHeight + attrHeight}" x2="${x + w}" y2="${y + headerHeight + attrHeight}" stroke="#000000" stroke-width="1"/>
      <!-- Attributes -->
      ${attrText}
      <!-- Methods -->
      ${methodText}
    </g>
  `;
}

// Generate the complete SVG
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}">
  <!-- Defs for arrows -->
  <defs>
    <marker id="diamond" viewBox="0 0 16 10" refX="0" refY="5" markerWidth="10" markerHeight="7" orient="auto">
      <polygon points="0,5 8,0 16,5 8,10" fill="#000" stroke="#000"/>
    </marker>
  </defs>

  <!-- Background -->
  <rect width="100%" height="100%" fill="#ffffff"/>
  
  <text x="${width / 2}" y="35" font-family="Arial, sans-serif" font-size="20" font-weight="bold" text-anchor="middle">Sơ đồ lớp chi tiết hệ thống PU Connection (UML Class Diagram)</text>

  <!-- 1. PhenikaaStudent (Top Left) -->
  ${classBox(40, 60, 240, 160, 'PhenikaaStudent', [
    '- studentId: String',
    '- fullName: String',
    '- email: String',
    '- faculty: String',
    '- major: String',
    '- cohort: Int',
    '- isActivated: Boolean'
  ], [
    '+ verifyIdentity(): Boolean',
    '+ markActivated(): Void'
  ])}

  <!-- 2. AuthUser / User (Center Top) -->
  ${classBox(360, 60, 270, 250, 'User', [
    '- uid: String',
    '- studentId: String',
    '- email: String',
    '- displayName: String',
    '- faculty: String',
    '- major: String',
    '- userType: String',
    '- gpa: Double',
    '- creditsEarned: Int',
    '- isBanned: Boolean',
    '- isOnline: Boolean'
  ], [
    '+ activateAccount(): Boolean',
    '+ updateProfile(): Void',
    '+ toggleOnlineStatus(): Void'
  ])}

  <!-- 3. Notification (Top Right) -->
  ${classBox(730, 60, 240, 170, 'Notification', [
    '- id: String',
    '- userId: String',
    '- title: String',
    '- content: String',
    '- type: Enum(academic,social...)',
    '- isRead: Boolean',
    '- createdAt: DateTime'
  ], [
    '+ markAsRead(): Void',
    '+ deleteNotification(): Void'
  ])}

  <!-- 4. Report (Far Right) -->
  ${classBox(1050, 60, 260, 180, 'Report', [
    '- id: String',
    '- reporterId: String',
    '- targetId: String',
    '- targetType: Enum(post,comment...)',
    '- reason: Enum(spam,fraud...)',
    '- status: Enum(pending,resolved...)',
    '- createdAt: DateTime'
  ], [
    '+ submitReport(): Void',
    '+ resolveReport(action): Void'
  ])}

  <!-- 5. Post (Middle Left) -->
  ${classBox(40, 390, 260, 240, 'Post', [
    '- postId: String',
    '- authorId: String',
    '- authorName: String',
    '- content: String',
    '- postType: String',
    '- category: String',
    '- subjectCode: String',
    '- likeCount: Int',
    '- commentCount: Int',
    '- createdAt: DateTime'
  ], [
    '+ createPost(): Void',
    '+ deletePost(): Void',
    '+ toggleLike(userId): Void'
  ])}

  <!-- 6. Comment (Directly below Post) -->
  ${classBox(40, 720, 260, 200, 'Comment', [
    '- commentId: String',
    '- postId: String',
    '- authorId: String',
    '- content: String',
    '- likeCount: Int',
    '- replyToCommentId: String',
    '- createdAt: DateTime'
  ], [
    '+ addComment(): Void',
    '+ deleteComment(): Void',
    '+ toggleLike(userId): Void'
  ])}

  <!-- 7. StudyDocument (Center Middle) -->
  ${classBox(360, 390, 270, 240, 'StudyDocument', [
    '- id: String',
    '- title: String',
    '- code: String',
    '- faculty: String',
    '- fileUrl: String',
    '- fileType: String',
    '- authorId: String',
    '- downloads: Int',
    '- rating: Double',
    '- createdAt: DateTime'
  ], [
    '+ uploadDocument(): Void',
    '+ downloadDocument(): File',
    '+ rateDocument(score): Void'
  ])}

  <!-- 8. DocumentReview (Directly below StudyDocument) -->
  ${classBox(360, 720, 270, 190, 'DocumentReview', [
    '- id: String',
    '- documentId: String',
    '- userId: String',
    '- userName: String',
    '- rating: Double',
    '- comment: String',
    '- createdAt: DateTime'
  ], [
    '+ submitReview(): Void',
    '+ editReview(): Void'
  ])}

  <!-- 9. Conversation / Chat (Middle Right) -->
  ${classBox(730, 390, 270, 230, 'Conversation', [
    '- id: String',
    '- participantIds: List<String>',
    '- lastMessage: String',
    '- lastMessageSenderId: String',
    '- lastMessageAt: DateTime',
    '- isGroup: Boolean',
    '- groupName: String',
    '- adminId: String'
  ], [
    '+ createConversation(): String',
    '+ sendMessage(msg): Void',
    '+ markAsRead(userId): Void'
  ])}

  <!-- 10. Message (Below Conversation) -->
  ${classBox(730, 720, 270, 210, 'Message', [
    '- messageId: String',
    '- chatId: String',
    '- senderId: String',
    '- senderName: String',
    '- content: String',
    '- imageUrl: String',
    '- fileUrl: String',
    '- isRead: Boolean',
    '- createdAt: DateTime'
  ], [
    '+ send(): Void',
    '+ markRead(): Void'
  ])}

  <!-- 11. Club (Bottom Right) -->
  ${classBox(1060, 390, 260, 210, 'Club', [
    '- id: String',
    '- name: String',
    '- category: String',
    '- leaderId: String',
    '- memberIds: List<String>',
    '- membersCount: Int',
    '- status: String'
  ], [
    '+ joinClub(userId): Void',
    '+ leaveClub(userId): Void',
    '+ updateClubInfo(): Void'
  ])}

  <!-- 12. StudyGroup (Bottom Far Right) -->
  ${classBox(1060, 720, 260, 210, 'StudyGroup', [
    '- id: String',
    '- creatorId: String',
    '- title: String',
    '- subject: String',
    '- maxMembers: Int',
    '- memberIds: List<String>',
    '- isOpen: Boolean'
  ], [
    '+ requestToJoin(userId): Void',
    '+ acceptRequest(userId): Void',
    '+ closeGroup(): Void'
  ])}

  <!-- RELATIONSHIP LINES -->

  <!-- User - PhenikaaStudent (1 - 1) -->
  <line x1="360" y1="140" x2="280" y2="140" stroke="#000" stroke-width="1.5"/>
  <text x="345" y="132" font-family="Arial" font-size="12">1</text>
  <text x="290" y="132" font-family="Arial" font-size="12">1</text>

  <!-- User - Notification (1 - N) -->
  <line x1="630" y1="130" x2="730" y2="130" stroke="#000" stroke-width="1.5"/>
  <text x="640" y="122" font-family="Arial" font-size="12">1</text>
  <text x="715" y="122" font-family="Arial" font-size="12">N</text>

  <!-- User - Report (1 - N) -->
  <path d="M 630 100 Q 840 40 1050 100" stroke="#000" stroke-width="1.5" fill="none"/>
  <text x="640" y="85" font-family="Arial" font-size="12">1</text>
  <text x="1035" y="85" font-family="Arial" font-size="12">N</text>

  <!-- User - Post (1 - N) -->
  <line x1="430" y1="310" x2="230" y2="390" stroke="#000" stroke-width="1.5"/>
  <text x="405" y="335" font-family="Arial" font-size="12">1</text>
  <text x="245" y="380" font-family="Arial" font-size="12">N</text>

  <!-- Post - Comment (1 - N) -->
  <line x1="170" y1="630" x2="170" y2="720" stroke="#000" stroke-width="1.5"/>
  <text x="180" y="650" font-family="Arial" font-size="12">1</text>
  <text x="180" y="705" font-family="Arial" font-size="12">N</text>

  <!-- User - Comment (1 - N) -->
  <path d="M 390 310 Q 320 550 300 750" stroke="#000" stroke-width="1.5" stroke-dasharray="4,4" fill="none"/>
  <text x="365" y="340" font-family="Arial" font-size="12">1</text>
  <text x="315" y="750" font-family="Arial" font-size="12">N</text>

  <!-- User - StudyDocument (1 - N) -->
  <line x1="495" y1="310" x2="495" y2="390" stroke="#000" stroke-width="1.5"/>
  <text x="505" y="335" font-family="Arial" font-size="12">1</text>
  <text x="505" y="375" font-family="Arial" font-size="12">N</text>

  <!-- StudyDocument - DocumentReview (1 - N) -->
  <line x1="495" y1="630" x2="495" y2="720" stroke="#000" stroke-width="1.5"/>
  <text x="505" y="650" font-family="Arial" font-size="12">1</text>
  <text x="505" y="705" font-family="Arial" font-size="12">N</text>

  <!-- User - DocumentReview (1 - N) -->
  <path d="M 580 310 Q 645 550 630 760" stroke="#000" stroke-width="1.5" stroke-dasharray="4,4" fill="none"/>
  <text x="590" y="340" font-family="Arial" font-size="12">1</text>
  <text x="640" y="760" font-family="Arial" font-size="12">N</text>

  <!-- User - Conversation (N - N) -->
  <line x1="590" y1="310" x2="750" y2="390" stroke="#000" stroke-width="1.5"/>
  <text x="615" y="335" font-family="Arial" font-size="12">N</text>
  <text x="730" y="380" font-family="Arial" font-size="12">N</text>

  <!-- Conversation - Message (1 - N) -->
  <line x1="865" y1="620" x2="865" y2="720" stroke="#000" stroke-width="1.5"/>
  <text x="875" y="645" font-family="Arial" font-size="12">1</text>
  <text x="875" y="705" font-family="Arial" font-size="12">N</text>

  <!-- User - Message (1 - N) -->
  <path d="M 610 310 Q 710 600 730 750" stroke="#000" stroke-width="1.5" stroke-dasharray="4,4" fill="none"/>
  <text x="635" y="360" font-family="Arial" font-size="12">1</text>
  <text x="715" y="735" font-family="Arial" font-size="12">N</text>

  <!-- User - Club (N - N) -->
  <path d="M 630 250 Q 860 280 1060 410" stroke="#000" stroke-width="1.5" fill="none"/>
  <text x="660" y="260" font-family="Arial" font-size="12">N</text>
  <text x="1035" y="405" font-family="Arial" font-size="12">N</text>

  <!-- User - StudyGroup (N - N) -->
  <path d="M 630 280 Q 980 500 1060 740" stroke="#000" stroke-width="1.5" fill="none"/>
  <text x="670" y="300" font-family="Arial" font-size="12">N</text>
  <text x="1035" y="730" font-family="Arial" font-size="12">N</text>

</svg>`;

fs.writeFileSync('docs/class_diagram_pu_connection.svg', svg);
console.log('Class diagram SVG generated successfully at docs/class_diagram_pu_connection.svg');

