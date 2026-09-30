import 'package:tiler_app/data/tileShareAttention.dart';

/// The chips above the Attention list (redesign T7).
enum AttentionFilter {
  all,
  invitations,
  changes,
  atRisk,

  /// What people did with my shares: declined, completed, or an invitation
  /// that could not be sent.
  responses;

  bool matches(AttentionItem item) {
    switch (this) {
      case AttentionFilter.all:
        return true;
      case AttentionFilter.invitations:
        return item.type == AttentionType.invitation;
      case AttentionFilter.changes:
        return item.type == AttentionType.changed;
      case AttentionFilter.atRisk:
        return item.type == AttentionType.atRisk;
      case AttentionFilter.responses:
        return item.type == AttentionType.declined ||
            item.type == AttentionType.completed ||
            item.type == AttentionType.deliveryFailed;
    }
  }

  /// The items this chip shows, in their existing order.
  List<AttentionItem> apply(List<AttentionItem> items) =>
      this == AttentionFilter.all
          ? items
          : items.where(matches).toList(growable: false);

  /// How many items each chip holds (zero included).
  static Map<AttentionFilter, int> counts(List<AttentionItem> items) => {
        for (final AttentionFilter filter in AttentionFilter.values)
          filter: items.where(filter.matches).length,
      };
}

/// Whether a card opens the owner's view of its cluster (people acted on MY
/// share) rather than the recipient's (I was invited / affected). Until the
/// unified detail screens (Step 9.12) this picks between the two existing
/// detail screens.
bool attentionOpensOutbox(AttentionItem item) {
  switch (item.type) {
    case AttentionType.declined:
    case AttentionType.completed:
    case AttentionType.deliveryFailed:
      return true;
    case AttentionType.invitation:
    case AttentionType.atRisk:
    case AttentionType.changed:
      return false;
  }
}
