import 'package:tiler_app/data/comments/comment.dart';

/// A person picked into the composer via the mention suggestion list.
class MentionSelection {
  final CommentParticipant participant;
  final int charOffset;

  const MentionSelection(this.participant, this.charOffset);
}

/// Parse/serialize helpers for the `<@userId>` mention tokens that are stored
/// inside comment text. Tokens must be rendered as highlighted `@Display
/// Name` runs — never rendered as HTML.
class MentionParser {
  static final RegExp _mentionPattern = RegExp(r'<@([^>]+)>');

  /// Returns the ids of the `<@userId>` tokens in [text], in order of
  /// appearance (may contain duplicates).
  static List<String> extractIds(String text) {
    return _mentionPattern.allMatches(text).map((m) => m.group(1)!).toList();
  }

  /// The distinct ids in [text] — this is exactly what the
  /// `mentionedUserIds` request field must contain (server compares as a set).
  static List<String> extractDistinctIds(String text) {
    final seen = <String>{};
    return _mentionPattern.allMatches(text).map((m) => m.group(1)!)
        .where(seen.add)
        .toList();
  }

  /// Splits [text] into ordered parts for rendering: null is a plain text run,
  /// a [CommentPerson] (or null) marks a mention run. Each mention id is
  /// resolved against [mentionLookup]; unknown or deleted ids yield null so
  /// the caller can show "Deleted user".
  static List<dynamic> splitForDisplay(
      String text, Map<String, CommentPerson> mentionLookup) {
    final parts = <dynamic>[];
    var cursor = 0;
    for (final match in _mentionPattern.allMatches(text)) {
      if (match.start > cursor) {
        parts.add(text.substring(cursor, match.start));
      }
      parts.add(mentionLookup[match.group(1)]);
      cursor = match.end;
    }
    if (cursor < text.length) {
      parts.add(text.substring(cursor));
    }
    return parts;
  }

  /// Converts the stored `<@userId>` tokens into display text for the edit
  /// mode: `@Display Name` with a trailing space. Unknown ids become
  /// `@DeletedUser` (caller may pass [deletedLabel]).
  static String toDisplayText(String text, Map<String, CommentPerson> lookup,
      {String deletedLabel = 'Deleted user'}) {
    return text.replaceAllMapped(_mentionPattern, (match) {
      final person = lookup[match.group(1)];
      final name =
          (person?.displayName == null || person!.displayName!.isEmpty)
              ? deletedLabel
              : person.displayName!;
      return '@$name ';
    });
  }

  /// Converts the composer's display text back into stored tokens. Each
  /// `@Display Name` from [selections] (matched at its [MentionSelection.charOffset]
  /// or by name) is replaced by `<@userId>`; everything else stays verbatim.
  /// The returned ids are in first-appearance order.
  static (String text, List<String> ids) toTokens(
      String displayText, List<MentionSelection> selections) {
    if (selections.isEmpty) {
      return (displayText, const <String>[]);
    }

    // Sort by char offset descending so replacements keep earlier offsets valid.
    final sorted = List<MentionSelection>.from(selections)
      ..sort((a, b) => b.charOffset.compareTo(a.charOffset));

    var result = displayText;
    for (final selection in sorted) {
      final name = selection.participant.displayName;
      if (name.isEmpty) continue;
      final display = '@$name';
      int index = -1;
      if (selection.charOffset >= 0 &&
          selection.charOffset + display.length <= result.length) {
        index = result.indexOf(display, selection.charOffset);
        // Allow a small drift after earlier (later-offset) replacements.
        if (index < 0 || index > selection.charOffset + 64) {
          index = result.indexOf(display);
        }
      } else {
        index = result.indexOf(display);
      }
      if (index >= 0) {
        result = result.replaceRange(
            index, index + display.length, '<@${selection.participant.id}>');
      }
    }
    return (result, extractDistinctIds(result));
  }

  /// Case-insensitive name-prefix filter for the suggestion list. Excludes
  /// the viewer and caps at [limit] candidates.
  static List<CommentParticipant> filterSuggestions(
      List<CommentParticipant> candidates, String query,
      {int limit = 8}) {
    final q = query.trim().toLowerCase();
    final out = <CommentParticipant>[];
    for (final candidate in candidates) {
      if (candidate.isViewer) continue;
      if (q.isEmpty ||
          candidate.displayName.toLowerCase().startsWith(q) ||
          candidate.displayName.toLowerCase().contains(q)) {
        out.add(candidate);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}