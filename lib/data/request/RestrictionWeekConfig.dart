import 'package:json_annotation/json_annotation.dart';

part 'RestrictionWeekConfig.g.dart';

@JsonSerializable(explicitToJson: true)
class RestrictionWeekConfig {
  List<RestrictionWeekDayConfig>? WeekDayOption;
  String isEnabled = 'false';
  String timeZone = 'utc';
  RestrictionWeekConfig();

  factory RestrictionWeekConfig.fromJson(Map<String, dynamic> json) =>
      _$RestrictionWeekConfigFromJson(json);

  toJson() => _$RestrictionWeekConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RestrictionWeekDayConfig {
  String? Start;
  String? Index;
  String? End;
  RestrictionWeekDayConfig();
  factory RestrictionWeekDayConfig.fromJson(Map<String, dynamic> json) =>
      _$RestrictionWeekDayConfigFromJson(json);

  toJson() => _$RestrictionWeekDayConfigToJson(this);
}
