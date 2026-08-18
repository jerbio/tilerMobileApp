/// Keyed chat suggestions from the backend. Keys are stable per generation so a
/// suggestion keeps its identity across rebuilds: { "sug_abc": "Plan my day" }.
class VibeAutoSuggestions {
  final Map<String, String> suggestions;

  /// True when the session has moved on since these were generated, meaning a
  /// refresh call will produce conversation-aware replacements.
  final bool isStale;

  const VibeAutoSuggestions({
    this.suggestions = const {},
    this.isStale = false,
  });

  bool get isEmpty => suggestions.isEmpty;

  List<MapEntry<String, String>> get entries => suggestions.entries.toList();

  factory VibeAutoSuggestions.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    final parsed = <String, String>{};
    if (rawSuggestions is Map) {
      rawSuggestions.forEach((key, value) {
        if (key != null && value != null) {
          parsed[key.toString()] = value.toString();
        }
      });
    }
    return VibeAutoSuggestions(
      suggestions: parsed,
      isStale: json['isStale'] == true,
    );
  }
}
