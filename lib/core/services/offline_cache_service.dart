import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  final SharedPreferences? _prefs;

  static const String _keyRecentPosts = 'pu_offline_recent_posts';
  static const String _keyRecentDocuments = 'pu_offline_recent_documents';
  static const String _keyLastCacheTime = 'pu_offline_last_cache_time';

  OfflineCacheService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Save recent feed posts to offline cache (maximum 30 posts)
  Future<void> saveRecentPosts(List<Map<String, dynamic>> posts) async {
    try {
      final prefs = await _getPrefs();
      final limited = posts.take(30).toList();
      final jsonStr = jsonEncode(limited);
      await prefs.setString(_keyRecentPosts, jsonStr);
      await prefs.setInt(
        _keyLastCacheTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Retrieve cached feed posts when offline
  Future<List<Map<String, dynamic>>> getRecentPosts() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyRecentPosts);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Save recent documents to offline cache (maximum 20 documents)
  Future<void> saveRecentDocuments(List<Map<String, dynamic>> documents) async {
    try {
      final prefs = await _getPrefs();
      final limited = documents.take(20).toList();
      final jsonStr = jsonEncode(limited);
      await prefs.setString(_keyRecentDocuments, jsonStr);
    } catch (_) {}
  }

  /// Retrieve cached documents when offline
  Future<List<Map<String, dynamic>>> getRecentDocuments() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyRecentDocuments);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get the last time the cache was updated
  Future<DateTime?> getLastCacheTime() async {
    try {
      final prefs = await _getPrefs();
      final millis = prefs.getInt(_keyLastCacheTime);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  /// Clear all offline cache
  Future<void> clearCache() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyRecentPosts);
      await prefs.remove(_keyRecentDocuments);
      await prefs.remove(_keyLastCacheTime);
    } catch (_) {}
  }
}
