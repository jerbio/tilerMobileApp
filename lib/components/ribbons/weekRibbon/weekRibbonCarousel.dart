import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/ribbons/weekRibbon/weekDayButton.dart';
import 'package:tiler_app/util.dart';

class WeeklyRibbonCarousel extends StatefulWidget {
  @override
  _WeeklyRibbonCarouselState createState() => _WeeklyRibbonCarouselState();
}

class _WeeklyRibbonCarouselState extends State<WeeklyRibbonCarousel> {
  final CarouselController _carouselController = CarouselController();
  late List<List<DateTime>> _weeks;

  @override
  void initState() {
    super.initState();
    final state = context.read<WeeklyUiDateManagerBloc>().state;
    _weeks = _getWeeksInMonth(state.selectedDate.year, state.selectedDate.month);
  }

  List<List<DateTime>> _getWeeksInMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1).dayDate;
    final daysInMonth = Utility.getDaysInMonth(firstDayOfMonth);
    List<List<DateTime>> weeksInMonth = List.generate(
        (daysInMonth.length / 7).ceil(),
            (index) {
          var weekDates = daysInMonth.skip(index * 7).take(7).map((date) {
            DateTime weekDate = DateTime(date.year, date.month, date.day).dayDate;
            return weekDate;
          }).toList();
          return weekDates;
        }
    );
    return weeksInMonth;
  }
  Widget _buildWeekWidget(List<DateTime> week) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((date) => WeekDayButton(
        dateTime: date,
        showMonth: date.day == 1 ,
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeeklyUiDateManagerBloc, WeeklyUiDateManagerState>(
      listenWhen: (previous, current) => !listEquals(previous.selectedWeek, current.selectedWeek)||previous.selectedDate!= current.selectedDate,
      listener: (context, state) {
      if (state.selectedDate.year != _weeks.first.first.year ||
          state.selectedDate.month != _weeks.first.last.month) {
        setState(() {
          _weeks = _getWeeksInMonth(
              state.selectedDate.year, state.selectedDate.month);
        });
      }
      final selectedWeekIndex = _weeks.indexWhere((week) {
        bool isMatch = week.first.dayDate.isAtSameMomentAs(
            state.selectedWeek.first);
        return isMatch;
      });
      if (selectedWeekIndex != -1) {
        _carouselController.jumpToPage(selectedWeekIndex);
    }
      },
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
          width: MediaQuery.of(context).size.width,
          height: 130,
            child: CarouselSlider(
              carouselController: _carouselController,
              items: _weeks.map(_buildWeekWidget).toList(),
              options: CarouselOptions(
                viewportFraction: 1,
                enableInfiniteScroll: false,
                initialPage: _weeks.indexWhere((week) =>
                    week.first.isAtSameMomentAs(state.selectedWeek.first)),
                onPageChanged:(index, reason){
                    context.read<WeeklyUiDateManagerBloc>().add(
                      UpdateSelectedWeek(selectedDate: _weeks[index].first),
                    );
                },
            ),
          ),
        );
      },
    );
  }
}
