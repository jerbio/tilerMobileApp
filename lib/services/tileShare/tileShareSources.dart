import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

// The data seams the TileShare cubits depend on (redesign T9). Each is a small
// interface over what a screen needs, not over an API class: the live adapters
// (liveTileShareSources.dart) delegate to the existing APIs, and tests inject
// in-memory fakes — the same pattern as `TileShareActivityWidget.loader`.
//
// A seam for editing a share (contacts, tilettes) is added with the step that
// first needs it.

/// The Clusters tab and cluster loading: what I created, what is shared with
/// me, a cluster's tilettes, and deleting a cluster.
abstract class TileShareClustersSource {
  /// One page of clusters: [isOutbox] `true` = created by me, `false` = shared
  /// with me.
  Future<List<TileShareClusterData>> clusters({
    required bool isOutbox,
    int index = 0,
    int pageSize = 50,
  });

  /// A single cluster; `null` when it does not exist or is not visible.
  Future<TileShareClusterData?> cluster(String clusterId);

  /// The cluster's tilettes, each with its assignments.
  Future<List<TileShareTemplate>> tilettes(String clusterId);

  Future<void> deleteCluster(String clusterId);
}

/// The signed-in user's own assignments and their responses.
abstract class TileShareAssignmentsSource {
  /// One page of my assignments, optionally scoped to a cluster.
  Future<List<DesignatedTile>> designatedTiles({
    String? clusterId,
    int index = 0,
    int pageSize = 50,
  });

  /// One designated tile template by id; `null` when it is not visible.
  Future<DesignatedTile?> designatedTile(String designatedTileId);

  /// Accepts or declines an assignment; returns the updated assignment.
  Future<DesignatedTile?> respond(
      String designatedTileId, InvitationStatus status);

  /// What must follow an acceptance so the new tiles appear: re-analyze the
  /// schedule, then refresh it.
  Future<void> afterAccept();
}

/// The accept preview (redesign T21): what accepting an assignment would do to
/// the user's schedule, other times for it, and accepting exactly what was
/// previewed.
abstract class TileSharePreviewSource {
  /// The forecast of accepting [assignmentId]; a viable one carries a token.
  Future<TileSharePreview> preview(String assignmentId);

  /// A page of alternative start times for one session of a previewed task;
  /// [offset] is the previous page's `nextOffset`.
  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  });

  /// The preview again with an option chosen (or a session locked), under a new
  /// token.
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  });

  /// Accepts exactly the previewed schedule, flexibly or locking one session
  /// (named by [sessionKey] and the [lockedTimeLine] the user was shown); the
  /// server finishes scheduling inside the call and answers with the operation,
  /// often already final. Sending the same [operationId] again - with the same
  /// [mode], [sessionKey] and [lockedTimeLine] - never accepts twice.
  Future<TileShareOperation> accept({
    required String assignmentId,
    required String previewToken,
    required String operationId,
    required TileShareAcceptanceMode mode,
    String? sessionKey,
    TileShareLockedTimeLine? lockedTimeLine,
  });

  /// The queued accept's current state; poll until it is final.
  Future<TileShareOperation> operation(String operationId);

  /// What a recipient can recover about an assignment, e.g. after the app was
  /// closed mid-accept.
  Future<TileShareAssignmentResponse> response(String assignmentId);

  /// A fresh id for one accept (32 lower-case hex characters).
  String newOperationId();
}

/// What the Attention inbox reads: my pending invitations, the activity feed
/// and the per-event dismissal.
abstract class TileShareAttentionSources {
  /// One page of my pending invitations; pass the previous page's
  /// `nextCursor` as [afterId] to continue.
  Future<TileShareInvitationPage> invitations({
    String? afterId,
    int pageSize = 50,
  });

  /// One page of the activity feed (events I have not dismissed), newest
  /// first; pass the previous page's `nextCursor` as [cursor] to continue.
  Future<TileShareActivityPage> activity({
    String? cursor,
    int pageSize = 50,
  });

  /// Dismisses ([isDismissed] `true`) or restores one activity event. Stored
  /// server-side, so it follows the user across devices.
  Future<void> setDismissed(String eventId, bool isDismissed);
}

/// A tilette's recipients, as its owner manages them (redesign Step 9.13).
abstract class TileShareRecipientsSource {
  /// Invites [contact] to the tilette; answers with the tilette and its
  /// recipients.
  Future<TileShareTemplate> addRecipient(String tiletteId, Contact contact);

  /// Removes one recipient's assignment from the tilette.
  Future<void> removeRecipient(String tiletteId, String assignmentId);

  /// The cluster's recent activity, newest first - where each recipient's
  /// invitation delivery is read from.
  Future<List<TileShareActivity>> clusterActivity(String clusterId);
}

/// The owner's changes to a share and its tasks (redesign Step 9.16b). Only
/// what is given changes. A task's length cannot change once it is shared.
abstract class TileShareEditSource {
  /// Renames the share or moves its deadline.
  Future<void> updateShare(String clusterId, {String? name, int? endMs});

  /// Adds a task to the share ([task] carries its name, length, deadline and
  /// the people it is sent to).
  Future<void> addTask(String clusterId, ClusterTemplateTileModel task);

  /// Renames a task or moves its deadline.
  Future<void> updateTask(String tiletteId, {String? name, int? endMs});

  /// Deletes a task and its assignments.
  Future<void> deleteTask(String tiletteId);
}
