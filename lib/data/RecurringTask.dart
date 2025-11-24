class RecurringTask {
  String? name;
  String? frequency;
  int? durationInMs;

  RecurringTask({this.name, this.frequency, this.durationInMs});

  factory RecurringTask.fromJson(Map<String, dynamic> json) {
    return RecurringTask(
      name: json['Name'],
      frequency: json['Frequency'],
      durationInMs: json['DurationInMs'],
    );
  }

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Frequency': frequency,
    'DurationInMs': durationInMs,
  };
}