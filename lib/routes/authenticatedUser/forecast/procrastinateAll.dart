import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

/// "Defer all": push everything back by a chosen duration.
///
/// The screen IS the redesigned duration picker ([AddTileDurationScreen],
/// titled "Defer"); it used to embed the raw package `DurationPicker` inside
/// the old Cancel/Proceed template, the last of the pre-redesign duration
/// looks. Committing a value runs the defer and pops; Back defers nothing.
class ProcrastinateAll extends StatefulWidget {
  /// Optional API seam (tests). Production creates its own.
  final ScheduleApi? scheduleApi;

  const ProcrastinateAll({Key? key, this.scheduleApi}) : super(key: key);

  @override
  _ProcrastinateAllState createState() => _ProcrastinateAllState();
}

class _ProcrastinateAllState extends State<ProcrastinateAll> {
  late ScheduleApi _scheduleApi;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scheduleApi =
        widget.scheduleApi ?? ScheduleApi(getContextCallBack: () => context);
  }

  void showMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: colorScheme.inverseSurface,
        textColor: colorScheme.onInverseSurface,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
          content: Text(message),
          action: SnackBarAction(
              label: AppLocalizations.of(context)!.close,
              onPressed: scaffold.hideCurrentSnackBar)),
    );
  }

  /// Defers everything by [duration], then leaves the screen. The request is
  /// awaited before popping so a caller refreshing on return (the preview
  /// sheet does) sees the deferred schedule, not the old one.
  Future<void> _deferAll(Duration duration) async {
    if (_submitting || duration.inMilliseconds <= 0) return;
    // Busy from the first frame: the picker dims and shows a spinner so the
    // tap is visibly acknowledged while the request is in flight.
    setState(() => _submitting = true);
    try {
      await _scheduleApi.procrastinateAll(duration);
      AnalysticsSignal.send('PROCRASTINATE_ALL_SUCCESS');
      if (!mounted) return;
      showMessage(
          AppLocalizations.of(context)!.clearedColon + duration.toHuman);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showErrorMessage(AppLocalizations.of(context)!.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddTileDurationScreen(
      title: AppLocalizations.of(context)!.defer,
      initialDuration: Duration.zero,
      onSelected: _deferAll,
      busy: _submitting,
    );
  }
}
