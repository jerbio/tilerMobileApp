import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class MonthlyPickerDialog extends StatefulWidget {
  @override
  State<MonthlyPickerDialog> createState() => _MonthlyPickerDialogState();
}

class _MonthlyPickerDialogState extends State<MonthlyPickerDialog> {
  late PageController _pageController;
  late List<int> _yearPages;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late bool byIcon;

  @override
  void initState() {
    byIcon=false;
    super.initState();
    int currentYear = context.read<MonthlyUiDateManagerBloc>().state.year;
    _yearPages = [currentYear - 2, currentYear - 1, currentYear, currentYear + 1, currentYear + 2];
    _pageController = PageController(initialPage: 2);
  }

  @override
  void didChangeDependencies() {
     theme=Theme.of(context);
     colorScheme=theme.colorScheme;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {



    return BlocBuilder<MonthlyUiDateManagerBloc, MonthlyUiDateManagerState>(
      buildWhen: (previous, current) =>
      previous.tempDate != current.tempDate ||
          previous.year != current.year,
      builder: (context, state) {
        if (state.year != _yearPages[2]) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final selectedIndex = _yearPages.indexOf(state.year);
            if (selectedIndex != -1) {
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  selectedIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ).then((_){
                  if(state.year> _yearPages[2] ){
                    _yearPages.add(_yearPages.last + 1);
                    _yearPages.removeAt(0);
                    _pageController.jumpToPage(2);
                  }else if(state.year< _yearPages[2] && state.year>0){
                    _yearPages.insert(0,_yearPages.first - 1);
                    _yearPages.removeLast();
                    _pageController.jumpToPage(2);
                  }
                  byIcon = false;
                });


              }
            }
          }
          );
        }
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(state),
                SizedBox(
                  height: 240,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _yearPages.length,
                    onPageChanged: (index) {
                      if(byIcon) return;
                      if (!mounted) return;
                      context.read<MonthlyUiDateManagerBloc>().add(ChangeYear(year: _yearPages[index]));
                    },
                    itemBuilder: (context, index) {
                      return _buildMonthGrid(state);
                    },
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader( MonthlyUiDateManagerState state) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                    Icons.arrow_back_ios_new_sharp,
                  ),
                onPressed: () {
                  context.read<MonthlyUiDateManagerBloc>().add(ChangeYear(year: state.year - 1));
                  byIcon=true;
                }
              ),
              Text(
                '${state.year}',
                style: TextStyle(
                    fontSize: 24
                ),
              ),
              IconButton(
                icon: Transform.rotate(
                  angle: math.pi ,
                  child: Icon(
                    Icons.arrow_back_ios_new_sharp,
                  ),
                ),
                onPressed: (){
                  context.read<MonthlyUiDateManagerBloc>().add(ChangeYear(year: state.year + 1));
                  byIcon=true;
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(MonthlyUiDateManagerState state) {
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
        final isSelected =
            month == state.tempDate.month && state.tempDate.year == state.year;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context
              .read<MonthlyUiDateManagerBloc>()
              .add(ChangeMonth(month: month)),
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: isSelected
                ? BoxDecoration(
                    border:
                        Border.all(color: colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              DateFormat('MMM').format(DateTime(state.year, month)),
              style: TextStyle(
                fontSize: 16,
              )
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            context
                .read<MonthlyUiDateManagerBloc>()
                .add(UpdateSelectedMonthOnPicking());
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Text(AppLocalizations.of(context)!.save,
              style: TileTextStyles.datePickersSaveStyle
          ),
        ),
      ),
    );
  }
}
