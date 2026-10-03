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
  double? completionPercentage;

  DesignatedTile.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }
    if (json.containsKey('name')) {
      name = json['name'];
    }
    if (json.containsKey('template') && json['template'] != null) {
      tileTemplate = TileShareTemplate.fromJson(json['template']);
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

    if (json.containsKey('completionPercent') &&
        json['completionPercent'] != null) {
      completionPercentage = json['completionPercent'];
    }
  }

  /// The designated tile template's user (`DesignatedUserId` on the server),
  /// read as the web reads it: the `userId` (else the profile id) of this
  /// template's entry in its tilette's `designatedUsers`; `null` without one.
  /// The tile-level [user] is never used - on a device it was not the
  /// template's designated user, and every recipient's own template looked
  /// like someone else's.
  String? get designatedUserId {
    for (final entry in tileTemplate?.designatedUsers ?? const []) {
      if (entry.designatedTileTemplateId == id) {
        final String? owner = entry.userId ?? entry.userProfile?.id;
        if (owner != null && owner.isNotEmpty) return owner;
      }
    }
    return null;
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

  /// Maps a server status string to [InvitationStatus]. `tentative` is still
  /// a pending invitation server-side, so it maps to [InvitationStatus.none];
  /// anything unrecognised is `null` (it must never throw while parsing a
  /// cluster).
  static InvitationStatus? stringToInvitationStatus(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == 'tentative') {
      return InvitationStatus.none;
    }
    for (final InvitationStatus status in InvitationStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return null;
  }
}
