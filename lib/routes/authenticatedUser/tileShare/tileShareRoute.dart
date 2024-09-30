import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileClusterWidget.dart';
import 'package:tiler_app/styles.dart';

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
          // automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: TileStyles.appBarColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.share,
                color: TileStyles.appBarTextColor,
              ),
              SizedBox.square(
                dimension: 5,
              ),
              Text(
                AppLocalizations.of(context)!.tileShare,
                style: TileStyles.titleBarStyle,
              )
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.add,
                  color: TileStyles.primaryContrastColor,
                ),
              ),
              Tab(
                  icon:
                      Icon(Icons.list, color: TileStyles.primaryContrastColor)),
              // Tab(icon: Icon(Icons.directions_bike)),
            ],
          ),
          // title: Text(AppLocalizations.of(context)!.tileShare),
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
