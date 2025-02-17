import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class PreviewSection {
  String? name;
  bool? isNullGrouping;
  List<TilerEvent>? tiles;

  PreviewSection.fromJson(Map<String, dynamic> json) {
    String nameKey = 'name';
    if (json.containsKey(nameKey)) {
      name = json[nameKey];
    }
    String isNullGroupingKey = 'isNullGrouping';
    if (json.containsKey(isNullGroupingKey)) {
      isNullGrouping = json[isNullGroupingKey];
    }

    String tilesKey = 'tiles';
    if (json.containsKey(tilesKey) && json[tilesKey] != null) {
      if (json[tilesKey] is List) {
        tiles = (json[tilesKey] as List)
            .where((element) => element != null)
            .map<TilerEvent>((e) => SubCalendarEvent.fromJson(e))
            .toList();
      }
    }
  }
}

class PreviewGroup {
  String? message;
  List<PreviewSection>? sections;

  PreviewGroup.fromJson(Map<String, dynamic> json) {
    String messageKey = 'message';
    if (json.containsKey(messageKey) && json[messageKey] != null) {
      message = json[messageKey];
    }
    String sectionKey = 'groupings';
    if (json.containsKey(sectionKey) && json[sectionKey] != null) {
      if (json[sectionKey] is List) {
        sections = (json[sectionKey] as List)
            .where((element) => element != null)
            .map<PreviewSection>((e) => PreviewSection.fromJson(e))
            .toList();
      }
    }
  }
}
