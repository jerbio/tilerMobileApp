import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareList.dart';
import 'package:tiler_app/styles.dart';

class TileShareRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TileShareState();
}

class ScreenArguments {
  final String? title;
  final String? message;

  ScreenArguments(this.title, this.message);
}

class _TileShareState extends State<TileShareRoute> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ScreenArguments?;
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
              color: TileStyles.appBarTextColor,
            ),
          ),
          backgroundColor: TileStyles.appBarColor,
          actions: [
            ElevatedButton.icon(
                style: TileStyles.enabledButtonStyle,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateTileShareClusterWidget()));
                },
                icon: Icon(
                  Icons.add,
                  color: TileStyles.primaryContrastColor,
                ),
                label: SizedBox.shrink())
          ],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  Icons.outbound,
                  color: TileStyles.primaryContrastColor,
                ),
              ),
              Tab(
                  icon: Icon(Icons.inbox_outlined,
                      color: TileStyles.primaryContrastColor)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TileShareList(
              isOutBox: true,
            ),
            TileShareList()
          ],
        ),
      ),
    );
  }
}
