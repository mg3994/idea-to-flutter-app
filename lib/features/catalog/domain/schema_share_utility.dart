import '../../catalog/domain/product_entity.dart';

class SchemaShareUtility {
  static const String appBaseUrl = 'https://blogstore.antinna.in';

  /// Generates deep-link URL for a product entity
  static String generateDeepLink({
    required String postId,
    required String blogId,
  }) {
    return '$appBaseUrl/product?id=$postId&blogId=$blogId';
  }

  /// Generates shareable summary text payload
  static String generateShareText(ProductEntity product) {
    final link = generateDeepLink(postId: product.id, blogId: product.blogId);
    return 'Check out "${product.title}" on Blog Store!\nPrice: \$${product.price.toStringAsFixed(2)} ${product.currency}\nLink: $link';
  }

  /// Parses deep-link query parameters
  static Map<String, String>? parseDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      final postId = uri.queryParameters['id'];
      final blogId = uri.queryParameters['blogId'];

      if (postId != null && postId.isNotEmpty) {
        return {
          'postId': postId,
          'blogId': blogId ?? '1774904866501098696',
        };
      }
    } catch (_) {}
    return null;
  }
}
