class VibeSession {
  final String? id;
  final int? creationTimeInMs;
  final String? title;

  VibeSession({
    this.id,
    this.creationTimeInMs,
    this.title
  });

  factory VibeSession.fromJson(Map<String, dynamic> json) {
    return VibeSession(
      id: json['id'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      title: json['title']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creationTimeInMs': creationTimeInMs,
      'title':title
    };
  }
}