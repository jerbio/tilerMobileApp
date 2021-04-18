import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/tileUI/tile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authentication/register.dart';
import 'package:tiler_app/services/api/subCalendarEvent.dart';
import 'package:tiler_app/services/localAuthentication.dart';

class AuthorizedRoute extends StatelessWidget {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        FutureBuilder(
            future: subCalendarEventApi.getSubEvent('men-can-be-feminist'),
            builder: (context, AsyncSnapshot<SubCalendarEvent> snapshot) {
              Widget retValue;
              if (snapshot.hasData) {
                retValue = Tile(snapshot.data!);
              } else {
                retValue = CircularProgressIndicator();
              }
              return retValue;
            }),
        ElevatedButton(
          child: Text('Log Out'),
          onPressed: () async {
            Authentication authentication = new Authentication();
            await authentication.deleteCredentials();
            while (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistrationRoute()),
            );
          },
        )
      ],
    );
  }
}
