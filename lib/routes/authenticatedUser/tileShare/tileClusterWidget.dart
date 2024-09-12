import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/tileClusterData.dart';

class TileClusterWidget extends StatefulWidget {
  Function? onAddTileCluster;
  Function? onAddingATileCluster;
  static final String routeName = '/TileCluster';
  @override
  TileClusterWidgetState createState() => TileClusterWidgetState();
}

class TileClusterWidgetState extends State<TileClusterWidget> {
  final TileClusterData tileClusterData = TileClusterData();
  Function? onProceedResponse;

  Widget clusterName() {
    throw UnimplementedError();
  }

  Widget additionalTiles() {
    throw UnimplementedError();
  }

  Widget duration() {
    throw UnimplementedError();
  }

  Widget deadline() {
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    Column response = Column(
      children: [clusterName(), additionalTiles(), duration(), deadline()],
    );
    return CancelAndProceedTemplateWidget(
      child: response,
      onProceed: onProceedResponse,
    );
  }
}
