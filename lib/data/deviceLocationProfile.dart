import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/permissionProfile.dart';

part 'deviceLocationProfile.g.dart';

@JsonSerializable(explicitToJson: true)
class DeviceLocationProfile {
  bool? isLoaded = false;
  Location? location;
  DateTime? lastTimeLoaded;
  PermissionProfile? permission;
  DeviceLocationProfile();

  factory DeviceLocationProfile.fromJson(Map<String, dynamic> json) =>
      _$DeviceLocationProfileFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceLocationProfileToJson(this);
}
