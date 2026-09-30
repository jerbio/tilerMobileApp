import 'package:tiler_app/data/tileShareClusterData.dart';

/// How a TileShare cluster is shared (redesign T2).
///
/// * [broadcast] — every recipient has their own instance of **a task**.
/// * [class_] — every recipient has their own instance of **a project**
///   (a multi-task copy each).
/// * [project] — everyone **shares one project**; tasks are worked by /
///   assigned to people.
///
/// The backend stores this as the cluster `Mode` (request key `Mode`,
/// lower-case values `broadcast` / `class` / `project`).
enum TileShareMode {
  broadcast,
  project,
  class_;

  /// The lower-case wire value the backend uses.
  String get wire => switch (this) {
        TileShareMode.broadcast => 'broadcast',
        TileShareMode.project => 'project',
        TileShareMode.class_ => 'class',
      };

  /// Parses a wire value (any casing, surrounding whitespace ignored).
  /// Anything that is not one of the three modes is `null` — never a guess
  /// and never a throw.
  static TileShareMode? tryParse(Object? raw) {
    if (raw is! String) return null;
    switch (raw.trim().toLowerCase()) {
      case 'broadcast':
        return TileShareMode.broadcast;
      case 'project':
        return TileShareMode.project;
      case 'class':
        return TileShareMode.class_;
    }
    return null;
  }

  /// The mode to use for [cluster]: the backend value when present, else the
  /// legacy `isMultiTilette` flag (single → broadcast, multi → project). The
  /// legacy flag cannot express Class, so a cluster without a backend mode is
  /// never resolved to [class_].
  static TileShareMode fromCluster(TileShareClusterData cluster) =>
      cluster.mode ??
      (cluster.isMultiTilette == true
          ? TileShareMode.project
          : TileShareMode.broadcast);
}
