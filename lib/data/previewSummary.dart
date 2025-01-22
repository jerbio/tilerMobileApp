import 'package:tiler_app/data/previewGroup.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class PreviewSummary {
  Duration? travelDuration;
  PreviewGroup? location;
  PreviewGroup? tag;
  PreviewGroup? classification;
  List<TilerEvent>? tiles;
  List<PreviewSection>? weather;
  List<PreviewSection>? physical;
  List<PreviewSection>? emotional;

  List<List<PreviewSection>> orderdByGrouping() {
    List<List<PreviewSection>> retValue = [];
    if (location != null &&
        location!.sections != null &&
        location!.sections!.isNotEmpty) {
      retValue.add(location!.sections!);
    }
    if (tag != null && tag!.sections != null && tag!.sections!.isNotEmpty) {
      retValue.add(tag!.sections!);
    }
    if (classification != null &&
        classification!.sections != null &&
        classification!.sections!.isNotEmpty) {
      retValue.add(classification!.sections!);
    }

    return retValue;
  }

  PreviewSummary.fromJson(Map<String, dynamic> json) {
    String locationKey = 'location';
    if (json.containsKey(locationKey) && json[locationKey] != null) {
      if (json[locationKey] is Map) {
        location = PreviewGroup.fromJson(json[locationKey]);
      }
    }
    String tagKey = 'tag';
    if (json.containsKey(tagKey) && json[tagKey] != null) {
      if (json[tagKey] is Map) {
        tag = PreviewGroup.fromJson(json[tagKey]);
      }
    }
    String classificationKey = 'classification';
    if (json.containsKey(classificationKey) &&
        json[classificationKey] != null) {
      if (json[classificationKey] is Map) {
        classification = PreviewGroup.fromJson(json[classificationKey]);
      }
    }

    String tilesKey = 'tiles';
    if (json.containsKey(tilesKey) && json[tilesKey] != null) {
      if (json[tilesKey] is List) {
        tiles = (json[tilesKey] as List)
            .where((element) => element != null)
            .map<TilerEvent>((e) => TilerEvent.fromJson(e))
            .toList();
      }
    }
  }
}
