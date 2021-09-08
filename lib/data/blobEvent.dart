import 'dart:collection';
import 'package:tiler_app/data/tilerEvent.dart';

class BlobEvent extends TilerEvent {
  HashSet<TilerEvent> blobOfTiles = new HashSet();

  BlobEvent.fromTilerEvents(List<TilerEvent> tilerEvents) {
    double? start;
    double? end;

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

  BlobEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
