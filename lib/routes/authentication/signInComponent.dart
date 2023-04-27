import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../services/api/authorization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  final _formKey = GlobalKey<FormState>();
  final userNameEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final confirmPasswordEditingController = TextEditingController();
  bool isRegistrationScreen = false;
  double credentialManagerHeight = 350;
  double credentialButtonHeight = 150;

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  void adHocSignin() async {
    if (_formKey.currentState!.validate()) {
      showMessage(AppLocalizations.of(context)!.signingIn);
      Authorization authorization = new Authorization();
      AuthenticationData authenticationData =
          await authorization.getAuthenticationInfo(
              userNameEditingController.text, passwordEditingController.text);

      String isValidSignIn = "Authentication data is valid:" +
          authenticationData.isValid.toString();
      if (!authenticationData.isValid) {
        if (authenticationData.errorMessage != null) {
          print("error sign in ${authenticationData.errorMessage!}");
          showErrorMessage(authenticationData.errorMessage!);
          return;
        }
      }

      TextInput.finishAutofillContext();
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
      print(isValidSignIn);
    }
  }

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  void registerUser() async {
    if (_formKey.currentState!.validate()) {
      showMessage(AppLocalizations.of(context)!.registeringUser);
      Authorization authorization = new Authorization();
      AuthenticationData authenticationData = await authorization.registerUser(
          emailEditingController.text,
          passwordEditingController.text,
          userNameEditingController.text,
          confirmPasswordEditingController.text,
          null);

      String isValidSignIn = "Authentication data is valid:" +
          authenticationData.isValid.toString();
      if (!authenticationData.isValid) {
        if (authenticationData.errorMessage != null) {
          showErrorMessage(authenticationData.errorMessage!);
          return;
        }
      }
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

      print(isValidSignIn);
    }
  }

  void setAsRegistrationScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() => {
          isRegistrationScreen = true,
          credentialManagerHeight = 450,
          credentialButtonHeight = 320
        });
  }

  void setAsSignInScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() => {
          isRegistrationScreen = false,
          credentialManagerHeight = 350,
          credentialButtonHeight = 150
        });
  }

  @override
  void dispose() {
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    emailEditingController.dispose();
    confirmPasswordEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var usernameTextField = TextFormField(
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (!isRegistrationScreen) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.fieldIsRequired;
          }
        }
        return null;
      },
      controller: userNameEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newUsername
            : AutofillHints.username
      ],
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.username,
        labelText: AppLocalizations.of(context)!.username,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.person),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    var emailTextField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.emailIsRequired;
        }
        return null;
      },
      controller: emailEditingController,
      autofillHints: [AutofillHints.email],
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.email,
        hintText: AppLocalizations.of(context)!.email,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.email),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    var passwordTextField = TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.passwordIsRequired;
        }

        if (isRegistrationScreen) {
          var minPasswordLength = 6;
          if (value != confirmPasswordEditingController.text) {
            return AppLocalizations.of(context)!.passwordsDontMatch;
          }
          if (value.length < minPasswordLength) {
            return AppLocalizations.of(context)!
                .passwordNeedToBeAtLeastSevenCharacters;
          }

          if (!value.contains(RegExp(r'[A-Z]+'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveUpperCaseChracters;
          }
          if (!value.contains(RegExp(r'[a-z]+'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveLowerCaseChracters;
          }
          if (!value.contains(RegExp(r'[0-9]+'))) {
            return AppLocalizations.of(context)!.passwordNeedsToHaveNumber;
          }
          if (!value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveASpecialCharacter;
          }
        }

        return null;
      },
      controller: passwordEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newPassword
            : AutofillHints.password
      ],
      onEditingComplete: () => TextInput.finishAutofillContext(),
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.password,
        labelText: AppLocalizations.of(context)!.password,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.lock),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    List<Widget> textFields = [usernameTextField, passwordTextField];
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
      var confirmPasswordTextField = TextFormField(
        keyboardType: TextInputType.visiblePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.confirmPasswordRequired;
          }
          return null;
        },
        controller: confirmPasswordEditingController,
        obscureText: true,
        autofillHints: [AutofillHints.newPassword],
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.confirmPassword,
          labelText: AppLocalizations.of(context)!.confirmPassword,
          filled: true,
          isDense: true,
          prefixIcon: Icon(Icons.lock),
          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          fillColor: Color.fromRGBO(255, 255, 255, .75),
        ),
      );
      textFields = [
        emailTextField,
        passwordTextField,
        confirmPasswordTextField,
        usernameTextField
      ];
      buttons = [backToSignInButton, registerUserButton];
    }
    return Form(
        key: _formKey,
        child: Container(
            alignment: Alignment.topCenter,
            height: credentialManagerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0)),
              color: Color.fromRGBO(245, 245, 245, 0.2),
              boxShadow: [
                BoxShadow(
                    color: Color.fromRGBO(245, 245, 245, 0.25),
                    spreadRadius: 5),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: credentialButtonHeight,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 20),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: textFields,
                        ),
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buttons,
                      ),
                    ),
                  ],
                ))));
  }
}
