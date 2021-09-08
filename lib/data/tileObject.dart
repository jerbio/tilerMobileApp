import 'package:tiler_app/util.dart';

class TilerObj {
  String? id = Utility.getUuid;
  String? userId;
  static T? cast<T>(x) => x is T ? x : null;

  TilerObj({this.id, this.userId});

  TilerObj.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('userId')) {
      userId = json['userId'];
    }
  }
}
