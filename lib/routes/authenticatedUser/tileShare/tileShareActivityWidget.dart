import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/tileShareActivityChanges.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'tileShareDetailWidget.dart';
import 'tileShareTemplateDetail.dart';

typedef TileShareActivityLoader = Future<TileShareActivityPage> Function(
    {String? clusterId, String? tiletteId, String? cursor});

class TileShareActivityWidget extends StatefulWidget {
  final String? clusterId;
  final String? tiletteId;
  final TileShareActivityLoader? loader;
  const TileShareActivityWidget(
      {super.key, this.clusterId, this.tiletteId, this.loader});

  @override
  State<TileShareActivityWidget> createState() => _TileShareActivityState();
}

class _TileShareActivityState extends State<TileShareActivityWidget>
    with WidgetsBindingObserver {
  TileShareActivityApi? _api;
  List<TileShareActivity> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _failed = false;
  bool _denied = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tileShareActivityChanges.addListener(_load);
    if (widget.loader == null)
      _api = TileShareActivityApi(getContextCallBack: () => context);
    _load();
  }

  @override
  void didUpdateWidget(covariant TileShareActivityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clusterId != oldWidget.clusterId ||
        widget.tiletteId != oldWidget.tiletteId) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ++_generation;
      setState(() {
        _items = [];
        _cursor = null;
      });
    }
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    final cursor = more ? _cursor : null;
    setState(() {
      _loading = true;
      _failed = false;
      _denied = false;
      if (!more) {
        _items = [];
        _cursor = null;
      }
    });
    try {
      final page = await (widget.loader ?? _api!.getActivity)(
          clusterId: widget.clusterId,
          tiletteId: widget.tiletteId,
          cursor: cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = {
          for (final item in [..._items, ...page.items]) item.eventId: item
        }.values.toList();
        _cursor = page.nextCursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [];
        _cursor = null;
        _loading = false;
        _failed = true;
        _denied = error is TileShareActivityAccessException;
      });
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    tileShareActivityChanges.removeListener(_load);
    _api?.dispose();
    super.dispose();
  }

  String _label(TileShareActivity item, AppLocalizations l) {
    if (!item.isKnown) return l.tileShareActivityUnknown;
    return switch (item.eventType) {
      'cluster_created' => l.tileShareActivityClusterCreated,
      'cluster_deleted' => l.tileShareActivityClusterDeleted,
      'tilette_added' => l.tileShareActivityTiletteAdded,
      'tilette_edited' => l.tileShareActivityTiletteEdited,
      'tilette_deleted' => l.tileShareActivityTiletteDeleted,
      'tilette_restored' => l.tileShareActivityTiletteRestored,
      'recipient_added' => l.tileShareActivityRecipientAdded,
      'recipient_removed' => l.tileShareActivityRecipientRemoved,
      'recipient_restored' => l.tileShareActivityRecipientRestored,
      'assignment_accepted' => l.tileShareActivityAccepted,
      'assignment_declined' => l.tileShareActivityDeclined,
      'invitation_sent' => l.tileShareActivityInvitationSent,
      'invitation_send_failed' => l.tileShareActivityInvitationFailed,
      'invitation_send_unknown' => l.tileShareActivityInvitationUnknown,
      _ => l.tileShareActivityUnknown,
    };
  }

  Future<void> _open(TileShareActivity item) async {
    final l = AppLocalizations.of(context)!;
    final api = TileShareClusterApi(getContextCallBack: () => context);
    try {
      if (item.tiletteId == null) {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                TileShareDetailWidget.byId(tileShareId: item.clusterId)));
      } else {
        final templates = await api.getTileShareTemplates(
            tileShareTemplateId: item.tiletteId, clusterId: item.clusterId);
        if (!mounted) return;
        if (templates.isEmpty) throw StateError('Unavailable target');
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TileShareTemplateDetailWidget(
                tileShareTemplate: templates.first)));
      }
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.tileShareActivityUnavailable)));
        await _load();
      }
    } finally {
      api.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Text(l.tileShareActivityTitle,
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    tooltip: l.tileShareActivityRefresh,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh)),
              ])),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_failed)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(_denied
                      ? l.tileShareActivityAccess
                      : l.tileShareActivityFailed),
                  TextButton(
                      onPressed: _load, child: Text(l.tileShareActivityRetry)),
                ])),
          if (!_loading && !_failed && _items.isEmpty)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.tileShareActivityEmpty)),
          for (int i = 0; i < _items.length; i++) ...[
            if (i == 0 ||
                !DateUtils.isSameDay(_items[i - 1].occurredAt.toLocal(),
                    _items[i].occurredAt.toLocal()))
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                      material.formatFullDate(_items[i].occurredAt.toLocal()))),
            ListTile(
                onTap:
                    _items[i].targetAvailable ? () => _open(_items[i]) : null,
                title: Text(_label(_items[i], l)),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_items[i].invitationChannel != null)
                        Text(switch (_items[i].invitationChannel) {
                          'email' => l.tileShareActivityEmail,
                          'sms' => l.tileShareActivitySms,
                          _ => l.tileShareActivityPush,
                        }),
                      if (_items[i].isKnown &&
                          _items[i].eventType == 'invitation_send_unknown')
                        Text(l.tileShareActivityExplicitResend),
                      if (_items[i].actorName != null)
                        Text(_items[i].actorName!),
                      if (widget.clusterId == null &&
                          _items[i].clusterTitle != null)
                        Text(_items[i].clusterTitle!),
                      if (_items[i].title != null) Text(_items[i].title!),
                      Text(material.formatTimeOfDay(TimeOfDay.fromDateTime(
                          _items[i].occurredAt.toLocal()))),
                      if (!_items[i].targetAvailable)
                        Text(l.tileShareActivityUnavailable),
                    ])),
          ],
          if (_cursor != null && !_loading)
            TextButton(
                onPressed: () => _load(more: true),
                child: Text(l.tileShareActivityMore)),
        ]));
  }
}

class TileShareActivityButton extends StatelessWidget {
  final String clusterId;
  final String? tiletteId;
  const TileShareActivityButton(
      {super.key, required this.clusterId, this.tiletteId});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: AppLocalizations.of(context)!.tileShareActivityTitle,
        icon: const Icon(Icons.history),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => Scaffold(
                  appBar: AppBar(
                      title: Text(AppLocalizations.of(context)!
                          .tileShareActivityTitle)),
                  body: TileShareActivityWidget(
                      clusterId: clusterId, tiletteId: tiletteId),
                ))),
      );
}
