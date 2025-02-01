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
  late int _initialItem;
  bool _isCarouselChange = false;
  bool _isManualJump = false;
  List<List<DateTime>> nextMonthWeeks = [];
  List<List<DateTime>> prevMonthWeeks = [];
  int? prevAnchorMonth = null;

  @override
  void initState() {
    super.initState();
    final state = context.read<WeeklyUiDateManagerBloc>().state;
    _weeks =
        _getWeeksInMonth(state.selectedDate.year, state.selectedDate.month);
    _initialItem = _weeks.indexWhere(
        (week) => week.first.isAtSameMomentAs(state.selectedWeek.first));
    _loadExtraMonths(_initialItem);
  }

  List<List<DateTime>> _getWeeksInMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1).dayDate;
    final daysInMonth = Utility.getDaysInMonth(firstDayOfMonth);
    List<List<DateTime>> weeksInMonth =
        List.generate((daysInMonth.length / 7).ceil(), (index) {
      var weekDates = daysInMonth.skip(index * 7).take(7).map((date) {
        DateTime weekDate = DateTime(date.year, date.month, date.day).dayDate;
        return weekDate;
      }).toList();
      return weekDates;
    });
    return weeksInMonth;
  }

  Widget _buildWeekWidget(List<DateTime> week) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: week
          .map((date) => Container(
                child: WeekDayButton(
                  dateTime: date,
                  showMonth: date.day == 1,
                ),
              ))
          .toList(),
    );
  }

  void _loadNextMonth() {
    final lastDate = _weeks.last.first;
    int nextMonth = lastDate.month + 1;
    int nextYear = lastDate.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    nextMonthWeeks = _getWeeksInMonth(nextYear, nextMonth);
    if (listEquals(nextMonthWeeks.first, _weeks.last))
      nextMonthWeeks.removeAt(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _weeks.addAll(nextMonthWeeks);
      });
    });
  }

  void _loadPreviousMonth() {
    final firstDate = _weeks.first.last;
    int prevMonth = firstDate.month - 1;
    int prevYear = firstDate.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }
    prevMonthWeeks = _getWeeksInMonth(prevYear, prevMonth);
    if (listEquals(prevMonthWeeks.last, _weeks.first))
      prevMonthWeeks.removeAt(prevMonthWeeks.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _weeks.insertAll(0, prevMonthWeeks);
        _isManualJump = true;
        _carouselController.jumpToPage(prevMonthWeeks.length);
      });
    });
  }

  void _trimWeeksOnNextLoad(int selectedItem) {
    if (nextMonthWeeks.isEmpty) return;
    int startRangeIndex = 1;
    if (nextMonthWeeks[0].first.day != 1) startRangeIndex = 0;
    if (listEquals(_weeks[selectedItem], nextMonthWeeks[startRangeIndex])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _weeks.removeRange(0, selectedItem - 1);
          _initialItem = 1;
        });
        _isManualJump = true;
        _carouselController.jumpToPage(1);
        nextMonthWeeks = [];
      });
    }
  }

  void _trimWeeksOnPreviousLoad(int selectedItem, int? prevAnchorMonth) {
    if (prevMonthWeeks.isEmpty || prevAnchorMonth == null) return;
    int startRangeIndex = prevMonthWeeks.length - 1;
    if (prevMonthWeeks.last.last.month != prevAnchorMonth) startRangeIndex -= 1;

    if (listEquals(_weeks[selectedItem], prevMonthWeeks[startRangeIndex])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _weeks.removeRange(startRangeIndex + 2, _weeks.length);
          _initialItem = startRangeIndex;
        });
        prevMonthWeeks = [];
      });
    }
  }

  void _loadExtraMonths(int selectedItem) {
    if (selectedItem == 0 &&
        Utility.isDateWithinPickerRange(
            _weeks.first.first.add(Duration(days: -1)))) {
      prevAnchorMonth = _weeks.first.first.month;
      _loadPreviousMonth();
    } else if (selectedItem == _weeks.length - 1 &&
        Utility.isDateWithinPickerRange(
            _weeks.last.last.add(Duration(days: 1)))) {
      _loadNextMonth();
    }
    _trimWeeksOnNextLoad(selectedItem);
    _trimWeeksOnPreviousLoad(selectedItem, prevAnchorMonth);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeeklyUiDateManagerBloc, WeeklyUiDateManagerState>(
      listenWhen: (previous, current) =>
          !listEquals(previous.selectedWeek, current.selectedWeek) ||
          previous.selectedDate != current.selectedDate,
      listener: (context, state) {
        if (_isCarouselChange) {
          _isCarouselChange = false;
          return;
        }
        if (state.selectedDate.isBefore(_weeks.first.first) ||
            state.selectedDate.isAfter(_weeks.last.first)) {
          setState(() {
            _weeks = _getWeeksInMonth(
                state.selectedDate.year, state.selectedDate.month);
          });
        }
        final selectedWeekIndex = _weeks.indexWhere((week) {
          bool isMatch =
              week.first.dayDate.isAtSameMomentAs(state.selectedWeek.first);
          return isMatch;
        });
        if (selectedWeekIndex != -1) {
          _isManualJump = true;
          _carouselController.jumpToPage(selectedWeekIndex);
          _loadExtraMonths(selectedWeekIndex);
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
              initialPage: _initialItem,
              onPageChanged: (index, reason) {
                if (_isManualJump) {
                  _isManualJump = false;
                  return;
                }
                _isCarouselChange = true;
                _loadExtraMonths(index);
                context.read<WeeklyUiDateManagerBloc>().add(
                      UpdateSelectedWeek(
                          selectedDate: index == 0
                              ? _weeks[index].last
                              : _weeks[index].first),
                    );
              },
            ),
          ),
        );
      },
    );
  }
}
