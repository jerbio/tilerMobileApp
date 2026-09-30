// TileShare redesign Step 9.1 (docs/tileshare-redesign-design.md, O9): for a
// Class the client adds every participant to every task. `ClassFanout` is the
// pure planner: which (participant, tilette) pairs still need adding.
// Identity is matched by user id, email (case-insensitive), phone (digits
// only) or username (@ stripped, case-insensitive) — any shared key matches.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

Contact _who({String? id, String? email, String? phone, String? username}) =>
    Contact()
      ..id = id
      ..email = email
      ..phoneNumber = phone
      ..username = username;

Map<String, dynamic> _du(
        {String? id,
        String? email,
        String? phone,
        String? username,
        String? displayed}) =>
    {
      'id': 'du-${id ?? email ?? phone ?? username ?? displayed}',
      if (displayed != null) 'displayedIdentifier': displayed,
      if (id != null || email != null || phone != null || username != null)
        'userProfile': {
          if (id != null) 'id': id,
          if (email != null) 'email': email,
          if (phone != null) 'phoneNumber': phone,
          if (username != null) 'username': username,
        },
    };

TileShareTemplate _t(String id, List<Map<String, dynamic>>? users) =>
    TileShareTemplate.fromJson({
      'id': id,
      'name': id,
      'clusterId': 'c',
      if (users != null) 'designatedUsers': users,
    });

List<String> _pairs(List<ClassFanoutGap> gaps) =>
    gaps.map((g) => '${g.participant.email ?? g.participant.username ?? g.participant.phoneNumber}@${g.tilette.id}').toList();

void main() {
  group('ClassFanout.missing', () {
    test('a complete class has nothing missing', () {
      final tilettes = [
        _t('t1', [_du(email: 'a@x.com'), _du(email: 'b@x.com')]),
        _t('t2', [_du(email: 'a@x.com'), _du(email: 'b@x.com')]),
      ];
      final gaps = ClassFanout.missing(
          tilettes: tilettes,
          participants: [_who(email: 'a@x.com'), _who(email: 'b@x.com')]);
      expect(gaps, isEmpty);
    });

    test('one participant missing on some tasks → exactly those pairs', () {
      final tilettes = [
        _t('t1', [_du(email: 'a@x.com'), _du(email: 'b@x.com')]),
        _t('t2', [_du(email: 'a@x.com')]),
        _t('t3', [_du(email: 'b@x.com')]),
      ];
      final gaps = ClassFanout.missing(
          tilettes: tilettes,
          participants: [_who(email: 'a@x.com'), _who(email: 'b@x.com')]);
      expect(_pairs(gaps), ['b@x.com@t2', 'a@x.com@t3']);
    });

    test('a brand-new task is missing everyone', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('new', null), _t('empty', const [])],
          participants: [_who(email: 'a@x.com'), _who(email: 'b@x.com')]);
      expect(_pairs(gaps),
          ['a@x.com@new', 'b@x.com@new', 'a@x.com@empty', 'b@x.com@empty']);
    });

    test('tilette-major order, then participant order (deterministic)', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', null), _t('t2', null)],
          participants: [_who(email: 'z@x.com'), _who(email: 'a@x.com')]);
      expect(_pairs(gaps),
          ['z@x.com@t1', 'a@x.com@t1', 'z@x.com@t2', 'a@x.com@t2']);
    });

    test('identity: email is case-insensitive and trimmed', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', [_du(email: 'Ann@X.com')])],
          participants: [_who(email: ' ann@x.COM ')]);
      expect(gaps, isEmpty);
    });

    test('identity: phone matches on digits only', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', [_du(phone: '+1 (555) 010-2000')])],
          participants: [_who(phone: '15550102000')]);
      expect(gaps, isEmpty);
    });

    test('identity: username matches without the @ and case', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', [_du(username: '@Sarah')])],
          participants: [_who(username: 'sarah')]);
      expect(gaps, isEmpty);
    });

    test('identity: a shared user id matches even if contact details differ',
        () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', [_du(id: 'u-1', email: 'old@x.com')])],
          participants: [_who(id: 'u-1', email: 'new@x.com')]);
      expect(gaps, isEmpty);
    });

    test('a designated user with only a displayed email still matches', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', [_du(displayed: 'ann@x.com')])],
          participants: [_who(email: 'ann@x.com')]);
      expect(gaps, isEmpty);
    });

    test('duplicate participants are planned once', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', null)],
          participants: [
            _who(email: 'a@x.com'),
            _who(email: 'A@x.com'),
            _who(phone: '555'),
          ]);
      expect(gaps.length, 2);
    });

    test('a participant with no usable identity is skipped, not planned', () {
      final gaps = ClassFanout.missing(
          tilettes: [_t('t1', null)], participants: [Contact()]);
      expect(gaps, isEmpty);
    });
  });

  group('ClassFanout.participantsOf', () {
    test('the union of designated users across tasks, de-duplicated', () {
      final tilettes = [
        _t('t1', [_du(email: 'a@x.com'), _du(email: 'b@x.com')]),
        _t('t2', [_du(email: 'A@x.com'), _du(phone: '555')]),
        _t('t3', null),
      ];
      final people = ClassFanout.participantsOf(tilettes);
      expect(people.map((c) => c.email ?? c.phoneNumber).toList(),
          ['a@x.com', 'b@x.com', '555']);
    });

    test('reconciliation: participantsOf + missing flags an incomplete class',
        () {
      final tilettes = [
        _t('t1', [_du(email: 'a@x.com'), _du(email: 'b@x.com')]),
        _t('t2', [_du(email: 'a@x.com')]),
      ];
      final gaps = ClassFanout.missing(
          tilettes: tilettes,
          participants: ClassFanout.participantsOf(tilettes));
      expect(_pairs(gaps), ['b@x.com@t2']);
    });
  });
}
