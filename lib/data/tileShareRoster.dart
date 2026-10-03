import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

/// How a recipient's invitation was delivered, from the owner-only
/// `invitation_*` activity events.
enum RecipientDelivery { sent, failed, unknown }

/// Where a roster row stands with the server.
enum RosterRowPhase {
  /// On the server.
  saved,

  /// Being added (to some or all of the tasks); not confirmed yet.
  adding,

  /// The server refused or never answered an add to one task or more; it can
  /// be retried. Tasks that did work stay done.
  addFailed,

  /// The server refused to remove it from one task or more; it is back.
  removeFailed,
}

/// One person on one task: their assignment, answer, progress and delivery;
/// [assignmentId] `null` when they are not on that task.
class RosterCell extends Equatable {
  final String tiletteId;
  final String? assignmentId;
  final InvitationStatus? rsvp;
  final double? completion;
  final RecipientDelivery? delivery;
  final String? deliveryChannel;

  const RosterCell({
    required this.tiletteId,
    this.assignmentId,
    this.rsvp,
    this.completion,
    this.delivery,
    this.deliveryChannel,
  });

  bool get isPresent => assignmentId != null;

  @override
  List<Object?> get props =>
      [tiletteId, assignmentId, rsvp, completion, delivery, deliveryChannel];
}

/// One person on a share's roster, as its owner sees it: one [cells] entry
/// per task, in the tasks' order (a Broadcast has one task).
class RosterRow extends Equatable {
  /// The person's first assignment once on the server; a local id while they
  /// are being added and on no task yet.
  final String key;

  /// Who it is: the identifier the server shows, else an email or phone.
  final String label;

  /// The person's identity (from the server, or as entered).
  final Contact? contact;
  final List<RosterCell> cells;
  final RosterRowPhase phase;
  final String? failureReason;

  const RosterRow({
    required this.key,
    required this.label,
    this.contact,
    this.cells = const <RosterCell>[],
    this.phase = RosterRowPhase.saved,
    this.failureReason,
  });

  /// Their first assignment; `null` while they are on no task.
  String? get assignmentId {
    for (final RosterCell c in cells) {
      if (c.isPresent) return c.assignmentId;
    }
    return null;
  }

  RosterCell? get _single => cells.length == 1 ? cells.first : null;

  /// The answer, progress and delivery of a one-task share.
  InvitationStatus? get rsvp => _single?.rsvp;
  double? get completion => _single?.completion;

  /// The worst delivery across their tasks (failed, then unknown, then sent).
  RecipientDelivery? get delivery => _worstDelivery?.delivery;
  String? get deliveryChannel => _worstDelivery?.deliveryChannel;

  RosterCell? get _worstDelivery {
    RosterCell? worst;
    int rank(RecipientDelivery? d) => switch (d) {
          RecipientDelivery.failed => 3,
          RecipientDelivery.unknown => 2,
          RecipientDelivery.sent => 1,
          null => 0,
        };
    for (final RosterCell c in cells) {
      if (rank(c.delivery) > rank(worst?.delivery)) worst = c;
    }
    return worst;
  }

  /// Tasks the person is not on, once they are on at least one.
  int get missingCount =>
      assignmentId == null ? 0 : cells.where((c) => !c.isPresent).length;

  /// On some tasks of a Class but not all (redesign O9).
  bool get isIncomplete => missingCount > 0;

  int get acceptedCount =>
      cells.where((c) => c.rsvp == InvitationStatus.accepted).length;

  /// Every task they are on, accepted.
  bool get acceptedAll =>
      cells.isNotEmpty &&
      cells.every((c) => c.isPresent && c.rsvp == InvitationStatus.accepted);

  /// The ways this person is recognised (user id, email, phone, username),
  /// to catch someone added twice.
  Set<String> get identities => contact == null
      ? <String>{'label:${label.trim().toLowerCase()}'}
      : ClassFanout.identityKeys(contact!);

  @override
  List<Object?> get props =>
      [key, label, contact?.email, contact?.phoneNumber, cells, phase, failureReason];
}

