import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingPillTag.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingSubWidget.dart';
import 'package:tiler_app/data/tileSuggestion.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TileSuggestionsWidget extends StatefulWidget {
  @override
  _TileSuggestionsState createState() => _TileSuggestionsState();
}

class _TileSuggestionsState extends State<TileSuggestionsWidget> {
  TextEditingController customTileController = TextEditingController();
  late  AppLocalizations localizations;
  late ThemeData theme;
  late TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(FetchTileSuggestionsEvent());
  }

  @override
  void dispose() {
    customTileController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    localizations=  AppLocalizations.of(context)!;
    theme = Theme.of(context);
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
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
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return OnboardingSubWidget(
          title: localizations.tileSuggestions,
          questionText: localizations.tileSuggestionsQuestion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.step == OnboardingStep.suggestionLoading) ...[
                _buildLoadingIndicator(colorScheme),
                SizedBox(height: 16),
              ],

              if (state.suggestedTiles != null && state.suggestedTiles!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.suggestedTiles!.map((tile) {
                    return OnboardingPillTag(
                      text: tile.tileName ?? "",
                      isEnabled: tile.isActive??true,
                      onTap: () {
                        context.read<OnboardingBloc>().add(AddTileSuggestionEvent(tile));
                      },
                    );
                  }).toList(),
                ),

              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customTileController,
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
                      decoration: TileDecorations.onboardingInputDecoration(
                        tileThemeExtension.onSurfaceVariantSecondary,
                        colorScheme.tertiary,
                        localizations.grabACoffee,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (customTileController.text.trim().isNotEmpty) {
                        final customTile = TileSuggestion(
                          tileName: customTileController.text.trim(),
                          durationInMs: 1800000
                        );
                        context.read<OnboardingBloc>().add(AddTileSuggestionEvent(customTile));
                        customTileController.clear();
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

              if (state.selectedSuggestionTiles != null && state.selectedSuggestionTiles!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.selectedSuggestionTiles!.asMap().entries.map((entry) {
                    int index = entry.key;
                    var tile = entry.value;
                    return OnboardingPillTag(
                      text: tile.tileName ?? "",
                      onDelete: () {
                        context.read<OnboardingBloc>().add(RemoveTileSuggestionEvent(index));
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}