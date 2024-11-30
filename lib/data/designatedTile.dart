import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/util.dart';

enum InvitationStatus { accepted, declined, none }

class DesignatedTile {
  String? id;
  String? name;
  int? startInMs;
  int? endInMs;
  String? invitationStatus = InvitationStatus.none.toString();
  bool? isViable;
  bool? isTilable;
  String? displayedIdentifier;
  TileShareTemplate? tileTemplate;
  UserProfile? user;
  UserProfile? clusterOwner;
  TilerEvent? tilerEvent;

  DesignatedTile.fromJson(Map<String, dynamic> json) {
    id = '';
    Utility.debugPrint(0.toString());
    if (json.containsKey('id')) {
      id = json['id'];
    }
    Utility.debugPrint(2.toString());
    if (json.containsKey('name')) {
      name = json['name'];
    }
    Utility.debugPrint(3.toString());
    if (json.containsKey('template') && json['template'] != null) {
      tileTemplate = TileShareTemplate.fromJson(json['template']);
    }
    Utility.debugPrint(4.toString());
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
      user = UserProfile.fromJson(json['user']);
    }

    if (json.containsKey('isTilable') && json['isTilable'] != null) {
      isTilable = json['isTilable'];
    }

    if (json.containsKey('clusterOwner') && json['clusterOwner'] != null) {
      clusterOwner = UserProfile.fromJson(json['clusterOwner']);
    }

    if (json.containsKey('tilerEvent') && json['tilerEvent'] != null) {
      tilerEvent = TilerEvent.fromJson(json['tilerEvent']);
    }
  }

  DateTime? get startTime {
    if (startInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(startInMs!);
    }
    if (tileTemplate != null && tileTemplate!.start != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.start!);
    }
    return null;
  }

  DateTime? get endTime {
    if (endInMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(endInMs!);
    }
    if (tileTemplate != null && tileTemplate!.end != null) {
      return DateTime.fromMillisecondsSinceEpoch(tileTemplate!.end!);
    }
    return null;
  }

  static InvitationStatus? stringToInvitationStatus(String value) {
    return InvitationStatus.values.firstWhere(
        (element) => element.name.toLowerCase() == value.toLowerCase());
  }
}
