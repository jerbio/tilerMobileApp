import 'dart:collection';
import 'package:tiler_app/data/tilerEvent.dart';

class BlobEvent extends TilerEvent {
  HashSet<TilerEvent> blobOfTiles = new HashSet();

  BlobEvent.fromTilerEvents(List<TilerEvent> tilerEvents) {
    int? start;
    int? end;

    tilerEvents.forEach((tilerEvent) {
      if (end == null) {
        end = tilerEvent.end;
      } else {
        if (tilerEvent.start! > end!) {
          end = tilerEvent.end;
        }
      }

      if (start == null) {
        start = tilerEvent.start;
      } else {
        if (tilerEvent.start! < start!) {
          start = tilerEvent.start;
        }
      }

      blobOfTiles.add(tilerEvent);
    });

    this.start = start;
    this.end = end;
  }

  /// this expands to get all tiles in the blob
  /// so if blob has 3 tiles, it returns all 3 tiles
  /// if one of those tiles is itself a blob, it expands that too
  /// and returns all tiles in that blob as well into a single list
  /// for example if blob A has tiles 1,2,3
  /// and tile 2 is itself a blob with tiles 4,5
  /// then AllTiles for blob A returns 1,3,4,5
  List<TilerEvent> get AllTiles {
    List<TilerEvent> allTiles = [];
    blobOfTiles.forEach((tilerEvent) {
      if (tilerEvent is BlobEvent) {
        allTiles.addAll(tilerEvent.AllTiles);
      } else {
        allTiles.add(tilerEvent);
      }
    });
    return allTiles;
  }

  BlobEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
