import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileClusterWidget.dart';

class TileShareRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TileShareState();
}

class _TileShareState extends State<TileShareRoute> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add)),
              Tab(icon: Icon(Icons.list)),
              // Tab(icon: Icon(Icons.directions_bike)),
            ],
          ),
          title: Text(AppLocalizations.of(context)!.tileShare),
        ),
        body: TabBarView(
          children: [
            TileClusterWidget(),
            DesignatedTileList(),
            // Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }
}
