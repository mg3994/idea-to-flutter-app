import '../../features/catalog/domain/product_entity.dart';
import 'env_config.dart';

class SampleCatalogLoader {
  static List<ProductEntity> getSampleProducts() {
    // 1. Master Post Schema
    final masterSchema = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      '@id': '${EnvConfig.defaultBlogId}/master_phone_1',
      'name': 'Antinna Master Smartphone 5G',
      'description': 'Flagship 5G smartphone with AMOLED 120Hz display, Snapdragon 8 Gen 3, and 50MP Triple Camera.',
      'brand': {'@type': 'Brand', 'name': 'Antinna'},
      'sku': 'ANT-PHONE-5G',
      'price': '899.00',
      'priceCurrency': 'USD',
      'image': 'https://picsum.photos/400/300?random=1',
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': '4.8',
        'reviewCount': '142',
      },
      'review': [
        {
          'author': {'name': 'Tech Reviewer'},
          'reviewBody': 'Incredible performance and screen quality!',
        }
      ],
      'areaServed': ['Worldwide', 'USA', 'India', 'Europe'],
    };

    // 2. Variant Post Schema overriding price and color via @base
    final variantSchemaInr = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      '@base': '${EnvConfig.defaultBlogId}/master_phone_1',
      'name': 'Antinna Master Smartphone 5G (India Edition)',
      'price': '69999.00',
      'priceCurrency': 'INR',
      'image': 'https://picsum.photos/400/300?random=2',
      'areaServed': 'India',
    };

    final variantSchemaEur = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      '@base': '${EnvConfig.defaultBlogId}/master_phone_1',
      'name': 'Antinna Master Smartphone 5G (Europe Edition)',
      'price': '799.00',
      'priceCurrency': 'EUR',
      'image': 'https://picsum.photos/400/300?random=3',
      'areaServed': 'Europe',
    };

    final masterPostMap = {
      'id': 'master_phone_1',
      'title': 'Antinna Master Smartphone 5G',
      'published': '2025-01-15T10:00:00Z',
      'labels': ['electronics', 'mobile', 'smartphone', 'flagship'],
      'schema': masterSchema,
    };

    final variantInrPostMap = {
      'id': 'var_phone_inr',
      'title': 'Antinna Master Smartphone 5G (India Edition)',
      'published': '2025-01-20T10:00:00Z',
      'labels': ['electronics', 'mobile', 'india'],
      'schema': variantSchemaInr,
    };

    final variantEurPostMap = {
      'id': 'var_phone_eur',
      'title': 'Antinna Master Smartphone 5G (Europe Edition)',
      'published': '2025-01-22T10:00:00Z',
      'labels': ['electronics', 'mobile', 'europe'],
      'schema': variantSchemaEur,
    };

    return [
      ProductEntity.fromPostMap(
        postMap: masterPostMap,
        blogId: EnvConfig.defaultBlogId,
        resolvedSchema: masterSchema,
      ),
      ProductEntity.fromPostMap(
        postMap: variantInrPostMap,
        blogId: EnvConfig.defaultBlogId,
        resolvedSchema: variantSchemaInr,
      ),
      ProductEntity.fromPostMap(
        postMap: variantEurPostMap,
        blogId: EnvConfig.defaultBlogId,
        resolvedSchema: variantSchemaEur,
      ),
    ];
  }
}
