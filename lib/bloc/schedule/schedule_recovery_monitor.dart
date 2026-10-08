import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// One application-wide observer; connectivity is a retry hint, not proof
/// that the API is reachable.
class ScheduleRecoveryMonitor with WidgetsBindingObserver {
  ScheduleRecoveryMonitor({
    required this.onRecover,
    required this.onSuspend,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
  })  : _connectivityChanges =
            connectivityChanges ?? Connectivity().onConnectivityChanged,
        _check = checkConnectivity ?? Connectivity().checkConnectivity;
  final Stream<List<ConnectivityResult>> _connectivityChanges;
  final Future<List<ConnectivityResult>> Function() _check;
  final VoidCallback onRecover;
  final VoidCallback onSuspend;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _foreground = true;
  bool? _connected;
  bool _closed = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _subscription = _connectivityChanges.listen(_update, onError: (Object _) {});
    unawaited(_checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      _update(await _check());
    } catch (_) {
      // Status requests still retry if the platform check is unavailable.
    }
  }

  void _update(List<ConnectivityResult> results) {
    if (_closed) return;
    final connected = results.any((r) => r != ConnectivityResult.none);
    final restored = _connected == false && connected;
    _connected = connected;
    if (!connected) onSuspend();
    if (restored && _foreground) onRecover();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closed) return;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      onRecover();
      unawaited(_checkConnectivity());
    } else {
      onSuspend();
    }
  }

  void close() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
  }
}
