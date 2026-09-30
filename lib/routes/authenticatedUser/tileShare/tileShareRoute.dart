import 'package:flutter/material.dart';
import 'tileShareActivityWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionTab.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareFlags.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareListWidget.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/util.dart';

class TileShareRoute extends StatefulWidget {
  /// Adds the redesigned Attention inbox as the first (and opening) tab. On
  /// with `--dart-define=TILESHARE_V2=true`; the other tabs are unchanged
  /// until the rest of the redesign replaces them.
  final bool showAttention;

  /// Builds the Attention tab's content; the live inbox unless a test
  /// supplies its own.
  final WidgetBuilder? attentionBuilder;

  const TileShareRoute({
    super.key,
    this.showAttention = kTileShareV2,
    this.attentionBuilder,
  });

  @override
  State<StatefulWidget> createState() => _TileShareState();
}

class _TileShareState extends State<TileShareRoute> {
  ValueKey inBoxKey = ValueKey(Utility.getUuid);
  ValueKey outBoxKey = ValueKey(Utility.getUuid);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DefaultTabController(
      length: widget.showAttention ? 4 : 3,
      initialIndex: widget.showAttention ? 0 : 1,
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
            // The bar is the primary colour, so the default (primary) selected
            // label vanishes into it and the unselected one is hard to read.
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.7),
            // Four tabs no longer fit across a phone without wrapping.
            isScrollable: widget.showAttention,
            tabAlignment:
                widget.showAttention ? TabAlignment.start : TabAlignment.fill,
            tabs: [
              if (widget.showAttention)
                Tab(
                    icon: const Icon(Icons.notifications_none),
                    text: AppLocalizations.of(context)!.attentionTabTitle),
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
            if (widget.showAttention)
              (widget.attentionBuilder ??
                  (_) => const TileShareAttentionTab())(context),
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
