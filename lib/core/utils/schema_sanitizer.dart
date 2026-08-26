class SchemaSanitizer {
  /// Strips HTML tags from raw descriptions
  static String sanitizeDescription(String? htmlDescription) {
    if (htmlDescription == null || htmlDescription.isEmpty) return '';
    return htmlDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Normalizes string price inputs to double
  static double sanitizePrice(dynamic priceInput) {
    if (priceInput == null) return 0.0;
    if (priceInput is num) return priceInput.toDouble();
    if (priceInput is String) {
      final cleaned = priceInput.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}
