import 'package:tiler_app/data/tileTemplate.dart';
import 'package:tiler_app/data/tilerUserProfile.dart';

class DesignatedTile {
  String? id;
  String? name;
  int? startInMs;
  int? endInMs;
  String? invitationStatus;
  bool? isViable;
  String? displayedIdentifier;
  TileTemplate? tileTemplate;
  TilerUserProfile? user;

  DesignatedTile.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('template') && json['template'] != null) {
      tileTemplate = TileTemplate.fromJson(json['template']);
    }

    if (json.containsKey('displayedIdentifier')) {
      displayedIdentifier = json['displayedIdentifier'];
    }

    if (json.containsKey('isViable')) {
      isViable = json['isViable'];
    }

    if (json.containsKey('invitationStatus')) {
      invitationStatus = json['invitationStatus'];
    }

    if (json.containsKey('user') && json['user'] != null) {
      user = TilerUserProfile.fromJson(json['user']);
    }
  }

  DateTime? get startTime {
    if (startInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(startInMs!);
    }
    if (tileTemplate != null && tileTemplate!.start != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.start!);
    }
  }

  DateTime? get endTime {
    if (endInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(endInMs!);
    }
    if (tileTemplate != null && tileTemplate!.end != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.end!);
    }
  }
}
