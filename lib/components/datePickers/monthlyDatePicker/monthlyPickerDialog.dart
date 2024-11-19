import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MonthlyPickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyUiDateManagerBloc, MonthlyUiDateManagerState>(
      builder: (context, state) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, state),
                _buildMonthGrid(context, state),
                _buildFooter(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MonthlyUiDateManagerState state) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration:BoxDecoration(
      color: TileStyles.primaryColor,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM yyyy').format(state.tempDate),
            style: TextStyle(color: TileStyles.primaryContrastColor, fontSize: 20),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.year}',
                style: TextStyle(color: TileStyles.primaryContrastColor, fontSize: 24),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Transform.rotate(
                      angle: -math.pi / 2,
                      child: Icon(Icons.arrow_back_ios_new_sharp, color: TileStyles.primaryContrastColor),
                    ),

                    onPressed: () => context.read<MonthlyUiDateManagerBloc>().add(ChangeYear(year: state.year - 1)),
                  ),
                  IconButton(
                    icon:Transform.rotate(
                      angle: math.pi / 2,
                      child: Icon(Icons.arrow_back_ios_new_sharp, color:TileStyles.primaryContrastColor),
                    ),
                    onPressed: () => context.read<MonthlyUiDateManagerBloc>().add(ChangeYear(year: state.year + 1)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, MonthlyUiDateManagerState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == state.tempDate.month && state.tempDate.year ==state.year ;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>  context.read<MonthlyUiDateManagerBloc>().add(ChangeMonth(month: month)),
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration:  isSelected ? BoxDecoration(
              border:Border.all(color: TileStyles.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ) : null,
            alignment: Alignment.center,
            child: Text(
              DateFormat('MMM').format(DateTime(state.year, month)),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: TileStyles.defaultTextColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
            context.read<MonthlyUiDateManagerBloc>().add(
                UpdateSelectedMonthOnPicking()
            );
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.save, style: TileStyles.datePickersSaveStyle),
        ),
      ),
    );

  }

}