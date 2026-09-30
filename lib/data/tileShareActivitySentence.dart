import 'package:tiler_app/data/tileShareActivity.dart';

/// What an activity event says, before it is put into words (redesign T17).
/// The UI maps each kind to a localized ICU sentence (Step 9.28); keeping the
/// decision here makes it unit-testable without widgets or locales.
enum ActivitySentenceKind {
  clusterCreated,
  clusterDeleted,
  clusterInvitation,
  tiletteAdded,
  tiletteDeleted,
  tiletteRestored,
  tiletteDeadlineChanged,
  tiletteRenamed,
  tiletteNotesUpdated,
  tiletteUpdated,
  recipientAdded,
  recipientRemoved,
  recipientRestored,
  invitationSent,
  invitationSendFailed,
  invitationSendUnknown,
  assignmentAccepted,
  assignmentDeclined,
  assignmentCompleted,
  assignmentReopened,
  unknown,
}

/// Who did something / who it was done to.
class ActivityActor {
  /// The signed-in user ("You").
  final bool isMe;

  /// The person's display name when the server gave one.
  final String? name;

  const ActivityActor({this.isMe = false, this.name});

  /// Whether the UI can name them ("You" or a name) rather than say
  /// "Someone".
  bool get isKnown => isMe || (name != null && name!.trim().isNotEmpty);
}

/// The lookups a sentence needs from the surrounding screen.
class ActivityContext {
  final String? currentUserId;

  /// Resolves a task id to its title (e.g. from the loaded tilettes).
  final String? Function(String? tiletteId)? titleOfTilette;

  /// Resolves a user id to a display name (e.g. from the participants).
  final String? Function(String? userId)? nameOfUser;

  const ActivityContext({
    this.currentUserId,
    this.titleOfTilette,
    this.nameOfUser,
  });
}

class ActivitySentence {
  final ActivitySentenceKind kind;
  final ActivityActor actor;

  /// The affected participant of a recipient event; `null` otherwise.
  final ActivityActor? subject;
  final String? taskTitle;
  final String? clusterTitle;

  /// For [ActivitySentenceKind.tiletteDeadlineChanged].
  final DateTime? deadlineBefore;
  final DateTime? deadlineAfter;

  /// For the invitation delivery events: `email`, `sms` or `push`.
  final String? channel;

  const ActivitySentence({
    required this.kind,
    required this.actor,
    this.subject,
    this.taskTitle,
    this.clusterTitle,
    this.deadlineBefore,
    this.deadlineAfter,
    this.channel,
  });

  static const Set<String> _recipientTypes = {
    'cluster_invitation',
    'recipient_added',
    'recipient_removed',
    'recipient_restored',
  };

  static ActivitySentence of(
    TileShareActivity event, {
    ActivityContext context = const ActivityContext(),
  }) {
    final String? me = context.currentUserId;
    final ActivityActor actor = ActivityActor(
      isMe: me != null && event.actorId == me,
      name: event.actorName,
    );

    ActivityActor? subject;
    if (_recipientTypes.contains(event.eventType) &&
        event.targetUserId != null) {
      subject = ActivityActor(
        isMe: me != null && event.targetUserId == me,
        name: context.nameOfUser?.call(event.targetUserId),
      );
    }

    final ActivitySentenceKind kind = _kindOf(event);
    return ActivitySentence(
      kind: kind,
      actor: actor,
      subject: subject,
      taskTitle: event.title ??
          event.tiletteTitle ??
          context.titleOfTilette?.call(event.tiletteId),
      clusterTitle: event.clusterTitle,
      deadlineBefore: kind == ActivitySentenceKind.tiletteDeadlineChanged
          ? event.deadlineBefore
          : null,
      deadlineAfter: kind == ActivitySentenceKind.tiletteDeadlineChanged
          ? event.deadlineAfter
          : null,
      channel: event.invitationChannel,
    );
  }

  static ActivitySentenceKind _kindOf(TileShareActivity event) {
    if (!event.isKnown) return ActivitySentenceKind.unknown;
    switch (event.eventType) {
      case 'cluster_created':
        return ActivitySentenceKind.clusterCreated;
      case 'cluster_deleted':
        return ActivitySentenceKind.clusterDeleted;
      case 'cluster_invitation':
        return ActivitySentenceKind.clusterInvitation;
      case 'tilette_added':
        return ActivitySentenceKind.tiletteAdded;
      case 'tilette_deleted':
        return ActivitySentenceKind.tiletteDeleted;
      case 'tilette_restored':
        return ActivitySentenceKind.tiletteRestored;
      case 'tilette_edited':
        return _editKind(event.changedFields);
      case 'recipient_added':
        return ActivitySentenceKind.recipientAdded;
      case 'recipient_removed':
        return ActivitySentenceKind.recipientRemoved;
      case 'recipient_restored':
        return ActivitySentenceKind.recipientRestored;
      case 'invitation_sent':
        return ActivitySentenceKind.invitationSent;
      case 'invitation_send_failed':
        return ActivitySentenceKind.invitationSendFailed;
      case 'invitation_send_unknown':
        return ActivitySentenceKind.invitationSendUnknown;
      case 'assignment_accepted':
        return ActivitySentenceKind.assignmentAccepted;
      case 'assignment_declined':
        return ActivitySentenceKind.assignmentDeclined;
      case 'assignment_completed':
        return ActivitySentenceKind.assignmentCompleted;
      case 'assignment_reopened':
        return ActivitySentenceKind.assignmentReopened;
    }
    return ActivitySentenceKind.unknown;
  }

  static ActivitySentenceKind _editKind(List<String> fields) {
    if (fields.length == 1) {
      switch (fields.single) {
        case 'deadline':
          return ActivitySentenceKind.tiletteDeadlineChanged;
        case 'name':
          return ActivitySentenceKind.tiletteRenamed;
        case 'note':
          return ActivitySentenceKind.tiletteNotesUpdated;
      }
    }
    return ActivitySentenceKind.tiletteUpdated;
  }
}
