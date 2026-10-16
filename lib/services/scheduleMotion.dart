import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';

export 'package:tiler_app/services/scheduleMotionPreferences.dart'
    show ScheduleUpdateMode, ScheduleUpdateModeMotion;

/// The one place that decides how much motion a schedule change gets.
/// Widgets ask this instead of reading
/// `MediaQuery.disableAnimations` or the setting themselves.
abstract final class ScheduleMotion {
  /// The effective mode: the lowest of the user's [setting], the OS
  /// reduced-motion cap (Off) and the change-origin cap (a background
  /// refresh never gets more than Minimal).
  static ScheduleUpdateMode effective({
    required ScheduleUpdateMode setting,
    required bool reduceMotion,
    ScheduleChangeOrigin? origin,
  }) {
    var mode = setting;
    if (reduceMotion) mode = mode.capAt(ScheduleUpdateMode.off);
    if (origin == ScheduleChangeOrigin.refresh) {
      mode = mode.capAt(ScheduleUpdateMode.minimal);
    }
    return mode;
  }

  /// The effective mode in [context]. Pass [origin] once the change is
  /// attributed; without it only the setting and OS caps apply.
  ///
  /// [listen] subscribes the caller to setting changes; use it from
  /// `build`, and pass `false` from callbacks. Without a
  /// [ScheduleMotionCubit] above (isolated tests, previews) the setting is
  /// its default, Detailed.
  static ScheduleUpdateMode modeFor(
    BuildContext context, {
    ScheduleChangeOrigin? origin,
    bool listen = true,
  }) {
    return effective(
      setting: _setting(context, listen),
      reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      origin: origin,
    );
  }

  static ScheduleUpdateMode _setting(BuildContext context, bool listen) {
    try {
      return listen
          ? context.watch<ScheduleMotionCubit>().state
          : context.read<ScheduleMotionCubit>().state;
    } on ProviderNotFoundException {
      return ScheduleMotionPreferences.defaultMode;
    }
  }
}
