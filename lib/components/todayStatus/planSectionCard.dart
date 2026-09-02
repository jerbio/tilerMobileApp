import 'package:flutter/material.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/components/todayStatus/statusIconWell.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// An expandable Today Status section card (spec §5.3 / §5.4 / §7.3).
///
/// One widget serves the placed, attention and late sections; the semantic
/// [status] drives the icon, tint and copy. Selection state is owned by the
/// caller so the screen keeps a single source of truth for the multi-select
/// completion flow.
class PlanSectionCard extends StatefulWidget {
  const PlanSectionCard({
    super.key,
    required this.status,
    required this.items,
    this.onItemTap,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelected,
    this.onEnterSelectionMode,
    this.onExitSelectionMode,
    this.selectionFooter,
    this.initiallyExpanded,
  });

  static const Key cardKey = Key('todayStatus.sectionCard');
  static const Key chevronKey = Key('todayStatus.sectionCard.chevron');
  static const Key enterSelectionKey =
      Key('todayStatus.sectionCard.enterSelection');
  static const Key exitSelectionKey =
      Key('todayStatus.sectionCard.exitSelection');

  /// Toggle for the group of sub-events sharing parent calendar event [parentId].
  static Key groupToggleKey(String parentId) =>
      Key('todayStatus.sectionCard.group.$parentId');

  /// §7.3: sections longer than this collapse by default, and §17 caps how many
  /// entries render before "Show all".
  static const int collapsedPreviewCount = 6;

  final PlanItemStatus status;
  final List<PlanItemViewModel> items;
  final ValueChanged<PlanItemViewModel>? onItemTap;

  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggleSelected;
  final VoidCallback? onEnterSelectionMode;
  final VoidCallback? onExitSelectionMode;

  /// Rendered below the rows while selecting — the "N selected / Complete
  /// Tiles" action carried over from the previous summary page.
  final Widget? selectionFooter;

  /// Overrides the §7.3 default. The screen collapses a healthy placed section
  /// when something needs attention, so the exception owns the screen.
  final bool? initiallyExpanded;

  @override
  State<PlanSectionCard> createState() => _PlanSectionCardState();
}

class _PlanSectionCardState extends State<PlanSectionCard> {
  bool? _expandedOverride;
  bool _showAll = false;
  final Set<String> _expandedGroups = {};

  /// Attention always leads expanded; placed/late collapse when long (§7.3).
  bool get _expanded =>
      _expandedOverride ??
      widget.initiallyExpanded ??
      (widget.status == PlanItemStatus.needsAttention ||
          widget.items.length <= PlanSectionCard.collapsedPreviewCount);

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final String title = _title(l10n);

