import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/calendarViewSwitcher/calendarViewOptions.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/autoSwitchingWidget.dart';

/// Bottom navigation bar used on the home screen.
///
/// Three items:
///   0 – Calendar view switcher (left). Its icon reflects [currentView]; tapping
///       opens an anchored pop-out (above the bar) listing the two other views.
///   1 – Tiler logo / add-tile (centre, raised)
///   2 – Share (right)
class HomeBottomNav extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onAddTile;

  /// The currently active calendar view — drives the switcher icon and which
  /// two views the pop-out offers.
  final AuthorizedRouteTileListPage currentView;

  /// Invoked with the chosen view when the user picks one from the pop-out.
  final ValueChanged<AuthorizedRouteTileListPage> onSelectView;

  const HomeBottomNav({
    super.key,
    required this.onShare,
    required this.onAddTile,
    required this.currentView,
    required this.onSelectView,
  });

  /// Opens the anchored pop-out (a menu, not a dialog) above the switcher button
  /// listing the views other than [currentView].
  Future<void> _showViewMenu(BuildContext buttonContext) async {
    final l10n = AppLocalizations.of(buttonContext)!;
    final ColorScheme colorScheme = Theme.of(buttonContext).colorScheme;
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(buttonContext)
        .overlay!
        .context
        .findRenderObject() as RenderBox;
    final Offset buttonTopLeft =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    // Estimate the menu's height so we can anchor it ABOVE the bottom nav bar
    // (showMenu lays the menu out downward from position.top, so we push the
    // top up by the estimated height to keep it above the button).
    const double rowHeight = 48.0;
    const double menuVerticalPadding = 16.0;
    final double estimatedMenuHeight =
        otherCalendarViews(currentView).length * rowHeight +
            menuVerticalPadding;
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonTopLeft.dx,
      buttonTopLeft.dy - estimatedMenuHeight,
      overlay.size.width - buttonTopLeft.dx - button.size.width,
      overlay.size.height - buttonTopLeft.dy,
    );

    final AuthorizedRouteTileListPage? selected =
        await showMenu<AuthorizedRouteTileListPage>(
      context: buttonContext,
      position: position,
      color: colorScheme.surfaceContainerHigh,
      items: [
        for (final view in otherCalendarViews(currentView))
          PopupMenuItem<AuthorizedRouteTileListPage>(
            value: view,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(view.navIcon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(view.label(l10n)),
              ],
            ),
          ),
      ],
    );

    if (selected != null) {
      onSelectView(selected);
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
          // Tighter vertical padding than the M3 default (12) so the
          // icon + text label pairs fit the default bar height.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left: calendar view switcher.
              _LabeledNavItem(
                label: currentView == AuthorizedRouteTileListPage.Daily
                    ? l10n.bottomNavToday
                    : currentView.label(l10n),
                child: Builder(
                  builder: (buttonContext) => IconButton(
                    visualDensity: VisualDensity.compact,
                    icon:
                        Icon(currentView.navIcon, color: colorScheme.primary),
                    onPressed: () => _showViewMenu(buttonContext),
                    tooltip: l10n.switchCalendarView,
                  ),
                ),
              ),

              // Centre: Tiler logo (add tile).
              _LabeledNavItem(
                label: l10n.bottomNavTiler,
                child: GestureDetector(
                  key: TutorialKeys.bottomNavAddTileKey,
                  onTap: onAddTile,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Center(
                      child: AutoSwitchingWidget(
                        duration: const Duration(milliseconds: 1000),
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Image.asset(
                                'assets/images/wire_tilerLogo_BlueBottom.png'),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Image.asset(
                                'assets/images/wire_tilerLogo_RedBottom.png'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Right: share.
              _LabeledNavItem(
                label: l10n.share,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.share, color: colorScheme.primary),
                  onPressed: onShare,
                  tooltip: l10n.share,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom-nav item: the tappable [child] with a small text [label]
/// beneath it (C25).
class _LabeledNavItem extends StatelessWidget {
  final Widget child;
  final String label;

  const _LabeledNavItem({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        child,
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
