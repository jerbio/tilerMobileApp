import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'shareWorkWidgets.dart';
import 'shareDisplayOptions.dart';

/// The common surface for tilettes, including read-only share previews.
class TaskCard extends StatelessWidget {
  final Widget child;
  final TiletteDensity? density;
  const TaskCard({super.key, required this.child, this.density});

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final mode = density ?? TileShareDisplayScope.densityOf(context);
    final comfortable = mode == TiletteDensity.comfortable;
    final list = mode == TiletteDensity.list;
    return Container(
      margin: EdgeInsets.only(
          bottom: comfortable
              ? 12
              : list
                  ? 0
                  : 8),
      padding: EdgeInsets.all(comfortable
          ? 16
          : list
              ? 8
              : 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            list ? null : BorderRadius.circular(comfortable ? 20 : 14),
        border: list
            ? Border(bottom: BorderSide(color: tokens.border))
            : Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

/// One layout for Class, Project and personal tilettes. Roles supply the
/// status and actions, while the title, metadata and footer stay in place.
class TiletteWorkCard extends StatefulWidget {
  final String title;
  final int? durationMs;
  final int? dueMs;
  final Widget? menu;
  final Widget? status;
  final Widget? details;
  final Widget? preview;
  final Widget? compactStatus;
  final Widget? listStatus;
  final Widget? listAction;
  final Widget? progress;
  final List<Widget> actions;
  final VoidCallback? onNotes;
  final VoidCallback? onComments;
  final VoidCallback? onOpen;
  final Key? notesKey;
  final Key? commentsKey;

  const TiletteWorkCard({
    super.key,
    required this.title,
    this.durationMs,
    this.dueMs,
    this.menu,
    this.status,
    this.details,
    this.preview,
    this.compactStatus,
    this.listStatus,
    this.listAction,
    this.progress,
    this.actions = const [],
    this.onNotes,
    this.onComments,
    this.onOpen,
    this.notesKey,
    this.commentsKey,
  });

  @override
  State<TiletteWorkCard> createState() => _TiletteWorkCardState();
}

class _TiletteWorkCardState extends State<TiletteWorkCard> {
  bool _expanded = false;
  TiletteDensity? _lastDensity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final density = TileShareDisplayScope.densityOf(context);
    if (_lastDensity != density) {
      _lastDensity = density;
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final density = TileShareDisplayScope.densityOf(context);
    if (density == TiletteDensity.list && !_expanded) {
      final l = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      return TaskCard(
        density: TiletteDensity.list,
        child: Semantics(
          button: true,
          expanded: widget.onOpen == null ? false : null,
          hint:
              widget.onOpen == null ? l.shareExpandTilette : l.shareViewTilette,
          child: InkWell(
            key: const Key('tilette_expand'),
            onTap: widget.onOpen ?? () => setState(() => _expanded = true),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: LayoutBuilder(
                  builder: (_, constraints) => Row(children: [
                        Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  widget.title.trim().isEmpty
                                      ? l.clusterTitleFallback
                                      : widget.title.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              DefaultTextStyle(
                                  style: theme.textTheme.bodySmall!.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  child: ShareWorkMeta(
                                      durationMs: widget.durationMs,
                                      dueMs: widget.dueMs)),
                            ])),
                        if (widget.listStatus != null ||
                            widget.compactStatus != null) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * .36),
                              child:
                                  widget.listStatus ?? widget.compactStatus!),
                        ],
                        if (widget.listAction != null) widget.listAction!,
                        if (widget.menu != null)
                          widget.menu!
                        else ...[
                          const SizedBox(width: 4),
                          Icon(
                              widget.onOpen == null
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                              size: 20),
                        ],
                      ])),
            ),
          ),
        ),
      );
    }
    return _card(context, density);
  }

  Widget _card(BuildContext context, TiletteDensity density) {
    final comfortable =
        density == TiletteDensity.comfortable || density == TiletteDensity.list;
    final title = widget.title, menu = widget.menu, status = widget.status;
    final durationMs = widget.durationMs, dueMs = widget.dueMs;
    final details = widget.details,
        progress = widget.progress,
        actions = widget.actions;
    final onNotes = widget.onNotes, onComments = widget.onComments;
    final notesKey = widget.notesKey, commentsKey = widget.commentsKey;
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall!
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    return TaskCard(
      density:
          comfortable ? TiletteDensity.comfortable : TiletteDensity.compact,
      child: InkWell(
          onTap: widget.onOpen,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ConstrainedBox(
                constraints: BoxConstraints(minHeight: comfortable ? 48 : 0),
                child: Row(
                    key: const Key('tilette_header'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                title.trim().isEmpty
                                    ? l.clusterTitleFallback
                                    : title.trim(),
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            if ((durationMs ?? 0) > 0 ||
                                dueMs != null ||
                                !comfortable &&
                                    widget.compactStatus != null) ...[
                              SizedBox(height: comfortable ? 6 : 4),
                              DefaultTextStyle(
                                  key: const Key('tilette_meta'),
                                  style: quiet,
                                  child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        ShareWorkMeta(
                                            durationMs: durationMs,
                                            dueMs: dueMs),
                                        if (!comfortable &&
                                            widget.compactStatus != null)
                                          KeyedSubtree(
                                              key: const Key('tilette_status'),
                                              child: widget.compactStatus!),
                                      ])),
                            ],
                          ])),
                      if (menu != null) menu,
                      if (density == TiletteDensity.list)
                        IconButton(
                            key: const Key('tilette_collapse'),
                            tooltip: l.shareCollapseTilette,
                            onPressed: () => setState(() => _expanded = false),
                            icon: const Icon(Icons.expand_less)),
                    ])),
            if (status != null &&
                (comfortable || widget.compactStatus == null)) ...[
              SizedBox(height: comfortable ? 12 : 6),
              KeyedSubtree(key: const Key('tilette_status'), child: status),
            ],
            if (details != null) ...[
              SizedBox(height: comfortable ? 8 : 4),
              KeyedSubtree(key: const Key('tilette_details'), child: details),
            ],
            if (comfortable && widget.preview != null) ...[
              const SizedBox(height: 8),
              widget.preview!,
            ],
            if (progress != null) ...[
              SizedBox(height: comfortable ? 12 : 6),
              KeyedSubtree(key: const Key('tilette_progress'), child: progress),
            ],
            if (actions.isNotEmpty && comfortable) ...[
              const SizedBox(height: 12),
              Wrap(
                  key: const Key('tilette_actions'),
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions),
            ],
            if (!comfortable &&
                (actions.isNotEmpty ||
                    onNotes != null ||
                    onComments != null)) ...[
              const SizedBox(height: 4),
              SingleChildScrollView(
                  key: const Key('tilette_footer'),
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    if (actions.isNotEmpty)
                      Row(
                          key: const Key('tilette_actions'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              actions[i],
                            ],
                          ]),
                    if (onNotes != null)
                      IconButton(
                          key: notesKey,
                          tooltip: l.notesTitle,
                          onPressed: onNotes,
                          icon:
                              const Icon(Icons.description_outlined, size: 20)),
                    if (onComments != null)
                      IconButton(
                          key: commentsKey,
                          tooltip: l.commentsTitle,
                          onPressed: onComments,
                          icon:
                              const Icon(Icons.chat_bubble_outline, size: 20)),
                  ])),
            ],
            if (comfortable && (onNotes != null || onComments != null)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              SingleChildScrollView(
                  key: const Key('tilette_footer'),
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    if (onNotes != null)
                      Tooltip(
                          message: l.notesTitle,
                          child: TextButton.icon(
                              key: notesKey,
                              onPressed: onNotes,
                              icon: const Icon(Icons.description_outlined,
                                  size: 18),
                              label: Text(l.notesTitle))),
                    if (onComments != null)
                      Padding(
                          padding:
                              EdgeInsets.only(left: onNotes == null ? 0 : 8),
                          child: Tooltip(
                              message: l.commentsTitle,
                              child: TextButton.icon(
                                  key: commentsKey,
                                  onPressed: onComments,
                                  icon: const Icon(Icons.chat_bubble_outline,
                                      size: 18),
                                  label: Text(l.commentsTitle)))),
                  ])),
            ],
          ])),
    );
  }
}
