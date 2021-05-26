import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class BlobEvent extends TilerEvent {
  List<SubCalendarEvent> blobOfSubEvents = [];

  BlobEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
