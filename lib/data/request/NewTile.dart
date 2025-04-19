import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/RestrictionWeekConfig.dart';
import 'package:tiler_app/data/request/addressModel.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:tiler_app/util.dart';

part 'NewTile.g.dart';

//flutter pub run build_runner watch

@JsonSerializable(explicitToJson: true)
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
  String? RestrictionProfileId;
  String? AutoReviseDeadline;
  String? Priority;

  RestrictionWeekConfig? RestrictiveWeek;

  List<ContactModel>? contacts;

  ClusterTemplateTileModel toClusterTemplateTileModel() {
    ClusterTemplateTileModel clusterTemplateTileModel =
        ClusterTemplateTileModel();
    clusterTemplateTileModel.Name = this.Name;
    if ((this.LocationAddress != null && this.LocationAddress!.isNotEmpty) ||
        (this.LocationTag != null && this.LocationTag!.isNotEmpty)) {
      AddressModel addressModel = AddressModel();
      addressModel.Address = this.LocationAddress;
      addressModel.Description = this.LocationTag;
      clusterTemplateTileModel.AddressData = addressModel;
    }

    if ((this.StartYear.isNot_NullEmptyOrWhiteSpace() &&
        this.StartMonth.isNot_NullEmptyOrWhiteSpace() &&
        this.StartDay.isNot_NullEmptyOrWhiteSpace())) {
      DateTime start = DateTime(
          int.parse(this.StartYear!),
          int.parse(this.StartMonth!),
          int.parse(this.StartDay!),
          int.parse(this.StartHour ?? "0"),
          int.parse(this.StartMinute ?? "0"));
      clusterTemplateTileModel.StartTime = start.millisecondsSinceEpoch;
    }

    if ((this.EndYear.isNot_NullEmptyOrWhiteSpace() &&
        this.EndMonth.isNot_NullEmptyOrWhiteSpace() &&
        this.EndDay.isNot_NullEmptyOrWhiteSpace())) {
      DateTime end = DateTime(
          int.parse(this.EndYear!),
          int.parse(this.EndMonth!),
          int.parse(this.EndDay!),
          int.parse(this.EndHour ?? "23"),
          int.parse(this.EndMinute ?? "59"));
      clusterTemplateTileModel.EndTime = end.millisecondsSinceEpoch;
    }
    clusterTemplateTileModel.DurationInMs = this.getDuration()?.inMilliseconds;
    clusterTemplateTileModel.Contacts = this.contacts?.toList();
    return clusterTemplateTileModel;
  }

  Duration? getDuration() {
    int dayInMinutes = Duration.minutesPerDay;
    int hourInMinutes = Duration.minutesPerHour;
    int? totalMinutes;
    if (this.DurationDays != null && this.DurationDays!.isNotEmpty) {
      int? days = int.tryParse(this.DurationDays!);
      if (days != null) {
        totalMinutes = (totalMinutes ?? 0) + dayInMinutes * days;
      }
    }

    if (this.DurationHours != null && this.DurationHours!.isNotEmpty) {
      int? hours = int.tryParse(this.DurationHours!);
      if (hours != null) {
        totalMinutes = (totalMinutes ?? 0) + hourInMinutes * hours;
      }
    }

    if (this.DurationMinute != null && this.DurationMinute!.isNotEmpty) {
      int? minutes = int.tryParse(this.DurationMinute!);
      if (minutes != null) {
        totalMinutes = (totalMinutes ?? 0) + minutes;
      }
    }

    if (totalMinutes != null) {
      return Duration(minutes: totalMinutes);
    }
    return null;
  }

  DateTime? getStartDateTime() {
    try{
    return DateTime(
        int.parse(this.StartYear!),
        int.parse(this.StartMonth!),
        int.parse(this.StartDay!),
        int.parse(this.StartHour ?? "0"),
        int.parse(this.StartMinute ?? "0"));}
    catch(e){
      Utility.debugPrint("Error in parsing start date: ${e.toString() } ${this.StartYear} ${this.StartMonth} ${this.StartDay} ${this.StartHour} ${this.StartMinute}");
      return null;
    }
  }
  DateTime? getEndDateTime() {
    try{
      return DateTime(
        int.parse(this.EndYear!),
        int.parse(this.EndMonth!),
        int.parse(this.EndDay!),
        int.parse(this.EndHour ?? "23"),
        int.parse(this.EndMinute ?? "59"));}
catch(e){
      Utility.debugPrint("Error in parsing end date: ${e.toString()} ${this.EndYear} ${this.EndMonth} ${this.EndDay} ${this.EndHour} ${this.EndMinute}");
      return null;
    }
  }
  Location? getLocation() {
    Location location = Location.fromDefault();
    location.address = this.LocationAddress;
    location.id = this.LocationId;
    location.source = this.LocationSource;
    location.description = this.LocationTag;
    location.isVerified = this.LocationIsVerified == "true" ? true : false;
    if ((this.LocationId != null && this.LocationId!.isNotEmpty) ||
        (this.LocationAddress != null && this.LocationAddress!.isNotEmpty) ||
        (this.LocationTag != null && this.LocationTag!.isNotEmpty)) {
      location.isDefault = false;
      location.isNull = false;
    } else {
      location.isDefault = true;
      location.isNull = true;
    }
    return location;
  }

  factory NewTile.fromJson(Map<String, dynamic> json) =>
      _$NewTileFromJson(json);

  Map<String, dynamic> toJson() => _$NewTileToJson(this);
}
