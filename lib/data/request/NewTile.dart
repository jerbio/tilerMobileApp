import 'package:json_annotation/json_annotation.dart';

part 'NewTile.g.dart';

@JsonSerializable()
class NewTile {
  NewTile();

  /// <summary>
  /// Blue Value for RGBO color format  for calendar event
  /// </summary>
  String? BColor;

  /// <summary>
  /// Red Value for RGBO color format  for calendar event
  /// </summary>
  String? RColor;

  /// <summary>
  /// Green Value for RGBO color format for calendar event
  /// </summary>
  String? GColor;

  /// <summary>
  /// Sets the opacity RGBO color format for calendar event
  /// </summary>
  String? Opacity;

  /// <summary>
  /// One of the preset color selections for tiler. The preset options are from [0-8].
  /// </summary>
  String? ColorSelection;

  /// <summary>
  /// The number of splits for a specific calendar event. Default is 1.
  /// </summary>
  String? Count;

  /// <summary>
  /// Sets the number of days for duration component of the given calendar event. Default is 0
  /// </summary>
  String? DurationDays;

  /// <summary>
  /// Sets the number of hours component for the duration of event. for the given calendar event. Default is 0
  /// </summary>
  String? DurationHours;

  /// <summary>
  /// Sets the number of Minutes component for the duration of event. for the given calendar event. Default is 0
  /// </summary>
  String? DurationMinute;

  /// <summary>
  /// Day-date component of End date.
  /// </summary>
  String? EndDay;

  /// <summary>
  /// Hour component of End date.
  /// </summary>
  String? EndHour;

  /// <summary>
  /// Minute component of End date.
  /// </summary>
  String? EndMinute;

  /// <summary>
  /// Month component of End date.
  /// </summary>
  String? EndMonth;

  /// <summary>
  /// Year component of End date.
  /// </summary>
  String? EndYear;

  /// <summary>
  /// Address provided by user
  /// </summary>
  String? LookupString;

  /// <summary>
  /// Address is a confirmed location from google maps or mapping service
  /// </summary>
  String? LocationIsVerified;

  /// <summary>
  /// Full Address for new event. Fully described in default format. e.g 1234 stret apt 56 Kingston, CO 78901
  /// </summary>
  String? LocationAddress;

  /// <summary>
  /// Should be populated when the location is from a cache
  /// </summary>
  String? LocationId;

  /// <summary>
  /// Source from where location is pulled
  /// </summary>
  String? LocationSource;

  /// <summary>
  /// Prefereed Nick name for location. If Nick name already exists, it overwrites previous full address & long lat with new nick name
  /// </summary>
  String? LocationTag;

  /// <summary>
  /// Name of Newly added Tile/Event
  /// </summary>
  String? Name;

  /// <summary>
  /// ***No current use***
  /// </summary>
  String? RepeatData;
  String? RepeatEndDay;
  String? RepeatEndMonth;
  String? RepeatEndYear;
  String? RepeatStartDay;
  String? RepeatStartMonth;
  String? RepeatStartYear;
  String? RepeatType;
  String? RepeatWeeklyData;
  String? Rigid;
  String? StartDay;
  String? StartHour;
  String? StartMinute;
  String? StartMonth;
  String? StartYear;
  String? RepeatFrequency;

  /// <summary>
  /// is time restriction set on this event
  /// </summary>
  String? isRestricted;

  /// <summary>
  /// Start time for restriction
  /// </summary>
  String? RestrictionStart;

  /// <summary>
  /// End time for restriction
  /// </summary>
  String? RestrictionEnd;

  /// <summary>
  /// is the restrcition to be for only work week.
  /// </summary>
  String? isWorkWeek;
  String? isEveryDay;

  factory NewTile.fromJson(Map<String, dynamic> json) =>
      _$NewTileFromJson(json);

  Map<String, dynamic> toJson() => _$NewTileToJson(this);
}
