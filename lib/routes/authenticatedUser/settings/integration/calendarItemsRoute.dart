import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CalendarItemsRoute extends StatelessWidget {
  static final String routeName = '/CalendarItems';
  final CalendarIntegration integration;

  const CalendarItemsRoute({
    Key? key,
    required this.integration,
  }) : super(key: key);

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
          SizedBox(height: 16),          Text(
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
    if (integration.calendarItems == null || integration.calendarItems!.isEmpty) {
      return renderEmpty(context);
    }

    // Calculate statistics
    int selectedCount = integration.calendarItems!
        .where((item) => item.isSelected == true)
        .length;

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
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    Text(
                      AppLocalizations.of(context)!.calendarsActive(selectedCount, integration.calendarItems!.length),
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
            itemCount: integration.calendarItems!.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final calendarItem = integration.calendarItems![index];
              return _CalendarItemTile(
                calendarItem: calendarItem,
                integration: integration,
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
          routeName: routeName,
          appBar: TileStyles.CancelAndProceedAppBar('titleText'),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: renderCalendarItems(context),
          ),
        ),
    );
    // String titleText = integration.email ?? integration.userId ?? integration.id ?? "Calendar Items";
    // print("before building CalendarItemsRoute: $titleText");
    // IntegrationsBloc integrationsBloc = context.read<IntegrationsBloc>();
    // print("Other CalendarItemsRoute: Building with integration: ${integration.id}");
    // print("Other Integration details: ${integrationsBloc.state}");
    // return CancelAndProceedTemplateWidget(
    //       routeName: routeName,
    //       appBar: TileStyles.CancelAndProceedAppBar(titleText),
    //       child: Container(
    //         padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
    //         child: renderCalendarItems(context),
    //       ),
    //     );
  }
}

class _CalendarItemTile extends StatefulWidget {
  final CalendarItem calendarItem;
  final CalendarIntegration integration;

  const _CalendarItemTile({
    required this.calendarItem,
    required this.integration,
  });

  @override
  _CalendarItemTileState createState() => _CalendarItemTileState();
}

class _CalendarItemTileState extends State<_CalendarItemTile> {
  late bool isSelected;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isSelected = widget.calendarItem.isSelected ?? false;
  }

  void _toggleSelection() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      isSelected = !isSelected;
      widget.calendarItem.isSelected = isSelected;
    });
    
    // Update calendar item selection via bloc
    context.read<IntegrationsBloc>().add(
      UpdateCalendarItemEvent(
        integrationId: widget.integration.id!,
        calendarItemId: widget.calendarItem.id!,
        calendarName: widget.calendarItem.name ?? '',
        isSelected: isSelected,
      ),
    );

    // Simulate loading state for better UX
    await Future.delayed(Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String calendarName = widget.calendarItem.name ??
    AppLocalizations.of(context)!.unknownCalendar;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: Colors.white,
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
                  valueColor: AlwaysStoppedAnimation<Color>(TileStyles.greenApproval),
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
    );
  }
}
