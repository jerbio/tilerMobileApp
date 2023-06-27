import 'package:tiler_app/data/location.dart';

class Combination{
Location? first;
Location? second;
double? duration;
int? count;
double? totalDuration;

Combination({
this.first,
this.second,
this.duration,
this.totalDuration,
this.count,

});
factory Combination.fromJson(Map<String,dynamic> json)=>Combination(
first: Location.fromJson(json['combination']['first']),
second: Location.fromJson(json['combination']['second']),
duration:double.parse( json['duration'].toString()),
count: json['count'],
// totalDuration: json['duration']* json['count']

);
}