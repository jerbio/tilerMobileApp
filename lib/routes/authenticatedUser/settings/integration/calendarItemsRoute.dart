import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

class CalendarItemsRoute extends StatefulWidget {
  static final String routeName = '/CalendarItems';
  final CalendarIntegration integration;

  const CalendarItemsRoute({
    Key? key,
    required this.integration,
  }) : super(key: key);

  @override
  _CalendarItemsRouteState createState() => _CalendarItemsRouteState();
}

class _CalendarItemsRouteState extends State<CalendarItemsRoute> {
  late List<CalendarItem> localCalendarItems;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the calendar items to work with locally
    localCalendarItems = widget.integration.calendarItems
            ?.map((item) => CalendarItem(
                  id: item.id,
                  name: item.name,
                  description: item.description,
                  isSelected: item.isSelected,
                  isEnabled: item.isEnabled,
                  authenticationId: item.authenticationId,
                  userIdentifier: item.userIdentifier,
                ))
            .toList() ??
        [];
  }

  void updateCalendarItemLocally(String calendarItemId, bool isSelected) {
    setState(() {
      final itemIndex = localCalendarItems.indexWhere(
        (item) => item.id == calendarItemId,
      );
      if (itemIndex != -1) {
        localCalendarItems[itemIndex].isSelected = isSelected;
      }
    });
  }

  Widget renderEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noCalendarItemsFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.calendarItemsWillAppearHere,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget renderCalendarItems(BuildContext context) {
    if (localCalendarItems.isEmpty) {
      return renderEmpty(context);
    }

    // Calculate statistics
    int selectedCount =
        localCalendarItems.where((item) => item.isSelected == true).length;

    return Column(
      children: [
        // Summary Card
        Container(
          margin: EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TileStyles.greenApproval.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TileStyles.greenApproval.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TileStyles.greenApproval,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check,
                  color: TileStyles.primaryContrastColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.calendarsActive(
                          selectedCount, localCalendarItems.length),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: TileStyles.greenApproval,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.toggleCalendarsToSync,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Calendar Items List
        Expanded(
          child: ListView.separated(
            itemCount: localCalendarItems.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final calendarItem = localCalendarItems[index];
              return _CalendarItemTile(
                calendarItem: calendarItem,
                integration: widget.integration,
                onToggle: updateCalendarItemLocally,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IntegrationsBloc, IntegrationsState>(
      listener: (context, state) {
        if (state is IntegrationsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: CancelAndProceedTemplateWidget(
        routeName: CalendarItemsRoute.routeName,
        appBar: TileStyles.CancelAndProceedAppBar(
            AppLocalizations.of(context)!.integratedCalendars),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: renderCalendarItems(context),
        ),
      ),
    );
  }
}

class _CalendarItemTile extends StatefulWidget {
  final CalendarItem calendarItem;
  final CalendarIntegration integration;
  final Function(String, bool) onToggle;

  const _CalendarItemTile({
    required this.calendarItem,
    required this.integration,
    required this.onToggle,
  });

  @override
  _CalendarItemTileState createState() => _CalendarItemTileState();
}

class _CalendarItemTileState extends State<_CalendarItemTile> {
  late bool isSelected;
  bool isLoading = false;
  late String? updateRequestId;

  @override
  void initState() {
    super.initState();
    isSelected = widget.calendarItem.isSelected ?? false;
    updateRequestId = null;
  }

  void _toggleSelection() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      isSelected = !isSelected;
      widget.calendarItem.isSelected = isSelected;
    });

    // Update local state immediately
    widget.onToggle(widget.calendarItem.id!, isSelected);

    // Update calendar item selection via bloc
    if (!context.read<IntegrationsBloc>().isClosed) {
      setState(() {
        updateRequestId = "update_integration_requestId_${Utility.getUuid}";
      });
      context.read<IntegrationsBloc>().add(
            UpdateCalendarItemEvent(
              integrationId: widget.integration.id!,
              calendarItemId: widget.calendarItem.id!,
              calendarName: widget.calendarItem.name ?? '',
              isSelected: isSelected,
              requestId: updateRequestId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    String calendarName = widget.calendarItem.name ??
        AppLocalizations.of(context)!.unknownCalendar;

    return BlocListener<IntegrationsBloc, IntegrationsState>(
      listener: (context, state) {
        if (state is IntegrationsLoaded && state.requestId == updateRequestId) {
          setState(() {
            isLoading = false;
            updateRequestId = null;
          });
        }
        if (state is IntegrationsError && state.requestId == updateRequestId) {
          setState(() {
            isLoading = false;
            updateRequestId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: TileStyles.primaryContrastColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TileStyles.greenApproval : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isSelected ? TileStyles.greenApproval : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: TileStyles.primaryContrastColor,
                    size: 12,
                  )
                : null,
          ),
          title: Text(
            calendarName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          subtitle: widget.calendarItem.description != null
              ? Text(
                  widget.calendarItem.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(TileStyles.greenApproval),
                  ),
                )
              : Switch(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(),
                  activeColor: TileStyles.greenApproval,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
          onTap: _toggleSelection,
        ),
      ),
    );
  }
}
