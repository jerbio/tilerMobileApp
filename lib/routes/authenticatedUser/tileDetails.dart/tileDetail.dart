import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TileDetail extends StatefulWidget {
  String tileId;
  TileDetail({required this.tileId});

  @override
  State<StatefulWidget> createState() => _TileDetailState();
}

class _TileDetailState extends State<TileDetail> {
  CalendarEvent? calEvent;
  EditTilerEvent? editTilerEvent;
  int? splitCount;
  TextEditingController? splitCountController;
  EditTileName? _editTileName;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this
        .context
        .read<CalendarTileBloc>()
        .add(GetCalendarTileEvent(calEventId: this.widget.tileId));
  }

  void onInputCountChange() {
    dataChange();
  }

  void dataChange() {}
  bool get isProcrastinateTile {
    return (this.calEvent!.isProcrastinate ?? false);
  }

  bool get isRigidTile {
    return (this.calEvent!.isProcrastinate ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      child: BlocListener<CalendarTileBloc, CalendarTileState>(
        listener: (context, state) {
          if (state is CalendarTileLoaded) {
            setState(() {
              if (calEvent == null) {
                calEvent = state.calEvent;
                editTilerEvent = new EditTilerEvent();
                editTilerEvent!.endTime = calEvent!.endTime!;
                editTilerEvent!.startTime = calEvent!.startTime!;
                editTilerEvent!.splitCount = calEvent!.split;
                editTilerEvent!.name = calEvent!.name ?? '';
                editTilerEvent!.thirdPartyId = calEvent!.thirdpartyId;
                editTilerEvent!.thirdPartyType = calEvent!.thirdpartyType;
                editTilerEvent!.thirdPartyUserId = calEvent!.thirdPartyUserId;
                editTilerEvent!.id = calEvent!.id;
                if (calEvent!.noteData != null) {
                  editTilerEvent!.note = calEvent!.noteData!.note;
                }
                if (calEvent!.calendarEvent != null) {
                  splitCount = calEvent!.split;
                  splitCountController =
                      TextEditingController(text: splitCount!.toString());
                  splitCountController!.addListener(onInputCountChange);
                  editTilerEvent!.splitCount = splitCount;
                }
              }
            });
          }
        },
        child: BlocBuilder<CalendarTileBloc, CalendarTileState>(
          builder: (context, state) {
            if (state is CalendarTileInitial ||
                state is CalendarTileLoading ||
                this.calEvent == null) {
              return PendingWidget();
            }
            String tileName =
                this.editTilerEvent?.name ?? this.calEvent!.name ?? '';
            _editTileName = EditTileName(
              tileName: tileName,
              isProcrastinate: isProcrastinateTile,
              onInputChange: dataChange,
            );

            DateTime startTime =
                this.editTilerEvent?.startTime ?? this.calEvent!.startTime!;
            _editStartDateAndTime = EditDateAndTime(
              time: startTime,
              onInputChange: dataChange,
            );
            DateTime endTime =
                this.editTilerEvent?.endTime ?? this.calEvent!.endTime!;
            _editEndDateAndTime = EditDateAndTime(
              time: endTime,
              onInputChange: dataChange,
            );

            var inputChildWidgets = <Widget>[
              _editTileName!,
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.start,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        _editStartDateAndTime!
                      ],
                    ),
                  )),
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.end,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        _editEndDateAndTime!
                      ],
                    ),
                  )),
            ];

            if (!isRigidTile && !isProcrastinateTile) {
              Widget splitWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.split,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            controller: splitCountController,
                          ),
                        )
                      ],
                    ),
                  ));

              Widget deadlineWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.deadline,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ));
              inputChildWidgets.insert(1, splitWidget);
              inputChildWidgets.add(deadlineWidget);
            }

            return Container(
              margin: TileStyles.topMargin,
              alignment: Alignment.topCenter,
              child: Column(
                children: inputChildWidgets,
              ),
            );
          },
        ),
      ),
    );
  }
}
