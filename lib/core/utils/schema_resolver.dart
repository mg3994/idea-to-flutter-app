import 'base_context.dart';
import 'schema_override.dart';

/// Schema resolver handling @base and @id link resolution across Blogger posts.
class SchemaResolver {
  final Future<Map<String, dynamic>?> Function(String blogId, String postId) fetchPostSchema;
  final String defaultBlogId;

  SchemaResolver({
    required this.fetchPostSchema,
    required this.defaultBlogId,
  });

  /// Resolves raw JSON-LD schema by combining base references and overrides recursively.
  Future<Map<String, dynamic>> resolve(Map<String, dynamic> rawSchema) async {
    final String? baseRaw = rawSchema['@base'] as String?;
    final BaseContext? baseContext = BaseContext.parse(baseRaw, fallbackBlogId: defaultBlogId);
    final String? idRef = rawSchema['@id'] as String?;

    if (baseContext == null && (idRef == null || !idRef.contains('/'))) {
      return rawSchema;
    }

    final String targetBlogId = baseContext?.blogId ?? defaultBlogId;
    final String? targetPostId = baseContext?.postId ?? _extractPostIdFromRef(idRef);

    if (targetPostId == null) return rawSchema;

    try {
      final Map<String, dynamic>? baseSchema = await fetchPostSchema(targetBlogId, targetPostId);
      if (baseSchema == null) return rawSchema;

      final Map<String, dynamic> resolvedBase = await resolve(baseSchema);

      return SchemaOverride.deepMerge(
        baseData: resolvedBase,
        overrideData: rawSchema,
      );
    } catch (_) {
      return rawSchema;
    }
  }

  String? _extractPostIdFromRef(String? ref) {
    if (ref == null) return null;
    final parts = ref.split('/');
    return parts.length >= 2 ? parts.last : null;
  }
}
