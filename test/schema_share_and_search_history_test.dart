import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/catalog/domain/schema_share_utility.dart';
import 'package:blog_store/features/catalog/domain/search_history_manager.dart';
import 'package:blog_store/features/catalog/domain/product_entity.dart';

void main() {
  group('SchemaShareUtility Tests', () {
    test('Generates deep link correctly', () {
      final link = SchemaShareUtility.generateDeepLink(
        postId: 'post_123',
        blogId: 'blog_456',
      );

      expect(link, 'https://blogstore.antinna.in/product?id=post_123&blogId=blog_456');
    });

    test('Parses deep link query parameters correctly', () {
      final parsed = SchemaShareUtility.parseDeepLink(
        'https://blogstore.antinna.in/product?id=post_999&blogId=blog_777',
      );

      expect(parsed, isNotNull);
      expect(parsed!['postId'], 'post_999');
      expect(parsed['blogId'], 'blog_777');
    });

    test('Generates share text payload', () {
      final product = ProductEntity(
        id: 'p_1',
        blogId: 'b_1',
        title: 'Shareable Item',
        price: 99.99,
        labels: [],
        rawSchema: {},
        resolvedSchema: {},
        publishedAt: '2025-01-01T00:00:00Z',
      );

      final shareText = SchemaShareUtility.generateShareText(product);
      expect(shareText, contains('Shareable Item'));
      expect(shareText, contains('99.99'));
      expect(shareText, contains('https://blogstore.antinna.in/product?id=p_1&blogId=b_1'));
    });
  });

  group('SearchHistoryManager Tests', () {
    test('Tracks recent search queries and limits to 5 items', () {
      SearchHistoryManager.clearHistory();

      SearchHistoryManager.addSearchQuery('electronics');
      SearchHistoryManager.addSearchQuery('mobile');
      SearchHistoryManager.addSearchQuery('laptop');
      SearchHistoryManager.addSearchQuery('watch');
      SearchHistoryManager.addSearchQuery('camera');
      SearchHistoryManager.addSearchQuery('drone');

      expect(SearchHistoryManager.recentSearches.length, 5);
      expect(SearchHistoryManager.recentSearches.first, 'drone');
      expect(SearchHistoryManager.recentSearches.contains('electronics'), isFalse);
    });
  });
}
