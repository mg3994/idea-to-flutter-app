import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/base_context.dart';
import 'package:blog_store/core/utils/schema_override.dart';
import 'package:blog_store/core/utils/schema_resolver.dart';
import 'package:blog_store/core/utils/area_served_matcher.dart';
import 'package:blog_store/shared/i18n/schema_i18n_resolver.dart';
import 'package:blog_store/features/catalog/domain/label_query_parser.dart';

void main() {
  group('BaseContext Tests', () {
    test('Parses full blogId/postId correctly', () {
      final context = BaseContext.parse('1774904866501098696/5522904867501094455');
      expect(context, isNotNull);
      expect(context!.blogId, '1774904866501098696');
      expect(context.postId, '5522904867501094455');
    });

    test('Parses relative postId with fallback blogId', () {
      final context = BaseContext.parse('5522904867501094455', fallbackBlogId: '1774904866501098696');
      expect(context, isNotNull);
      expect(context!.blogId, '1774904866501098696');
      expect(context.postId, '5522904867501094455');
    });

    test('Returns null for invalid base input', () {
      expect(BaseContext.parse(null), isNull);
      expect(BaseContext.parse(''), isNull);
    });
  });

  group('SchemaOverride Deep Merge Tests', () {
    test('Recursively merges override schema onto base blueprint schema', () {
      final baseData = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': 'Master Smartphone',
        'brand': {'@type': 'Brand', 'name': 'Acme'},
        'offers': {'@type': 'Offer', 'price': 999.0, 'priceCurrency': 'USD'},
        'color': 'Black',
      };

      final overrideData = {
        'name': 'Variant Smartphone Red',
        'color': 'Red',
        'offers': {'price': 899.0},
      };

      final merged = SchemaOverride.deepMerge(baseData: baseData, overrideData: overrideData);

      expect(merged['name'], 'Variant Smartphone Red');
      expect(merged['color'], 'Red');
      expect(merged['brand']['name'], 'Acme');
      expect(merged['offers']['price'], 899.0);
      expect(merged['offers']['priceCurrency'], 'USD');
    });
  });

  group('SchemaResolver Inheritance Tests', () {
    test('Resolves @base linked post schemas recursively', () async {
      final masterPostSchema = {
        '@type': 'Product',
        'name': 'Master Laptop',
        'brand': 'TechCorp',
        'price': 1200.0,
      };

      final resolver = SchemaResolver(
        defaultBlogId: '1774904866501098696',
        fetchPostSchema: (blogId, postId) async {
          if (blogId == '1774904866501098696' && postId == 'master_123') {
            return masterPostSchema;
          }
          return null;
        },
      );

      final variantPostSchema = {
        '@base': '1774904866501098696/master_123',
        'name': 'Variant Laptop 16GB RAM',
        'price': 1350.0,
      };

      final resolved = await resolver.resolve(variantPostSchema);

      expect(resolved['name'], 'Variant Laptop 16GB RAM');
      expect(resolved['brand'], 'TechCorp');
      expect(resolved['price'], 1350.0);
    });
  });

  group('AreaServedMatcher Tests', () {
    test('Matches simple string areaServed', () {
      expect(AreaServedMatcher.matches(areaServed: 'California', state: 'California'), isTrue);
      expect(AreaServedMatcher.matches(areaServed: 'Texas', state: 'California'), isFalse);
    });

    test('Matches list areaServed', () {
      final area = ['New York', 'California', '90210'];
      expect(AreaServedMatcher.matches(areaServed: area, city: 'New York'), isTrue);
      expect(AreaServedMatcher.matches(areaServed: area, postalCode: '90210'), isTrue);
      expect(AreaServedMatcher.matches(areaServed: area, city: 'Miami'), isFalse);
    });
  });

  group('SchemaI18nResolver & LabelQueryParser Tests', () {
    test('Resolves dynamic @value and @language locale nodes', () {
      final i18nNode = [
        {'@value': 'El Teléfono', '@language': 'es'},
        {'@value': 'The Phone', '@language': 'en'},
      ];

      expect(SchemaI18nResolver.resolveValue(i18nNode, locale: 'en'), 'The Phone');
      expect(SchemaI18nResolver.resolveValue(i18nNode, locale: 'es'), 'El Teléfono');
    });

    test('Parses label query expressions with pipe OR and space operators', () {
      final labels = ['electronics', 'mobile', 'android'];

      expect(LabelQueryParser.matches(labels, 'label:electronics | label:apple'), isTrue);
      expect(LabelQueryParser.matches(labels, 'label:ios | label:apple'), isFalse);
      expect(LabelQueryParser.matches(labels, 'mobile android'), isTrue);
    });
  });
}
