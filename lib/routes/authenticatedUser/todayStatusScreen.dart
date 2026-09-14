import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/todayStatus/planPreviewCta.dart';
import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/statusSummaryStrip.dart';
import 'package:tiler_app/components/todayStatus/todayAppBar.dart';
import 'package:tiler_app/components/todayStatus/trackStatusCard.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/todayStatus/dayPlanViewModel.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// Today Status screen — the rebuilt day summary
/// (docs/today-status-screen-engineering-ui-spec.md).
///
/// Owns page composition, scrolling, the sticky CTA and state routing; all
/// display decisions come from [DayPlanViewModel] rather than being re-derived
/// here (spec §15.1).
class TodayStatusScreen extends StatefulWidget {
  const TodayStatusScreen({
    super.key,
    required this.timeline,
    this.scheduleApi,
  });

  static const Key loadingKey = Key('todayStatus.screen.loading');
  static const Key errorKey = Key('todayStatus.screen.error');
  static const Key retryKey = Key('todayStatus.screen.retry');

  final Timeline timeline;

  /// Injectable for tests; defaults to a context-bound [ScheduleApi].
  final ScheduleApi? scheduleApi;

  @override
  State<TodayStatusScreen> createState() => _TodayStatusScreenState();
}

class _TodayStatusScreenState extends State<TodayStatusScreen> {
  /// The preview pipeline is not wired yet, and §16.2 requires the CTA to
  /// appear only when a preview can actually be generated. Flip this once the
  /// endpoint exists.
  static const bool _canPreviewPlan = false;

  late final ScheduleApi _scheduleApi;
  TimelineSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;

  bool _selectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _scheduleApi =
        widget.scheduleApi ?? ScheduleApi(getContextCallBack: () => context);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final TimelineSummary? summary =
          await _scheduleApi.getTimelineSummary(widget.timeline);
      summary?.timeline ??= widget.timeline;
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      Utility.debugPrint('[TodayStatus] summary fetch failed: $error');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final DayPlanViewModel model = DayPlanViewModel.fromTimelineSummary(
      timeline: widget.timeline,
      summary: _summary,
      canPreviewPlan: _canPreviewPlan,
    );

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: TodayAppBar(
        date: model.date,
        onClose: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(child: _body(model, tokens)),
      bottomNavigationBar: model.showPreviewCta ? _stickyCta(tokens) : null,
    );
  }

  Widget _body(DayPlanViewModel model, TodayStatusTokens tokens) {
    if (_isLoading) {
      return KeyedSubtree(
          key: TodayStatusScreen.loadingKey, child: PendingWidget());
    }
    if (_hasError) {
      return _errorState(tokens);
    }

    final double pagePadding =
        TodayStatusTokens.pagePaddingFor(MediaQuery.of(context).size.width);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            pagePadding, TodayStatusTokens.space3, pagePadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _content(model, tokens),
        ),
      ),
    );
  }

  List<Widget> _content(DayPlanViewModel model, TodayStatusTokens tokens) {
    if (model.displayState == TodayStatusDisplayState.clearDay) {
      return [_clearDay(tokens)];
    }

    final Widget attentionCard = PlanSectionCard(
      status: PlanItemStatus.needsAttention,
      items: model.attentionItems,
      selectionMode: _selectionMode,
      selectedIds: _selectedIds,
      onItemTap: _openTile,
      onToggleSelected: _toggleSelected,
      onEnterSelectionMode: _enterSelectionMode,
      onExitSelectionMode: _exitSelectionMode,
      selectionFooter: _selectionFooter(model, tokens),
    );

    return [
      StatusSummaryStrip(
        placedCount: model.placedCount,
        attentionCount: model.attentionCount,
        lateCount: model.lateCount,
      ),
      if (model.showLateCard)
        PlanSectionCard(
          status: PlanItemStatus.late,
          items: model.lateItems,
          onItemTap: _openTile,
        ),
      if (model.attentionLeadsContent) attentionCard,
      if (model.showPlacedCard)
        PlanSectionCard(
          status: PlanItemStatus.placed,
          items: model.placedItems,
          onItemTap: _openTile,
          initiallyExpanded: model.hasException ? false : null,
        ),
      if (model.showAttentionCard && !model.attentionLeadsContent)
        attentionCard,
      if (model.showTrackStatusCard)
        TrackStatusCard(copy: model.trackStatusCopy),
      const SizedBox(height: TodayStatusTokens.space6),
    ];
  }

  Widget? _selectionFooter(DayPlanViewModel model, TodayStatusTokens tokens) {
    if (!_selectionMode || _selectedIds.isEmpty) {
      return null;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            l10n.numberOfTilesSelected(_selectedIds.length.toString()),
            style: TextStyle(
                fontWeight: FontWeight.w600, color: tokens.textPrimary),
          ),
        ),
        OutlinedButton(
          onPressed: () => _completeSelected(model),
          child: Text(l10n.completeTiles),
        ),
      ],
    );
  }

  Widget _clearDay(TodayStatusTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.todayStatusClearDay,
          style: TextStyle(fontSize: 18, color: tokens.textSecondary),
        ),
      ),
    );
  }

  Widget _errorState(TodayStatusTokens tokens) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(
      key: TodayStatusScreen.errorKey,
      child: Padding(
        padding: const EdgeInsets.all(TodayStatusTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: tokens.textSecondary, size: 32),
            const SizedBox(height: TodayStatusTokens.space3),
            Text(
              l10n.errorOccurred,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: TodayStatusTokens.space3),
            OutlinedButton(
              key: TodayStatusScreen.retryKey,
              onPressed: _load,
              child: Text(l10n.previewRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stickyCta(TodayStatusTokens tokens) {
    final double pagePadding =
        TodayStatusTokens.pagePaddingFor(MediaQuery.of(context).size.width);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, TodayStatusTokens.space2,
            pagePadding, TodayStatusTokens.space4),
        child: PlanPreviewCta(onPressed: () {}),
      ),
    );
  }

  void _enterSelectionMode() => setState(() => _selectionMode = true);

  void _exitSelectionMode() => setState(() {
        _selectionMode = false;
        _selectedIds = {};
      });

  void _toggleSelected(String id) {
    setState(() {
      final Set<String> next = {..._selectedIds};
      next.contains(id) ? next.remove(id) : next.add(id);
      _selectedIds = next;
    });
  }

  void _openTile(PlanItemViewModel item) {
    final source = item.source;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTile(
          tileId: (source.isFromTiler ? source.id : source.thirdpartyId) ?? "",
          tileSource: source.thirdpartyType,
          thirdPartyUserId: source.thirdPartyUserId,
        ),
      ),
    );
  }

  /// Ported from the previous summary page: the API takes parallel
  /// comma-joined id / type / user-id strings.
  Future<void> _completeSelected(DayPlanViewModel model) async {
    final List<PlanItemViewModel> selected = model.attentionItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    if (selected.isEmpty) return;

    final String ids = selected.map((e) => e.source.id ?? '').join(',');
    final String types = selected
        .map((e) => e.source.thirdpartyType?.name.toLowerCase() ?? '')
        .join(',');
    final String userIds = selected
        .map((e) => e.source.thirdPartyUserId.isEmpty
            ? 'tiler-account'
            : e.source.thirdPartyUserId)
        .join(',');

    Utility.debugPrint(
        '[TodayStatus] completing ${selected.length} tile(s): $ids');

    final bool success = await BlocProvider.of<ScheduleSummaryBloc>(context)
        .completeTasks(ids, types, userIds);

    if (!mounted) return;
    if (success) {
      _exitSelectionMode();
      await _load();
    }
  }
}
