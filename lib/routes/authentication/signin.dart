import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Color.fromRGBO(0, 194, 237, 1),
                Color.fromRGBO(0, 194, 237, 1),
                Color.fromRGBO(0, 194, 237, 1),
                Color.fromRGBO(0, 119, 170, 1),
                Color.fromRGBO(0, 119, 170, 1)
              ])),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Container(height: 50), SignInComponent()],
          )),
    );
  }
}
