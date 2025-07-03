import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/datePickers/weeklyDatePicker/weeklyPickerDialog.dart';
import 'dart:ui';

import 'package:tiler_app/theme/tile_text_styles.dart';

class WeekPickerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme= Theme.of(context);
    final colorScheme=theme.colorScheme;
    return BlocBuilder<WeeklyUiDateManagerBloc, WeeklyUiDateManagerState>(
      builder: (context, state) {
        return InkWell(
          onTap: () => _showWeekPickerDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.MMMM().format(state.selectedDate),
                style: TileTextStyles.datePickersMain,
              ),
              SizedBox(width: 6.0),
              Transform.rotate(
                angle: 1.5 * 3.14159,
                child: Icon(Icons.arrow_back_ios_new_sharp,
                    size: 24.0, color: colorScheme.onSurface),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeekPickerDialog(BuildContext context) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Center(child: WeeklyPickerDialog()),
          ],
        ),
        transitionsBuilder: (context, animation, _, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 3 * animation.value,
              sigmaY: 3 * animation.value,
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result == null) {
      context.read<WeeklyUiDateManagerBloc>().add(ResetTempEvent());
    }
  }
}
