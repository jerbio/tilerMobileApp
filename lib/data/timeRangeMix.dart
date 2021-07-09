abstract class TimeRange {
  double? start;
  double? end;

  bool isInterfering(TimeRange timeRange) {
    bool retValue = false;
    if (this.start != null &&
        this.end != null &&
        timeRange.start != null &&
        timeRange.end != null) {
      retValue = this.end! > timeRange.start! && timeRange.end! > this.start!;
    }

    return retValue;
  }
}
