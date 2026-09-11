class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String phenikaaStudentsCollection = 'phenikaa_students';
  static const String postsCollection = 'posts';
  static const String commentsSubcollection = 'comments';
  static const String reactionsSubcollection = 'reactions';
  static const String studyDocumentsCollection = 'study_documents';
  static const String documentReviewsSubcollection = 'reviews';
  static const String groupsCollection = 'groups';
  static const String groupMembersSubcollection = 'members';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String notificationsSubcollection = 'notifications';
  static const String subjectsCollection = 'subjects';
  static const String topicsCollection = 'topics';

  static const String friendsSubcollection = 'friends';
  static const String friendRequestsSubcollection = 'friend_requests';
  static const String followersSubcollection = 'followers';

  static const String studentEmailDomain = '@st.phenikaa-uni.edu.vn';
  static const String staffEmailDomain = '@phenikaa-uni.edu.vn';

  static bool isPhenikaaEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith(studentEmailDomain) || lower.endsWith(staffEmailDomain);
  }
}
