import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tuple/tuple.dart';

class WeeklyTileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  final Function()? onTap;
  WeeklyTileWidget({subEvent, this.onTap}) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  WeeklyTileWidgetState createState() => WeeklyTileWidgetState();
}
class WeeklyTileWidgetState extends State<WeeklyTileWidget> {
  Tuple2<bool, String> isStringUrl(String url) {
    try {
      bool retValue = Uri.parse(url).isAbsolute;
      return Tuple2(retValue, url);
    } catch (err) {
      List<String> eachUrlComponent = url.split(" ");
      if (eachUrlComponent.isNotEmpty) {
        for (var element in eachUrlComponent) {
          Tuple2<bool, String> isStringUrlTuple = isStringUrl(element);
          if (isStringUrlTuple.item1) {
            return isStringUrlTuple;
          }
        }
      }
    }
    return Tuple2(false, url);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth =( screenWidth * 0.136).floorToDouble();
    Widget? emojiField ;
    if (widget.subEvent.emojis != null && widget.subEvent.emojis!.isNotEmpty) {
      String emojiString = "";
      if (widget.subEvent.emojis!.contains(':')) {
        emojiString = widget.subEvent.emojis!.split(':')[1].trim();
      } else {
        emojiString = widget.subEvent.emojis!..trim();;
      }
      double fontSize = 30;
      if (emojiString.length > 0) {
        int emojiCount = Constants.emojiRegex.allMatches(emojiString).length;
        fontSize = fontSize / emojiCount + 2;
      }

      emojiField = Text(
          emojiString,
          maxLines: 1,
          style: TextStyle(
              fontSize: fontSize,
              fontFamily: TileStyles.rubikFontName,
              fontWeight: FontWeight.bold,
              color: TileStyles.defaultTextColor)
      );
    }

    bool isAddressTexturl = false;
    String? addressString = widget.subEvent.searchdDescription != null
        ? widget.subEvent.searchdDescription
        : widget.subEvent.address;
    addressString = addressString == null || addressString.trim().isEmpty
        ? widget.subEvent.addressDescription
        : addressString;
    if (addressString != null && addressString.isNotEmpty) {
      addressString.split(" ");
      var isStringUrlResult = isStringUrl(addressString);
      isAddressTexturl = isStringUrlResult.item1;
      if (!isAddressTexturl) {
        addressString =
            addressString[0].toUpperCase() + addressString.substring(1);
      }
    }
    return GestureDetector(
      onTap:widget.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2),
        width: calculatedWidth,
        decoration: BoxDecoration(
          color:Color.fromRGBO(240, 240, 240, 1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emojiField != null)emojiField,
            Padding(
              padding: const EdgeInsets.only(top:5.0,bottom: 10),
              child: Text(
                  widget.subEvent.name!,
                  maxLines: 3,
                  style: TextStyle(
                      fontSize: 8,
                      fontFamily: TileStyles.rubikFontName
                  ),
              ),
            ),

            if(addressString!=null && addressString.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom:5),
                child: Text(
                  addressString,
                  maxLines: 1,
                  style:  TextStyle(
                    fontSize: 10,
                    color: Color.fromRGBO(31, 31, 31,0.5),
                    fontFamily: TileStyles.rubikFontName,
                  ),
                ),
              ),
            TimeFrameWidget(
              timeRange: widget.subEvent,
              isWeeklyView: true,
              fontSize: 8,
              textColor: Color.fromRGBO(31, 31, 31,0.5),
            ),
          ],
        ),

      ),
    );
  }
}
