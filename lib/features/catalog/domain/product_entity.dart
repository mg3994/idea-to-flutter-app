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
        currency = offers['priceCurrency']?.toString() ?? 'USD';
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        price = double.tryParse(offers.first['price']?.toString() ?? '0') ?? 0.0;
        currency = offers.first['priceCurrency']?.toString() ?? 'USD';
      }
    } else if (resolvedSchema['price'] != null) {
      price = double.tryParse(resolvedSchema['price'].toString()) ?? 0.0;
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
    );
  }
}
