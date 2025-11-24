class TileShareTemplateMiscData {
  String? id;
  String? userNote;

  TileShareTemplateMiscData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('userNote')) {
      userNote = json['userNote'];
    }
  }
}
