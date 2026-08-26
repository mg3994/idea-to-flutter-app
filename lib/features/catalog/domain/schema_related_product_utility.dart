import '../domain/product_entity.dart';

class SchemaRelatedProductUtility {
  /// Computes top related products for cross-selling based on shared brand, labels, and price proximity
  static List<ProductEntity> getRelatedProducts({
    required ProductEntity currentProduct,
    required List<ProductEntity> allProducts,
    int limit = 4,
  }) {
    final Map<ProductEntity, int> scoreMap = {};

    for (final other in allProducts) {
      if (other.id == currentProduct.id) continue;

      int score = 0;

      // 1. Same brand bonus (+5)
      if (currentProduct.brand != null &&
          other.brand != null &&
          currentProduct.brand!.toLowerCase() == other.brand!.toLowerCase()) {
        score += 5;
      }

      // 2. Shared labels (+2 per label)
      for (final label in currentProduct.labels) {
        if (other.labels.map((l) => l.toLowerCase()).contains(label.toLowerCase())) {
          score += 2;
        }
      }

      // 3. Price proximity bonus (+3 if within 25% price range)
      if (currentProduct.price > 0 && other.price > 0) {
        final priceRatio = (other.price / currentProduct.price);
        if (priceRatio >= 0.75 && priceRatio <= 1.25) {
          score += 3;
        }
      }

      if (score > 0) {
        scoreMap[other] = score;
      }
    }

    final sortedEntries = scoreMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((e) => e.key).take(limit).toList();
  }
}
