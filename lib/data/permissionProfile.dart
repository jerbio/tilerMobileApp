import 'package:json_annotation/json_annotation.dart';

part 'permissionProfile.g.dart';

@JsonSerializable(explicitToJson: true)
class PermissionProfile {
  DateTime? lastCheck;
  bool? isGranted = false;
  PermissionProfile();

  factory PermissionProfile.fromJson(Map<String, dynamic> json) =>
      _$PermissionProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionProfileToJson(this);
}
