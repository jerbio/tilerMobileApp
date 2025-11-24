import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

class ProcrastinateAll extends StatefulWidget {
  @override
  _ProcrastinateAllState createState() => _ProcrastinateAllState();
}

class _ProcrastinateAllState extends State<ProcrastinateAll> {
  Duration _duration = Duration();
  late ScheduleApi _scheduleApi;
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme==theme.colorScheme;
    super.didChangeDependencies();
  }

  static final String procrastinateAllCancelAndProceedRouteName =
      "procrastinateAllCancelAndProceed";

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: colorScheme.inverseSurface,
        textColor:  colorScheme.onInverseSurface,
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

  @override
  Widget build(BuildContext context) {
    Function? callBackOnProcrastinate;
    if (_duration.inMilliseconds > 0) {
      callBackOnProcrastinate = () {
        return _scheduleApi.procrastinateAll(_duration).then((value) {
          AnalysticsSignal.send('PROCRASTINATE_ALL_SUCCESS');
          showMessage(
              AppLocalizations.of(context)!.clearedColon + _duration.toHuman);
        });
      };
    }
    return CancelAndProceedTemplateWidget(
      routeName: procrastinateAllCancelAndProceedRouteName,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.defer),
        automaticallyImplyLeading: false,
      ),
      child: Container(
          margin: EdgeInsets.fromLTRB(
              0, MediaQuery.of(context).size.height / 4, 0, 0),
          alignment: Alignment.topCenter,
          child: DurationPicker(
              duration: _duration,
              onChange: (val) {
                setState(() => _duration = val);
              })),
      onProceed: callBackOnProcrastinate,
    );
  }
}
