import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';

/// Settings row for the "Schedule updates" setting.
/// Shows the current mode; tapping opens [ScheduleUpdatesSheet].
class ScheduleUpdatesSettingTile extends StatelessWidget {
  static const Key tileKey = Key('settings_schedule_updates');

  final Color color;

  const ScheduleUpdatesSettingTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ScheduleUpdateMode mode;
    try {
      mode = context.watch<ScheduleMotionCubit>().state;
    } on ProviderNotFoundException {
      // Hosts without the app-level cubit (isolated screens in tests)
      // have nothing to change, so the row is left out.
      return const SizedBox.shrink();
    }
    return ListTile(
      key: tileKey,
      leading: Icon(Icons.animation, color: color),
      title: Text(l10n.scheduleUpdates, style: TextStyle(color: color)),
      trailing: Text(
        ScheduleUpdatesSheet.label(l10n, mode),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      onTap: () => ScheduleUpdatesSheet.show(context),
    );
  }
}

/// Bottom sheet with the three modes and a one-line description each.
/// Picking one saves it and closes the sheet.
class ScheduleUpdatesSheet extends StatelessWidget {
  const ScheduleUpdatesSheet({super.key});

  /// Most motion first, so the default sits at the top.
  static const List<ScheduleUpdateMode> order = [
    ScheduleUpdateMode.detailed,
    ScheduleUpdateMode.minimal,
    ScheduleUpdateMode.off,
  ];

  static Key optionKey(ScheduleUpdateMode mode) =>
      Key('schedule_updates_option_${mode.name}');

  static Future<void> show(BuildContext context) {
    final cubit = context.read<ScheduleMotionCubit>();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Size to the content (three options with descriptions), not the
      // default 9/16 cap; the content scrolls on short screens.
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const ScheduleUpdatesSheet(),
      ),
    );
  }

  static String label(AppLocalizations l10n, ScheduleUpdateMode mode) {
    switch (mode) {
      case ScheduleUpdateMode.detailed:
        return l10n.scheduleUpdatesDetailed;
      case ScheduleUpdateMode.minimal:
        return l10n.scheduleUpdatesMinimal;
      case ScheduleUpdateMode.off:
        return l10n.scheduleUpdatesOff;
    }
  }

  static String description(AppLocalizations l10n, ScheduleUpdateMode mode) {
    switch (mode) {
      case ScheduleUpdateMode.detailed:
        return l10n.scheduleUpdatesDetailedDescription;
      case ScheduleUpdateMode.minimal:
        return l10n.scheduleUpdatesMinimalDescription;
      case ScheduleUpdateMode.off:
        return l10n.scheduleUpdatesOffDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cubit = context.watch<ScheduleMotionCubit>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.scheduleUpdates,
                  style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.scheduleUpdatesDescription,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            RadioGroup<ScheduleUpdateMode>(
              groupValue: cubit.state,
              onChanged: (mode) {
                if (mode == null) return;
                cubit.setMode(mode);
                Navigator.of(context).maybePop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in order)
                    RadioListTile<ScheduleUpdateMode>(
                      key: optionKey(mode),
                      value: mode,
                      title: Text(label(l10n, mode)),
                      subtitle: Text(description(l10n, mode)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
