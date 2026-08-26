class FaqItem {
  final String question;
  final String answer;

  FaqItem({
    required this.question,
    required this.answer,
  });
}

class SchemaFaqExtractor {
  /// Parses Schema.org FAQPage / mainEntity / question / acceptedAnswer nodes
  static List<FaqItem> extractFaqs(Map<String, dynamic> schema) {
    final List<FaqItem> items = [];

    dynamic mainEntityNode = schema['mainEntity'] ?? schema['faq'];

    if (mainEntityNode == null && schema['@type'] == 'FAQPage') {
      mainEntityNode = schema['mainEntity'];
    }

    if (mainEntityNode is List) {
      for (final qNode in mainEntityNode) {
        if (qNode is Map<String, dynamic>) {
          final qText = qNode['name']?.toString() ?? qNode['text']?.toString() ?? '';
          final answerNode = qNode['acceptedAnswer'];
          String aText = '';
          if (answerNode is Map) {
            aText = answerNode['text']?.toString() ?? answerNode['name']?.toString() ?? '';
          } else if (answerNode is String) {
            aText = answerNode;
          }

          if (qText.isNotEmpty && aText.isNotEmpty) {
            items.add(FaqItem(question: qText, answer: aText));
          }
        }
      }
    }

    return items;
  }
}
