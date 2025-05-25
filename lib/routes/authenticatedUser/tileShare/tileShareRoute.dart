import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareListWidget.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

class TileShareRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TileShareState();
}

class _TileShareState extends State<TileShareRoute> {
  ValueKey inBoxKey = ValueKey(Utility.getUuid);
  ValueKey outBoxKey = ValueKey(Utility.getUuid);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.close,
              color: TileColors.appBarTextColor,
            ),
          ),
          backgroundColor: TileColors.appBarColor,
          actions: [
            ElevatedButton.icon(
                style: TileStyles.enabledButtonStyle,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateTileShareClusterWidget())).whenComplete(() {
                    setState(() {
                      inBoxKey = ValueKey(Utility.getUuid);
                      outBoxKey = ValueKey(Utility.getUuid);
                    });
                  });
                },
                icon: Icon(
                  Icons.add,
                  color: TileColors.primaryContrastColor,
                ),
                label: SizedBox.shrink())
          ],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.share,
                color: TileColors.appBarTextColor,
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
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Column(
                  children: [
                    Icon(
                      Icons.outbox_outlined,
                      color: TileColors.primaryContrastColor,
                    ),
                    Text(
                      AppLocalizations.of(context)!.outBound,
                      style: TileStyles.titleBarStyle,
                    )
                  ],
                ),
              ),
              Tab(
                  icon: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      color: TileColors.primaryContrastColor),
                  Text(
                    AppLocalizations.of(context)!.inBound,
                    style: TileStyles.titleBarStyle,
                  )
                ],
              )),
            ],
            dividerColor: TileColors.appBarTextColor,
            indicatorColor: TileColors.appBarTextColor,
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            TileShareListWidget(
              key: outBoxKey,
              isOutBox: true,
            ),
            TileShareListWidget(
              key: inBoxKey,
              isOutBox: false,
            )
          ],
        ),
      ),
    );
  }
}
