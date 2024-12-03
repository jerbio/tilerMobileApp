import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/userProfile.dart';

class TileShareTemplate {
  String? id;
  String? clusterId;
  String? name;
  UserProfile? creator;
  List<DesignatedUser>? designatedUsers;
  int? start;
  int? end;

  TileShareTemplate.fromJson(Map<String, dynamic> json) {
    id = '';
    print("TileShareTemplate");
    print(json);
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('creator') && json['creator'] != null) {
      creator = UserProfile.fromJson(json['creator']);
    }
    if (json.containsKey('clusterId')) {
      clusterId = json['clusterId'];
    }

    if (json.containsKey('designatedUsers') &&
        json['designatedUsers'] != null) {
      designatedUsers = json['designatedUsers']
          .where((e) => (e != null))
          .map<DesignatedUser>((e) => ((DesignatedUser.fromJson(e))))
          .toList();
    }

    if (json.containsKey('start')) {
      start = json['start'];
    }

    if (json.containsKey('end')) {
      end = json['end'];
    }
  }
}
