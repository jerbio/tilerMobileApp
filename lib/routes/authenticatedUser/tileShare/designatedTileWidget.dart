import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTille.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  String _responseMessage = '';

  // Function to handle API calls with status updates
  Future<void> _makeApiCall(String endpoint) async {
    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    // try {
    //   var response =
    //       await http.post(Uri.parse('https://api.example.com/$endpoint'));
    //   if (response.statusCode == 200) {
    //     setState(() {
    //       _responseMessage = '$endpoint successful';
    //     });
    //   } else {
    //     setState(() {
    //       _responseMessage = '$endpoint failed';
    //     });
    //   }
    // } catch (e) {
    //   setState(() {
    //     _responseMessage = 'Error: $e';
    //   });
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  }

  // Handlers for each button
  Future<void> _handleAccept() async =>
      _makeApiCall(AppLocalizations.of(context)!.accept);
  Future<void> _handleDecline() async =>
      _makeApiCall(AppLocalizations.of(context)!.decline);
  Future<void> _handleDismiss() async =>
      _makeApiCall(AppLocalizations.of(context)!.dismiss);

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
              widget.designatedTile.name ?? "",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            widget.designatedTile.endTime != null
                ? Text(
                    AppLocalizations.of(context)!.deadlineTime(
                        DateFormat('d MMM')
                            .format(widget.designatedTile.endTime!)),
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
                    label: Text("Accept"),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handleDecline,
                    icon: Icon(Icons.close),
                    label: Text("Decline"),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handleDismiss,
                    icon: Icon(Icons.remove_circle_outline),
                    label: Text("Dismiss"),
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
