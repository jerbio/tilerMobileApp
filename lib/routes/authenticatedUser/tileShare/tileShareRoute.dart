import 'package:flutter/material.dart';
import 'tileShareActivityWidget.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/hub/tileShareHubHost.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareFlags.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareListWidget.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/util.dart';

class TileShareRoute extends StatefulWidget {
  /// Shows the redesigned hub (Attention | Clusters) instead of the tabs below.
  /// On with `--dart-define=TILESHARE_V2=true`; the released app keeps today's
  /// tabs until the redesign is complete.
  final bool showAttention;

  /// Builds the hub; the live one unless a test supplies its own.
  final WidgetBuilder? hubBuilder;

  const TileShareRoute({
    super.key,
    this.showAttention = kTileShareV2,
    this.hubBuilder,
  });

  @override
  State<StatefulWidget> createState() => _TileShareState();
}

class _TileShareState extends State<TileShareRoute> {
  ValueKey inBoxKey = ValueKey(Utility.getUuid);
  ValueKey outBoxKey = ValueKey(Utility.getUuid);
  @override
  Widget build(BuildContext context) {
    if (widget.showAttention) {
      return (widget.hubBuilder ?? (_) => const TileShareHubHost())(context);
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.onPrimary),
            onPressed: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.close,
            ),
          ),
          actions: [
            ElevatedButton.icon(
                style:
                    TileButtonStyles.enabled(borderColor: colorScheme.primary),
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
                  color: colorScheme.onPrimary,
                ),
                label: SizedBox.shrink())
          ],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.share,
                color: colorScheme.onPrimary,
              ),
              SizedBox.square(
                dimension: 5,
              ),
              Text(
                AppLocalizations.of(context)!.tileShare,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                ),
              )
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.history), text: AppLocalizations.of(context)!.tileShareActivityTitle),
              Tab(
                icon: Column(
                  children: [
                    Icon(
                      Icons.outbox_outlined,
                      color: colorScheme.onPrimary,
                    ),
                    Text(
                      AppLocalizations.of(context)!.outBound,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                      ),
                    )
                  ],
                ),
              ),
              Tab(
                  icon: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: colorScheme.onPrimary,
                  ),
                  Text(AppLocalizations.of(context)!.inBound,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                      ))
                ],
              )),
            ],
            dividerColor: colorScheme.surfaceContainerLowest,
            indicatorColor: colorScheme.onPrimary,
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            const TileShareActivityWidget(),
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
