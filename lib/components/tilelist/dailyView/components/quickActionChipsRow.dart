import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/actionChip.dart';

/// Quick action chips row with "Show Route" and "Re-optimize" buttons
class QuickActionChipsRow extends StatelessWidget {
  final VoidCallback? onShowRoute;
  final VoidCallback? onReOptimize;
  final bool preview;

  const QuickActionChipsRow(
      {Key? key, this.onShowRoute, this.onReOptimize, this.preview = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          if (onShowRoute != null)
            TilerActionChip(
              preview: preview,
              icon: Icons.route,
              label: l10n.showRouteChip,
              onTap: (){
//                 String tileId =  "1he3d5sih83tbte3v29dm50ltu_20260911T163000Z";
// Map<String, dynamic> editParams = {'tileId': tileId, 'source': "google", 
// 'thirdPartyUserId': "jeromebiotidara@gmail.com"};
                String tileId =  "6c82dcb2-519f-4bb6-8fa3-0e352784a209_7_01KTNTV37DHZD428TYRGXS9YBF_01KTNTV37DDDE5ZMQTZXXCCTJK";
Map<String, dynamic> editParams = {'tileId': tileId, 'source': "tiler", 
'thirdPartyUserId': ""};
      Navigator.pushNamed(context, '/EditTileRedesign', arguments: editParams);
              }!,
            ),
          if (onShowRoute != null && onReOptimize != null)
            const SizedBox(width: 8),
          if (onReOptimize != null)
            TilerActionChip(
              preview: preview,
              icon: Icons.refresh,
              label: l10n.reOptimizeChip,
              onTap: onReOptimize!,
            ),
        ],
      ),
    );
  }
}
