import 'package:tiler_app/util.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalysticSession {
  final String _sessionId = Utility.uuid.toString();
  final int _beginTime = Utility.msCurrentTime;
  int? _endTime;
  int sequenceNumber = 0;
  void endSession() {
    _endTime = Utility.msCurrentTime;
  }

  void incrementSequence() {
    sequenceNumber += 1;
  }

  String get sessionId {
    return _sessionId;
  }
}

class AnalysticsSignal {
  final String tag;
  Map? additionalInfo;
  final AnalysticSession session;
  static AnalysticSession latestSession = new AnalysticSession();
  static final FirebaseAnalytics fireBaseAnalytics = FirebaseAnalytics.instance;
  AnalysticsSignal(
      {required this.session, this.tag = "default", this.additionalInfo}) {
    this.session.incrementSequence();
  }
  factory AnalysticsSignal.nextSignal(
      {required String signalTag, Map? additionalInfo}) {
    return AnalysticsSignal(
        session: latestSession, tag: signalTag, additionalInfo: additionalInfo);
  }

  factory AnalysticsSignal.bySession(
      AnalysticSession newSession, String signalTag) {
    return AnalysticsSignal(session: newSession, tag: signalTag);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> retValue = {
      'name': this.tag,
      'sessionId': this.session.sessionId,
      'sequnceNumber': this.session.sequenceNumber,
      'tag': this.tag,
      'time': Utility.msCurrentTime,
    };
    if (this.additionalInfo != null) {
      try {
        retValue['additionalInfo'] = this.additionalInfo.toString();
      } catch (e) {}
    }

    return retValue;
  }

  static Future send(String tag, {Map? additionalInfo}) async {
    if (tag.isEmpty) {
      return "no-tag-set";
    }
    // AnalysticsSignal nextSignal = AnalysticsSignal.nextSignal(
    //     signalTag: tag, additionalInfo: additionalInfo);
    // await fireBaseAnalytics
    //     .logEvent(name: nextSignal.tag, parameters: nextSignal.toJson())
    //     .then((value) {
    //   print("---- custom event analystics user logged in verified-----");
    // });
  }
}
