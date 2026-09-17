import 'package:flutter/foundation.dart';
import 'package:tiler_app/util.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../constants.dart' as Constants;

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

  Map<String, Object>? toJson() {
    Map<String, Object> retValue = {
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

  /// Test transport; production uses Firebase and retains the debug guard.
  @visibleForTesting
  static Future<void> Function(String, Map<String, Object>)? testSink;

  /// [parameters] exposes structured event fields alongside session metadata.
  /// Existing callers may continue using [additionalInfo]. Delivery failures
  /// must not interrupt the user flow that emitted the event.
  static Future send(String tag,
      {Map? additionalInfo, Map<String, Object>? parameters}) async {
    if (tag.isEmpty || (Constants.isDebug && testSink == null)) {
      return "no-tag-set";
    }
    try {
      final signal = AnalysticsSignal.nextSignal(
          signalTag: tag, additionalInfo: additionalInfo);
      final payload = <String, Object>{
        ...?parameters,
        ...?signal.toJson(),
      };
      if (testSink != null) {
        await testSink!(tag, payload);
      } else {
        await fireBaseAnalytics.logEvent(name: tag, parameters: payload);
      }
    } catch (_) {
      debugPrint('Analytics delivery failed: $tag');
    }
  }
}
