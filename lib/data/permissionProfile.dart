import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/util.dart';

part 'permissionProfile.g.dart';

@JsonSerializable(explicitToJson: true)
class PermissionProfile {
  DateTime? lastCheck;
  bool? isGranted = false;
  PermissionProfile();
  PermissionProfile.deny() {
    isGranted = false;
    lastCheck = Utility.currentTime();
  }

  PermissionProfile.unknown() {
    isGranted = null;
    lastCheck = DateTime(0);
  }

  PermissionProfile.accept() {
    isGranted = true;
    lastCheck = Utility.currentTime();
  }

  factory PermissionProfile.fromJson(Map<String, dynamic> json) =>
      _$PermissionProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionProfileToJson(this);

  @override
  String toString() {
    return 'PermissionProfile{lastCheck: $lastCheck, isGranted: $isGranted}';
  }
}
