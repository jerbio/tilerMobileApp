import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authentication/register.dart';
//ey: not used
class PreAuthenticationRoute extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preauthorization Route',),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Go to register user'),
          onPressed: () {
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
