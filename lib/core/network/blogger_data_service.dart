import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/env_config.dart';

class BloggerDataService {
  final Dio dio;
  final String? apiKey;
  final String? authToken;

  BloggerDataService({
    required this.dio,
    this.apiKey,
    this.authToken,
  });

  /// Dual-mode fetching:
  /// - Authenticated REST API v3 if [authToken] or [apiKey] is present
  /// - Unauthenticated Blogger Feeds JSON if not authenticated
  Future<List<Map<String, dynamic>>> fetchPosts({
    String blogId = EnvConfig.defaultBlogId,
    String? label,
    String? areaQuery,
    int maxResults = 20,
    String? pageToken,
  }) async {
    if (authToken != null || apiKey != null) {
      return _fetchPostsRestApi(blogId: blogId, label: label, maxResults: maxResults, pageToken: pageToken);
    } else {
      return _fetchPostsFeeds(blogId: blogId, label: label, areaQuery: areaQuery, maxResults: maxResults);
    }
  }

  Future<Map<String, dynamic>?> fetchPostById({
    required String blogId,
    required String postId,
  }) async {
    if (authToken != null || apiKey != null) {
      try {
        final Map<String, dynamic> headers = {};
        if (authToken != null) {
          headers['Authorization'] = 'Bearer $authToken';
        }
        final queryParams = <String, dynamic>{};
        if (apiKey != null) queryParams['key'] = apiKey;

        final response = await dio.get(
          '${EnvConfig.bloggerApiBaseUrl}/blogs/$blogId/posts/$postId',
          queryParameters: queryParams,
          options: Options(headers: headers),
        );
        if (response.data is Map<String, dynamic>) {
          final content = response.data['content'] as String? ?? '';
          final jsonLd = extractJsonLd(content) ?? {};
          return {
            'id': response.data['id'],
            'title': response.data['title'],
            'published': response.data['published'],
            'updated': response.data['updated'],
            'url': response.data['url'],
            'labels': List<String>.from(response.data['labels'] ?? []),
            'content': content,
            'schema': jsonLd,
          };
        }
      } catch (_) {}
    }

    // Fallback: Fetch single post via public Feeds API
    try {
      final response = await dio.get(
        '${EnvConfig.bloggerFeedBaseUrl}/$blogId/posts/default/$postId',
        queryParameters: {'alt': 'json'},
      );
      if (response.data is Map<String, dynamic>) {
        final entry = response.data['entry'];
        if (entry != null) {
          return _parseFeedEntry(entry);
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchPostsFeeds({
    required String blogId,
    String? label,
    String? areaQuery,
    int maxResults = 20,
  }) async {
    final String encCategory = label != null && label.isNotEmpty ? Uri.encodeComponent(label) : '';
    final String urlPath = encCategory.isNotEmpty
        ? '${EnvConfig.bloggerFeedBaseUrl}/$blogId/posts/default/-/$encCategory'
        : '${EnvConfig.bloggerFeedBaseUrl}/$blogId/posts/default';

    final queryParams = <String, dynamic>{
      'alt': 'json',
      'max-results': maxResults,
    };

    if (areaQuery != null && areaQuery.trim().isNotEmpty) {
      final encArea = Uri.encodeComponent(areaQuery.trim());
      queryParams['q'] = '"$encArea"';
    }

    final response = await dio.get(
      urlPath,
      queryParameters: queryParams,
    );

    final List<Map<String, dynamic>> results = [];
    if (response.data != null && response.data['feed'] != null && response.data['feed']['entry'] != null) {
      final entries = response.data['feed']['entry'] as List;
      for (final entry in entries) {
        final parsed = _parseFeedEntry(entry);
        if (parsed != null) {
          results.add(parsed);
        }
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchPostsRestApi({
    required String blogId,
    String? label,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final Map<String, dynamic> headers = {};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    final Map<String, dynamic> queryParams = {
      'maxResults': maxResults,
    };
    if (apiKey != null) queryParams['key'] = apiKey;
    if (label != null && label.isNotEmpty) queryParams['labels'] = label;
    if (pageToken != null) queryParams['pageToken'] = pageToken;

    final response = await dio.get(
      '${EnvConfig.bloggerApiBaseUrl}/blogs/$blogId/posts',
      queryParameters: queryParams,
      options: Options(headers: headers),
    );

    final List<Map<String, dynamic>> results = [];
    if (response.data != null && response.data['items'] != null) {
      final items = response.data['items'] as List;
      for (final item in items) {
        final content = item['content'] as String? ?? '';
        final jsonLd = extractJsonLd(content) ?? {};
        results.add({
          'id': item['id'],
          'title': item['title'],
          'published': item['published'],
          'updated': item['updated'],
          'url': item['url'],
          'labels': List<String>.from(item['labels'] ?? []),
          'content': content,
          'schema': jsonLd,
        });
      }
    }
    return results;
  }

  Map<String, dynamic>? _parseFeedEntry(dynamic entry) {
    try {
      final String idStr = entry['id']?['\$t'] as String? ?? '';
      final String postId = idStr.split('post-').last;
      final String title = entry['title']?['\$t'] as String? ?? '';
      final String published = entry['published']?['\$t'] as String? ?? '';
      final String updated = entry['updated']?['\$t'] as String? ?? '';
      final String content = entry['content']?['\$t'] as String? ?? entry['summary']?['\$t'] as String? ?? '';

      final List<String> labels = [];
      if (entry['category'] != null && entry['category'] is List) {
        for (final cat in entry['category']) {
          if (cat['term'] != null) labels.add(cat['term'].toString());
        }
      }

      final jsonLd = extractJsonLd(content) ?? {};

      return {
        'id': postId,
        'title': title,
        'published': published,
        'updated': updated,
        'url': idStr,
        'labels': labels,
        'content': content,
        'schema': jsonLd,
      };
    } catch (_) {
      return null;
    }
  }

  /// JSON-LD extractor for Blogger HTML responses.
  static Map<String, dynamic>? extractJsonLd(String htmlContent) {
    try {
      final RegExp regExp = RegExp(
        r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
        multiLine: true,
        caseSensitive: false,
        dotAll: true,
      );

      final match = regExp.firstMatch(htmlContent);
      final jsonString = match != null ? match.group(1) : htmlContent;

      if (jsonString == null || jsonString.trim().isEmpty) return null;

      final cleaned = jsonString
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
