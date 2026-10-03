import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareActivity.dart';

/// How a recipient's invitation was delivered, from the owner-only
/// `invitation_*` activity events.
enum RecipientDelivery { sent, failed, unknown }

/// Where a roster row stands with the server.
enum RosterRowPhase {
  /// On the server.
  saved,

  /// Being added; not confirmed yet.
  adding,

  /// The server refused or never answered the add; it can be retried.
  addFailed,

  /// The server refused to remove it; it is back where it was.
  removeFailed,
}

/// One recipient on a tilette's roster, as its owner sees it.
class RosterRow extends Equatable {
  /// The assignment id once saved; a local id while it is being added.
  final String key;

  /// The recipient's designated tile template; `null` until saved.
  final String? assignmentId;

  /// Who it is: the identifier the server shows, else an email or phone.
  final String label;

  /// The contact as entered (an add in progress or failed, for Retry).
  final Contact? contact;
  final InvitationStatus? rsvp;
  final double? completion;
  final RecipientDelivery? delivery;
  final String? deliveryChannel;
  final RosterRowPhase phase;
  final String? failureReason;

  const RosterRow({
    required this.key,
    this.assignmentId,
    required this.label,
    this.contact,
    this.rsvp,
    this.completion,
    this.delivery,
    this.deliveryChannel,
    this.phase = RosterRowPhase.saved,
    this.failureReason,
  });

  /// A saved recipient from its tilette's `designatedUsers` entry.
  factory RosterRow.fromRecipient(DesignatedUser user) {
    final String? assignment = user.designatedTileTemplateId ?? user.id;
    final String label = _firstNonBlank([
          user.displayedName,
          user.userProfile?.email,
          user.userProfile?.phoneNumber,
          user.userProfile?.fullName,
          user.userProfile?.username,
        ]) ??
        '';
    return RosterRow(
      key: assignment ?? label,
      assignmentId: assignment,
      label: label,
      contact: user.userProfile == null
          ? null
          : (Contact()
            ..email = user.userProfile!.email
            ..phoneNumber = user.userProfile!.phoneNumber),
      rsvp: user.rsvpStatus,
      completion: user.completionPercentage,
    );
  }

  /// The ways this row can be recognised, normalised: its label, email and
  /// phone - to catch someone added twice.
  Set<String> get identities => <String>{
        for (final String? v in [label, contact?.email, contact?.phoneNumber])
          if (v != null && v.trim().isNotEmpty) normalise(v),
      };

  static String normalise(String value) => value.trim().toLowerCase();

  static String? _firstNonBlank(Iterable<String?> values) {
    for (final String? v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  RosterRow copyWith({
    RecipientDelivery? delivery,
    String? deliveryChannel,
    RosterRowPhase? phase,
    String? failureReason,
    bool clearFailure = false,
  }) =>
      RosterRow(
        key: key,
        assignmentId: assignmentId,
        label: label,
        contact: contact,
        rsvp: rsvp,
        completion: completion,
        delivery: delivery ?? this.delivery,
        deliveryChannel: deliveryChannel ?? this.deliveryChannel,
        phase: phase ?? this.phase,
        failureReason: clearFailure ? null : (failureReason ?? this.failureReason),
      );

  @override
  List<Object?> get props => [
        key,
        assignmentId,
        label,
        contact?.email,
        contact?.phoneNumber,
        rsvp,
        completion,
        delivery,
        deliveryChannel,
        phase,
        failureReason,
      ];
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
