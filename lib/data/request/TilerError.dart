import 'package:json_annotation/json_annotation.dart';
part 'TilerError.g.dart';

@JsonSerializable()
class TilerError {
  static const String unexpectedCharacter = 'Unexpected character';
  String? Message;
  String? Code;

  /// Original local error, retained for lifecycle decisions, never sent on wire.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Object? cause;
  TilerError({this.Message, this.Code, this.cause});

  factory TilerError.fromJson(Map<String, dynamic> json) =>
      _$TilerErrorFromJson({
        ...json,
        if (json['Code'] is num) 'Code': json['Code'].toString(),
      });

  Map<String, dynamic> toJson() => _$TilerErrorToJson(this);
  static bool isUnexpectedCharacter(e) {
    return e != null &&
        (e is FormatException) &&
        (e).message == TilerError.unexpectedCharacter;
  }
}