/// Builds roster rows from a share's tasks: people matched across tasks by
/// identity ([ClassFanout]), in order of first appearance, one cell per task.
abstract final class RosterPeople {
  static List<RosterRow> of(
    List<TileShareTemplate> tilettes,
    Map<String, (RecipientDelivery, String?)> delivery,
  ) {
    final List<Set<String>> keys = <Set<String>>[];
    final List<Map<String, DesignatedUser>> byTilette =
        <Map<String, DesignatedUser>>[];
    final List<DesignatedUser> first = <DesignatedUser>[];
    for (final TileShareTemplate tilette in tilettes) {
      for (final DesignatedUser user
          in tilette.designatedUsers ?? const <DesignatedUser>[]) {
        final Contact? contact = ClassFanout.contactOfUser(user);
        final Set<String> own =
            contact == null ? <String>{} : ClassFanout.identityKeys(contact);
        if (own.isEmpty) own.add('assignment:${assignmentOf(user)}');
        final int found = keys.indexWhere((known) => known.any(own.contains));
        if (found >= 0) {
          keys[found].addAll(own);
          byTilette[found].putIfAbsent(tilette.id ?? '', () => user);
        } else {
          keys.add(<String>{...own});
          byTilette.add(<String, DesignatedUser>{tilette.id ?? '': user});
          first.add(user);
        }
      }
    }
    return <RosterRow>[
      for (int i = 0; i < first.length; i++)
        _row(first[i], byTilette[i], tilettes, delivery),
    ];
  }

  static String? assignmentOf(DesignatedUser user) =>
      user.designatedTileTemplateId ?? user.id;

  static RosterRow _row(
    DesignatedUser firstUser,
    Map<String, DesignatedUser> byTilette,
    List<TileShareTemplate> tilettes,
    Map<String, (RecipientDelivery, String?)> delivery,
  ) {
    final List<RosterCell> cells = <RosterCell>[
      for (final TileShareTemplate t in tilettes)
        () {
          final DesignatedUser? user = byTilette[t.id ?? ''];
          final String? assignment = user == null ? null : assignmentOf(user);
          final (RecipientDelivery, String?)? known =
              assignment == null ? null : delivery[assignment];
          return RosterCell(
            tiletteId: t.id ?? '',
            assignmentId: assignment,
            rsvp: user?.rsvpStatus,
            completion: user?.completionPercentage,
            delivery: known?.$1,
            deliveryChannel: known?.$2,
          );
        }(),
    ];
    final String? key = cells
        .firstWhere((c) => c.isPresent, orElse: () => cells.first)
        .assignmentId;
    return RosterRow(
      key: key ?? labelOf(firstUser),
      label: labelOf(firstUser),
      contact: ClassFanout.contactOfUser(firstUser),
      cells: cells,
    );
  }

  static String labelOf(DesignatedUser user) {
    for (final String? v in [
      user.displayedName,
      user.userProfile?.email,
      user.userProfile?.phoneNumber,
      user.userProfile?.fullName,
      user.userProfile?.username,
    ]) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}

/// Delivery per assignment: each recipient's **newest** `invitation_*` event.
abstract final class RosterDelivery {
  static const Map<String, RecipientDelivery> _byType =
      <String, RecipientDelivery>{
    'invitation_sent': RecipientDelivery.sent,
    'invitation_send_failed': RecipientDelivery.failed,
    'invitation_send_unknown': RecipientDelivery.unknown,
  };

  static Map<String, (RecipientDelivery, String?)> fromActivity(
      Iterable<TileShareActivity> events) {
    final List<TileShareActivity> sorted = events.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final Map<String, (RecipientDelivery, String?)> result =
        <String, (RecipientDelivery, String?)>{};
    for (final TileShareActivity e in sorted) {
      final RecipientDelivery? delivery = _byType[e.eventType];
      final String? assignment = e.assignmentId;
      if (delivery == null || assignment == null) continue;
      result.putIfAbsent(assignment, () => (delivery, e.invitationChannel));
    }
    return result;
  }
}
