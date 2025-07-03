import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

class _DayOfWeekRestriction {
  String weekDayText = '';
  int dayIndex = -1;
  TimeOfDay start = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 18, minute: 0);
  bool isSelected = false;
  _DayOfWeekRestriction({required this.weekDayText, required this.dayIndex});
  RestrictionDay toRestrictionDay() {
    Duration duration = Duration(
        milliseconds: (end.durationFromMidnight - start.durationFromMidnight));
    var retValue = RestrictionDay(
        restrictionTimeLine: RestrictionTimeLine(
            duration: duration, start: this.start, weekDay: this.dayIndex));
    retValue.weekday = this.dayIndex;
    return retValue;
  }
}

class CustomTimeRestrictionRoute extends StatefulWidget {
  Map? params;
  @override
  State<StatefulWidget> createState() => CustomTimeRestrictionRouteState();
}

class CustomTimeRestrictionRouteState
    extends State<CustomTimeRestrictionRoute> {
  TimeOfDay? _copiedStart;
  TimeOfDay? _copiedEnd;
  int? _copiedDayIndex;
  bool _hasCopied = false;
  final List<String> weekdays = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
  ];
  final NumberFormat doubleZeroFormatter = new NumberFormat('00');
  Map<String, _DayOfWeekRestriction> mapOfWeekDayToDayRestriction = {};
  Map? paramArgs = {};
  RestrictionProfile? restrictionProfileParams;
  bool isMapOfDayRestrictionInitialized = false;
  static String routeName = '/CustomRestrictionsRoute';

  static final String customTimeRestrictionRouteName =
      "customTimeRestrictionRouteName";
  late ThemeData theme;
  late ColorScheme colorScheme;
  late  TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
  }
  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay selectedTime) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    return timeOfDay;
  }

  _initializeDayRestrictions() {
    var localMapOfWeekDayToDayRestriction = mapOfWeekDayToDayRestriction;
    List checkBoxText = [
      AppLocalizations.of(this.context)!.sunday,
      AppLocalizations.of(this.context)!.monday,
      AppLocalizations.of(this.context)!.tuesday,
      AppLocalizations.of(this.context)!.wednesday,
      AppLocalizations.of(this.context)!.thursday,
      AppLocalizations.of(this.context)!.friday,
      AppLocalizations.of(this.context)!.saturday
    ];

    localMapOfWeekDayToDayRestriction['sunday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.sunday, dayIndex: 0);
    localMapOfWeekDayToDayRestriction['monday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.monday, dayIndex: 1);
    localMapOfWeekDayToDayRestriction['tuesday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.tuesday, dayIndex: 2);
    localMapOfWeekDayToDayRestriction['wednesday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.wednesday, dayIndex: 3);
    localMapOfWeekDayToDayRestriction['thursday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.thursday, dayIndex: 4);
    localMapOfWeekDayToDayRestriction['friday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.friday, dayIndex: 5);
    localMapOfWeekDayToDayRestriction['saturday'] = _DayOfWeekRestriction(
        weekDayText: AppLocalizations.of(this.context)!.saturday, dayIndex: 6);

    Map? args = ModalRoute.of(context)?.settings.arguments as Map?;
    this.widget.params = args;
    if (args != null && args.containsKey('restrictionProfile')) {
      RestrictionProfile? restrictionProfileParams = args['restrictionProfile'];
      this.restrictionProfileParams = restrictionProfileParams;
    }
    if (this.restrictionProfileParams != null) {
      for (int i = 0;
          i < this.restrictionProfileParams!.daySelection.length;
          i++) {
        var restrictionDay = this.restrictionProfileParams!.daySelection[i];
        if (restrictionDay != null) {
          var dayOfWeekRestriction = _DayOfWeekRestriction(
              weekDayText: checkBoxText[restrictionDay.weekday!],
              dayIndex: restrictionDay.weekday!);
          dayOfWeekRestriction.isSelected = true;
          localMapOfWeekDayToDayRestriction[weekdays[restrictionDay.weekday!]] =
              dayOfWeekRestriction;

          if (restrictionDay.restrictionTimeLine != null) {
            if (restrictionDay.restrictionTimeLine!.start != null &&
                restrictionDay.restrictionTimeLine!.duration != null) {
              dayOfWeekRestriction.start =
                  restrictionDay.restrictionTimeLine!.start!;
              DateTime startDateTime = DateTime(
                  2022,
                  1,
                  1,
                  dayOfWeekRestriction.start.hour,
                  dayOfWeekRestriction.start.minute);
              dayOfWeekRestriction.end = TimeOfDay.fromDateTime(startDateTime
                  .add(restrictionDay.restrictionTimeLine!.duration!));
            }
          }
        }
      }
    }

    setState(() {
      isMapOfDayRestrictionInitialized = true;
      mapOfWeekDayToDayRestriction = localMapOfWeekDayToDayRestriction;
      paramArgs = args;
    });
  }

  Widget _buildCopyPasteIcon(_DayOfWeekRestriction day) {
    final bool isCopiedDay = _copiedDayIndex == day.dayIndex;
    final bool isSelected = day.isSelected;
    final bool showPaste = _hasCopied && !isCopiedDay;

    Color iconColor = colorScheme.onInverseSurface.withLightness(0.7);

    if (isSelected) {
      if (showPaste) {
        iconColor = colorScheme.primary;
      } else if (isCopiedDay) {
        iconColor = TileColors.copied;
      } else {
        iconColor = colorScheme.primary;
      }
    }

    return Container(
      margin: EdgeInsets.only(left: 10),
      width: 24,
      height: 24,
      child: showPaste
          ? SvgPicture.asset(
        'assets/icons/settings/paste-icon.svg',
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      )
          : SvgPicture.asset(
        'assets/icons/settings//copy-icon.svg',
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  Widget generateEachDayWidget(_DayOfWeekRestriction dayOfWeekRestriction) {
    final localizations = MaterialLocalizations.of(context);
    Widget retValue = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TilerCheckBox(
          text: dayOfWeekRestriction.weekDayText,
          isChecked: dayOfWeekRestriction.isSelected,
          onChange: (TilerCheckBoxState checkBoxState) {
            var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
            bool isSelected = checkBoxState.isChecked;
            dayOfWeekRestriction.isSelected = isSelected;
            mapOfWeekDays[this.weekdays[dayOfWeekRestriction.dayIndex]] =
                dayOfWeekRestriction;
            this.setState(() {
              mapOfWeekDayToDayRestriction = mapOfWeekDays;
            });
          },
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    GestureDetector(
          onTap: () async {
            var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
            if (dayOfWeekRestriction.isSelected) {
              TimeOfDay? timeOfDay = await _selectTime(
                  this.context, dayOfWeekRestriction.start);
              if (timeOfDay != null) {
                dayOfWeekRestriction.start = timeOfDay;
                mapOfWeekDays[
                        this.weekdays[dayOfWeekRestriction.dayIndex]] =
                    dayOfWeekRestriction;
              }
              this.setState(() {
                mapOfWeekDayToDayRestriction = mapOfWeekDays;
              });
            }
          },
          child:Container(
            padding: EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.onInverseSurface.withLightness(0.7), width: 2)),
            ),
            child: Text(
              localizations.formatTimeOfDay(dayOfWeekRestriction.start),
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
                    ),
              Center(
                  child: Text(
                    ' - ',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
                    ),
              ),
                    GestureDetector(
        onTap: () async {
          var mapOfWeekDays = this.mapOfWeekDayToDayRestriction;
          if (dayOfWeekRestriction.isSelected) {
            TimeOfDay? timeOfDay =
                await _selectTime(this.context, dayOfWeekRestriction.end);
            if (timeOfDay != null) {
              dayOfWeekRestriction.end = timeOfDay;
              mapOfWeekDays[
                      this.weekdays[dayOfWeekRestriction.dayIndex]] =
                  dayOfWeekRestriction;
            }
            this.setState(() {
              mapOfWeekDayToDayRestriction = mapOfWeekDays;
            });
          }
        },
        child:Container(
          padding: EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: colorScheme.onInverseSurface.withLightness(0.7), width: 2)),
          ),
          child: Text(
            localizations.formatTimeOfDay(dayOfWeekRestriction.end),
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        )
                    ),
              GestureDetector(
                onTap: () {
                  if (dayOfWeekRestriction.isSelected) {
                    if (_hasCopied && _copiedDayIndex == dayOfWeekRestriction.dayIndex) {
                      setState(() {
                        _hasCopied = false;
                        _copiedDayIndex = null;
                        _copiedStart = null;
                        _copiedEnd = null;
                      });
                    }
                    else if (_hasCopied && _copiedDayIndex != dayOfWeekRestriction.dayIndex) {
                      setState(() {
                        dayOfWeekRestriction.start = _copiedStart!;
                        dayOfWeekRestriction.end = _copiedEnd!;
                      });
                    } else {
                      setState(() {
                        _copiedStart = dayOfWeekRestriction.start;
                        _copiedEnd = dayOfWeekRestriction.end;
                        _copiedDayIndex = dayOfWeekRestriction.dayIndex;
                        _hasCopied = true;
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildCopyPasteIcon(dayOfWeekRestriction),
                ),
              ),
            ]
        ),

      ],
    );
    return retValue;
  }

  onProceed() {
    List<RestrictionDay?> daySelections = this
        .mapOfWeekDayToDayRestriction
        .values
        .map((dayRestriction) => dayRestriction.isSelected
            ? dayRestriction.toRestrictionDay()
            : null)
        .toList();
    List<RestrictionDay?> nonNullRestrictionDays = daySelections
        .where((restrictionDay) => restrictionDay != null)
        .toList();
    if (this.paramArgs != null) {
      this.paramArgs!.remove('restrictionProfile');
      if (nonNullRestrictionDays.isNotEmpty) {
        RestrictionProfile restrictionProfile =
            RestrictionProfile(daySelection: daySelections);
        this.paramArgs!['restrictionProfile'] = restrictionProfile;
      }
    }
  }

  bool isProceedReady() {
    bool retValue = true;

    List<_DayOfWeekRestriction> dayRestrictions = this
        .mapOfWeekDayToDayRestriction
        .values
        .where((dayRestriction) =>
            dayRestriction != null && dayRestriction.isSelected)
        .toList();
    if (dayRestrictions.isNotEmpty) {
      retValue = !dayRestrictions.any((dayRestriction) =>
          !dayRestriction.toRestrictionDay().restrictionTimeLine!.isValid);
    }
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    Map restrictionProfileParams =
        ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.params = restrictionProfileParams;
    if (!isMapOfDayRestrictionInitialized) {
      _initializeDayRestrictions();
    }

    return CancelAndProceedTemplateWidget(
        routeName: customTimeRestrictionRouteName,
        onProceed: isProceedReady() ? onProceed : null,
        child: Stack(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Center(
                    child: Column(
                        children: this
                            .weekdays
                            .map((weekdayString) => Padding(
                          padding: EdgeInsets.only(bottom: 5,right: 25),
                          child: generateEachDayWidget(
                              this.mapOfWeekDayToDayRestriction[weekdayString]!),
                        ))
                            .toList(),
                    )
              )
              )
            ],
          ),
        );
  }
}
