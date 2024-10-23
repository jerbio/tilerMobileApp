class TileTemplate {
  String? id;
  String? name;
  List<String?>? users;
  int? start;
  int? end;

  TileTemplate.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('users') && json['users'] != null) {
      users = json['users']
          .map<String?>((e) => (e as String?))
          .where((e) => (e != null))
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
