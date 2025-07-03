import 'package:flutter/material.dart';
import 'package:tiler_app/util.dart';

//ey: not used
class DatePickerField extends StatelessWidget {
  final String hintText;
  final TextEditingController dateController;
  DatePickerField({required this.hintText, required this.dateController});

  //TextEditingController dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(right: 15, top: 10, left: 15),
      child: TextFormField(
          controller: dateController,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 17),
          textAlign: TextAlign.start,
          decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none),
              hintText: hintText,
              fillColor: Colors.red[350],
              filled: true,
              prefixIcon: Icon(
                Icons.calendar_month,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 17)),
          onTap: () async {
            List months = [
              'Jan',
              'Feb',
              'Mar',
              'April',
              'May',
              'Jun',
              'July',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec'
            ];
            DateTime date = DateTime(1900);
            FocusScope.of(context).requestFocus(new FocusNode());

            date = (await showDatePicker(
                context: context,
                initialDate: Utility.currentTime(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100)))!;
            String month = months[date.month - 1];
            dateController.text = "${date.day} $month, ${date.year}";
          }),
    );
  }
}
