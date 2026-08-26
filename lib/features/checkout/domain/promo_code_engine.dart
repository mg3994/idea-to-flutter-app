class PromoResult {
  final bool isValid;
  final double discountAmount;
  final String code;
  final String? message;

  PromoResult({
    required this.isValid,
    required this.discountAmount,
    required this.code,
    this.message,
  });
}

class PromoCodeEngine {
  static final Map<String, double> _validPromosPercentage = {
    'SAVE10': 0.10,
    'SAVE20': 0.20,
    'WELCOME50': 0.50,
  };

  static PromoResult evaluate({
    required String code,
    required double cartTotal,
  }) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return PromoResult(isValid: false, discountAmount: 0.0, code: code, message: 'Please enter a promo code');
    }

    if (_validPromosPercentage.containsKey(cleanCode)) {
      final percentage = _validPromosPercentage[cleanCode]!;
      final discount = cartTotal * percentage;
      return PromoResult(
        isValid: true,
        discountAmount: discount,
        code: cleanCode,
        message: '${(percentage * 100).toInt()}% discount applied!',
      );
    }

    return PromoResult(isValid: false, discountAmount: 0.0, code: cleanCode, message: 'Invalid or expired promo code');
  }
}
