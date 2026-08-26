enum StockStatus {
  inStock,
  outOfStock,
  preOrder,
  discontinued,
  unknown,
}

class SchemaInStockChecker {
  /// Parses Schema.org offers.availability URL or string e.g. "https://schema.org/InStock" or "InStock"
  static StockStatus checkAvailability(Map<String, dynamic> schema) {
    dynamic availabilityNode;

    if (schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        availabilityNode = offers['availability'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        availabilityNode = offers.first['availability'];
      }
    }

    availabilityNode ??= schema['availability'];

    if (availabilityNode == null) return StockStatus.inStock; // Default to in stock if unmentioned

    final val = availabilityNode.toString().toLowerCase();

    if (val.contains('instock')) return StockStatus.inStock;
    if (val.contains('outofstock') || val.contains('soldout')) return StockStatus.outOfStock;
    if (val.contains('preorder')) return StockStatus.preOrder;
    if (val.contains('discontinued')) return StockStatus.discontinued;

    return StockStatus.unknown;
  }
}
