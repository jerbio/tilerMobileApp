import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
class VibeResponse {
  final VibeMessage? userMessage;
  final VibeMessage? tilerMessage;
  final dynamic tilerUser;

  VibeResponse({
    this.userMessage,
    this.tilerMessage,
    this.tilerUser,
  });

  factory VibeResponse.fromJson(Map<String, dynamic> json) {
    VibeMessage? user;
    VibeMessage? tiler;

    if (json['prompts'] != null) {
      (json['prompts'] as Map<String, dynamic>).forEach((key, value) {
        final msg = VibeMessage.fromJson(value);
        if (msg.origin?.name == 'user') {
          user = msg;
        } else if (msg.origin?.name == 'tiler') {
          tiler = msg;
        }
      });
    }

    return VibeResponse(
      userMessage: user,
      tilerMessage: tiler,
      tilerUser: json['tilerUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userMessage': userMessage?.toJson(),
      'tilerMessage': tilerMessage?.toJson(),
      'tilerUser': tilerUser,
    };
  }
}