import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

export 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart'
    show ScheduleChangeOrigin;

/// A schedule change a screen is about to make, recorded so the revision it
/// produces shows as that change (moved tiles step into place, with the
/// "Plan updated" chip) rather than as a background refresh.
///
/// Begin it before the request; [abandon] it if the request fails; name
/// the tile it is about with [attachSubject] once known (e.g. a new tile's
/// id). The bloc is captured up front, so both work after an `await` even
/// if the screen has gone.
class PendingScheduleChange {
  final ScheduleBloc _bloc;
  final int _token;

  PendingScheduleChange._(this._bloc, this._token);

  /// Records the change; null when there is no [ScheduleBloc] above
  /// [context] (isolated screens in tests).
  static PendingScheduleChange? begin(
      BuildContext context, ScheduleChangeOrigin origin,
      {String? subjectId}) {
    try {
      final bloc = context.read<ScheduleBloc>();
      return PendingScheduleChange._(
          bloc, bloc.beginChange(origin, subjectId: subjectId));
    } on ProviderNotFoundException {
      return null;
    }
  }

  void attachSubject(String subjectId) =>
      _bloc.attachChangeSubject(_token, subjectId);

  void abandon() => _bloc.abandonChange(_token);
}
