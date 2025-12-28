import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingPillTag.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingSubWidget.dart';
import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/data/tileSuggestion.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class TileSuggestionsWidget extends StatefulWidget {
  @override
  _TileSuggestionsState createState() => _TileSuggestionsState();
}

class _TileSuggestionsState extends State<TileSuggestionsWidget>
    with SingleTickerProviderStateMixin {
  TextEditingController customTileController = TextEditingController();
  late AppLocalizations localizations;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late AnimationController _rotationController;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    customTileController.addListener(() => setState(() {}));
    context.read<OnboardingBloc>().add(FetchTileSuggestionsEvent());
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    customTileController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    localizations = AppLocalizations.of(context)!;
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    screenHeight = MediaQuery.of(context).size.height;
    super.didChangeDependencies();
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tileThemeExtension.suggestionLoadingOnboardingSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
            ),
          ),
          SizedBox(width: 12),
          Text(
            localizations.tileProfiling,
            style: TextStyle(fontSize: 12, color: TileColors.darkContent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.step == OnboardingStep.suggestionRefreshing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
          _rotationController.reset();
        }
      },
      builder: (context, state) {
        return OnboardingSubWidget(
          title: localizations.tileSuggestions,
          questionText: localizations.tileSuggestionsQuestion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.step == OnboardingStep.suggestionLoading ||
                  state.step == OnboardingStep.suggestionRefreshing) ...[
                _buildLoadingIndicator(),
                SizedBox(height: 16),
              ],
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customTileController,
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.w400),
                      decoration: TileDecorations.onboardingInputDecoration(
                          tileThemeExtension.onSurfaceVariantSecondary,
                          colorScheme.tertiary,
                          localizations.typeSomething),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: customTileController.text.trim().isEmpty
                        ? null
                        : () {
                            final customTile = TileSuggestion(
                              tileName: customTileController.text.trim(),
                              durationInMs: 1800000,
                            );
                            context
                                .read<OnboardingBloc>()
                                .add(AddTileSuggestionEvent(tile: customTile));
                            customTileController.clear();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customTileController.text.trim().isEmpty
                          ? tileThemeExtension.disabledOnboardingPill
                          : colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: Text(localizations.addPlus,
                        style: TextStyle(
                            color: customTileController.text.trim().isEmpty
                                ? tileThemeExtension.onDisabledOnboardingPill
                                : colorScheme.onPrimary,
                            fontSize: 16)),
                  ),
                ],
              ),
              SizedBox(height: 0),
              Row(
                children: [
                  Text(
                    localizations.selectSuggestions,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  IconButton(
                    onPressed: state.step == OnboardingStep.suggestionRefreshing
                        ? null
                        : () {
                            context.read<OnboardingBloc>().add(
                                FetchTileSuggestionsEvent(isRefresh: true));
                          },
                    icon: RotationTransition(
                      turns: _rotationController,
                      child: Icon(Icons.refresh,
                          color: state.step ==
                                  OnboardingStep.suggestionRefreshing
                              ? colorScheme.tertiary
                              : tileThemeExtension.onDisabledOnboardingPill),
                    ),
                    iconSize: 20,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.3),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.selectedSuggestionTiles != null &&
                          state.selectedSuggestionTiles!.isNotEmpty)
                        ...state.selectedSuggestionTiles!
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          var tile = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: OnboardingPillTag(
                              text: tile.tileName ?? "",
                              onDelete: () {
                                context
                                    .read<OnboardingBloc>()
                                    .add(RemoveTileSuggestionEvent(index));
                              },
                            ),
                          );
                        }).toList(),
                      if (state.suggestedTiles != null &&
                          state.suggestedTiles!.isNotEmpty)
                        ...state.suggestedTiles!
                            .where((tile) => tile != null)
                            .map((tile) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: OnboardingPillTag(
                              text: tile!.tileName ?? "",
                              isEnabled: false,
                              onTap: () {
                                if (state.step !=
                                    OnboardingStep.suggestionLoading)
                                  context.read<OnboardingBloc>().add(
                                      AddTileSuggestionEvent(
                                          tile: tile, isAddedByPill: true));
                              },
                            ),
                          );
                        }).toList(),
                    ],
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
