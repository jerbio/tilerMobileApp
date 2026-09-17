import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;
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
          decoration: TileDecorations.onboardingInputDecoration(
            tileThemeExtension.onSurfaceVariantSecondary,
            colorScheme.tertiary,
            AppLocalizations.of(context)!.enterAddress,
          ),
          controller: locationAddressController,
        );
        Widget locationSearchWidget = ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35),
          child: LocationSearchWidget(
            includeDeviceLocation: false,
            onChanged: (address) {
              context.read<OnboardingBloc>().add(AddressTextChanged(address));
            },
            textField: addressTextField,
            onLocationSelection: onAutoSuggestedLocationTap,
          ),
        );

        final localizations = AppLocalizations.of(context)!;

        // Stage 3.1: device-location consent is button-driven only —
        // swiping or Next must never trigger the permission flow.
        ElevatedButton deviceLocationButton = ElevatedButton(
          onPressed: () {
            context.read<OnboardingBloc>().add(GetTimeAndLocationEvent(true));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            localizations.useDeviceLocation,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

        return OnboardingSubWidget(
          questionText: localizations.primaryLocationQuestion,
          questionSubText: localizations.timeAndLocationSecondarySubTitle,
          child: Column(
            children: [
              locationSearchWidget,
              const SizedBox(height: 20.0),
              deviceLocationButton,
            ],
          ),
        );
      },
    );
  }
}
