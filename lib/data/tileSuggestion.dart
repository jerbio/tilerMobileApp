class TileSuggestion {
  String? id;
  String? tileName;
  String? description;
  String? category;
  int? durationInMs;
  String? repetitionFrequency;
  int? priority;
  int? estimatedDurationMinutes;
  String? recurrencePattern;
  List<String>? tags;
  String? locationAddress;
  String? locationDescription;
  bool? isActive;

  TileSuggestion({
    this.id,
    this.tileName,
    this.description,
    this.category,
    this.durationInMs,
    this.repetitionFrequency,
    this.priority,
    this.estimatedDurationMinutes,
    this.recurrencePattern,
    this.tags,
    this.locationAddress,
    this.locationDescription,
    this.isActive,
  });

  factory TileSuggestion.fromJson(Map<String, dynamic> json) {
    return TileSuggestion(
      id: json['Id'],
      tileName: json['TileName'],
      description: json['Description'],
      category: json['Category'],
      durationInMs: json['DurationInMs'],
      repetitionFrequency: json['RepetitionFrequency'],
      priority: json['Priority'],
      estimatedDurationMinutes: json['EstimatedDurationMinutes'],
      recurrencePattern: json['RecurrencePattern'],
      tags: json['Tags'] != null ? List<String>.from(json['Tags']) : [],
      locationAddress: json['LocationAddress'],
      locationDescription: json['LocationDescription'],
      isActive: json['IsActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'TileName': tileName,
      'Description': description,
      'Category': category,
      'DurationInMs': durationInMs,
      'RepetitionFrequency': repetitionFrequency,
      'Priority': priority,
      'EstimatedDurationMinutes': estimatedDurationMinutes,
      'RecurrencePattern': recurrencePattern,
      'Tags': tags,
      'LocationAddress': locationAddress,
      'LocationDescription': locationDescription,
      'IsActive': isActive,
    };
  }
}