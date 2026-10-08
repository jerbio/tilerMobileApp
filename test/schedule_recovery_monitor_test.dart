import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_recovery_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reconnects only in foreground, resumes, and cleans up', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    var recoveries = 0;
    var suspensions = 0;
    final monitor = ScheduleRecoveryMonitor(
      onRecover: () => recoveries++,
      onSuspend: () => suspensions++,
      connectivityChanges: changes.stream,
      checkConnectivity: () async => [ConnectivityResult.none],
    );
    monitor.start();
    await Future<void>.delayed(Duration.zero);
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    final before = recoveries;
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(recoveries, before + 1);
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(recoveries, before + 1);
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    changes.add([ConnectivityResult.none]);
    changes.add([ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);
    expect(recoveries, before + 1);
    expect(suspensions, greaterThan(0));
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(recoveries, before + 2);
    monitor.close();
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(recoveries, before + 2);
    await changes.close();
  });
}
