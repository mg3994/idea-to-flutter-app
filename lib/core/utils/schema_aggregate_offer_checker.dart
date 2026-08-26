class AggregateOfferInfo {
  final double lowPrice;
  final double highPrice;
  final int offerCount;
  final String currency;
  final bool isAggregate;

  AggregateOfferInfo({
    required this.lowPrice,
    required this.highPrice,
    required this.offerCount,
    required this.currency,
    required this.isAggregate,
  });
}

class SchemaAggregateOfferChecker {
  /// Parses Schema.org AggregateOffer nodes from resolved schema
  static AggregateOfferInfo checkAggregateOffer(Map<String, dynamic> schema) {
    dynamic offerNode = schema['offers'];

    if (offerNode is Map<String, dynamic> && offerNode['@type'] == 'AggregateOffer') {
      final low = double.tryParse(offerNode['lowPrice']?.toString() ?? '0') ?? 0.0;
      final high = double.tryParse(offerNode['highPrice']?.toString() ?? '0') ?? low;
      final count = int.tryParse(offerNode['offerCount']?.toString() ?? '1') ?? 1;
      final curr = offerNode['priceCurrency']?.toString() ?? schema['priceCurrency']?.toString() ?? 'USD';

      return AggregateOfferInfo(
        lowPrice: low,
        highPrice: high,
        offerCount: count,
        currency: curr,
        isAggregate: true,
      );
    }

    return AggregateOfferInfo(
      lowPrice: 0.0,
      highPrice: 0.0,
      offerCount: 1,
      currency: 'USD',
      isAggregate: false,
    );
  }
}
