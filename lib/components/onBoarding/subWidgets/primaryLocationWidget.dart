import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/data/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'onBoardingSubWidget.dart';

class PrimaryLocationWidget extends StatefulWidget {
  @override
  _PrimaryLocationWidgetState createState() => _PrimaryLocationWidgetState();
}

class _PrimaryLocationWidgetState extends State<PrimaryLocationWidget> {
  TextEditingController? locationAddressController;
  onAutoSuggestedLocationTap({Location? location, bool onlyAddress = false}) {
    locationAddressController!.text = location!.address ?? '';
    context.read<OnboardingBloc>().add(LocationSelected(location));
  }

  @override
  void initState() {
    super.initState();
    locationAddressController = TextEditingController();
    locationAddressController!.addListener(() {
      if (mounted) {
        context
            .read<OnboardingBloc>()
            .add(AddressTextChanged(locationAddressController!.text));
      }
    });
  }

  @override
  void dispose() {
    locationAddressController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state.addressText != null &&
            state.addressText != locationAddressController!.text) {
          locationAddressController!.text = state.addressText!;
        }
        TextField addressTextField = TextField(
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            border: OutlineInputBorder(
              gapPadding: 40,
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: colorScheme.onSurfaceVariant),
            ),
            hintText: AppLocalizations.of(context)!.enterAddress,
            filled: true,
            isDense: true,
            fillColor: Colors.transparent,
          ),
          controller: locationAddressController,
        );
        Widget locationSearchWidget = Flexible(
          child: Material(
            child: LocationSearchWidget(
              includeDeviceLocation: false,
              onChanged: (address) {
                context.read<OnboardingBloc>().add(AddressTextChanged(address));
              },
              textField: addressTextField,
              onLocationSelection: onAutoSuggestedLocationTap,
              // includeDeviceLocation: false,
            ),
          ),
        );

        return OnboardingSubWidget(
          questionText: AppLocalizations.of(context)!.primaryLocationQuestion,
          child: locationSearchWidget,
        );
      },
    );
  }
}
