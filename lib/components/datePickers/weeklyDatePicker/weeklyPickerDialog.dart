import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WeeklyPickerDialog extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeeklyUiDateManagerBloc, WeeklyUiDateManagerState>(
      builder: (context, state) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                child: Text(
                    AppLocalizations.of(context)!.selectWeek,
                    style: TextStyle(fontSize: 20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${DateFormat('d MMM').format(state.tempSelectedWeek.first)} - ${DateFormat('d MMM').format(
                      state.tempSelectedWeek.last )}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              _buildMonthYearPicker(context, state),
              TableCalendar(
                firstDay: Utility.getFirstDate(),
                lastDay: Utility.getLastDate(),
                focusedDay: state.tempDate,
                selectedDayPredicate: (day) =>
                    (state.tempSelectedWeek ).any((d) =>
                        isSameDay(d, day)),
                onDaySelected: (selectedDay, _) {
                  DateTime selectedDate=Utility.getWeekSunday(selectedDay);
                  context.read<WeeklyUiDateManagerBloc>().add(
                      SetTempSelectedWeek(selectedDate: selectedDate));
                },
                onPageChanged: (focusedDay) {
                  context.read<WeeklyUiDateManagerBloc>().add(UpdateTempDate(tempDate: focusedDay.dayDate));
                },
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarFormat: CalendarFormat.month,
                calendarStyle:CalendarStyle(
                  isTodayHighlighted: false,
                  defaultDecoration: BoxDecoration(shape: BoxShape.rectangle),
                  selectedDecoration: BoxDecoration(color: TileStyles.primaryColor),
                  outsideDecoration: BoxDecoration(shape: BoxShape.rectangle),
                ),
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, date, _) {
                    bool isFirstDay = date.weekday == DateTime.sunday;
                    bool isLastDay = date.weekday == DateTime.saturday;

                    return Container(
                      margin: isFirstDay ? const EdgeInsets.only(left: 8.0) :
                      isLastDay ? const EdgeInsets.only(right: 8.0) : EdgeInsets
                          .zero,
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      height: 45.0,
                      decoration: BoxDecoration(
                        border: Border(
                          left: isFirstDay
                              ? BorderSide(
                              color: TileStyles.primaryColor, width: 2)
                              : BorderSide.none,
                          right: isLastDay
                              ? BorderSide(
                              color: TileStyles.primaryColor, width: 2)
                              : BorderSide.none,
                          top: BorderSide(
                              color: TileStyles.primaryColor, width: 2),
                          bottom: BorderSide(
                              color: TileStyles.primaryColor, width: 2),
                        ),
                        borderRadius: isFirstDay ? BorderRadius.horizontal(
                            left: Radius.circular(25)) :
                        isLastDay ? BorderRadius.horizontal(
                            right: Radius.circular(25)) : BorderRadius.zero,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                          '${date.day}',
                          style:TextStyle(color:TileStyles.defaultTextColor),
                      ),
                    );
                  },
                  todayBuilder: (context, date, _) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration:BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                          '${date.day}',
                          style: TextStyle(color:TileStyles.primaryContrastColor),
                      ),
                    );
                  },
                ),
                headerVisible: false,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<WeeklyUiDateManagerBloc>().add(UpdateSelectedWeek(
                          selectedDate: state.tempSelectedWeek.first)
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.save, style: TileStyles.datePickersSaveStyle),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthYearPicker(BuildContext context,
      WeeklyUiDateManagerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () =>
                  context.read<WeeklyUiDateManagerBloc>().add(UpdateTempDate(tempDate: DateTime(state.tempDate.year, state.tempDate.month - 1).dayDate))
          ),
          TextButton(
            onPressed: () => _selectYear(context),
            child: Text(
              '${DateFormat.MMMM().format(
                  state.tempDate)} ${state
                  .tempDate.year}',
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: TileStyles.primaryColor
              )
            ),
          ),
          IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () =>
                  context.read<WeeklyUiDateManagerBloc>().add(UpdateTempDate(tempDate: DateTime(state.tempDate.year, state.tempDate.month + 1).dayDate))
          ),
        ],
      ),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final bloc = context.read<WeeklyUiDateManagerBloc>();
    final state = bloc.state;
    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectYear,),
            content: Container(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                ),
                itemCount: 11,
                itemBuilder: (context, index) {
                  int displayedYear = DateTime.now().year - 5 + index;
                  bool isSelected = displayedYear == state.tempDate.year;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, displayedYear);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color:TileStyles.primaryColor, width: 2)
                            : Border.all(color: Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$displayedYear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: TileStyles.defaultTextColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
      },
    );
    if (selectedYear != null && selectedYear != state.tempDate.year) {
      bloc.add(UpdateTempDate(tempDate: DateTime(selectedYear, state.tempDate.month).dayDate));
    }
  }

}
