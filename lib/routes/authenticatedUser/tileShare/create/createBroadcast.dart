import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/contactFieldRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/deadlinePicker.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/shareDetailsForm.dart'
    show shareNameMaxLength, shareNameMinLength;
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personLine.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Picks a length, starting from [seed]. Injected in tests.
typedef CreatePickDuration = Future<Duration?> Function(
  BuildContext context,
  Duration seed,
);

/// Called once the share exists, with its id; the host opens it.
typedef OnShareCreated = void Function(BuildContext context, String clusterId);

/// A Broadcast's length when none is picked.
const Duration defaultBroadcastLength = Duration(hours: 1);

/// A new share's deadline when none is picked: a week from [now], at the end
/// of that day. Every share has one (owner, 9.18).
DateTime defaultShareDeadline(DateTime now) =>
    DateTime(now.year, now.month, now.day + 7, 23, 59);

Future<Duration?> _durationScreen(BuildContext context, Duration seed) =>
    pushDurationPicker(context, initialDuration: seed);

/// Create a Broadcast (T14, §5.7) - one screen: its name, its one tilette's
/// length, the deadline and the people; each person gets their own copy.
///
///  * Send stays tappable and says what is missing (a name of 3+
///    characters, someone to send it to); a length is always set.
///  * Send creates the share by its mode (`Mode: broadcast`, its one
///    tilette sent explicitly) and hands its id to [onCreated]; a refusal
///    keeps everything and says so.
///  * Leaving with something entered asks first.
class CreateBroadcastScreen extends StatefulWidget {
  final TileShareCreateSource source;
  final OnShareCreated onCreated;
  final DateTime Function() now;
  final CreatePickDuration pickDuration;
  final DeadlinePickDate pickDate;
  final DeadlinePickTime pickTime;

  const CreateBroadcastScreen({
    super.key,
    required this.source,
    required this.onCreated,
    this.now = DateTime.now,
    this.pickDuration = _durationScreen,
    this.pickDate = platformPickDate,
    this.pickTime = platformPickTime,
  });

  @override
  State<CreateBroadcastScreen> createState() => _CreateBroadcastScreenState();
}

