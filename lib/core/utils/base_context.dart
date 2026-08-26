/// Parses context paths structured as "blogId/postId".
class BaseContext {
  final String blogId;
  final String postId;

  const BaseContext({required this.blogId, required this.postId});

  /// Extracts blogId and postId from "@base" or relative paths.
  /// Standard @base format: "blogId/postId" e.g., "1774904866501098696/5522904867501094455"
  static BaseContext? parse(String? baseStr, {String? fallbackBlogId}) {
    if (baseStr == null || baseStr.isEmpty) return null;

    final cleanStr = baseStr.trim();
    final parts = cleanStr.split('/');
    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return BaseContext(blogId: parts[0], postId: parts[1]);
    } else if (parts.length == 1 && fallbackBlogId != null && fallbackBlogId.isNotEmpty) {
      return BaseContext(blogId: fallbackBlogId, postId: parts[0]);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseContext &&
          runtimeType == other.runtimeType &&
          blogId == other.blogId &&
          postId == other.postId;

  @override
  int get hashCode => blogId.hashCode ^ postId.hashCode;

  @override
  String toString() => '$blogId/$postId';
}
