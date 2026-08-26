import '../../../shared/i18n/schema_i18n_resolver.dart';

class ProductEntity {
  final String id;
  final String blogId;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final String? brand;
  final String? sku;
  final List<String> labels;
  final Map<String, dynamic> rawSchema;
  final Map<String, dynamic> resolvedSchema;
  final dynamic areaServed;
  final String publishedAt;
  final double? ratingValue;
  final int? reviewCount;
  final List<Map<String, dynamic>> reviews;

  ProductEntity({
    required this.id,
    required this.blogId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.brand,
    this.sku,
    required this.labels,
    required this.rawSchema,
    required this.resolvedSchema,
    this.areaServed,
    required this.publishedAt,
    this.ratingValue,
    this.reviewCount,
    this.reviews = const [],
  });

  factory ProductEntity.fromPostMap({
    required Map<String, dynamic> postMap,
    required String blogId,
    required Map<String, dynamic> resolvedSchema,
    String locale = 'en',
  }) {
    final title = SchemaI18nResolver.resolveValue(
      resolvedSchema['name'] ?? postMap['title'],
      locale: locale,
    );

    final description = SchemaI18nResolver.resolveValue(
      resolvedSchema['description'] ?? postMap['content'],
      locale: locale,
    );

    double price = 0.0;
    String currency = 'USD';

    if (resolvedSchema['offers'] != null) {
      final offers = resolvedSchema['offers'];
      if (offers is Map) {
        price = double.tryParse(offers['price']?.toString() ?? '0') ?? 0.0;
        currency = offers['priceCurrency']?.toString() ?? resolvedSchema['priceCurrency']?.toString() ?? 'USD';
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        price = double.tryParse(offers.first['price']?.toString() ?? '0') ?? 0.0;
        currency = offers.first['priceCurrency']?.toString() ?? resolvedSchema['priceCurrency']?.toString() ?? 'USD';
      }
    } else if (resolvedSchema['price'] != null) {
      price = double.tryParse(resolvedSchema['price'].toString()) ?? 0.0;
      currency = resolvedSchema['priceCurrency']?.toString() ?? 'USD';
    }

    String? imageUrl;
    if (resolvedSchema['image'] != null) {
      final img = resolvedSchema['image'];
      if (img is String) {
        imageUrl = img;
      } else if (img is List && img.isNotEmpty) {
        imageUrl = img.first.toString();
      } else if (img is Map && img['url'] != null) {
        imageUrl = img['url'].toString();
      }
    }

    String? brand;
    if (resolvedSchema['brand'] != null) {
      final b = resolvedSchema['brand'];
      if (b is String) {
        brand = b;
      } else if (b is Map && b['name'] != null) {
        brand = b['name'].toString();
      }
    }

    double? ratingValue;
    int? reviewCount;
    if (resolvedSchema['aggregateRating'] != null && resolvedSchema['aggregateRating'] is Map) {
      final agg = resolvedSchema['aggregateRating'] as Map;
      ratingValue = double.tryParse(agg['ratingValue']?.toString() ?? '');
      reviewCount = int.tryParse(agg['reviewCount']?.toString() ?? agg['ratingCount']?.toString() ?? '');
    }

    final List<Map<String, dynamic>> parsedReviews = [];
    if (resolvedSchema['review'] != null) {
      final rev = resolvedSchema['review'];
      if (rev is List) {
        for (final r in rev) {
          if (r is Map<String, dynamic>) parsedReviews.add(r);
        }
      } else if (rev is Map<String, dynamic>) {
        parsedReviews.add(rev);
      }
    }

    return ProductEntity(
      id: postMap['id']?.toString() ?? '',
      blogId: blogId,
      title: title.isNotEmpty ? title : (postMap['title']?.toString() ?? ''),
      description: description,
      price: price,
      currency: currency,
      imageUrl: imageUrl,
      brand: brand,
      sku: resolvedSchema['sku']?.toString(),
      labels: List<String>.from(postMap['labels'] ?? []),
      rawSchema: Map<String, dynamic>.from(postMap['schema'] ?? {}),
      resolvedSchema: resolvedSchema,
      areaServed: resolvedSchema['areaServed'],
      publishedAt: postMap['published']?.toString() ?? '',
      ratingValue: ratingValue,
      reviewCount: reviewCount,
      reviews: parsedReviews,
    );
  }
}
