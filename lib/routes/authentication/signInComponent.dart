import 'dart:ffi';
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
  final emailEditingController = TextEditingController();
  final confirmPasswordEditingController = TextEditingController();
  bool isRegistrationScreen = false;
  double credentialManagerHeight = 350;
  double credentialButtonHeight = 150;
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

  void registerUser() async {
    // Authorization authorization = new Authorization();
    // AuthenticationData authenticationData =
    //     await authorization.getAuthenticationInfo(
    //         userNameEditingController.text, passwordEditingController.text);

    // String isValidSignIn =
    //     "Authentication data is valid:" + authenticationData.isValid.toString();
    // if (authenticationData.isValid) {
    //   Authentication localAuthentication = new Authentication();
    //   await localAuthentication.saveCredentials(authenticationData);
    //   while (Navigator.canPop(context)) {
    //     Navigator.pop(context);
    //   }
    //   Navigator.pop(context);
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => AuthorizedRoute()),
    //   );
    // }
    // print(isValidSignIn);
  }

  void setAsRegistrationScreen() {
    setState(() => {
          isRegistrationScreen = true,
          credentialManagerHeight = 450,
          credentialButtonHeight = 250
        });
  }

  void setAsSignInScreen() {
    setState(() => {
          isRegistrationScreen = false,
          credentialManagerHeight = 350,
          credentialButtonHeight = 150
        });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    emailEditingController.dispose();
    confirmPasswordEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var usernameTextField = TextField(
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
          borderSide: BorderSide(color: Colors.white, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
    );
    var emailTextField = TextField(
      controller: emailEditingController,
      decoration: InputDecoration(
        hintText: 'Email Address',
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.email),
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
          borderSide: BorderSide(color: Colors.white, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
    );
    var passwordTextField = TextField(
      controller: passwordEditingController,
      obscureText: true,
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
          borderSide: BorderSide(color: Colors.white, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
    );
    var textFields = [usernameTextField, passwordTextField];
    var signUpButton = ElevatedButton(
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
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.person_add),
          ),
          Text('Sign Up')
        ],
      ),
      onPressed: setAsRegistrationScreen,
    );
    var signInButton = ElevatedButton(
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
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_forward),
          ),
          Text('Sign In')
        ],
      ),
      onPressed: adHocSignin,
    );

    var backToSignInButton = ElevatedButton(
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
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_back),
          ),
          Text('Sign In')
        ],
      ),
      onPressed: setAsSignInScreen,
    );

    var registerUserButton = ElevatedButton(
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
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_forward),
          ),
          Text('Register')
        ],
      ),
      onPressed: registerUser,
    );

    var buttons = [signUpButton, signInButton];

    if (isRegistrationScreen) {
      var confirmPasswordTextField = TextField(
        controller: confirmPasswordEditingController,
        obscureText: true,
        decoration: InputDecoration(
          hintText: 'Confirm Password',
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
            borderSide: BorderSide(color: Colors.white, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(5.0),
            ),
            borderSide: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
      );
      textFields = [
        usernameTextField,
        emailTextField,
        passwordTextField,
        confirmPasswordTextField
      ];
      buttons = [backToSignInButton, registerUserButton];
    }
    return Container(
        height: credentialManagerHeight,
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
                  height: credentialButtonHeight,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: textFields,
                  ),
                ),
                Container(
                  //Button Container //
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: buttons,
                  ),
                ),
              ],
            )));
  }
}
