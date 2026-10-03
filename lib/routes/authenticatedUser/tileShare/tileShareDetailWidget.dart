import 'package:flutter/material.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailHost.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/inboxMultiTiletteTileShareDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/multiTiletteTileShareDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/singleTiletteTileShareDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareFlags.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme.dart';
import 'package:tiler_app/util.dart';

/// A cluster's detail, opened by cluster id, by one of its designated tile
/// templates (a shared tile on the schedule) or with the cluster in hand.
///
/// A thin router (redesign Step 9.12): the new one-scaffold detail
/// ([TileShareDetailHost]) behind its own switch, [useNewDetail]
/// (`--dart-define=TILESHARE_DETAIL_V2=true`), until the mode contents
/// (9.13-9.16) replace today's screens; otherwise today's screens. The old
/// `isOutBox` becomes the ownership hint, used only when the signed-in user is
/// not known.
class TileShareDetailWidget extends StatelessWidget {
  final String? tileShareId;
  final String? designatedTileShareId;
  final bool isOutBox;
  final TileShareClusterData? tileShareClusterData;

  const TileShareDetailWidget.byId(
      {super.key, required this.tileShareId, this.isOutBox = true})
      : designatedTileShareId = null,
        tileShareClusterData = null;

  const TileShareDetailWidget.byDesignatedTileShareId(
      {super.key,
      required this.designatedTileShareId,
      this.isOutBox = false})
      : tileShareId = null,
        tileShareClusterData = null;

  const TileShareDetailWidget.byTileShareData(
      {super.key,
      required TileShareClusterData this.tileShareClusterData,
      this.isOutBox = true})
      : tileShareId = null,
        designatedTileShareId = null;

  /// Whether the new detail is shown.
  static bool get useNewDetail => kTileShareDetailV2;

  /// Where the new detail opens from.
  TileShareDetailTarget get target {
    final TileShareClusterData? data = tileShareClusterData;
    if (data != null) return TileShareDetailTarget.data(data);
    final String? designated = designatedTileShareId;
    if (designated != null) return TileShareDetailTarget.designatedTile(designated);
    return TileShareDetailTarget.cluster(tileShareId ?? '');
  }

  /// Whether the caller opened it as the owner's.
  bool get ownerHint => isOutBox;

  @override
  Widget build(BuildContext context) {
    if (useNewDetail) {
      return TileShareDetailHost(target: target, ownerHint: ownerHint);
    }
    return LegacyTileShareDetailWidget(
      tileShareId: tileShareId,
      designatedTileShareId: designatedTileShareId,
      tileShareClusterData: tileShareClusterData,
      isOutBox: isOutBox,
    );
  }
}

/// Today's detail: a router over the three old screens. Retired in 9.17.
class LegacyTileShareDetailWidget extends StatefulWidget {
  final String? tileShareId;
  final String? designatedTileShareId;
  final bool isOutBox;
  final TileShareClusterData? tileShareClusterData;

  const LegacyTileShareDetailWidget({
    super.key,
    this.tileShareId,
    this.designatedTileShareId,
    this.tileShareClusterData,
    required this.isOutBox,
  });

  @override
  _TileShareDetailWidget createState() => _TileShareDetailWidget();
}

