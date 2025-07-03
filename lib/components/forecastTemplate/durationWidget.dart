import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../styles.dart';

//ey: not used
class DurationWidget extends StatelessWidget {
  const DurationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    return Padding(
        padding: EdgeInsets.only(top: 15, left: 15, right: 15),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/forecastDuration'),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[350]),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 15, bottom: 15),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    AppLocalizations.of(context)!.duration,
                    style: TextStyle(
                        fontSize: 17, color: colorScheme.onSurface.withValues(alpha: 0.4),),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
