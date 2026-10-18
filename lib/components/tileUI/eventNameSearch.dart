import 'package:tiler_app/services/calendarSearchController.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/tileUI/searchResultDestination.dart';
import 'package:tiler_app/components/tileUI/searchResultsPane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/deletion_confirmation_widget.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';

import '../../bloc/calendarTiles/calendar_tile_bloc.dart';
import '../../constants.dart' as Constants;

class EventNameSearchWidget extends SearchWidget {
  /// Optional UTC epoch-millisecond overlap window, forwarded to every batch.
  final int? start;
  final int? end;
  final int pageSize;

  EventNameSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      context,
      renderBelowTextfield = true,
      this.start,
      this.end,
      this.pageSize = 10,
      Key? key})
      : assert(pageSize >= 1 && pageSize <= 150),
        assert((start == null) == (end == null)),
        assert(start == null || start < end!),
        super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            key: key);
  @override
  EventNameSearchState createState() => EventNameSearchState();
}

class EventNameSearchState extends SearchWidgetState {
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late TileNameApi tileNameApi;
  late CalendarEventApi calendarEventApi;
  late SubCalendarEventApi subCalendarEventApi;
  late IntegrationApi integrationApi;
  TextEditingController textController = TextEditingController();

  // Deletion confirmation state: tracks which item ID is showing deletion confirmation
  String? _tileIdPendingDeletion;

  late CalendarSearchController _search;
  EventNameSearchWidget get _searchWidget => widget as EventNameSearchWidget;
  List<CalendarSearchItem> get _searchItems => _search.items;
  List<CalendarSearchSourceStatus> get _sourceStatuses =>
      _search.sourceStatuses;
  CalendarSearchUnavailableError? get _searchUnavailable => _search.unavailable;
  String get _query => _search.query;
  TileSource? _selectedProvider;
  // Third-party providers the user has connected; drives which chips render.
  Set<TileSource> _connectedProviders = {};
  // Providers the server reported as `failed` on the last search; hidden
  // from the chip strip until a later search reports them healthy.
  Set<TileSource> _failedProviders = {};

  void _refreshResultView() {
    if (mounted) setState(() {});
  }

  void _dismissResults() {
    _search.cancelPending();
    setState(() => showResponseContainer = false);
  }

  Widget _resultsPane() => SearchResultsPane(
        header: _buildResultsHeader(),
        results: _buildResultWidgets(),
        onDismiss: _dismissResults,
        decoration: widget.resultBoxDecoration,
      );

