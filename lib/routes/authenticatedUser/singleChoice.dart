import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

enum Priority { low, medium, high }

class SingleChoice extends StatefulWidget {
  final Function? onChanged;
  final Priority priority;
  const SingleChoice({super.key, this.onChanged, required this.priority});

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {
  late Priority _priorityView;
  @override
  void initState() {
    super.initState();
    _priorityView = this.widget.priority;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Priority>(
      style: TileStyles.toggledButtonStyle,
      segments: <ButtonSegment<Priority>>[
        ButtonSegment<Priority>(
            value: Priority.low,
            label: Text(AppLocalizations.of(context)!.lowPriorityTrunc),
            icon: Icon(Icons.circle)),
        ButtonSegment<Priority>(
            value: Priority.medium,
            label: Text(AppLocalizations.of(context)!.mediumPriorityTrunc),
            icon: Icon(Icons.calendar_view_week)),
        ButtonSegment<Priority>(
            value: Priority.high,
            label: Text(AppLocalizations.of(context)!.highPriorityTrunc),
            icon: Icon(Icons.calendar_view_month)),
      ],
      selected: <Priority>{_priorityView},
      onSelectionChanged: (Set<Priority> newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          _priorityView = newSelection.first;
        });
        if (this.widget.onChanged != null) {
          this.widget.onChanged!(newSelection.first);
        }
      },
    );
  }
}
