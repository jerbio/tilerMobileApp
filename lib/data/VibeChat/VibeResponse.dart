import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/data/userProfile.dart';

class VibeResponse {
  final List<VibeMessage>? prompts;
  final UserProfile? tilerUser;

  VibeResponse({
    this.prompts,
    this.tilerUser,
  });

  factory VibeResponse.fromJson(Map<String, dynamic> json) {
    List<VibeMessage>? promptsList;

    if (json['prompts'] != null) {
      promptsList = [];
      (json['prompts'] as Map<String, dynamic>).forEach((key, value) {
        promptsList!.add(VibeMessage.fromJson(value));
      });
    }

    return VibeResponse(
      prompts: promptsList,
      tilerUser: json['tilerUser'] != null
          ? UserProfile.fromJson(json['tilerUser'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompts': prompts?.map((p) => p.toJson()).toList(),
      'tilerUser': tilerUser?.toJson(),
    };
  }
}