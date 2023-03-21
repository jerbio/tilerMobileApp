import 'package:json_annotation/json_annotation.dart';
part 'TilerError.g.dart';

@JsonSerializable()
class TilerError {
  String? message;
  String? Code;
  TilerError({this.message});

  factory TilerError.fromJson(Map<String, dynamic> json) =>
      _$TilerErrorFromJson(json);

  Map<String, dynamic> toJson() => _$TilerErrorToJson(this);
}
