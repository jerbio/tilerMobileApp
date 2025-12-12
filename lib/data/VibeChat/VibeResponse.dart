import 'package:tiler_app/data/VibeChat/VibeMessage.dart';

class VibeResponse {
  final Map<String, VibeMessage>? prompts;
  final dynamic tilerUser;

  VibeResponse({
    this.prompts,
    this.tilerUser,
  });

  factory VibeResponse.fromJson(Map<String, dynamic> json) {
    Map<String, VibeMessage>? promptsMap;

    if (json['prompts'] != null) {
      promptsMap = {};
      (json['prompts'] as Map<String, dynamic>).forEach((key, value) {
        promptsMap![key] = VibeMessage.fromJson(value);
      });
    }

    return VibeResponse(
      prompts: promptsMap,
      tilerUser: json['tilerUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompts': prompts?.map((key, value) => MapEntry(key, value.toJson())),
      'tilerUser': tilerUser,
    };
  }
}