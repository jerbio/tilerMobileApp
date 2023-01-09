import 'package:tiler_app/data/tileObject.dart';

class NoteData extends TilerObj {
  String? note;
  NoteData.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('note')) {
      note = json['note'];
    }
  }
}
