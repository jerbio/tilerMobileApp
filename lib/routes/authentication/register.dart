import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authentication/signin.dart';

class RegistrationRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Route'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Go to Sign In Route'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignInRoute()),
            );
          },
        ),
      ),
    );
  }
}
