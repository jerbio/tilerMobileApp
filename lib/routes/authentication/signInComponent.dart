import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../services/api/authorization.dart';
import 'AuthorizedRoute.dart';

class SignInComponent extends StatefulWidget {
  @override
  SignInComponentState createState() => SignInComponentState();
}

// Define a corresponding State class.
// This class holds data related to the Form.
class SignInComponentState extends State<SignInComponent> {
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
    return Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0)),
          color: Color.fromRGBO(245, 245, 245, 0.2),
          boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(245, 245, 245, 0.25), spreadRadius: 5),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 10),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Column(
              children: [
                Container(
                  //Inout container
                  // color: Colors.yellow,
                  height: 150,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    // mainAxisSize: MainAxisSize.max,
                    children: [
                      TextField(
                        controller: userNameEditingController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          filled: true,
                          isDense: true,
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.fromLTRB(10, 20, 0, 0),
                          fillColor: Color.fromRGBO(255, 255, 255, .75),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(50.0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0),
                            ),
                            borderSide:
                                BorderSide(color: Colors.white, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0),
                            ),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                        ),
                      ),
                      TextField(
                        controller: passwordEditingController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          isDense: true,
                          prefixIcon: Icon(Icons.lock),
                          contentPadding: EdgeInsets.fromLTRB(10, 20, 0, 0),
                          fillColor: Color.fromRGBO(255, 255, 255, .75),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(50.0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0),
                            ),
                            borderSide:
                                BorderSide(color: Colors.white, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0),
                            ),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  //Button Container //
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.transparent, // background
                            onPrimary: Colors.white,
                            shadowColor: Colors.transparent // foreground
                            ),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 4.0, color: const Color(0xFFFFFFFF)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40)),
                                color: Colors.transparent,
                              ),
                              child: Icon(Icons.arrow_forward),
                            ),
                            Text('Sign In')
                          ],
                        ),
                        onPressed: adHocSignin,
                      ),
                    ],
                  ),
                ),
              ],
            )));

    ;
  }
}
