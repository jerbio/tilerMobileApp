import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/datePickers/monthlyDatePicker/monthlyPickerDialog.dart';
import 'package:tiler_app/styles.dart';
import 'dart:ui';

class MonthPickerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyUiDateManagerBloc, MonthlyUiDateManagerState>(
      builder: (context, state) {
        return InkWell(
          onTap: () => _showMonthPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM').format(state.selectedDate),
                style: TileStyles.datePickersMainStyle,
              ),
              SizedBox(width: 6.0),
              Transform.rotate(
                angle: 1.5 * 3.14159,
                child: Icon(Icons.arrow_back_ios_new_sharp, size: 24.0, color: TileStyles.defaultTextColor),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showMonthPicker(BuildContext context) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Center(child: MonthlyPickerDialog()),
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
      context.read<MonthlyUiDateManagerBloc>().add(ResetTempEvent());
    }
  }
}
