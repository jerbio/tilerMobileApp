import 'package:bloc/bloc.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/util.dart';

/// C9: the user's Daily-view layout choice (list or grid), restored from
/// [DayGridPreferences] on construction and persisted on every toggle.
///
/// Logging (step 1.5): restore logs stored-vs-default; every toggle emits
/// the `daygrid_layout_toggled` analytics tag with the new layout and the
/// day index the toggle happened on.
class DailyViewLayoutCubit extends Cubit<DailyViewLayout> {
  DailyViewLayoutCubit() : super(DailyViewLayout.list) {
    _restore();
  }

  Future<void> _restore() async {
    final layout = await DayGridPreferences.getLayout();
    final restored = layout != state;
    if (restored) {
      emit(layout);
    }
    Utility.debugPrint('DayGrid:: restore layout: ${layout.name} '
        '(source: ${restored ? 'stored' : 'default'})');
  }

  /// Toggles list <-> grid, persists the choice, and logs the event.
  /// [dayIndex] is the day the user was viewing (analytics context).
  Future<void> toggle({int? dayIndex}) async {
    final next = state == DailyViewLayout.list
        ? DailyViewLayout.grid
        : DailyViewLayout.list;
    emit(next);
    await DayGridPreferences.setLayout(next);
    Utility.debugPrint(
        'DayGrid:: layout toggled -> ${next.name} (dayIndex: $dayIndex)');
    await AnalysticsSignal.send('daygrid_layout_toggled',
        additionalInfo: {'to': next.name, 'dayIndex': dayIndex});
  }
}
