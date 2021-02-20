import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authentication/register.dart';
import 'package:tiler_app/routes/tilelist/TileList.dart';
import 'package:tiler_app/services/localAuthentication.dart';

class AuthorizedRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
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
        ),
      ),
    );
  }
}
