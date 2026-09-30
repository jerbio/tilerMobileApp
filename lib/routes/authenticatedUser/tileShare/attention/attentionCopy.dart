import 'package:intl/intl.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';

/// The words on an Attention card. Pure functions of the item and the locale,
/// so the wording rules live in one place and read off the item — never off
/// the widget tree.
abstract final class AttentionCopy {
  static String _date(DateTime value, String locale) =>
      DateFormat.MMMd(locale).format(value.toLocal());

  static String title(AttentionItem item) =>
      item.clusterTitle ?? item.taskTitle ?? '';

  /// The one line saying why this needs attention.
  static String reason(AppLocalizations l10n, AttentionItem item, String locale) {
    final String actor = item.actorName ?? l10n.attentionSomeone;
    switch (item.type) {
      case AttentionType.invitation:
        final String inviter = item.inviterName ?? l10n.attentionSomeone;
        return item.count > 1
            ? l10n.attentionReasonInvitedMany(inviter, item.count)
            : l10n.attentionReasonInvited(inviter);
      case AttentionType.atRisk:
        if (item.count > 1) return l10n.attentionReasonAtRiskMany(item.count);
        return item.taskTitle != null
            ? l10n.attentionReasonAtRiskOne(item.taskTitle!)
            : l10n.attentionReasonAtRiskUntitled;
      case AttentionType.changed:
        if (item.count > 1) {
          return l10n.attentionReasonManyChanges(actor, item.count);
        }
        if (item.changedFields.length == 1) {
          switch (item.changedFields.single) {
            case 'deadline':
              if (item.deadlineBefore != null && item.deadlineAfter != null) {
                return l10n.attentionReasonDeadlineMoved(
                    actor,
                    _date(item.deadlineBefore!, locale),
                    _date(item.deadlineAfter!, locale));
              }
              return l10n.attentionReasonDeadlineChanged(actor);
            case 'name':
              return l10n.attentionReasonRenamed(actor);
            case 'note':
              return l10n.attentionReasonNotesUpdated(actor);
          }
        }
        return l10n.attentionReasonUpdated(actor);
      case AttentionType.declined:
        return item.count > 1
            ? l10n.attentionReasonDeclinedMany(item.count)
            : l10n.attentionReasonDeclined(actor);
      case AttentionType.deliveryFailed:
        if (item.count > 1) return l10n.attentionReasonNotSentMany(item.count);
        return item.hasUnknownOutcome
            ? l10n.attentionReasonSendUnknown
            : l10n.attentionReasonNotSent;
      case AttentionType.completed:
        if (item.count > 1) return l10n.attentionReasonCompletedMany(item.count);
        return item.taskTitle != null
            ? l10n.attentionReasonCompleted(actor, item.taskTitle!)
            : l10n.attentionReasonCompletedUntitled(actor);
    }
  }

  /// "Class · 3 tasks · Due Oct 4" — the mode, how many tasks it covers and the
  /// deadline, each only when it is known and relevant; `null` when empty.
  static String? meta(AppLocalizations l10n, AttentionItem item, String locale) {
    final List<String> parts = <String>[];
    final String? mode = TileShareModeBadge.labelOf(l10n, item.mode);
    if (mode != null) parts.add(mode);
    final bool aboutTasks = item.type == AttentionType.invitation ||
        item.type == AttentionType.atRisk;
    if (aboutTasks) parts.add(l10n.attentionMetaTasks(item.count));
    if (aboutTasks && item.deadlineMs != null) {
      parts.add(l10n.attentionMetaDue(
          _date(DateTime.fromMillisecondsSinceEpoch(item.deadlineMs!), locale)));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String pill(AppLocalizations l10n, AttentionType type) {
    switch (type) {
      case AttentionType.invitation:
        return l10n.attentionPillInvitation;
      case AttentionType.atRisk:
        return l10n.attentionPillAtRisk;
      case AttentionType.declined:
        return l10n.attentionPillDeclined;
      case AttentionType.deliveryFailed:
        return l10n.attentionPillNotSent;
      case AttentionType.changed:
        return l10n.attentionPillChanged;
      case AttentionType.completed:
        return l10n.attentionPillCompleted;
    }
  }

  static StatusPillTone tone(AttentionType type) {
    switch (type) {
      case AttentionType.invitation:
        return StatusPillTone.primary;
      case AttentionType.atRisk:
        return StatusPillTone.warning;
      case AttentionType.declined:
      case AttentionType.deliveryFailed:
        return StatusPillTone.danger;
      case AttentionType.changed:
        return StatusPillTone.info;
      case AttentionType.completed:
        return StatusPillTone.success;
    }
  }

  /// The call to action at the foot of the card.
  static String cta(AppLocalizations l10n, AttentionType type) {
    switch (type) {
      case AttentionType.invitation:
        return l10n.attentionCtaReview;
      case AttentionType.atRisk:
        return l10n.attentionCtaReviewPlan;
      case AttentionType.changed:
        return l10n.attentionCtaReviewChanges;
      case AttentionType.declined:
      case AttentionType.deliveryFailed:
      case AttentionType.completed:
        return l10n.attentionCtaView;
    }
  }

  static String filterLabel(AppLocalizations l10n, String filterName) {
    switch (filterName) {
      case 'all':
        return l10n.attentionFilterAll;
      case 'invitations':
        return l10n.attentionFilterInvitations;
      case 'changes':
        return l10n.attentionFilterChanges;
      case 'atRisk':
        return l10n.attentionFilterAtRisk;
      default:
        return l10n.attentionFilterResponses;
    }
  }
}
