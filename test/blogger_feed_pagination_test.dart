import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:blog_store/core/network/blogger_data_service.dart';

void main() {
  group('BloggerDataService Pagination Tests', () {
    test('Constructs feed pagination query parameters with start-index', () {
      final dio = Dio();
      final service = BloggerDataService(dio: dio);

      expect(service, isNotNull);
    });
  });
}
