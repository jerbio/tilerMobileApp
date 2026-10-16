import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';

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
    scheduleFlowLog('recovery_monitor_started',
        fields: {'foreground': _foreground});
    _subscription =
        _connectivityChanges.listen(_update, onError: (Object error) {
      scheduleFlowLog('connectivity_stream_error', error: error);
    });
    unawaited(_checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      _update(await _check());
    } catch (error) {
      scheduleFlowLog('connectivity_check_failed', error: error);
      // Status requests still retry if the platform check is unavailable.
    }
  }

  void _update(List<ConnectivityResult> results) {
    if (_closed) return;
    final connected = results.any((r) => r != ConnectivityResult.none);
    final restored = _connected == false && connected;
    scheduleFlowLog('connectivity_observed', fields: {
      'connected': connected,
      'previousConnected': _connected,
      'restored': restored,
      'foreground': _foreground,
    });
    _connected = connected;
    if (!connected) onSuspend();
    if (restored && _foreground) onRecover();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closed) return;
    _foreground = state == AppLifecycleState.resumed;
    scheduleFlowLog('app_lifecycle',
        fields: {'lifecycle': state.name, 'foreground': _foreground});
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
