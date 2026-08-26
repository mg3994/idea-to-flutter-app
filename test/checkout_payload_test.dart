import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/checkout/data/checkout_client.dart';

void main() {
  group('Checkout Client & Payload Tests', () {
    test('Serializes CheckoutPayload correctly to JSON', () {
      final payload = CheckoutPayload(
        userId: 'user_test_99',
        items: [
          OrderItem(id: 'p1', title: 'Smartphone', price: 699.99, quantity: 2),
        ],
        totalAmount: 1399.98,
        paymentMethod: PaymentMethod.googlePay,
        shippingAddress: {'city': 'San Francisco', 'country': 'USA'},
      );

      final json = payload.toJson();

      expect(json['userId'], 'user_test_99');
      expect(json['paymentMethod'], 'googlePay');
      expect(json['totalAmount'], 1399.98);
      expect((json['items'] as List).length, 1);
      expect((json['items'] as List).first['title'], 'Smartphone');
      expect(json['shippingAddress']['city'], 'San Francisco');
    });

    test('Parses CheckoutResponse correctly from JSON', () {
      final responseJson = {
        'success': true,
        'orderId': 'ORD-12345',
        'message': 'Payment approved',
        'paymentToken': 'tok_abc123',
      };

      final response = CheckoutResponse.fromJson(responseJson);

      expect(response.success, isTrue);
      expect(response.orderId, 'ORD-12345');
      expect(response.message, 'Payment approved');
      expect(response.paymentToken, 'tok_abc123');
    });
  });
}
