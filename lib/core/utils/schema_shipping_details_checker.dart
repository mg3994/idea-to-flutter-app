class ShippingDetailsInfo {
  final double shippingRate;
  final String currency;
  final bool isFreeShipping;
  final String deliveryWindowText;

  ShippingDetailsInfo({
    required this.shippingRate,
    required this.currency,
    required this.isFreeShipping,
    required this.deliveryWindowText,
  });
}

class SchemaShippingDetailsChecker {
  /// Parses Schema.org shippingDetails or shippingRate from resolved schema
  static ShippingDetailsInfo checkShippingDetails(Map<String, dynamic> schema) {
    dynamic shippingNode = schema['shippingDetails'];

    if (shippingNode == null && schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        shippingNode = offers['shippingDetails'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        shippingNode = offers.first['shippingDetails'];
      }
    }

    if (shippingNode is Map<String, dynamic>) {
      double rate = 0.0;
      String curr = schema['priceCurrency']?.toString() ?? 'USD';

      if (shippingNode['shippingRate'] != null) {
        final rateNode = shippingNode['shippingRate'];
        if (rateNode is Map) {
          rate = double.tryParse(rateNode['value']?.toString() ?? '0') ?? 0.0;
          curr = rateNode['currency']?.toString() ?? curr;
        } else {
          rate = double.tryParse(rateNode.toString()) ?? 0.0;
        }
      }

      final deliveryDays = shippingNode['deliveryTime']?['handlingTime']?['value'] ?? 3;

      return ShippingDetailsInfo(
        shippingRate: rate,
        currency: curr,
        isFreeShipping: rate == 0.0,
        deliveryWindowText: rate == 0.0 ? 'Free Delivery (2-4 Days)' : 'Delivery in $deliveryDays Days',
      );
    }

    return ShippingDetailsInfo(
      shippingRate: 0.0,
      currency: 'USD',
      isFreeShipping: true,
      deliveryWindowText: 'Free Standard Delivery',
    );
  }
}