    return Container(
      key: PlanSectionCard.cardKey,
      margin: const EdgeInsets.only(bottom: TodayStatusTokens.space4),
      padding: const EdgeInsets.symmetric(
          horizontal: TodayStatusTokens.space4,
          vertical: TodayStatusTokens.space4),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(TodayStatusTokens.radiusLg),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n, tokens, title),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _body(context, l10n, tokens)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n,
      TodayStatusTokens tokens, String title) {
    return Row(
      children: [
        StatusIconWell(status: widget.status, icon: _icon()),
        const SizedBox(width: TodayStatusTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: StatusIconWell.foregroundFor(widget.status, tokens),
                ),
              ),
              Text(
                l10n.todayStatusTileCount(widget.items.length),
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        if (widget.selectionMode)
          _iconButton(
            key: PlanSectionCard.exitSelectionKey,
            icon: Icons.close,
            label: MaterialLocalizations.of(context).closeButtonLabel,
            color: tokens.textSecondary,
            onPressed: widget.onExitSelectionMode,
          )
        else ...[
          if (widget.onEnterSelectionMode != null)
            _iconButton(
              key: PlanSectionCard.enterSelectionKey,
              icon: Icons.checklist,
              label: l10n.todayStatusSelectTiles,
              color: tokens.textSecondary,
              onPressed: widget.onEnterSelectionMode,
            ),
          _iconButton(
            key: PlanSectionCard.chevronKey,
            icon: _expanded ? Icons.expand_less : Icons.expand_more,
            label: _expanded
                ? l10n.todayStatusCollapseSection(title)
                : l10n.todayStatusExpandSection(title),
            color: tokens.textSecondary,
            onPressed: _toggleExpanded,
          ),
        ],
      ],
    );
  }

  Widget _iconButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: key,
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(TodayStatusTokens.minTouchTarget / 2),
        child: SizedBox(
          width: TodayStatusTokens.minTouchTarget,
          height: TodayStatusTokens.minTouchTarget,
          child: Icon(icon, size: TodayStatusTokens.iconSm, color: color),
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, AppLocalizations l10n, TodayStatusTokens tokens) {
    final String? helper = _helperText(l10n);
    final List<_PlanEntry> entries = _groupedEntries();
    final bool truncated =
        !_showAll && entries.length > PlanSectionCard.collapsedPreviewCount;
    final List<_PlanEntry> visible = truncated
        ? entries.take(PlanSectionCard.collapsedPreviewCount).toList()
        : entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: TodayStatusTokens.space2),
            child: Text(
              helper,
              style: TextStyle(fontSize: 13, color: tokens.textSecondary),
            ),
          ),
        const SizedBox(height: TodayStatusTokens.space1),
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) Divider(height: 1, color: tokens.border),
          _entry(visible[i], l10n, tokens),
        ],
        if (truncated)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(l10n.todayStatusShowAll),
            ),
          ),
        if (widget.selectionMode && widget.selectionFooter != null) ...[
          const SizedBox(height: TodayStatusTokens.space4),
          widget.selectionFooter!,
        ],
      ],
    );
  }

  /// Collapses consecutive sub-events of the same parent calendar event into a
  /// single entry, preserving the incoming order of first appearance.
  List<_PlanEntry> _groupedEntries() {
    final Map<String, List<PlanItemViewModel>> byParent = {};
    final List<_PlanEntry> entries = [];

    for (final PlanItemViewModel item in widget.items) {
      final String? parentId = item.parentId;
      if (parentId == null) {
        entries.add(_PlanEntry.single(item));
        continue;
      }
      final List<PlanItemViewModel>? existing = byParent[parentId];
      if (existing == null) {
        final List<PlanItemViewModel> siblings = [item];
        byParent[parentId] = siblings;
        entries.add(_PlanEntry.group(parentId, siblings));
      } else {
        existing.add(item);
      }
    }

    // A parent with only one sub-event isn't a group.
    return [
      for (final _PlanEntry entry in entries)
        entry.isGroup && entry.items.length == 1
            ? _PlanEntry.single(entry.items.first)
            : entry
    ];
  }

  Widget _entry(
      _PlanEntry entry, AppLocalizations l10n, TodayStatusTokens tokens) {
    if (!entry.isGroup) {
      return _row(entry.items.first, tokens);
    }

    final PlanItemViewModel lead = entry.items.first;
    final String title = lead.title ?? l10n.todayStatusUntitledTile;
    final bool expanded = _expandedGroups.contains(entry.parentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _row(lead, tokens, groupCount: entry.items.length)),
            _iconButton(
              key: PlanSectionCard.groupToggleKey(entry.parentId!),
              icon: expanded ? Icons.expand_less : Icons.expand_more,
              label: expanded
                  ? l10n.todayStatusCollapseGroup(title)
                  : l10n.todayStatusExpandGroup(title),
              color: tokens.textSecondary,
              onPressed: () => _toggleGroup(entry.parentId!),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding:
                      const EdgeInsets.only(left: TodayStatusTokens.space5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final PlanItemViewModel child in entry.items) ...[
                        Divider(height: 1, color: tokens.border),
                        _row(child, tokens),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _row(PlanItemViewModel item, TodayStatusTokens tokens,
      {int? groupCount}) {
    if (!widget.selectionMode) {
      return PlanTaskRow(
        item: item,
        groupCount: groupCount,
        onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(item),
      );
    }
    return PlanTaskRow(
      item: item,
      groupCount: groupCount,
      onTap: () => widget.onToggleSelected?.call(item.id),
      leading: SizedBox(
        width: TodayStatusTokens.iconWell,
        height: TodayStatusTokens.iconWell,
        child: Checkbox(
          value: widget.selectedIds.contains(item.id),
          onChanged: (_) => widget.onToggleSelected?.call(item.id),
          activeColor: tokens.success,
        ),
      ),
    );
  }

  void _toggleGroup(String parentId) {
    setState(() {
      _expandedGroups.contains(parentId)
          ? _expandedGroups.remove(parentId)
          : _expandedGroups.add(parentId);
    });
  }

  void _toggleExpanded() {
    setState(() => _expandedOverride = !_expanded);
    Utility.debugPrint(
        '[TodayStatus] section=${widget.status.name} expanded=$_expanded '
        'items=${widget.items.length}');
  }

  String _title(AppLocalizations l10n) {
    switch (widget.status) {
      case PlanItemStatus.placed:
        return l10n.todayStatusPlacedTitle;
      case PlanItemStatus.needsAttention:
        return l10n.todayStatusAttentionTitle;
      case PlanItemStatus.late:
        return l10n.todayStatusLateTitle;
    }
  }

  String? _helperText(AppLocalizations l10n) {
    switch (widget.status) {
      case PlanItemStatus.placed:
        return null;
      case PlanItemStatus.needsAttention:
        return l10n.todayStatusAttentionHelper;
      case PlanItemStatus.late:
        return l10n.todayStatusLateHelper;
    }
  }

  IconData _icon() {
    switch (widget.status) {
      case PlanItemStatus.placed:
        return Icons.check_circle;
      case PlanItemStatus.needsAttention:
        return Icons.error_outline;
      case PlanItemStatus.late:
        return Icons.warning_amber;
    }
  }
}

/// Either a standalone tile or a collapsed set of sub-events that share a
/// parent calendar event.
class _PlanEntry {
  _PlanEntry.single(PlanItemViewModel item)
      : parentId = null,
        items = [item],
        isGroup = false;

  _PlanEntry.group(this.parentId, this.items) : isGroup = true;

  final String? parentId;
  final List<PlanItemViewModel> items;
  final bool isGroup;
}
