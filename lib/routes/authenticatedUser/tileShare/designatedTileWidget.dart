import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTille.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileClusterApi.dart';

class DesignatedTileWidget extends StatefulWidget {
  final DesignatedTile designatedTile;
  DesignatedTileWidget(this.designatedTile);

  @override
  State<StatefulWidget> createState() => _DesignatedWidgetState();
}

class _DesignatedWidgetState extends State<DesignatedTileWidget> {
  bool _isLoading = false;
  final TileClusterApi tileClusterApi = TileClusterApi();
  final ScheduleApi scheduleApi = ScheduleApi();
  String _responseMessage = '';
  late DesignatedTile designatedTile;
  @override
  void initState() {
    super.initState();
    this.designatedTile = this.widget.designatedTile;
  }

  // Function to handle API calls with status updates
  Future<void> _statusUpdate(InvitationStatus status) async {
    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    try {
      if (this.designatedTile.id != null) {
        DesignatedTile? updatedDesignatedTile =
            await tileClusterApi.statusUpdate(this.designatedTile.id!, status);
        if (updatedDesignatedTile != null) {
          setState(() {
            this.designatedTile = updatedDesignatedTile;
          });
        }
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handlers for each button
  Future<void> _handleAccept() async {
    await _statusUpdate(InvitationStatus.accepted);
    tileClusterApi.analyzeSchedule().then((value) {
      return scheduleApi.buzzSchedule();
    });
  }

  Future<void> _handleDecline() async =>
      _statusUpdate(InvitationStatus.declined);
  Future<void> _handlePreview() async {
    setState(() {});
  }

  ButtonStyle generateButtonStyle(bool isSelected, Color defaultColor) {
    ButtonStyle retValue =
        ElevatedButton.styleFrom(foregroundColor: defaultColor);
    if (isSelected) {
      retValue = ElevatedButton.styleFrom(
          backgroundColor: defaultColor, foregroundColor: Colors.white);
    }
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              designatedTile.name ?? "",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            designatedTile.endTime != null
                ? Text(
                    AppLocalizations.of(context)!.deadlineTime(
                        DateFormat('d MMM').format(designatedTile.endTime!)),
                    style: TextStyle(fontSize: 16),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                      onPressed: _handleAccept,
                      icon: Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)!.accept),
                      style: generateButtonStyle(
                          this.designatedTile.invitationStatus ==
                              InvitationStatus.accepted.name.toString(),
                          Colors.green)
                      // ElevatedButton.styleFrom(foregroundColor: Colors.green),
                      ),
                  ElevatedButton.icon(
                      onPressed: _handleDecline,
                      icon: Icon(Icons.close),
                      label: Text(AppLocalizations.of(context)!.decline),
                      style: generateButtonStyle(
                          this.designatedTile.invitationStatus ==
                              InvitationStatus.declined.name.toString(),
                          Colors.red)
                      // style:
                      //     ElevatedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ElevatedButton.icon(
                    onPressed: _handlePreview,
                    icon: Icon(Icons.remove_circle_outline),
                    label: Text(AppLocalizations.of(context)!.preview),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
            SizedBox(height: 10),
            Text(
              _responseMessage,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
