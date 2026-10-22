import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_connection/core/services/offline_cache_service.dart';

void main() {
  group('OfflineCacheService Tests', () {
    late OfflineCacheService cacheService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cacheService = OfflineCacheService();
    });

    test('Initial cache is empty', () async {
      final posts = await cacheService.getRecentPosts();
      final docs = await cacheService.getRecentDocuments();
      final lastTime = await cacheService.getLastCacheTime();

      expect(posts, isEmpty);
      expect(docs, isEmpty);
      expect(lastTime, isNull);
    });

    test('saveRecentPosts and getRecentPosts save and retrieve cached posts', () async {
      final samplePosts = [
        {'id': 'post_1', 'content': 'Bài viết ôn thi giải tích', 'author': 'Hà Mạnh Long'},
        {'id': 'post_2', 'content': 'Tìm bạn cùng phòng KTX Phenikaa', 'author': 'Trần Thị Mai'},
      ];

      await cacheService.saveRecentPosts(samplePosts);

      final retrieved = await cacheService.getRecentPosts();
      expect(retrieved.length, 2);
      expect(retrieved[0]['id'], 'post_1');
      expect(retrieved[0]['content'], 'Bài viết ôn thi giải tích');
      expect(retrieved[1]['author'], 'Trần Thị Mai');

      final lastTime = await cacheService.getLastCacheTime();
      expect(lastTime, isNotNull);
    });

    test('saveRecentDocuments and getRecentDocuments save and retrieve cached documents', () async {
      final sampleDocs = [
        {'id': 'doc_1', 'title': 'Đề thi cuối kỳ Giải tích 2', 'courseCode': 'MAT102'},
        {'id': 'doc_2', 'title': 'Slide Lập trình Mobile Flutter', 'courseCode': 'IT305'},
      ];

      await cacheService.saveRecentDocuments(sampleDocs);

      final retrieved = await cacheService.getRecentDocuments();
      expect(retrieved.length, 2);
      expect(retrieved[0]['id'], 'doc_1');
      expect(retrieved[0]['title'], 'Đề thi cuối kỳ Giải tích 2');
      expect(retrieved[1]['courseCode'], 'IT305');
    });

    test('clearCache removes all stored offline items', () async {
      await cacheService.saveRecentPosts([{'id': 'p1'}]);
      await cacheService.saveRecentDocuments([{'id': 'd1'}]);

      expect((await cacheService.getRecentPosts()).length, 1);
      expect((await cacheService.getRecentDocuments()).length, 1);

      await cacheService.clearCache();

      expect(await cacheService.getRecentPosts(), isEmpty);
      expect(await cacheService.getRecentDocuments(), isEmpty);
      expect(await cacheService.getLastCacheTime(), isNull);
    });
  });
}
