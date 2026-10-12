import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';

/// The authenticated app session already holds the profile. Opening a share
/// must not fetch it again or delay the share requests behind a profile fetch.
String? tileShareSessionUserId(BuildContext context) {
  final String? id = context
      .read<DeviceSettingBloc?>()
      ?.sessionProfile
      .userProfile
      ?.id
      ?.trim();
  return id == null || id.isEmpty ? null : id;
}
