import 'package:tiler_app/data/preview/day_preview_metrics.dart';

/// Localization adapter for the preview summary sentence.
///
/// Tests inject synthetic implementations; the widget layer builds one
/// from `AppLocalizations` and locale-specific number / date formatters.
class PreviewLabels {
  final String greeting;
  final String Function(int count) tilesClause;
  final String Function(int count) blocksClause;
  final String Function(int count) tileSharesClause;
  final String Function(String hoursText) workClause;
  final String Function(int minutes) transitClause;
  final String Function(String timeText) clearsByClause;
  final String countsPrefix;
  final String countsSuffix;
  final String andSeparator;
  final String sentenceJoiner;
  final String noTiles;
  final String Function(double hours) formatHours;
  final String Function(DateTime time) formatClearTime;

  const PreviewLabels({
    required this.greeting,
    required this.tilesClause,
    required this.blocksClause,
    required this.tileSharesClause,
    required this.workClause,
    required this.transitClause,
    required this.clearsByClause,
    required this.countsPrefix,
    required this.countsSuffix,
    required this.andSeparator,
    required this.sentenceJoiner,
    required this.noTiles,
    required this.formatHours,
    required this.formatClearTime,
  });
}

/// Builds the rich day-preview sentence from metrics + localized labels.
///
/// Clauses are dropped cleanly when their underlying metric is empty so
/// the sentence reads naturally regardless of which data is present.
String buildPreviewSentence({
  required DayPreviewMetrics metrics,
  required PreviewLabels labels,
}) {
  final hasCounts = metrics.tilesCount > 0 ||
      metrics.blocksCount > 0 ||
      metrics.tileSharesCount > 0;
  final hasWork = metrics.workDuration.inMilliseconds > 0;
  final hasTransit = metrics.transitDuration.inMilliseconds > 0;
  final hasClearsBy = metrics.dayClearsBy != null;

  if (!hasCounts && !hasWork && !hasTransit && !hasClearsBy) {
    return labels.noTiles;
  }

  final sentences = <String>[];

  if (hasCounts) {
    final clauses = <String>[];
    if (metrics.tilesCount > 0) {
      clauses.add(labels.tilesClause(metrics.tilesCount));
    }
    if (metrics.blocksCount > 0) {
      clauses.add(labels.blocksClause(metrics.blocksCount));
    }
    if (metrics.tileSharesCount > 0) {
      clauses.add(labels.tileSharesClause(metrics.tileSharesCount));
    }

    final body = _joinClauses(clauses, labels.andSeparator);
    sentences.add(
      '${labels.greeting} ${labels.countsPrefix} $body ${labels.countsSuffix}',
    );
  }

  final tail = <String>[];
  if (hasWork) {
    final hoursDecimal = metrics.workDuration.inMinutes / 60.0;
    tail.add(labels.workClause(labels.formatHours(hoursDecimal)));
  }
  if (hasTransit) {
    tail.add(labels.transitClause(metrics.transitDuration.inMinutes));
  }
  if (hasClearsBy) {
    tail.add(
        labels.clearsByClause(labels.formatClearTime(metrics.dayClearsBy!)));
  }
  if (tail.isNotEmpty) {
    sentences.add(_joinClauses(tail, labels.andSeparator));
  }

  return sentences.join(labels.sentenceJoiner);
}

String _joinClauses(List<String> clauses, String andSeparator) {
  if (clauses.isEmpty) return '';
  if (clauses.length == 1) return clauses.single;
  if (clauses.length == 2) {
    return '${clauses[0]} $andSeparator ${clauses[1]}';
  }
  final head = clauses.sublist(0, clauses.length - 1).join(', ');
  return '$head, $andSeparator ${clauses.last}';
}
