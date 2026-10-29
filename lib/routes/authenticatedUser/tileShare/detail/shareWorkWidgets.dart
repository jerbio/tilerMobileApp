import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';
import 'shareDisplayOptions.dart';

/// Server completion is a percentage; absence is unknown, not zero progress.
double? shareCompletion(double? value) =>
    value == null || !value.isFinite ? null : value.clamp(0.0, 100.0);

enum ShareWorkFilter { all, attention, inProgress, completed }

/// Tabs become wrapping chips when large text needs more vertical room.
class ShareDetailTabs<T> extends StatelessWidget {
  final List<(T, String, Key?)> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  const ShareDetailTabs(
      {super.key,
      required this.tabs,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final tab in tabs)
          ChoiceChip(
              label: Text(tab.$2, key: tab.$3),
              selected: selected == tab.$1,
              showCheckmark: false,
              onSelected: (_) => onChanged(tab.$1)),
      ]);
    }
    return SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final tab in tabs)
            ButtonSegment<T>(
                value: tab.$1,
                label: Text(tab.$2,
                    key: tab.$3, maxLines: 1, overflow: TextOverflow.ellipsis))
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first));
  }
}

bool matchesShareWorkFilter(ShareWorkFilter filter,
    Iterable<(InvitationStatus?, double?)> assignments) {
  final cells = assignments.toList();
  return switch (filter) {
    ShareWorkFilter.all => true,
    ShareWorkFilter.attention =>
      cells.isEmpty || cells.any((c) => c.$1 != InvitationStatus.accepted),
    ShareWorkFilter.inProgress => cells.any((c) =>
        c.$1 == InvitationStatus.accepted &&
        (shareCompletion(c.$2) ?? 0) > 0 &&
        (shareCompletion(c.$2) ?? 0) < 100),
    ShareWorkFilter.completed => cells.isNotEmpty &&
        cells.every((c) =>
            c.$1 == InvitationStatus.accepted &&
            (shareCompletion(c.$2) ?? 0) >= 100),
  };
}

class ShareWorkFilterButton extends StatelessWidget {
  final ShareWorkFilter selected;
  final ValueChanged<ShareWorkFilter> onChanged;
  const ShareWorkFilterButton(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String label(ShareWorkFilter value) => switch (value) {
          ShareWorkFilter.all => l.todayStatusShowAll,
          ShareWorkFilter.attention => l.shareNeedsAttention,
          ShareWorkFilter.inProgress => l.shareInProgress,
          ShareWorkFilter.completed => l.completed,
        };
    return PopupMenuButton<ShareWorkFilter>(
      key: const Key('share_work_filter'),
      tooltip: '${l.shareWork}: ${label(selected)}',
      initialValue: selected,
      icon: Icon(Icons.filter_list,
          color: selected == ShareWorkFilter.all
              ? null
              : Theme.of(context).colorScheme.primary),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final value in ShareWorkFilter.values)
          CheckedPopupMenuItem(
              value: value,
              checked: value == selected,
              child: Text(label(value)))
      ],
    );
  }
}

class ShareWorkStatus extends StatelessWidget {
  final InvitationStatus? response;
  final double? completion;
  const ShareWorkStatus({super.key, this.response, this.completion});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final progress = shareCompletion(completion);
    final (String, StatusPillTone) status = switch (response) {
      InvitationStatus.declined => (l.declined, StatusPillTone.danger),
      InvitationStatus.accepted when progress == null => (
          l.accepted,
          StatusPillTone.success
        ),
      InvitationStatus.accepted when progress! >= 100 => (
          l.completed,
          StatusPillTone.success
        ),
      InvitationStatus.accepted when progress! > 0 => (
          l.shareInProgress,
          StatusPillTone.info
        ),
      InvitationStatus.accepted => (l.shareNotStarted, StatusPillTone.neutral),
      _ => (l.shareAwaitingResponse, StatusPillTone.warning),
    };
    return TileShareStatusPill(label: status.$1, tone: status.$2);
  }
}

class ShareWorkMeta extends StatelessWidget {
  final int? durationMs;
  final int? dueMs;
  const ShareWorkMeta({super.key, this.durationMs, this.dueMs});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(spacing: 12, runSpacing: 4, children: [
      if ((durationMs ?? 0) > 0)
        Text(Duration(milliseconds: durationMs!).toHumanLocalized(context)),
      if (dueMs != null)
        Text(l.attentionMetaDue(
            DateFormat.MMMd(Localizations.localeOf(context).toString()).format(
                DateTime.fromMillisecondsSinceEpoch(dueMs!).toLocal()))),
    ]);
  }
}

class ShareCompletionBar extends StatelessWidget {
  final double value;
  final String label;
  const ShareCompletionBar(
      {super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final fraction = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final theme = Theme.of(context);
    final compact =
        TileShareDisplayScope.densityOf(context) != TiletteDensity.comfortable;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: theme.textTheme.bodySmall),
      SizedBox(height: compact ? 4 : 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: compact ? 4 : 8,
          semanticsLabel: label,
          color: TileColors.acceptedTileShare,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    ]);
  }
}

/// Wrapping stats stay readable on narrow phones and with enlarged text.
class ShareWorkSummary extends StatelessWidget {
  final List<(IconData, int, String, Color)> stats;
  final Widget? progress;
  const ShareWorkSummary({super.key, required this.stats, this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = TileShareDisplayScope.of(context);
    final condensed = settings?.condensedSummary ?? true;
    if (condensed) {
      final visible = stats.where((s) => s.$2 > 0).toList();
      final shown = visible.isEmpty ? stats.take(1) : visible;
      return Container(
        key: const Key('share_summary_strip'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (progress != null) progress!,
          if (progress != null && shown.isNotEmpty) const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final stat in shown)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(stat.$1, size: 16, color: stat.$4),
                const SizedBox(width: 4),
                Flexible(
                    child: Text('${stat.$2} ${stat.$3}',
                        style: theme.textTheme.bodySmall)),
              ])
          ]),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (progress != null) progress!,
        if (progress != null && stats.isNotEmpty) const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final enlarged = MediaQuery.textScalerOf(context).scale(14) > 20;
          final columns = enlarged
              ? 1
              : constraints.maxWidth < 290
                  ? 2
                  : 3;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 16, children: [
            for (final stat in stats)
              SizedBox(
                  width: width,
                  child: Semantics(
                    label: '${stat.$2} ${stat.$3}',
                    excludeSemantics: true,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(stat.$1, color: stat.$4, size: 26),
                            const SizedBox(width: 8),
                            Flexible(
                                child: Text('${stat.$2}',
                                    style: theme.textTheme.titleLarge)),
                          ]),
                          const SizedBox(height: 6),
                          Text(stat.$3, style: theme.textTheme.bodySmall),
                        ]),
                  )),
          ]);
        }),
      ]),
    );
  }
}
