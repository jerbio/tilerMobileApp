import 'package:bloc/bloc.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';
import 'package:tiler_app/util.dart';

/// The user's "Schedule updates" setting (Off / Minimal / Detailed),
/// restored from [ScheduleMotionPreferences] on construction and persisted
/// on every change.
///
/// Read through `ScheduleMotion.modeFor`, never directly by widgets, so the
/// OS reduced-motion and change-origin caps always apply.
class ScheduleMotionCubit extends Cubit<ScheduleUpdateMode> {
  ScheduleMotionCubit() : super(ScheduleMotionPreferences.defaultMode) {
    _restore();
  }

  Future<void> _restore() async {
    final mode = await ScheduleMotionPreferences.getMode();
    final restored = mode != state;
    if (restored && !isClosed) {
      emit(mode);
    }
    Utility.debugPrint('ScheduleMotion:: restore mode: ${mode.name} '
        '(source: ${restored ? 'stored' : 'default'})');
  }

  /// Persists [mode] and logs the change. A no-op when it is already set.
  Future<void> setMode(ScheduleUpdateMode mode) async {
    final from = state;
    if (mode == from) return;
    emit(mode);
    await ScheduleMotionPreferences.setMode(mode);
    Utility.debugPrint(
        'ScheduleMotion:: mode changed ${from.name} -> ${mode.name}');
    await AnalysticsSignal.send('schedule_update_mode_changed',
        additionalInfo: {'from': from.name, 'to': mode.name});
  }
}
