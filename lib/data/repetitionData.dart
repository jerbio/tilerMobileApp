import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/util.dart';

class RepetitionData {
  RepetitionFrequency frequency;
  DateTime? repetitionEnd;
  bool isAutoRepetitionEnd = false;
  Set<int>? weeklyRepetition = Set();
  RepetitionData(
      {required this.frequency, this.repetitionEnd, this.weeklyRepetition}) {
    if (this.repetitionEnd == null) {
      this.repetitionEnd = Utility.currentTime().add(Duration(days: 180));
      isAutoRepetitionEnd = true;
      if (this.frequency == RepetitionFrequency.yearly) {
        this.repetitionEnd = Utility.currentTime().add(Duration(days: 3650));
        isAutoRepetitionEnd = true;
      }
    }

    if (weeklyRepetition == null) {
      weeklyRepetition = Set();
    }
  }

  RepetitionData clone() {
    RepetitionData retValue = RepetitionData(frequency: this.frequency);
    retValue.isAutoRepetitionEnd = this.isAutoRepetitionEnd;
    retValue.repetitionEnd = this.repetitionEnd;
    if (this.weeklyRepetition != null) {
      retValue.weeklyRepetition = Set.from(this.weeklyRepetition!);
    }

    return retValue;
  }
}