class _TileShareDetailWidget extends State<LegacyTileShareDetailWidget> {
  late final TileShareClusterApi clusterApi;
  late final DesignatedTileApi designatedTileShareApi;
  TileShareClusterData? tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  List<DesignatedTile>? designatedTileList = null;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 8);
  ScrollController _contactControllerfinal = ScrollController();
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    isLoading = false;
    isTileListLoading = false;
    clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    designatedTileShareApi =
        DesignatedTileApi(getContextCallBack: () => context);
    if (this.widget.tileShareClusterData != null) {
      isLoading = false;
      tileShareCluster = this.widget.tileShareClusterData;
    } else if (this.widget.tileShareId.isNot_NullEmptyOrWhiteSpace()) {
      isLoading = true;
      getTileShareCluster();
    } else if (this
        .widget
        .designatedTileShareId
        .isNot_NullEmptyOrWhiteSpace()) {
      isLoading = true;
      getDesignatedTileShareId(this.widget.designatedTileShareId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  Future getTileShareCluster({String? tileShareId}) async {
    bool tileLoadingState = false;
    String? lookupClusterId = tileShareId ?? this.widget.tileShareId;
    if (lookupClusterId.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi.getTileShareClusters(clusterId: lookupClusterId).then((value) {
        Utility.debugPrint("Success getting tile cluster");
        setState(() {
          tilerError = null;
          tileShareCluster = value.firstOrNull;
          isLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Failed to get tile cluster");
        setState(() {
          tilerError = TilerError(
              Message:
                  AppLocalizations.of(context)!.failedToLoadTileShareCluster);
          if (onError is TilerError) {
            tilerError = onError;
          }

          isLoading = false;
        });
      });

      clusterApi
          .getDesignatedTiles(clusterId: this.widget.tileShareId)
          .then((value) {
        setState(() {
          Utility.debugPrint("Success getting tileShare list ");
          tilerError = null;
          designatedTileList = value;
          isTileListLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Error getting tileShare list ");
        setState(() {
          if (onError is TilerError) {
            tilerError = onError;
          }
          tilerError = TilerError(
              Message: AppLocalizations.of(context)!.errorLoadingTilelist);
          isTileListLoading = false;
        });
      });
    }
    isTileListLoading = tileLoadingState;
    setState(() {
      isLoading = true;
      tilerError = null;
      isTileListLoading = tileLoadingState;
    });
  }

  Future getDesignatedTileShareId(String designatedTileShareId) async {
    designatedTileShareApi
        .getDesignatedTiles(designatedTileId: designatedTileShareId)
        .then((value) {
      if (value.isNotEmpty) {
        String? clusterShareId = value.first.tileTemplate?.clusterId;
        if (clusterShareId.isNot_NullEmptyOrWhiteSpace()) {
          getTileShareCluster(tileShareId: clusterShareId);
        }
      }
    });
  }

  Widget renderAuthorization() {
    throw UnimplementedError();
  }

  Widget renderError() {
    return Text(this.tilerError?.Message ?? "Error loading tilelist");
  }

  Widget renderNotFound() {
    return Text("Resource not found");
  }

  Widget _buildContactPill(Contact contact) {
    return Chip(
      avatar: Icon(
        (contact.phoneNumber.isNot_NullEmptyOrWhiteSpace()
            ? Icons.messenger_outline
            : Icons.email_outlined),
        color: colorScheme.onPrimary,
      ),
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: null,
      side: BorderSide.none,
      backgroundColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: colorScheme.onPrimary,
      ),
    );
  }

  Widget renderTileShareCluster() {
    if (this.tileShareCluster == null) {
      this.tilerError = TilerError(
          Message: AppLocalizations.of(context)!.missingTileShareCluster);
      return renderError();
    }

    TileShareClusterData cluster = this.tileShareCluster!;
    String creatorInfo =
        cluster.creator?.username ?? cluster.creator?.email ?? "";
    return Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cluster.endTimeInMs != null && cluster.endTimeInMs! > 0)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colorScheme.onSurface,
                    size: 16,
                  ),
                  rowSpacer,
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(
                        DateTime.fromMillisecondsSinceEpoch(
                            cluster.endTimeInMs!)),
                    style: TileTextStyles.defaultText.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined,
                      size: 14, color: colorScheme.onSurface),
                ],
              )
            else
              SizedBox.shrink(),
            verticalSpacer,
            if (creatorInfo.isNot_NullEmptyOrWhiteSpace())
              Row(
                children: [
                  Icon(
                    Icons.person_2_outlined,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  rowSpacer,
                  Text(
                    (creatorInfo.contains('@') ? '' : '@') + '${creatorInfo}',
                    style: TileTextStyles.defaultText,
                  )
                ],
              ),
            verticalSpacer,
            Container(
              height: 50,
              child: ListView(
                controller: _contactControllerfinal,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...(cluster.contacts ?? [])
                          .map((contact) => _buildContactPill(contact))
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
            verticalSpacer,
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator(color: colorScheme.tertiary);
  }

  bool get _isReadOnly {
    return this.widget.isOutBox != true;
  }

  bool get _isOutBox {
    return this.widget.isOutBox != false;
  }

  @override
  Widget build(BuildContext context) {
    if (this.isLoading == true) {
      return Scaffold(
        body: Center(
          child: renderLoading(),
        ),
      );
    }
    if (this.tileShareCluster != null) {
      if (this.tileShareCluster!.isMultiTilette == true) {
        if (this._isOutBox) {
          return MultiTiletteTileShareDetailWidget(
              tileShareClusterData: this.tileShareCluster!,
              isReadOnly: this._isReadOnly);
        } else {
          return InboxMultiTiletteTileShareDetailWidget(
              tileShareClusterData: this.tileShareCluster!);
        }
      } else {
        return SingleTiletteTileShareDetailWidget(
          tileShareClusterData: this.tileShareCluster!,
          isReadOnly: this._isReadOnly,
        );
      }
    }

    return Scaffold(
      body: Center(
        child: renderError(),
      ),
    );
  }
}
