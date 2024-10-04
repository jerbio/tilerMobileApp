import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';

class TileShareWidget extends StatefulWidget {
  final TileShareClusterData? tileShareCluster;

  TileShareWidget({required this.tileShareCluster});

  @override
  _TileShareState createState() => _TileShareState();
}

class _TileShareState extends State<TileShareWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Template ID: ${widget.tileShareCluster?.id ?? "no-id"}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text('Template Name: ${widget.tileShareCluster?.name ?? "no-name"}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text(
            'Start Time: ${DateTime.fromMillisecondsSinceEpoch(widget.tileShareCluster?.startTimeInMs ?? 0)}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text(
            'End Time: ${DateTime.fromMillisecondsSinceEpoch(widget.tileShareCluster?.endTimeInMs ?? 0)}',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 16),
        Text(
            'Displayed Identifier: ${widget.tileShareCluster?.contacts ?? "no-identifier"}',
            style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
