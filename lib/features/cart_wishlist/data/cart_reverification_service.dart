import 'dart:convert';
import '../../../core/network/blogger_data_service.dart';
import '../../../core/utils/schema_resolver.dart';
import 'app_database.dart';

class ReverificationResult {
  final bool isValid;
  final double currentPrice;
  final double oldPrice;
  final String? message;

  ReverificationResult({
    required this.isValid,
    required this.currentPrice,
    required this.oldPrice,
    this.message,
  });
}

class CartReverificationService {
  final BloggerDataService bloggerDataService;
  final SchemaResolver schemaResolver;
  final AppDatabase database;

  CartReverificationService({
    required this.bloggerDataService,
    required this.schemaResolver,
    required this.database,
  });

  /// Re-verifies local cart items against live Blogger posts before checkout.
  Future<List<ReverificationResult>> reverifyCart() async {
    final cartItems = await database.select(database.cartItems).get();
    final List<ReverificationResult> results = [];

    for (final item in cartItems) {
      final livePost = await bloggerDataService.fetchPostById(
        blogId: item.blogId,
        postId: item.postId,
      );

      if (livePost == null || livePost['schema'] == null) {
        results.add(ReverificationResult(
          isValid: false,
          currentPrice: 0.0,
          oldPrice: item.price,
          message: 'Product post ${item.title} is no longer available.',
        ));
        continue;
      }

      final rawSchema = Map<String, dynamic>.from(livePost['schema'] as Map);
      final resolvedSchema = await schemaResolver.resolve(rawSchema);

      final double livePrice = _extractPrice(resolvedSchema) ?? item.price;

      if ((livePrice - item.price).abs() > 0.001) {
        // Price changed; update local cart item price
        await (database.update(database.cartItems)..where((tbl) => tbl.id.equals(item.id))).write(
          CartItemsCompanion(
            price: Value(livePrice),
            schemaJson: Value(jsonEncode(resolvedSchema)),
          ),
        );

        results.add(ReverificationResult(
          isValid: false,
          currentPrice: livePrice,
          oldPrice: item.price,
          message: 'Price for ${item.title} changed from \$${item.price} to \$${livePrice}. Cart updated.',
        ));
      } else {
        results.add(ReverificationResult(
          isValid: true,
          currentPrice: livePrice,
          oldPrice: item.price,
        ));
      }
    }

    return results;
  }

  double? _extractPrice(Map<String, dynamic> schema) {
    final priceInfo = _extractPriceAndCurrency(schema);
    return priceInfo?['price'] as double?;
  }

  Map<String, dynamic>? _extractPriceAndCurrency(Map<String, dynamic> schema) {
    if (schema['offers'] != null) {
      final offers = schema['offers'];
      if (offers is Map && offers['price'] != null) {
        return {
          'price': double.tryParse(offers['price'].toString()),
          'currency': offers['priceCurrency']?.toString() ?? schema['priceCurrency']?.toString() ?? 'USD',
        };
      } else if (offers is List && offers.isNotEmpty && offers.first['price'] != null) {
        return {
          'price': double.tryParse(offers.first['price'].toString()),
          'currency': offers.first['priceCurrency']?.toString() ?? schema['priceCurrency']?.toString() ?? 'USD',
        };
      }
    }
    if (schema['price'] != null) {
      return {
        'price': double.tryParse(schema['price'].toString()),
        'currency': schema['priceCurrency']?.toString() ?? 'USD',
      };
    }
    return null;
  }
}
