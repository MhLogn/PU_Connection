import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/repositories/saved_posts_repository.dart';

class SavedPostsRepositoryImpl implements SavedPostsRepository {
  final FirebaseFirestore? _firestore;

  // In-memory store cho test/offline: userId -> Set<postId>
  final Map<String, Set<String>> _inMemorySavedPosts = {};
  final Map<String, StreamController<List<String>>> _controllers = {};

  SavedPostsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamController<List<String>> _getController(String userId) {
    if (!_controllers.containsKey(userId) || _controllers[userId]!.isClosed) {
      _controllers[userId] = StreamController<List<String>>.broadcast();
    }
    return _controllers[userId]!;
  }

  void _notify(String userId) {
    final ids = _inMemorySavedPosts[userId]?.toList() ?? [];
    _getController(userId).add(List.unmodifiable(ids));
  }

  @override
  Stream<List<String>> watchSavedPostIds(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    final db = _db;
    if (db == null) {
      Timer.run(() => _notify(userId));
      return _getController(userId).stream;
    }

    try {
      return db
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection('saved_posts')
          .orderBy('savedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toList();
        _inMemorySavedPosts[userId] = ids.toSet();
        return ids;
      }).handleError((_) {
        return _inMemorySavedPosts[userId]?.toList() ?? [];
      });
    } catch (_) {
      Timer.run(() => _notify(userId));
      return _getController(userId).stream;
    }
  }

  @override
  Future<List<String>> getSavedPostIds(String userId) async {
    if (userId.isEmpty) return [];

    final db = _db;
    if (db != null) {
      try {
        final snapshot = await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection('saved_posts')
            .orderBy('savedAt', descending: true)
            .get();

        final ids = snapshot.docs.map((doc) => doc.id).toList();
        _inMemorySavedPosts[userId] = ids.toSet();
        return ids;
      } catch (_) {}
    }

    return _inMemorySavedPosts[userId]?.toList() ?? [];
  }

  @override
  Future<void> savePost(String userId, String postId) async {
    if (userId.isEmpty || postId.isEmpty) return;

    // 1. Cập nhật In-memory
    final set = _inMemorySavedPosts.putIfAbsent(userId, () => <String>{});
    set.add(postId);
    _notify(userId);

    // 2. Ghi Firestore
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection('saved_posts')
            .doc(postId)
            .set({
          'postId': postId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> unsavePost(String userId, String postId) async {
    if (userId.isEmpty || postId.isEmpty) return;

    // 1. Cập nhật In-memory
    final set = _inMemorySavedPosts[userId];
    if (set != null) {
      set.remove(postId);
      _notify(userId);
    }

    // 2. Xóa Firestore
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .collection('saved_posts')
            .doc(postId)
            .delete();
      } catch (_) {}
    }
  }

  @override
  Future<bool> isPostSaved(String userId, String postId) async {
    if (userId.isEmpty || postId.isEmpty) return false;

    if (_inMemorySavedPosts.containsKey(userId)) {
      return _inMemorySavedPosts[userId]!.contains(postId);
    }

    final list = await getSavedPostIds(userId);
    return list.contains(postId);
  }
}
