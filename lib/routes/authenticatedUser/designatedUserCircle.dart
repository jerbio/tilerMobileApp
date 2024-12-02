import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/styles.dart';
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
  @override
  void initState() {
    super.initState();
    e = this.widget.designatedUser.userProfile != null
        ? Contact.fromUserProfile(this.widget.designatedUser.userProfile!)
        : Contact();
  }

  Widget _subScriptWidget() {
    const double left = 35;
    const double top = 25;
    if (this.widget.designatedUser.completionPercentage != null) {
      double pct = this.widget.designatedUser.completionPercentage!;
      return Positioned(
        top: 25,
        left: 30,
        child: Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          height: 24,
          width: 24,
          child: Text(
            "${pct.toInt()}%",
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileStyles.rubikFontName,
                color: Colors.white),
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pct > 65
                ? Colors.green
                : pct > 33
                    ? Colors.amber
                    : TileStyles.primaryColor,
          ),
        ),
      );
    }

    if (this.widget.designatedUser.rsvpStatus == InvitationStatus.accepted)
      return Positioned(
        top: top,
        left: left,
        child: Icon(
          Icons.check,
          color: Colors.green,
          size: 20,
          weight: 50,
        ),
      );
    else if (this.widget.designatedUser.rsvpStatus == InvitationStatus.declined)
      return Positioned(
        top: top,
        left: left,
        child: Icon(
          Icons.dnd_forwardslash_outlined,
          color: Colors.red,
          size: 20,
          weight: 50,
        ),
      );
    else
      return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration inActiveDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: this.widget.color ?? Colors.white,
        border: Border.all(
          color: Colors.transparent,
          width: 5,
        ));
    return Stack(children: [
      Container(
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
          alignment: Alignment.center,
          width: 50,
          height: 50,
          decoration: this.widget.decoration ?? inActiveDecoration,
          child: Text(
              e.displayedIdentifier.isNot_NullEmptyOrWhiteSpace(minLength: 1)
                  ? e.displayedIdentifier!.capitalize()[0]
                  : "",
              style: TextStyle(
                  fontSize: 25,
                  fontFamily: TileStyles.rubikFontName,
                  color: Colors.white))),
      _subScriptWidget()
    ]);
  }
}
