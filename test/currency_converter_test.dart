import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/shared/i18n/currency_converter.dart';

void main() {
  group('CurrencyConverter Tests', () {
    test('Converts price between USD, EUR, GBP, and INR correctly', () {
      final eurPrice = CurrencyConverter.convert(
        price: 100.0,
        fromCurrency: 'USD',
        toCurrency: 'EUR',
      );
      expect(eurPrice, 92.0);

      final inrPrice = CurrencyConverter.convert(
        price: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'INR',
      );
      expect(inrPrice, 835.0);
    });

    test('Formats currency output string with symbols', () {
      final formattedUsd = CurrencyConverter.format(
        price: 50.0,
        fromCurrency: 'USD',
        targetCurrency: 'USD',
      );
      expect(formattedUsd, '\$50.00');

      final formattedEur = CurrencyConverter.format(
        price: 100.0,
        fromCurrency: 'USD',
        targetCurrency: 'EUR',
      );
      expect(formattedEur, '€92.00');

      final formattedGbp = CurrencyConverter.format(
        price: 100.0,
        fromCurrency: 'USD',
        targetCurrency: 'GBP',
      );
      expect(formattedGbp, '£79.00');
    });
  });
}
