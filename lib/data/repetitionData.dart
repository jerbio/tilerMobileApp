import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/util.dart';

class RepetitionData {
  RepetitionFrequency frequency;
  DateTime? repetitionEnd;
  DateTime? repetitionStart;
  bool isForever = false;
  bool isEnabled = false;
  Set<int>? weeklyRepetition = Set();
  RepetitionData(
      {required this.frequency,
      this.repetitionStart,
      this.repetitionEnd,
      this.weeklyRepetition,
      this.isEnabled = false}) {
    if (this.repetitionEnd == null) {
      this.repetitionEnd = Utility.currentTime().add(Duration(days: 180));
      isForever = true;
      if (this.frequency == RepetitionFrequency.yearly) {
        this.repetitionEnd = Utility.currentTime().add(Duration(days: 3650));
        isForever = true;
      }
    }

    if (weeklyRepetition == null) {
      weeklyRepetition = Set();
    }
  }

  RepetitionData clone() {
    RepetitionData retValue = RepetitionData(frequency: this.frequency);
    retValue.isForever = this.isForever;
    retValue.repetitionStart = this.repetitionStart;
    retValue.isEnabled = this.isEnabled;
    retValue.isForever = this.isForever;
    if (this.weeklyRepetition != null) {
      retValue.weeklyRepetition = Set.from(this.weeklyRepetition!);
    }

    return retValue;
  }
}