  CalendarSearchController _createSearchController() =>
      CalendarSearchController(
        loader: tileNameApi.searchCalendarEvents,
        batchSize: _searchWidget.pageSize,
        minimumQueryLength: Constants.autoCompleteMinCharLength + 1,
      )..addListener(_onSearchChanged);

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      showResponseContainer = _query.trim().isNotEmpty;
      if (_search.isLoading) _tileIdPendingDeletion = null;
      if (_search.hasSearched && !_search.hasError) {
        _failedProviders = {
          for (final status in _sourceStatuses)
            if (status.isFailed)
              switch (parseCalendarSearchSource(status.source)) {
                CalendarSearchSource.google => TileSource.google,
                CalendarSearchSource.microsoft => TileSource.outlook,
                _ => TileSource.tiler,
              }
        }..remove(TileSource.tiler);
      }
    });
  }

  void _onSearchTextChanged() {
    final name = textController.text;
    if (name == _query) return;
    if (name.trim().length > Constants.autoCompleteMinCharLength) {
      AnalysticsSignal.send('NAME_SEARCH_REQUEST_RECEIVED');
    }
    _search.scheduleSearch(name,
        sources: _selectedProvider == null
            ? null
            : [_wireSource(_selectedProvider!)],
        start: _searchWidget.start,
        end: _searchWidget.end);
  }

  @override
  void initState() {
    super.initState();
    // The base SearchWidget registers this listener inside its build; since we
    // lay out the text field ourselves we register it here instead.
    textController.addListener(_onSearchTextChanged);
    calendarEventApi = new CalendarEventApi(
        getContextCallBack: () => mounted ? context : null);
    subCalendarEventApi = new SubCalendarEventApi(
        getContextCallBack: () => mounted ? context : null);
    tileNameApi =
        new TileNameApi(getContextCallBack: () => mounted ? context : null);
    integrationApi =
        new IntegrationApi(getContextCallBack: () => mounted ? context : null);
    _search = _createSearchController();
    _loadConnectedProviders();
  }

  @override
  void didUpdateWidget(covariant EventNameSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = _query;
    if (oldWidget.pageSize != _searchWidget.pageSize) {
      _search.removeListener(_onSearchChanged);
      _search.dispose();
      _search = _createSearchController();
      _runSearch(query);
    } else if (oldWidget.start != _searchWidget.start ||
        oldWidget.end != _searchWidget.end) {
      _runSearch(query);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  Tuple4<List<SubCalendarEvent>, List<Timeline>, Timeline, ScheduleStatus>
      getPriorStateVariables() {
    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = new ScheduleStatus();
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    return Tuple4(renderedSubEvents, timeLines, lookupTimeline, scheduleStatus);
  }

  void _submitSearchChange(ScheduleChangeKind kind, String tileId,
      Future<dynamic> Function() request,
      {String? eventName}) {
    if (!scheduleChangesAllowed(context)) return;
    final schedule = context.read<ScheduleBloc>();
    final summary = context.read<ScheduleSummaryBloc>();
    final prior = ScheduleState.generatePriorScheduleState(schedule.state);
    // Reserve before closing search, and retain providers beyond this widget.
    final pending = schedule.runScheduleChange(() async {
      final result = await request();
      if (!summary.isClosed) summary.add(GetScheduleDaySummaryEvent());
      return result;
    }, kind: kind, eventName: eventName, affectedTileIds: [tileId]);
    schedule.add(EvaluateSchedule(
        renderedSubEvents: prior.subEvents,
        renderedTimelines: prior.timelines,
        renderedScheduleTimeline: prior.previousLookupTimeline,
        scheduleStatus: prior.scheduleStatus,
        isAlreadyLoaded: true,
        callBack: pending));
    _search.cancelPending();
    Navigator.pop(context);
  }

  Function? createSetAsNowCallBack(String tileId, {String? eventName}) => () {
        _submitSearchChange(ScheduleChangeKind.startNow, tileId, () {
          AnalysticsSignal.send('NAME_SEARCH_SETASNOW_REQUEST');
          return calendarEventApi.setAsNow(tileId);
        }, eventName: eventName);
      };

  Function? createDeletionCallBack(CalendarSearchItem item) => () {
        setState(() {
          _tileIdPendingDeletion = item.id;
        });
        _refreshResultView();
      };

  void _performDeletion(CalendarSearchItem item) {
    final source = _wireSource(_tileSourceOf(item));
    _submitSearchChange(ScheduleChangeKind.delete, item.id, () {
      AnalysticsSignal.send('NAME_SEARCH_DELETION_REQUEST');
      return item.isFromProvider
          ? subCalendarEventApi.delete(
              item.id, item.thirdPartyEventId, item.thirdPartyUserId, source)
          : calendarEventApi.delete(item.id, item.thirdPartyEventId ?? '');
    }, eventName: item.name);
  }

  Function? createCompletionCallBack(String tileId, {String? eventName}) => () {
        _submitSearchChange(ScheduleChangeKind.complete, tileId, () {
          AnalysticsSignal.send('NAME_SEARCH_COMPLETE_REQUEST');
          return calendarEventApi.complete(tileId);
        }, eventName: eventName);
      };

  // ---------------------------------------------------------------------------
  // Provider filter
  // ---------------------------------------------------------------------------

  /// Providers offered in the filter chip strip. `null` means "All".
  /// Chips offered in the filter strip. `null` means "All". Third-party
  /// providers only appear when connected and not currently failing.
  List<TileSource?> get _providerFilters => [
        null,
        TileSource.tiler,
        for (final source in const [TileSource.google, TileSource.outlook])
          if (_connectedProviders.contains(source) &&
              !_failedProviders.contains(source))
            source,
      ];

  Future<void> _loadConnectedProviders() async {
    try {
      final integrations = await integrationApi.getIntegrations();
      final Set<TileSource> connected = {};
      for (final integration in integrations ?? const []) {
        final String provider = (integration.calendarType ?? '').toLowerCase();
        if (provider == 'google') connected.add(TileSource.google);
        if (provider == 'microsoft' || provider == 'outlook') {
          connected.add(TileSource.outlook);
        }
      }
      if (!mounted) return;
      setState(() => _connectedProviders = connected);
      _ensureSelectedProviderAvailable();
    } catch (error) {
      Utility.debugPrint('Failed to load integrations for search: $error');
    }
  }

  /// Falls back to "All" if the selected chip is no longer offered.
  void _ensureSelectedProviderAvailable() {
    if (_selectedProvider != null &&
        !_providerFilters.contains(_selectedProvider)) {
      setState(() => _selectedProvider = null);
      if (_query.isNotEmpty) _runSearch(_query);
    }
  }

  String _providerLabel(TileSource? source) {
    final localization = AppLocalizations.of(context)!;
    switch (source) {
      case TileSource.tiler:
        return localization.searchFilterTiler;
      case TileSource.google:
        return localization.searchFilterGoogle;
      case TileSource.outlook:
        return localization.searchFilterOutlook;
      case null:
        return localization.searchFilterAll;
    }
  }

  /// Wire vocabulary for the `sources` query filter (`microsoft`, not `outlook`).
  static String _wireSource(TileSource source) {
    switch (source) {
      case TileSource.google:
        return 'google';
      case TileSource.outlook:
        return 'microsoft';
      case TileSource.tiler:
        return 'tiler';
    }
  }

  static TileSource _tileSourceOf(CalendarSearchItem item) =>
      tileSourceOfSearchItem(item);

  String _sourceStatusLabel(String wireSource) {
    switch (parseCalendarSearchSource(wireSource)) {
      case CalendarSearchSource.google:
        return _providerLabel(TileSource.google);
      case CalendarSearchSource.microsoft:
        return _providerLabel(TileSource.outlook);
      case CalendarSearchSource.tiler:
        return _providerLabel(TileSource.tiler);
      case CalendarSearchSource.unknown:
        return wireSource;
    }
  }

  String? _providerIconPath(TileSource? source) {
    switch (source) {
      case TileSource.google:
        return 'assets/icons/settings/google.svg';
      case TileSource.outlook:
        return 'assets/icons/settings/microsoft.svg';
      default:
        return null;
    }
  }

  Widget _buildProviderChip(TileSource? source) {
    final bool isSelected = _selectedProvider == source;
    final String? iconPath = _providerIconPath(source);
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (_selectedProvider == source) return;
          setState(() => _selectedProvider = source);
          // The Search endpoint filters server-side via `sources`, so a chip
          // change re-queries rather than filtering the cached list.
          _runSearch(_query);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath != null) ...[
                SvgPicture.asset(iconPath, width: 14, height: 14),
                SizedBox(width: 6),
              ],
              Text(
                _providerLabel(source),
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: TileTextStyles.rubikFontName,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    final localization = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 12),
          child: Text(
            localization.searchResultsForQuery(
                _search.totalCount ?? _searchItems.length, _query),
            style: TextStyle(
              fontSize: 15,
              fontFamily: TileTextStyles.rubikFontName,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _providerFilters.map(_buildProviderChip).toList(),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  /// Warning strip shown when some connected calendars failed to search
  /// (envelope source status `partial` / `failed`).
  Widget? _buildPartialFailureBanner() {
    final degraded =
        _sourceStatuses.where((s) => s.isPartial || s.isFailed).toList();
    if (degraded.isEmpty) return null;
    final localization = AppLocalizations.of(context)!;
    final String labels =
        degraded.map((s) => _sourceStatusLabel(s.source)).join(', ');
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: colorScheme.onTertiaryContainer),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${localization.searchPartialFailureWarning} ($labels)',
              style: TextStyle(
                fontSize: 13,
                fontFamily: TileTextStyles.rubikFontName,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _runSearch(_query),
            child: Text(localization.searchRetry),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result cards
  // ---------------------------------------------------------------------------

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontFamily: TileTextStyles.rubikFontName,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _metaSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text('·',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
    );
  }

  Widget _providerBadge(TileSource source) {
    final String? iconPath = _providerIconPath(source);
    if (iconPath == null) return SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconPath, width: 14, height: 14),
        SizedBox(width: 6),
        Text(
          _providerLabel(source),
          style: TextStyle(
            fontSize: 14,
            fontFamily: TileTextStyles.rubikFontName,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _cardAction({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontFamily: TileTextStyles.rubikFontName,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardActionDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: EdgeInsets.symmetric(horizontal: 12),
      color: colorScheme.outlineVariant,
    );
  }

  /// Opens the edit flow the same way the timeline tile does: third-party
  /// rows are addressed by their provider event id + source + account.
  /// A Tiler row is a CALENDAR EVENT and opens Tile details; a provider
  /// row is a SUB-EVENT and opens Edit Tile (searchResultDestination.dart).
  void _openEditTile(CalendarSearchItem item) {
    final Widget? destination = searchResultEditorFor(item);
    if (destination == null) return;
    _search.cancelPending();
    _refreshResultView();
    AnalysticsSignal.send('NAME_SEARCH_EDIT_OPENED');
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => destination));
  }

  Widget? _buildMoreMenu(CalendarSearchItem item) {
    final caps = item.capabilities;
    if (!caps.canEdit && !caps.canDelete) return null;
    final localization = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          _openEditTile(item);
        } else if (value == 'delete') {
          createDeletionCallBack(item)!();
        }
      },
      itemBuilder: (context) => [
        if (caps.canEdit)
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurface),
              SizedBox(width: 10),
              Text(localization.edit),
            ]),
          ),
        if (caps.canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              SizedBox(width: 10),
              Text(localization.delete,
                  style: TextStyle(color: colorScheme.error)),
            ]),
          ),
      ],
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tileThemeExtension.shadowSearch.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _readOnlyBadge() {
    final localization = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        localization.readOnly,
        style: TextStyle(
          fontSize: 12,
          fontFamily: TileTextStyles.rubikFontName,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget searchItemToWidget(CalendarSearchItem item) {
    // If this item is pending deletion, show deletion confirmation instead
    if (_tileIdPendingDeletion == item.id) {
      return _cardShell(
        child: DeletionConfirmationWidget(
          isRigid: false,
          tileSource: _tileSourceOf(item),
          onCancel: () {
            setState(() {
              _tileIdPendingDeletion = null;
            });
            _refreshResultView();
          },
          onConfirm: () {
            setState(() {
              _tileIdPendingDeletion = null;
            });
            _performDeletion(item);
          },
        ),
      );
    }

    final localization = AppLocalizations.of(context)!;
    final caps = item.capabilities;

    // Meta row: duration · due date · provider
    List<Widget> metaItems = [];
    final TileSource itemSource = _tileSourceOf(item);
    if (item.end > item.start) {
      final Duration duration = Duration(milliseconds: item.end - item.start);
      metaItems.add(_metaItem(
        Icons.access_time_rounded,
        Utility.toHuman(duration, abbreviations: true, context: context),
      ));
    }
    if (item.end > 0) {
      DateTime end = DateTime.fromMillisecondsSinceEpoch(item.end);
      String dueLabel =
          '${Utility.returnMonth(end).substring(0, 3)} ${end.day}';
      metaItems.add(_metaItem(
        Icons.calendar_today_outlined,
        localization.dueOnDate(dueLabel),
      ));
    }
    if (itemSource != TileSource.tiler) {
      metaItems.add(_providerBadge(itemSource));
    }
    List<Widget> metaRow = [];
    for (int i = 0; i < metaItems.length; i++) {
      if (i > 0) metaRow.add(_metaSeparator());
      metaRow.add(metaItems[i]);
    }

    // Action row: Complete | Start now ... more — gated by capabilities
    List<Widget> actions = [];
    if (!item.isReadOnly && caps.canComplete) {
      actions.add(_cardAction(
        icon: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: TileColors.completedGreen.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 16, color: TileColors.completedGreen),
        ),
        label: localization.complete,
        onTap: () => createCompletionCallBack(item.id, eventName: item.name)!(),
      ));
    }
    if (!item.isReadOnly && caps.canSetAsNow) {
      if (actions.isNotEmpty) actions.add(_cardActionDivider());
      actions.add(_cardAction(
        icon: Icon(Icons.play_arrow_outlined,
            size: 24, color: colorScheme.onSurface),
        label: localization.startNow,
        onTap: () => createSetAsNowCallBack(item.id, eventName: item.name)!(),
      ));
    }
    // Third-party rows can't be completed / started, so surface Edit and
    // Delete inline rather than tucking them behind the more menu.
    Widget? moreMenu;
    if (!item.isReadOnly && actions.isEmpty) {
      if (caps.canEdit) {
        actions.add(_cardAction(
          icon:
              Icon(Icons.edit_outlined, size: 22, color: colorScheme.onSurface),
          label: localization.edit,
          onTap: () => _openEditTile(item),
        ));
      }
      if (caps.canDelete) {
        if (actions.isNotEmpty) actions.add(_cardActionDivider());
        actions.add(_cardAction(
          icon: Icon(Icons.delete_outline, size: 22, color: colorScheme.error),
          label: localization.delete,
          onTap: () => createDeletionCallBack(item)!(),
        ));
      }
    } else if (!item.isReadOnly) {
      moreMenu = _buildMoreMenu(item);
    }
    final bool hasActionRow = actions.isNotEmpty || moreMenu != null;

    // The whole card opens the tile (Tile details for a Tiler row, Edit
    // Tile for a provider row) and claims the tap, so the results stay
    // open — the list's outer GestureDetector used to swallow it and hide
    // them (2026-09-19).
    final bool canOpen = searchResultEditorFor(item) != null;
    return _cardShell(
      child: SearchResultTapTarget(
        key: ValueKey('searchResult_${item.identityKey}'),
        onOpen: canOpen ? () => _openEditTile(item) : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 12, hasActionRow ? 8 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: TileTextStyles.rubikFontName,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (item.isReadOnly) ...[
                    SizedBox(width: 8),
                    _readOnlyBadge(),
                  ],
                ],
              ),
              if (metaRow.isNotEmpty) ...[
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: metaRow),
                ),
              ],
              if (item.thirdPartyUserId != null &&
                  item.thirdPartyUserId!.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  localization.searchConnectedAccount(item.thirdPartyUserId!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: TileTextStyles.rubikFontName,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (hasActionRow) ...[
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4, right: 4),
                  child: Divider(height: 1, color: colorScheme.outlineVariant),
                ),
                Row(
                  children: [
                    ...actions,
                    Spacer(),
                    if (moreMenu != null) moreMenu,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result list assembly
  // ---------------------------------------------------------------------------

  Widget _messageBlock(String text, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: colorScheme.onSurfaceVariant),
            SizedBox(height: 8),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// The scrolling part of the results — cards, banners, messages. The
  /// header is pinned above them by [_resultsPane].
  List<Widget> _buildResultWidgets() {
    final localization = AppLocalizations.of(context)!;
    if (!_search.canSearch) {
      return [_messageBlock(localization.atLeastThreeLettersForLookup)];
    }
    if (_search.isLoading) {
      return [
        const Center(child: CircularProgressIndicator()),
        _messageBlock(localization.loading)
      ];
    }
    final List<Widget> results = [];
    if (_search.hasError) {
      final message = _searchUnavailable?.message;
      results.add(_messageBlock(
        message != null && message.trim().isNotEmpty
            ? message
            : localization.searchUnavailableMessage,
        icon: Icons.cloud_off_rounded,
      ));
      results.add(Center(
          child: TextButton(
              onPressed: () => _runSearch(_query),
              child: Text(localization.searchRetry))));
    }
    final banner = _buildPartialFailureBanner();
    if (banner != null) results.add(banner);
    if (_search.showNoMatches) {
      results.add(_messageBlock(_selectedProvider == null
          ? localization.noMatchWasFound
          : localization.noResultsForProvider));
    }
    results.addAll(_searchItems.map(searchItemToWidget));
    if (_search.hasMore) {
      results.add(Center(
          child: TextButton.icon(
        key: const ValueKey('calendarSearchLoadMore'),
        onPressed: _search.isLoadingMore ? null : () => _search.loadMore(),
        icon: _search.isLoadingMore
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.expand_more),
        label: Text(_search.isLoadingMore
            ? localization.loading
            : localization.tileShareActivityMore),
      )));
    }
    return results;
  }

  Future<void> _runSearch(String name) => _search.search(name,
      sources:
          _selectedProvider == null ? null : [_wireSource(_selectedProvider!)],
      start: _searchWidget.start,
      end: _searchWidget.end);

  TextField _buildSearchField() {
    final localization = AppLocalizations.of(context)!;
    return TextField(
      autofocus: true,
      maxLength: 100,
      controller: textController,
      style: TextStyle(
        fontSize: 20,
        fontFamily: TileTextStyles.rubikFontName,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: localization.tileName,
        counterText: '',
        filled: true,
        isDense: true,
        fillColor: colorScheme.surfaceContainerLowest,
        hintStyle: TextStyle(
            color: tileThemeExtension.onSurfaceHint,
            fontSize: 20,
            fontFamily: TileTextStyles.rubikFontName),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Icon(Icons.search, size: 26, color: colorScheme.onSurface),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: textController,
          builder: (context, value, _) {
            if (value.text.isEmpty) return SizedBox.shrink();
            return IconButton(
              icon: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.close, size: 16, color: colorScheme.onSurface),
              ),
              onPressed: () {
                _tileIdPendingDeletion = null;
                textController.clear();
              },
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: colorScheme.onInverseSurface, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext eventNameSearchContext) {
    return BlocBuilder<CalendarTileBloc, CalendarTileState>(
      builder: (context, calendarTileState) {
        return BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            if (state is ScheduleEvaluationState) {
              if (state.message != null) {
                Fluttertoast.showToast(
                    msg: state.message!,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.SNACKBAR,
                    timeInSecForIosWeb: 1,
                    backgroundColor: colorScheme.inverseSurface,
                    textColor: colorScheme.onInverseSurface,
                    fontSize: 16.0);
              }
            }
          },
          child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, scheduleState) {
            this.widget.textField = _buildSearchField();
            this.widget.resultBoxDecoration = BoxDecoration();

            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Container(
                decoration: TileDecorations.defaultBackground,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, 12, 16, 0),
                        child: Row(
                          children: [
                            BackButton(
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(child: this.widget.textField!),
                          ],
                        ),
                      ),
                      Expanded(
                        child: showResponseContainer
                            ? Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: _resultsPane())
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    textController.removeListener(_onSearchTextChanged);
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    tileNameApi.dispose();
    integrationApi.dispose();
    textController.dispose();
    super.dispose();
  }
}
