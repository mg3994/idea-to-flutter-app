class PriceHistoryRecord {
  final double price;
  final String currency;
  final DateTime timestamp;

  PriceHistoryRecord({
    required this.price,
    required this.currency,
    required this.timestamp,
  });
}

class SchemaPriceTracker {
  /// Calculates price change delta and percentage difference between old and new price
  static Map<String, dynamic> calculatePriceDelta({
    required double oldPrice,
    required double newPrice,
  }) {
    final diff = newPrice - oldPrice;
    final percentage = oldPrice > 0 ? (diff / oldPrice) * 100 : 0.0;
    final isPriceDropped = diff < 0;

    return {
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'difference': diff,
      'percentageChange': percentage,
      'isPriceDropped': isPriceDropped,
    };
  }
}
