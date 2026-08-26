import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/schema_faq_extractor.dart';

void main() {
  group('SchemaFaqExtractor Tests', () {
    test('Extracts question and acceptedAnswer nodes correctly', () {
      final schema = {
        '@type': 'FAQPage',
        'mainEntity': [
          {
            '@type': 'Question',
            'name': 'What is the return policy?',
            'acceptedAnswer': {
              '@type': 'Answer',
              'text': 'We offer a 30-day money-back guarantee.',
            },
          },
          {
            '@type': 'Question',
            'name': 'Is international shipping supported?',
            'acceptedAnswer': {
              '@type': 'Answer',
              'text': 'Yes, worldwide shipping is supported.',
            },
          },
        ],
      };

      final faqs = SchemaFaqExtractor.extractFaqs(schema);

      expect(faqs.length, 2);
      expect(faqs[0].question, 'What is the return policy?');
      expect(faqs[0].answer, contains('30-day'));
      expect(faqs[1].question, 'Is international shipping supported?');
    });
  });
}
