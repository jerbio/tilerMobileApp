import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/designatedTille.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileWidget.dart';
import 'package:tiler_app/services/api/tileClusterApi.dart';

class DesignatedTileList extends StatefulWidget {
  static final String routeName = '/DesignatedTileList';
  @override
  State<StatefulWidget> createState() => _DesignatedTileListState();
}

class _DesignatedTileListState extends State<DesignatedTileList> {
  TileClusterApi tileClusterApi = TileClusterApi();
  List<DesignatedTile> designatedTiles = [];
  @override
  void initState() {
    super.initState();
    tileClusterApi.getDesignatedTiles().then((value) {
      setState(() {
        designatedTiles = value;
      });
    });
  }

  Widget renderBody() {
    if (designatedTiles.isEmpty) {
      return Text("No designated tiles");
    }
    return ListView.builder(
        itemCount: designatedTiles.length,
        itemBuilder: (context, index) {
          return DesignatedTileWidget(designatedTiles[index]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: renderBody(),
    );
  }
}
