import '../domain/product_entity.dart';

class ComparisonMatrixRow {
  final String propertyKey;
  final Map<String, String> productValues; // productId -> value string

  ComparisonMatrixRow({
    required this.propertyKey,
    required this.productValues,
  });
}

class ProductComparisonUtility {
  /// Builds a side-by-side comparison matrix for a list of products
  static List<ComparisonMatrixRow> buildMatrix(List<ProductEntity> products) {
    if (products.isEmpty) return [];

    final Set<String> allKeys = {};
    for (final p in products) {
      allKeys.addAll(p.resolvedSchema.keys.where((k) => !k.startsWith('@')));
    }

    final List<ComparisonMatrixRow> rows = [];

    for (final key in allKeys) {
      final Map<String, String> values = {};
      for (final p in products) {
        final val = p.resolvedSchema[key];
        values[p.id] = val != null ? val.toString() : '-';
      }
      rows.add(ComparisonMatrixRow(propertyKey: key, productValues: values));
    }

    return rows;
  }
}
