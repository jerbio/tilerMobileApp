// Builders for TileShare test data, shared by the TileShare suites (redesign
// Step 9.3). The models only have `fromJson` constructors, so everything goes
// through the wire shape — which also keeps the fixtures honest.
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

/// A fixed "now" for time-dependent tests.
final DateTime kTileShareNow = DateTime.utc(2026, 9, 29, 12);

int tileShareMsFromNow(Duration offset) =>
    kTileShareNow.add(offset).millisecondsSinceEpoch;

TileShareClusterData tsCluster(
  String id, {
  String? name,
  TileShareMode? mode,
  bool? multi,
  int? endMs,
  List<String> contacts = const <String>[],
  bool completed = false,
  String? creatorId,
  String? creatorName,
}) =>
    TileShareClusterData.fromJson({
      'id': id,
      'name': name ?? 'Cluster $id',
      if (creatorId != null)
        'creator': {
          'id': creatorId,
          'username': creatorId,
          if (creatorName != null) 'fullName': creatorName,
        },
      if (mode != null) 'mode': mode.wire,
      if (multi != null) 'isMultiTilette': multi,
      if (endMs != null) 'end': endMs,
      if (contacts.isNotEmpty) 'truncatedUser': contacts,
      'isCompleted': completed,
    });

/// An owner's-view assignment: one recipient on one tilette.
DesignatedUser tsAssignee(
  String email, {
  InvitationStatus? status,
  double? completion,
}) =>
    DesignatedUser.fromJson({
      'id': 'asg-$email',
      'designatedTileTemplateId': 'asg-$email',
      'displayedIdentifier': email,
      if (status != null) 'rsvpStatus': status.name,
      if (completion != null) 'completionPct': completion,
      'userProfile': {'id': 'u-$email', 'email': email},
    });

Map<String, dynamic> _assigneeJson(DesignatedUser u) => {
      'id': u.id,
      if (u.designatedTileTemplateId != null)
        'designatedTileTemplateId': u.designatedTileTemplateId,
      if (u.displayedName != null) 'displayedIdentifier': u.displayedName,
      if (u.rsvpStatus != null) 'rsvpStatus': u.rsvpStatus!.name,
      if (u.completionPercentage != null) 'completionPct': u.completionPercentage,
      if (u.userProfile != null)
        'userProfile': {
          'id': u.userProfile!.id,
          'email': u.userProfile!.email,
        },
    };

TileShareTemplate tsTilette(
  String id, {
  String clusterId = 'c1',
  String? name,
  int? durationMs,
  int? endMs,
  List<DesignatedUser> assignees = const <DesignatedUser>[],
}) =>
    TileShareTemplate.fromJson({
      'id': id,
      'name': name ?? 'Tilette $id',
      'clusterId': clusterId,
      if (durationMs != null) 'duration': durationMs,
      if (endMs != null) 'end': endMs,
      'designatedUsers': assignees.map(_assigneeJson).toList(),
    });

/// The recipient's own copy of a tilette.
DesignatedTile tsDesignatedTile(
  String id, {
  String clusterId = 'c1',
  InvitationStatus status = InvitationStatus.none,
  bool? viable,
  int? endMs,
  String? name,
  String? ownerId = 'me',
  double? completion,
  int? durationMs,
}) =>
    DesignatedTile.fromJson({
      'id': id,
      'name': name ?? 'Tile $id',
      'invitationStatus': status.name,
      if (completion != null) 'completionPercent': completion,
      if (viable != null) 'isViable': viable,
      'template': {
        'id': 'tpl-$id',
        'clusterId': clusterId,
        'name': name ?? 'Tile $id',
        if (endMs != null) 'end': endMs,
        if (durationMs != null) 'duration': durationMs,
        // whose designated tile template it is: its entry in the tilette, as
        // `api/DesignatedTile/designated` sends it (and as the web reads it)
        if (ownerId != null)
          'designatedUsers': [
            {
              'designatedTileTemplateId': id,
              'userId': ownerId,
              'userProfile': {'id': ownerId},
            }
          ],
      },
    });

TileShareInvitation tsInvitation(
  String assignmentId,
  String clusterId, {
  int? deadlineMs,
  String inviter = 'Sarah Kim',
  String name = 'Task',
}) =>
    TileShareInvitation.fromJson({
      'assignmentId': assignmentId,
      'clusterId': clusterId,
      'tiletteId': 't-$assignmentId',
      'name': name,
      'clusterName': 'Cluster $clusterId',
      if (deadlineMs != null) 'deadline': deadlineMs,
      'inviterName': inviter,
    });

TileShareActivity tsActivity(
  String id,
  String type, {
  String cluster = 'c1',
  String? actorId = 'other',
  String? actorName = 'Jordan',
  int atMsFromNow = 0,
  String? tiletteId,
  String? assignmentId,
  Map<String, dynamic>? metadata,
}) =>
    TileShareActivity.fromJson({
      'eventId': id,
      'schemaVersion': 1,
      'eventType': type,
      'clusterId': cluster,
      'clusterTitle': 'Cluster $cluster',
      'occurredAt': kTileShareNow.millisecondsSinceEpoch + atMsFromNow,
      if (actorId != null) 'actorId': actorId,
      if (actorId != null && actorName != null) 'actorName': actorName,
      if (tiletteId != null) 'tiletteId': tiletteId,
      if (assignmentId != null) 'assignmentId': assignmentId,
      if (metadata != null) 'metadata': metadata,
    });


