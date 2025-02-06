import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/src/painting/gradient.dart' as paintGradient;
import 'package:tiler_app/routes/authentication/signInComponent.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/services/localAuthentication.dart';
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
    UserPasswordAuthenticationData authenticationData =
        await UserPasswordAuthenticationData.getAuthenticationInfo(
            userNameEditingController.text, passwordEditingController.text);

    String isValidSignIn =
        "Authentication data is valid:" + authenticationData.isValid.toString();
    if (authenticationData.isValid) {
      Authentication localAuthentication = new Authentication();
      await localAuthentication.saveCredentials(authenticationData);
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context
          .read<ScheduleBloc>()
          .add(LogInScheduleEvent(getContextCallBack: () {
        return this.context;
      }));
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

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
                child: SizedBox(),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: SizedBox(),
              ),
            ),
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
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Container(
                  //   height: height / (height / 50),
                  // ),
                  SignInComponent()
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0, height / (height / 40), 0, 0),
              alignment: Alignment.topCenter,
              child: _keyboardIsVisible()
                  ? SizedBox.shrink()
                  : Image.asset(
                      'assets/images/tiler_logo_black.png',
                      scale: 4,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
