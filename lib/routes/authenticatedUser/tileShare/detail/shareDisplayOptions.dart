import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/tileShare/tileShareDisplaySettings.dart';
export 'package:tiler_app/services/tileShare/tileShareDisplaySettings.dart';

class TileShareDisplayScope
    extends InheritedNotifier<TileShareDisplaySettings> {
  const TileShareDisplayScope(
      {super.key,
      required TileShareDisplaySettings settings,
      required super.child})
      : super(notifier: settings);

  static TileShareDisplaySettings? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TileShareDisplayScope>()
      ?.notifier;
  static TiletteDensity densityOf(BuildContext context) =>
      of(context)?.density ?? TiletteDensity.compact;

  /// Route overlays need the same setting as the share that opened them.
  static Widget wrap(BuildContext context, Widget child) {
    final settings = of(context);
    return settings == null
        ? child
        : TileShareDisplayScope(settings: settings, child: child);
  }
}

class ShareViewOptionsButton extends StatelessWidget {
  const ShareViewOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = TileShareDisplayScope.of(context);
    if (settings == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return IconButton(
      key: const Key('share_view_options'),
      tooltip: l.shareViewOptions,
      icon: Icon(switch (settings.density) {
        TiletteDensity.comfortable => Icons.view_agenda_outlined,
        TiletteDensity.compact => Icons.view_compact_outlined,
        TiletteDensity.list => Icons.view_list_outlined,
      }),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ListenableBuilder(
              listenable: settings,
              builder: (_, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(l.shareViewOptions,
                              style: Theme.of(context).textTheme.titleLarge)),
                      for (final density in TiletteDensity.values)
                        Semantics(
                            selected: density == settings.density,
                            child: ListTile(
                              key: Key('share_density_${density.name}'),
                              leading: Icon(density == settings.density
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked),
                              title: Text(switch (density) {
                                TiletteDensity.comfortable =>
                                  l.shareDensityComfortable,
                                TiletteDensity.compact => l.shareDensityCompact,
                                TiletteDensity.list => l.shareDensityList,
                              }),
                              subtitle: Text(switch (density) {
                                TiletteDensity.comfortable =>
                                  l.shareDensityComfortableHint,
                                TiletteDensity.compact =>
                                  l.shareDensityCompactHint,
                                TiletteDensity.list => l.shareDensityListHint,
                              }),
                              onTap: () {
                                settings.setDensity(density);
                                Navigator.pop(sheetContext);
                              },
                            )),
                    ],
                  )),
        )),
      ),
    );
  }
}
