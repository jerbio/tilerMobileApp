// Diagnosing the old invitation tile's binoculars (the what-if forecast): one
// pure rule decides whether it shows, and says why not, so the log on a device
// is exactly what the screen did.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/services/tileShare/tileShareForecastRequest.dart';

const int _now = 1789500000000;
const int _hour = 3600000;

DesignatedTile _tile({
  String status = 'none',
  int? duration = _hour,
  int? end = _now + 24 * _hour,
  bool withTemplate = true,
}) =>
    DesignatedTile.fromJson({
      'id': 'd1',
      'invitationStatus': status,
      if (withTemplate)
        'template': {
          'id': 't1',
          if (duration != null) 'duration': duration,
          if (end != null) 'end': end,
        },
    });

void main() {
  test('shows for a pending task with a length and a future deadline', () {
    expect(TileShareForecastRequest.hiddenReason(_tile(), _now), isNull);
  });

  test('each reason it is hidden is named', () {
    expect(TileShareForecastRequest.hiddenReason(_tile(status: 'accepted'), _now),
        contains('accepted'));
    expect(TileShareForecastRequest.hiddenReason(_tile(duration: null), _now),
        contains('no duration'));
    expect(TileShareForecastRequest.hiddenReason(_tile(end: null), _now),
        contains('no deadline'));
    expect(TileShareForecastRequest.hiddenReason(_tile(end: _now - 1), _now),
        contains('deadline passed'));
    expect(TileShareForecastRequest.hiddenReason(_tile(withTemplate: false), _now),
        contains('no template'));
  });

  test('a status spelled another way is still the exact check the screen '
      'makes', () {
    // The screen compares the raw string with "accepted"; "Accepted" is not
    // hidden by it - the reason must say what the screen does, not what it
    // should do.
    expect(TileShareForecastRequest.hiddenReason(_tile(status: 'Accepted'), _now),
        isNull);
  });
}
