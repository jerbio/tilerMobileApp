class TilerObj {
  String? id;
  String? userId;
  static T? cast<T>(x) => x is T ? x : null;

  TilerObj.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('userId')) {
      userId = json['userId'];
    }
  }
}
