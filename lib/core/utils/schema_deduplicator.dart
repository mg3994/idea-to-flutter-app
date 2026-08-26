import '../domain/product_entity.dart';

class SchemaDeduplicator {
  /// Deduplicates a list of ProductEntity items based on canonical @id, @base, or title + brand key
  static List<ProductEntity> deduplicate(List<ProductEntity> products) {
    final Map<String, ProductEntity> uniqueMap = {};

    for (final product in products) {
      final key = _computeCanonicalKey(product);
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = product;
      }
    }

    return uniqueMap.values.toList();
  }

  static String _computeCanonicalKey(ProductEntity product) {
    if (product.resolvedSchema['@id'] != null && product.resolvedSchema['@id'].toString().isNotEmpty) {
      return 'id:${product.resolvedSchema['@id']}';
    }
    if (product.id.isNotEmpty) {
      return 'post:${product.blogId}_${product.id}';
    }
    final brandKey = product.brand?.trim().toLowerCase() ?? 'generic';
    final titleKey = product.title.trim().toLowerCase();
    return 'title_brand:${brandKey}_$titleKey';
  }
}
