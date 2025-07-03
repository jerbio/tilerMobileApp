import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/theme/tileThemeExtension.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';


class DesignatedUserCircle extends StatefulWidget {
  final BoxDecoration? decoration;
  final Color? color;
  final DesignatedUser designatedUser;
  DesignatedUserCircle(
      {required this.designatedUser, this.decoration, this.color});
  @override
  State<StatefulWidget> createState() => _DesignatedUserCircleState();
}

class _DesignatedUserCircleState extends State<DesignatedUserCircle> {
  late Contact e;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    super.initState();
    e = this.widget.designatedUser.userProfile != null
        ? Contact.fromUserProfile(this.widget.designatedUser.userProfile!)
        : Contact();
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  Widget _subScriptWidget() {
    const double top = 22.4;
    const double left = 22.4;

    if (this.widget.designatedUser.completionPercentage != null &&
        this.widget.designatedUser.completionPercentage != 0) {
      double pct = this.widget.designatedUser.completionPercentage!;
      return Positioned(
        top: 22.4,
        left: 25,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 14,
          width: 25,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLow, width: 1),
            borderRadius: BorderRadius.circular(5),
            color: pct > 66.66
                ? TileColors.highCompletionTileShare
                : pct > 33.33
                    ?  TileColors.lowCompletionTileShare
                    : colorScheme.primary,
          ),
          child: Text(
            "${pct.round()}%",
            style: TextStyle(
                fontSize: 7,
                fontFamily: TileTextStyles.rubikFontName,
                color: tileThemeExtension.onFixedColors),
          ),
        ),
      );
    }

    if (this.widget.designatedUser.rsvpStatus == InvitationStatus.accepted)
      return Positioned(
        top: top,
        left: left,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 15.36,
          width: 15.36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TileColors.acceptedRsvpTileShare,
          ),
          child: Icon(
            Icons.check,
            color: tileThemeExtension.onFixedColors,
            size: 12.8,
            weight: 32,
          ),
        ),
      );
    else if (this.widget.designatedUser.rsvpStatus == InvitationStatus.declined)
      return Positioned(
        top: top,
        left: left,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 15.36,
          width: 15.36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TileColors.declinedRsvpTileShare,
          ),
          child: Icon(
            Icons.dnd_forwardslash_outlined,
            color: tileThemeExtension.onFixedColors,
            size: 12.8,
            weight: 32,
          ),
        ),
      );
    else
      return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration inActiveDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: this.widget.color ?? colorScheme.surfaceContainerLow,
        border: Border.all(
          color: Colors.transparent,
          width: 5,
        ));
    return Stack(children: [
      Container(
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
          alignment: Alignment.center,
          width: 40,
          height: 38,
          decoration: this.widget.decoration ?? inActiveDecoration,
          child: Text(
              e.displayedIdentifier.isNot_NullEmptyOrWhiteSpace(minLength: 1)
                  ? e.displayedIdentifier!.capitalize()[0]
                  : "",
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: TileTextStyles.rubikFontName,
                  color: tileThemeExtension.onFixedColors))),
      _subScriptWidget()
    ]);
  }
}
