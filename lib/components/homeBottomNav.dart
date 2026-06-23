import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/autoSwitchingWidget.dart';

/// Bottom navigation bar used on the home screen.
///
/// Three items:
///   0 – Share (left)
///   1 – Tiler logo / add-tile (centre, raised)
///   2 – Calendar view switcher (right)
class HomeBottomNav extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onAddTile;
  final VoidCallback onCalendar;

  const HomeBottomNav({
    super.key,
    required this.onShare,
    required this.onAddTile,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
      key: TutorialKeys.bottomNavKey,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(30),
        topLeft: Radius.circular(30),
      ),
      child: BottomAppBar(
        color: colorScheme.surfaceContainerHigh,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ── Left: Share ───────────────────────────────────────────────
            IconButton(
              icon: Icon(Icons.share, color: colorScheme.primary),
              onPressed: onShare,
              tooltip: AppLocalizations.of(context)!.share,
            ),

            // ── Centre: Tiler logo ────────────────────────────────────────
            GestureDetector(
              onTap: onAddTile,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AutoSwitchingWidget(
                    duration: const Duration(milliseconds: 1000),
                    children: [
                      Transform.scale(
                        scale: 0.6,
                        child: Image.asset('assets/images/wire_tilerLogo_BlueBottom.png'),
                      ),
                      Transform.scale(
                        scale: 0.6,
                        child: Image.asset('assets/images/wire_tilerLogo_RedBottom.png'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Right: Calendar view switcher ──────────────────────────────
            IconButton(
              icon: Icon(Icons.calendar_month, color: colorScheme.primary),
              onPressed: onCalendar,
              tooltip: AppLocalizations.of(context)!.switchCalendarView,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
