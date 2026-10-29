import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

import 'onBoardingSubWidget.dart';
import 'professionTaskPreviews.dart';

class ProfessionWidget extends StatefulWidget {
  const ProfessionWidget({Key? key}) : super(key: key);

  @override
  State<ProfessionWidget> createState() => _ProfessionWidgetState();
}

class _ProfessionWidgetState extends State<ProfessionWidget> {
  late TextEditingController customController;
  final GlobalKey _otherFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    customController = TextEditingController(
      text: state.isCustomProfession && state.profession != 'Other'
          ? state.profession
          : null,
    );
  }

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  void _scrollToOtherField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _otherFieldKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;
    final localizations = AppLocalizations.of(context)!;
    final professions = [
      (
        value: 'Medical Professional',
        label: localizations.medicalProfessional,
        preview: 'medical'
      ),
      (
        value: 'Software Developer',
        label: localizations.softwareDeveloper,
        preview: 'software'
      ),
      (value: 'Student', label: localizations.student, preview: 'student'),
      (value: 'Engineer', label: localizations.engineer, preview: 'engineer'),
      (
        value: 'Field Sales Professional',
        label: localizations.fieldSalesProfessional,
        preview: 'sales',
      ),
      (
        value: 'Remote Worker & Digital Nomad',
        label: localizations.remoteWorker,
        preview: 'remote',
      ),
      (
        value: 'Stay At Home Parent',
        label: localizations.stayAtHomeParent,
        preview: 'parent'
      ),
      (
        value: 'Client/Account Managers',
        label: localizations.clientAccountManagers,
        preview: 'account',
      ),
      (value: 'Other', label: localizations.other, preview: 'other'),
    ];
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isOtherSelected = state.isCustomProfession ||
            state.profession == 'Other' ||
            (state.profession?.isNotEmpty == true &&
                !professions.any((option) => option.value == state.profession));

        return OnboardingSubWidget(
          title: localizations.yourProfession,
          questionText: localizations.yourProfessionQuestion,
          questionExplanation: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              localizations.professionAiExplanation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          child: ProfessionTaskPreviews(
            previews: professions
                .map((profession) =>
                    localizations.professionTaskPreview(profession.preview))
                .toList(),
            children: [
              ...professions.map((profession) {
                final isOther = profession.value == 'Other';
                final isChecked = isOther
                    ? isOtherSelected
                    : state.profession == profession.value && !isOtherSelected;
                return _ProfessionOption(
                  key: ValueKey('profession_${profession.value}'),
                  isChecked: isChecked,
                  text: profession.label,
                  onTap: () {
                    context.read<OnboardingBloc>().add(SelectProfessionEvent(
                        profession: isOther && customController.text.isNotEmpty
                            ? customController.text
                            : profession.value,
                        isCustom: isOther));
                    if (isOther) {
                      _scrollToOtherField();
                    }
                  },
                );
              }).toList(),
            ],
            footer: isOtherSelected
                ? Padding(
                    key: _otherFieldKey,
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: customController,
                      textAlign: TextAlign.left,
                      onChanged: (value) {
                        context.read<OnboardingBloc>().add(
                            SelectProfessionEvent(
                                profession: value, isCustom: true));
                      },
                      style: const TextStyle(fontSize: 16),
                      decoration: TileDecorations.onboardingInputDecoration(
                        tileThemeExtension.onSurfaceVariantSecondary,
                        colorScheme.tertiary,
                        localizations.yourProfessionHint,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _ProfessionOption extends StatelessWidget {
  final bool isChecked;
  final String text;
  final VoidCallback onTap;

  const _ProfessionOption({
    required super.key,
    required this.isChecked,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      checked: isChecked,
      inMutuallyExclusiveGroup: true,
      label: text,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isChecked ? colors.primary : colors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
