import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

/// One (participant, tilette) pair that still has to be added.
class ClassFanoutGap {
  final Contact participant;
  final TileShareTemplate tilette;

  const ClassFanoutGap(this.participant, this.tilette);
}

/// Pure planner for the Class fan-out (redesign O9): until the server does it,
/// the client adds every participant to **every** task of a Class. This works
/// out which (participant, task) pairs are still missing — for create, for
/// "add person" / "add task", and for reconciling an incomplete class on load.
///
/// Identity is matched by any shared key: user id, email (case-insensitive),
/// phone (digits only) or username (leading `@` stripped, case-insensitive).
abstract final class ClassFanout {
  /// The identity keys of [contact]; empty when it has no usable identity.
  static Set<String> identityKeys(Contact contact) {
    final Set<String> keys = <String>{};
    final String id = (contact.id ?? '').trim();
    if (id.isNotEmpty) keys.add('id:$id');
    final String email = (contact.email ?? '').trim().toLowerCase();
    if (email.isNotEmpty) keys.add('email:$email');
    final String phone = (contact.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (phone.isNotEmpty) keys.add('phone:$phone');
    String username = (contact.username ?? '').trim().toLowerCase();
    if (username.startsWith('@')) username = username.substring(1);
    if (username.isNotEmpty) keys.add('user:$username');
    return keys;
  }

  /// The identity of a designated user as a [Contact] (the profile when the
  /// server sent one, else the displayed email / phone / username); `null`
  /// when there is nothing to match on.
  static Contact? contactOfUser(DesignatedUser user) {
    if (user.userProfile != null) {
      return Contact.fromUserProfile(user.userProfile!);
    }
    return user.toContact();
  }

  /// De-duplicates [contacts] by shared identity, dropping any without one.
  /// The first occurrence of each person is kept, in order.
  static List<Contact> _distinct(Iterable<Contact> contacts) {
    final List<Contact> kept = <Contact>[];
    final List<Set<String>> keptKeys = <Set<String>>[];
    for (final Contact contact in contacts) {
      final Set<String> keys = identityKeys(contact);
      if (keys.isEmpty) continue;
      final int existing =
          keptKeys.indexWhere((known) => known.any(keys.contains));
      if (existing >= 0) {
        keptKeys[existing].addAll(keys);
      } else {
        kept.add(contact);
        keptKeys.add(<String>{...keys});
      }
    }
    return kept;
  }

  /// Everyone assigned to at least one of [tilettes], de-duplicated, in order
  /// of first appearance.
  static List<Contact> participantsOf(Iterable<TileShareTemplate> tilettes) {
    final List<Contact> all = <Contact>[];
    for (final TileShareTemplate tilette in tilettes) {
      for (final DesignatedUser user
          in tilette.designatedUsers ?? const <DesignatedUser>[]) {
        final Contact? contact = contactOfUser(user);
        if (contact != null) all.add(contact);
      }
    }
    return _distinct(all);
  }

  /// The (participant, tilette) pairs where the participant is not yet a
  /// designated user of the tilette. Tilette-major order, then participant
  /// order, so the result is deterministic.
  static List<ClassFanoutGap> missing({
    required Iterable<TileShareTemplate> tilettes,
    required Iterable<Contact> participants,
  }) {
    final List<Contact> people = _distinct(participants);
    final List<ClassFanoutGap> gaps = <ClassFanoutGap>[];
    for (final TileShareTemplate tilette in tilettes) {
      final Set<String> present = <String>{};
      for (final DesignatedUser user
          in tilette.designatedUsers ?? const <DesignatedUser>[]) {
        final Contact? contact = contactOfUser(user);
        if (contact != null) present.addAll(identityKeys(contact));
      }
      for (final Contact person in people) {
        if (!identityKeys(person).any(present.contains)) {
          gaps.add(ClassFanoutGap(person, tilette));
        }
      }
    }
    return gaps;
  }
}
