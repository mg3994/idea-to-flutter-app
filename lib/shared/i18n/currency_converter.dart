class CurrencyConverter {
  static const Map<String, double> _ratesToUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 83.50,
  };

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
  };

  /// Converts price from [fromCurrency] to [toCurrency]
  static double convert({
    required double price,
    required String fromCurrency,
    required String toCurrency,
  }) {
    final fromRate = _ratesToUsd[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = _ratesToUsd[toCurrency.toUpperCase()] ?? 1.0;

    final priceInUsd = price / fromRate;
    return priceInUsd * toRate;
  }

  /// Formats converted price string with currency symbol
  static String format({
    required double price,
    required String fromCurrency,
    required String targetCurrency,
  }) {
    final converted = convert(
      price: price,
      fromCurrency: fromCurrency,
      toCurrency: targetCurrency,
    );
    final symbol = currencySymbols[targetCurrency.toUpperCase()] ?? targetCurrency;
    return '$symbol${converted.toStringAsFixed(2)}';
  }
}
