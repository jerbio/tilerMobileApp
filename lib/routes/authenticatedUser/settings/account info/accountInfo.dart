import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountInfo extends StatelessWidget {
  static final String routeName = '/accountInfo';
  final String _requestId = Utility.getUuid;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final ValueNotifier<bool> _hasChangesNotifier = ValueNotifier<bool>(false);
  UserProfile? _originalProfile;
  AccountInfo({Key? key}) : super(key: key);

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteAccount),
          content:
              Text(AppLocalizations.of(context)!.deleteAccountConfirmation),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<DeviceSettingBloc>().add(
                    DeleteAccountMainSettingDeviceSettingEvent(
                        id: _requestId, context: dialogContext));
              },
            ),
          ],
        );
      },
    );
  }

  Widget renderPending() {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
        child: CircularProgressIndicator(),
        height: 200.0,
        width: 200.0,
      )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
  }

  String _displayRawDate(String? rawDate) {
    if (rawDate == null) return '';
    final datePart = rawDate.split(' ').first;
    final parts = datePart.split('/');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      return '$day/$month/${parts[2]}';
    }
    return datePart;
  }

  DateTime? _tryParseDate(String rawDate) {
    final formats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(rawDate);
      } catch (e) {
        debugPrint('Failed to parse with $format: $e');
      }
    }

    return null;
  }

  void _pickDate(BuildContext context, UserProfile? userProfile) async {
    DateTime initialDate = DateTime(2000);

    if (userProfile?.dateOfBirth != null) {
      final rawDate = userProfile!.dateOfBirth!;
      final datePart = rawDate.split(' ').first;
      final parsedDate = _tryParseDate(datePart);

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }
    initialDate =
        initialDate.isBefore(DateTime(1900)) ? DateTime(1900) : initialDate;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && context.mounted) {
      _dateOfBirthController.text =
          DateFormat.yMd(Localizations.localeOf(context).languageCode)
              .format(picked);
      context.read<DeviceSettingBloc>().add(
            UpdateUserProfileDateOfBirthSettingEvent(
              id: _requestId,
              dateOfBirth: picked,
            ),
          );
    }
  }

  Future<bool> _saveUserProfile(
      BuildContext context, UserProfile userProfile) async {
    userProfile.fullName = _fullNameController.text;
    if (userProfile.fullName.isNot_NullEmptyOrWhiteSpace()) {
      String fullName = userProfile.fullName!;
      fullName = fullName.trim();
      if (fullName.isNot_NullEmptyOrWhiteSpace()) {
        var names = fullName.split(' ');
        userProfile.firstName = names.first;
        userProfile.lastName = names.skip(1).join(' ');
      }
    }

    userProfile.username = _usernameController.text;
    userProfile.phoneNumber = _phoneNumberController.text;
    final completer = Completer<bool>();
    final subscription =
        context.read<DeviceSettingBloc>().stream.listen((state) {
      if (state is DeviceSettingSaved) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
      if (state is DeviceSettingError) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });
    context.read<DeviceSettingBloc>().add(
          UpdateUserProfileDeviceSettingEvent(
            id: _requestId,
          ),
        );
    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  Widget _buildContent(BuildContext context, DeviceSettingState state) {
    final userProfile = (state is DeviceSettingLoaded && state.id == _requestId)
        ? state.sessionProfile?.userProfile
        : null;
    if (state is DeviceUserProfileSettingLoading) {
      return renderPending();
    }
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTextField(
          AppLocalizations.of(context)!.fullName,
          controller: _fullNameController,
        ),
        _buildTextField(
          AppLocalizations.of(context)!.username,
          controller: _usernameController,
        ),
        _buildTextField(
          AppLocalizations.of(context)!.email,
          controller: TextEditingController(
              text: userProfile?.email ?? 'tiler@test.com'),
          enabled: false,
          filled: true,
        ),
        _buildTextField(
          AppLocalizations.of(context)!.phoneNumber,
          controller: _phoneNumberController,
        ),
        _buildTextField(
          AppLocalizations.of(context)!.dateOfBirth,
          controller: _dateOfBirthController,
          onTap: () => _pickDate(context, userProfile),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10),
          child: ListTile(
            leading: SvgPicture.asset(
              'assets/icons/settings/DeleteAccount.svg',
              colorFilter:
                  ColorFilter.mode(TileStyles.primaryColor, BlendMode.srcIn),
            ),
            title: Text(AppLocalizations.of(context)!.deleteAccount,
                style: TextStyle(color: TileStyles.primaryColor)),
            onTap: () => _showDeleteConfirmationDialog(context),
          ),
        )
      ],
    );
  }

  void _checkForChanges() {
    if (_originalProfile == null) return;

    bool hasChanges = _fullNameController.text !=
            (_originalProfile?.fullName ?? '') ||
        _usernameController.text != (_originalProfile?.username ?? '') ||
        _phoneNumberController.text != (_originalProfile?.phoneNumber ?? '') ||
        _dateOfBirthController.text !=
            _displayRawDate(_originalProfile?.dateOfBirth);

    _hasChangesNotifier.value = hasChanges;
  }

  void _setupControllerListeners(UserProfile userProfile) {
    _originalProfile = UserProfile()
      ..fullName = userProfile.fullName
      ..username = userProfile.username
      ..phoneNumber = userProfile.phoneNumber
      ..dateOfBirth = userProfile.dateOfBirth
      ..email = userProfile.email;

    _fullNameController.removeListener(_checkForChanges);
    _usernameController.removeListener(_checkForChanges);
    _phoneNumberController.removeListener(_checkForChanges);
    _dateOfBirthController.removeListener(_checkForChanges);

    _fullNameController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _phoneNumberController.addListener(_checkForChanges);
    _dateOfBirthController.addListener(_checkForChanges);

    _checkForChanges();
  }

  @override
  Widget build(BuildContext context) {
    NotificationOverlayMessage notificationOverlayMessage =
        NotificationOverlayMessage();
    context.read<DeviceSettingBloc>().add(
          GetUserProfileDeviceSettingEvent(
            id: _requestId,
          ),
        );

    return BlocListener<DeviceSettingBloc, DeviceSettingState>(
      listener: (context, state) {
        if (state is DeviceSettingLoaded && state.id == _requestId) {
          final userProfile = state.sessionProfile?.userProfile;
          if (userProfile != null) {
            _fullNameController.text = userProfile.fullName ?? '';
            _usernameController.text = userProfile.username ?? '';
            _phoneNumberController.text = userProfile.phoneNumber ?? '';
            _dateOfBirthController.text =
                _displayRawDate(userProfile.dateOfBirth);
            _setupControllerListeners(userProfile);
          }
        }
        if (state is DeviceSettingError) {
          final errorMessage = state.error is TilerError
              ? (state.error as TilerError).Message
              : state.error.toString();

          notificationOverlayMessage.showToast(
            context,
            errorMessage ?? 'Unknown Error',
            NotificationOverlayMessageType.error,
          );
        }
        if (state is DeviceSettingSaved) {
          notificationOverlayMessage.showToast(
            context,
            AppLocalizations.of(context)!.accountInfoUpdatedSuccessfully,
            NotificationOverlayMessageType.success,
          );
        }
      },
      child: BlocBuilder<DeviceSettingBloc, DeviceSettingState>(
        builder: (context, state) {
          return ValueListenableBuilder<bool>(
              valueListenable: _hasChangesNotifier,
              builder: (context, hasChanges, _) {
                return CancelAndProceedTemplateWidget(
                    onProceed: (state is DeviceSettingLoaded &&
                            state.id == _requestId &&
                            hasChanges)
                        ? () => _saveUserProfile(
                            context, state.sessionProfile!.userProfile!)
                        : null,
                    appBar: TileStyles.CancelAndProceedAppBar(
                      AppLocalizations.of(context)!.accountInfo,
                    ),
                    routeName: AccountInfo.routeName,
                    child: _buildContent(context, state));
              });
        },
      ),
    );
  }

  Widget _buildTextField(String label,
      {bool enabled = true,
      bool filled = false,
      VoidCallback? onTap,
      required TextEditingController? controller}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16, right: 20, left: 20),
      decoration: BoxDecoration(
        color: filled ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        readOnly: onTap != null,
        onTap: onTap,
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: filled,
          fillColor: filled ? Colors.grey[200] : Colors.white,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
