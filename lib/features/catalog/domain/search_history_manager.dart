class SearchHistoryManager {
  static final List<String> _recentSearches = [];

  static List<String> get recentSearches => List.unmodifiable(_recentSearches);

  static void addSearchQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _recentSearches.remove(clean);
    _recentSearches.insert(0, clean);

    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
  }

  static void clearHistory() {
    _recentSearches.clear();
  }
}