class _CreateBroadcastScreenState extends State<CreateBroadcastScreen> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Duration _length = defaultBroadcastLength;
  late DateTime _deadline;
  late final DateTime _initialDeadline;
  final List<Contact> _people = <Contact>[];
  String? _duplicate;
  String? _nameError;
  bool _needsPerson = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialDeadline = defaultShareDeadline(widget.now());
    _deadline = _initialDeadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _entered =>
      _name.text.trim().isNotEmpty ||
      _people.isNotEmpty ||
      _length != defaultBroadcastLength ||
      _deadline != _initialDeadline;

  bool get _ready =>
      _name.text.trim().length >= shareNameMinLength && _people.isNotEmpty;

  static String _labelOf(Contact contact) =>
      (contact.email ?? contact.phoneNumber ?? '').trim();

  /// Adds someone; someone already on the list is said so, as listed.
  void _add(Contact contact) {
    final Set<String> keys = ClassFanout.identityKeys(contact);
    final Contact? known = _people
        .where((c) => ClassFanout.identityKeys(c).any(keys.contains))
        .firstOrNull;
    setState(() {
      if (known != null) {
        _duplicate = _labelOf(known);
      } else {
        _duplicate = null;
        _needsPerson = false;
        _people.add(contact);
      }
    });
  }

  Future<void> _pickLength() async {
    final Duration? picked = await widget.pickDuration(context, _length);
    if (picked != null && picked > Duration.zero && mounted) {
      setState(() => _length = picked);
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await pickDeadline(
      context,
      _deadline,
      pickDate: widget.pickDate,
      pickTime: widget.pickTime,
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  String? _nameProblem(AppLocalizations l10n) {
    final String name = _name.text.trim();
    if (name.isEmpty) return l10n.addTileNameRequired;
    if (name.length < shareNameMinLength) return l10n.taskSheetNameTooShort;
    return null;
  }

  Future<void> _send() async {
    if (_busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? problem = _nameProblem(l10n);
    if (problem != null || _people.isEmpty) {
      setState(() {
        _nameError = problem;
        _needsPerson = _people.isEmpty;
      });
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    // By its mode only (the legacy IsMultiTilette is for older apps), so
    // the Broadcast's one tilette is sent as such, with its people; the
    // share's own list is empty, never null (the server joins the two).
    final int start = widget.now().millisecondsSinceEpoch;
    final int end = _deadline.millisecondsSinceEpoch;
    final ClusterTemplateTileModel tilette = ClusterTemplateTileModel()
      ..Name = _name.text.trim()
      ..DurationInMs = _length.inMilliseconds
      ..StartTime = start
      ..EndTime = end
      ..Contacts = _people.map((c) => c.toContactModel()).toList();
    final TileShareClusterData share = TileShareClusterData()
      ..name = _name.text.trim()
      ..mode = TileShareMode.broadcast
      ..startTimeInMs = start
      ..endTimeInMs = end
      ..contacts = <Contact>[]
      ..tilettes = <ClusterTemplateTileModel>[tilette];
    final String id;
    try {
      id = await widget.source.createShare(share);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    widget.onCreated(context, id);
  }

  /// Leaves, asking first when something was entered.
  Future<void> _leave() async {
    if (!_entered) {
      Navigator.of(context).pop();
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createDiscardTitle),
        content: Text(l10n.createDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notesConflictKeepEditing),
          ),
          TextButton(
            key: const Key('create_broadcast_discard'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.editTileDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? quiet = textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );
    final String locale = Localizations.localeOf(context).toString();
    return PopScope(
      canPop: !_entered || _busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        key: const Key('create_broadcast'),
        backgroundColor: tokens.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('create_broadcast_close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: _busy ? null : _leave,
          ),
          title: Text(l10n.createBroadcastTitle),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddTileSection(
                      children: [
                        AddTileTextFieldRow(
                          icon: Icons.edit_outlined,
                          label: l10n.shareNameLabel,
                          controller: _name,
                          focusNode: _nameFocus,
                          fieldKey: const Key('create_broadcast_name'),
                          required: true,
                          maxLength: shareNameMaxLength,
                          error: _nameError,
                          onChanged: (_) => setState(() => _nameError = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AddTileSection(
                      children: [
                        AddTileFieldRow(
                          key: const Key('create_broadcast_length'),
                          icon: Icons.hourglass_empty_rounded,
                          label: l10n.addTileFieldDuration,
                          value: formatDurationSummary(l10n, _length) ?? '',
                          onTap: _busy ? null : _pickLength,
                        ),
                        AddTileFieldRow(
                          key: const Key('create_broadcast_deadline'),
                          icon: Icons.flag_outlined,
                          label: l10n.editTileFieldDeadline,
                          value: DateFormat.yMMMEd(locale)
                              .add_jm()
                              .format(_deadline),
                          onTap: _busy ? null : _pickDeadline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                      child: Text(
                        l10n.taskSheetPeopleLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    AddTileSection(
                      children: [
                        // People added or taken off grow in and shrink out
                        // (T11).
                        AnimatedKeyedColumn(
                          children: [
                            for (final Contact c in _people)
                              KeyedSubtree(
                                key: Key(
                                  'create_broadcast_person_${_labelOf(c)}',
                                ),
                                child: PersonLine(
                                  label: _labelOf(c),
                                  trailing: [
                                    IconButton(
                                      key: Key(
                                        'create_broadcast_remove_${_labelOf(c)}',
                                      ),
                                      tooltip: l10n.participantRemove,
                                      onPressed: _busy
                                          ? null
                                          : () => setState(
                                              () => _people.remove(c),
                                            ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        KeyedSubtree(
                          key: const Key('create_broadcast_add_person'),
                          child: ContactFieldRow(
                            label: l10n.taskSheetAddPerson,
                            message: _duplicate == null
                                ? null
                                : l10n.participantAlreadyInvited(_duplicate!),
                            onContact: _add,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                      child: Text(l10n.createBroadcastPeopleHint, style: quiet),
                    ),
                    RevealSlot(
                      child: _failed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AddTileCallout(
                                key: const Key('create_broadcast_failed'),
                                icon: Icons.error_outline,
                                text: l10n.createFailed,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            AddTilePrimaryButton(
              key: const Key('create_broadcast_send'),
              label: _people.isEmpty
                  ? l10n.createSend
                  : l10n.createSendTo(_people.length),
              busyLabel: l10n.createSending,
              enabled: _ready,
              busy: _busy,
              hint: _needsPerson ? l10n.createNeedsPerson : null,
              onTap: _send,
            ),
          ],
        ),
      ),
    );
  }
}
