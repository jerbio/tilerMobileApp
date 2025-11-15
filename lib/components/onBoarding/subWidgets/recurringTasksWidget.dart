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
  late  AppLocalizations localizations;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    taskController.addListener(() => setState(() {}));

  }

  @override
  void didChangeDependencies() {
    localizations=  AppLocalizations.of(context)!;
    theme = Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    screenHeight= MediaQuery.of(context).size.height ;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: taskController.text.trim().isEmpty
                        ? null
                        :() {
                      if (taskController.text.trim().isNotEmpty) {
                        context.read<OnboardingBloc>().add(AddRecurringTaskEvent(taskController.text.trim()));
                        taskController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  taskController.text.trim().isEmpty
                          ? tileThemeExtension.disabledOnboardingPill : colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: Text(localizations.addPlus, style: TextStyle(color: colorScheme.onPrimary, fontSize: 16)),
                  ),
                ],
              ),
              SizedBox(height: 16),

              if (state.recurringTasks != null && state.recurringTasks!.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screenHeight*0.35),
                    child: SingleChildScrollView(
                      child: Column(
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
                      ),
                    ),
                  )
            ],
          ),
        );
      },
    );
  }
}