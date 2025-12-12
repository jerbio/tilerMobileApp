class VibeSession {
  final String? id;
  final int? creationTimeInMs;

  VibeSession({
    this.id,
    this.creationTimeInMs,
  });

  factory VibeSession.fromJson(Map<String, dynamic> json) {
    return VibeSession(
      id: json['id'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creationTimeInMs': creationTimeInMs,
    };
  }
}