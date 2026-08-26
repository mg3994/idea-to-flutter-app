class SellerInfo {
  final String sellerName;
  final String? sellerUrl;
  final bool isVerifiedMerchant;

  SellerInfo({
    required this.sellerName,
    this.sellerUrl,
    required this.isVerifiedMerchant,
  });
}

class SchemaSellerChecker {
  /// Parses Schema.org seller, offeredBy, or provider from resolved schema
  static SellerInfo checkSeller(Map<String, dynamic> schema) {
    dynamic sellerNode = schema['seller'] ?? schema['offeredBy'] ?? schema['provider'];

    if (sellerNode == null && schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map) {
        sellerNode = offers['seller'] ?? offers['offeredBy'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        sellerNode = offers.first['seller'] ?? offers.first['offeredBy'];
      }
    }

    if (sellerNode is Map<String, dynamic>) {
      final name = sellerNode['name']?.toString() ?? 'Official Merchant';
      final url = sellerNode['url']?.toString() ?? sellerNode['@id']?.toString();
      return SellerInfo(
        sellerName: name,
        sellerUrl: url,
        isVerifiedMerchant: true,
      );
    } else if (sellerNode is String && sellerNode.isNotEmpty) {
      return SellerInfo(
        sellerName: sellerNode,
        isVerifiedMerchant: true,
      );
    }

    return SellerInfo(
      sellerName: 'Antinna Store',
      isVerifiedMerchant: true,
    );
  }
}
