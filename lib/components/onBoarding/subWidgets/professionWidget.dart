import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'onBoardingSubWidget.dart';
class ProfessionWidget extends StatefulWidget {

  const ProfessionWidget({Key? key}) : super(key: key);

  @override
  State<ProfessionWidget> createState() => _ProfessionWidgetState();
}


class _ProfessionWidgetState extends State<ProfessionWidget> {
  late TextEditingController customController;

  @override
  void initState() {
    super.initState();
    customController = TextEditingController();
  }

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;
    final localizations=AppLocalizations.of(context)!;
    final List<String> professions =  [
      localizations.medicalProfessional,
      localizations.softwareDeveloper,
      localizations.student,
      localizations.engineer,
      localizations.fieldSalesProfessional,
      localizations.remoteWorker,
      localizations.stayAtHomeParent,
      localizations.clientAccountManagers,
      localizations.other,
    ];
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final predefinedProfessions = [
          'Medical Professional',
          'Software Developer',
          'Student',
          'Engineer',
          'Field Sales Professional',
          'Remote Worker & Digital Nomad',
          'Stay At Home Parent',
          'Client/Account Managers'
        ];

        bool isOtherSelected = state.profession != null &&
            state.profession!.isNotEmpty &&
            (state.profession == 'Other' ||
                !predefinedProfessions.contains(state.profession));



        return OnboardingSubWidget(
          title: localizations.yourProfession,
          questionText: localizations.yourProfessionQuestion,
          child: Column(
            children: [
              ...professions.map((profession) {
                bool isChecked = profession == 'Other'
                    ? isOtherSelected
                    : state.profession == profession;
                return TilerCheckBox(
                  isChecked: isChecked,
                  text: profession,
                  onChange: (checkboxState) {
                    context.read<OnboardingBloc>().add(
                        SelectProfessionEvent(
                            profession: profession,
                            isCustom: profession == 'Other'
                        )
                    );
                  },
                );
              }).toList(),

              if (isOtherSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: customController,
                    textAlign: TextAlign.left,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        context.read<OnboardingBloc>().add(
                            SelectProfessionEvent(
                                profession: value,
                                isCustom: true
                            )
                        );
                      }
                    },
                    style: const TextStyle(fontSize: 16),
                    decoration: TileDecorations.onboardingInputDecoration(
                      tileThemeExtension.onSurfaceVariantSecondary,
                      colorScheme.tertiary,
                      localizations.yourProfessionHint,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
