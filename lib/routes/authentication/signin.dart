import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/src/painting/gradient.dart' as paintGradient;
import 'package:tiler_app/routes/authentication/signInComponent.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../services/api/authorization.dart';
import 'AuthorizedRoute.dart';

class SignInRoute extends StatefulWidget {
  @override
  SignInRouteState createState() => SignInRouteState();
}

class SignInRouteState extends State<SignInRoute> {
  // Create a text controller. Later, use it to retrieve the
  // current value of the TextField.
  final userNameEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();
  void adHocSignin() async {
    Authorization authorization = new Authorization();
    AuthenticationData authenticationData =
        await authorization.getAuthenticationInfo(
            userNameEditingController.text, passwordEditingController.text);

    String isValidSignIn =
        "Authentication data is valid:" + authenticationData.isValid.toString();
    if (authenticationData.isValid) {
      Authentication localAuthentication = new Authentication();
      await localAuthentication.saveCredentials(authenticationData);
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthorizedRoute()),
      );
    }
    print(isValidSignIn);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(
      children: [
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
          child: SizedBox(),
        )),
        RiveAnimation.asset('assets/rive/fuzzySpinBground.riv'),
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: SizedBox(),
        )),
        Container(
            decoration: BoxDecoration(
                gradient: paintGradient.LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white,
                  Color.fromRGBO(179, 194, 242, 1),
                  Color.fromRGBO(179, 194, 242, 1),
                  Color.fromRGBO(179, 194, 242, 1),
                  Color.fromRGBO(239, 48, 84, 1),
                  Color.fromRGBO(239, 48, 84, 1),
                  Color.fromRGBO(239, 48, 84, 1)
                ])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Container(height: 50), SignInComponent()],
            )),
        Container(
          padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
          alignment: Alignment.topCenter,
          child: Image.asset(
            'assets/images/tiler_logo_black.png',
            scale: 4,
          ),
        ),
      ],
    )));
  }
}
