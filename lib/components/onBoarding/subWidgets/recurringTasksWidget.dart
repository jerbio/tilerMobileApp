import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'onBoardingPillTag.dart';
import 'onBoardingSubWidget.dart';

class RecurringTasksWidget extends StatefulWidget {
  @override
  _RecurringTasksWidgetState createState() => _RecurringTasksWidgetState();
}
class _RecurringTasksWidgetState extends State<RecurringTasksWidget> {
  TextEditingController taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    taskController = TextEditingController();
  }

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;
    final localizations=AppLocalizations.of(context)!;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return OnboardingSubWidget(
          title:localizations.recurringTasks ,
          questionText: localizations.recurringTasksQuestion,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: taskController,
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
                      decoration:TileDecorations.onboardingInputDecoration(
                          tileThemeExtension.onSurfaceVariantSecondary,
                          colorScheme.tertiary,
                          localizations.grabACoffee ,

                      )
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (taskController.text.trim().isNotEmpty) {
                        context.read<OnboardingBloc>().add(AddRecurringTaskEvent(taskController.text.trim()));
                        taskController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: Text(localizations.addPlus, style: TextStyle(color: colorScheme.onPrimary, fontSize: 16)),
                  ),
                ],
              ),
              SizedBox(height: 16),

              if (state.recurringTasks != null && state.recurringTasks!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: (state.recurringTasks!.toList()
                    ..sort((a, b) => (a.name?.length ?? 0).compareTo(b.name?.length ?? 0)))
                      .asMap()
                      .entries
                      .map((entry) {
                    int originalIndex = state.recurringTasks!.indexOf(entry.value);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: OnboardingPillTag(
                        text: entry.value.name ?? "",
                        onDelete: () {
                          context.read<OnboardingBloc>().add(RemoveRecurringTaskEvent(originalIndex));
                        },
                      ),
                    );
                  }).toList(),
                )
            ],
          ),
        );
      },
    );
  }
}