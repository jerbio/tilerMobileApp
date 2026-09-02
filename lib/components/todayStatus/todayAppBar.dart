import 'package:flutter/material.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// Today Status app bar (spec §5.2 / §6.2).
///
/// The title uses the humanized date rather than a literal "Today" because this
/// screen is also opened for other days from the weekly view; `humanDate`
/// already yields "Today"/"Tomorrow" when it applies.
class TodayAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TodayAppBar({
    super.key,
    required this.date,
    this.onClose,
    this.trailing,
  });

  static const Key closeKey = Key('todayStatus.appBar.close');

  final DateTime date;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);

    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: tokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        excludeSemantics: true,
        child: InkWell(
          key: closeKey,
          onTap: onClose ?? () => Navigator.of(context).maybePop(),
          borderRadius:
              BorderRadius.circular(TodayStatusTokens.minTouchTarget / 2),
          child: SizedBox(
            width: TodayStatusTokens.minTouchTarget,
            height: TodayStatusTokens.minTouchTarget,
            child: Icon(Icons.close,
                size: TodayStatusTokens.iconMd, color: tokens.textPrimary),
          ),
        ),
      ),
      title: Text(
        date.humanDate(context),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        ),
      ),
      // Keeps the title optically centred when there is no trailing control.
      actions: [
        trailing ?? const SizedBox(width: TodayStatusTokens.minTouchTarget),
      ],
    );
  }
}
