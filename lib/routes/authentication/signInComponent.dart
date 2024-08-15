import 'dart:io';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../services/api/authorization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/analyticsSignal.dart';

import '../../util.dart';
import 'AuthorizedRoute.dart';
import 'onBoarding.dart';

class SignInComponent extends StatefulWidget {
  @override
  SignInComponentState createState() => SignInComponentState();
}

// Define a corresponding State class.
// This class holds data related to the Form.
class SignInComponentState extends State<SignInComponent>
    with TickerProviderStateMixin {
  // Create a text controller. Later, use it to retrieve the
  // current value of the TextField.
  final _formKey = GlobalKey<FormState>();
  final userNameEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final confirmPasswordEditingController = TextEditingController();
  late AnimationController signinInAnimationController;
  bool isRegistrationScreen = false;
  bool isForgetPasswordScreen = false;
  final double registrationContainerHeight = 450;
  final double signInContainerHeight = 400;
  final double forgotPasswordContainerHeight = 300;

  final double registrationContainerButtonHeight = 300;
  final double signInContainerButtonHeight = 175;
  final double forgotPasswordContainerButtonHeight = 100;

  late double credentialManagerHeight = 400;
  double credentialButtonHeight = 175;
  bool isPendingSigning = false;
  bool isPendingRegistration = false;
  bool isPendingResetPassword = false;
  bool isGoogleSignInEnabled = false;
  final authApi = AuthorizationApi();

  @override
  void initState() {
    super.initState();
    signinInAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    isGoogleSignInEnabled = !Platform.isIOS;
    if (Platform.isIOS) {
      authApi.statusSupport().then((value) {
        String versionKey = "version";
        String authResult = "315";
        if (value != null &&
            value.containsKey(versionKey) &&
            value[versionKey] != null) {
          for (var versions in value[versionKey]) {
            if (versions == authResult) {
              setState(() {
                isGoogleSignInEnabled = true;
              });
            }
          }
        }
      });
    }
    credentialManagerHeight = signInContainerHeight;
    credentialButtonHeight = signInContainerButtonHeight;
  }

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

  void userNamePasswordSignIn() async {
    if (_formKey.currentState!.validate()) {
      AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_INITIATED');
      showMessage(AppLocalizations.of(context)!.signingIn);
      setState(() {
        isPendingSigning = true;
      });
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      try {
        UserPasswordAuthenticationData authenticationData =
            await UserPasswordAuthenticationData.getAuthenticationInfo(
                userNameEditingController.text, passwordEditingController.text);

        setState(() {
          isPendingSigning = false;
        });
        String isValidSignIn = "Authentication data is valid:" +
            authenticationData.isValid.toString();
        if (!authenticationData.isValid) {
          AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_FAILED');
          if (authenticationData.errorMessage != null) {
            showErrorMessage(authenticationData.errorMessage!);
            return;
          }
        }
        AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_SUCCESS');
        setState(() {
          isPendingSigning = false;
        });
        TextInput.finishAutofillContext();
        Authentication localAuthentication = new Authentication();
        await localAuthentication.saveCredentials(authenticationData);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.read<ScheduleBloc>().add(LogInScheduleEvent());
        bool nextPage = await Utility.checkOnboardingStatus();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  nextPage ? AuthorizedRoute() : OnboardingView()),
        );
        print(isValidSignIn);
        setState(() {
          isPendingSigning = false;
        });
      } catch (e) {
        if (TilerError.isUnexpectedCharacter(e)) {
          setState(() {
            isPendingSigning = false;
          });
          showErrorMessage(
              AppLocalizations.of(context)!.invalidUsernameOrPassword);
        }
      }
    }
  }

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  void registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          isPendingRegistration = true;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        showMessage(AppLocalizations.of(context)!.registeringUser);
        AuthorizationApi authorization = new AuthorizationApi();
        UserPasswordAuthenticationData authenticationData =
            await authorization.registerUser(
                emailEditingController.text,
                passwordEditingController.text,
                userNameEditingController.text,
                confirmPasswordEditingController.text,
                null);
        setState(() {
          isPendingRegistration = false;
        });
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
        bool nextPage = await Utility.checkOnboardingStatus();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  nextPage ? AuthorizedRoute() : OnboardingView()),
        );

        print(isValidSignIn);
      } catch (e) {
        setState(() {
          isPendingRegistration = false;
        });
        if (TilerError.isUnexpectedCharacter(e)) {
          showErrorMessage(
              AppLocalizations.of(context)!.issuesConnectingToTiler);
          setState(() {
            isPendingRegistration = false;
          });
        }
      }
    }
  }

  void forgetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          isPendingResetPassword = true;
        });
        AnalysticsSignal.send('FORGOT_PASSWORD_INITIATED');
        showMessage(AppLocalizations.of(context)!.forgetPassword);
        var result = await AuthorizationApi.sendForgotPasswordRequest(
            emailEditingController.text);
        if (result.error.code == "0") {
          AnalysticsSignal.send('FORGOT_PASSWORD_SUCCESS');
          showMessage(result.error.message);
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              setAsSignInScreen();
            });
          });
        } else {
          AnalysticsSignal.send('FORGOT_PASSWORD_ERROR');
          showErrorMessage(result.error.message);
        }
      } catch (e) {
        AnalysticsSignal.send('FORGOT_PASSWORD_SERVER_ERROR');
        showErrorMessage("Error: $e");
      } finally {
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            isPendingResetPassword = false;
          });
        });
      }
    }
  }

  void setAsForgetPasswordScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() {
      isForgetPasswordScreen = true;
      isRegistrationScreen = false;
      credentialManagerHeight = forgotPasswordContainerHeight;
      credentialButtonHeight = forgotPasswordContainerButtonHeight;
    });
  }

  void setAsRegistrationScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() {
      isRegistrationScreen = true;
      credentialManagerHeight = registrationContainerHeight;
      credentialButtonHeight = registrationContainerButtonHeight;
    });
  }

  void setAsSignInScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() => {
          isRegistrationScreen = false,
          isForgetPasswordScreen = false,
          credentialManagerHeight = signInContainerHeight,
          credentialButtonHeight = signInContainerButtonHeight
        });
  }

  Widget createSignInPendingComponent(String message) {
    return Container(
        child: Center(
            child: FadeTransition(
      opacity: CurvedAnimation(
        parent: signinInAnimationController,
        curve: Curves.easeIn,
      ),
      child: Row(children: [
        CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ))
      ]),
    )));
  }

  Future signInToGoogle() async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    AnalysticsSignal.send('GOOGLE_SIGNUP_INITIALIZE');
    setState(() {
      isPendingSigning = true;
    });
    AuthorizationApi authorizationApi = AuthorizationApi();
    AuthenticationData? authenticationData =
        await authorizationApi.signInToGoogle().then((value) {
      AnalysticsSignal.send('GOOGLE_SIGNUP_SUCCESSFUL');
      return value;
    }).catchError((onError) {
      setState(() {
        isPendingSigning = false;
      });
      AnalysticsSignal.send('GOOGLE_SIGNUP_FAILED');
      showErrorMessage(onError.message);
      return null;
    });

    if (authenticationData != null) {
      if (authenticationData.isValid) {
        Authentication localAuthentication = new Authentication();
        await localAuthentication.saveCredentials(authenticationData);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.read<ScheduleBloc>().add(LogInScheduleEvent());
        bool nextPage = await Utility.checkOnboardingStatus();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  nextPage ? AuthorizedRoute() : OnboardingView()),
        );
      }
    }
    setState(() {
      isPendingSigning = false;
    });
  }

  @override
  void dispose() {
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    emailEditingController.dispose();
    confirmPasswordEditingController.dispose();
    signinInAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var usernameTextField = TextFormField(
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
    var forgetPasswordTextButton = GestureDetector(
      onTap: () => setAsForgetPasswordScreen(),
      child: Container(
        padding: EdgeInsets.only(left: 5),
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.forgotPasswordBtn,
          style: TextStyle(
              color: Color(0xFF880E4F), decoration: TextDecoration.underline),
        ),
      ),
    );
    List<Widget> textFields = [
      usernameTextField,
      passwordTextField,
      forgetPasswordTextButton
    ];

    var signUpButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.person_add),
        label: Text(AppLocalizations.of(context)!.signUp),
        onPressed: setAsRegistrationScreen,
      ),
    );

    var signInButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.arrow_forward),
        label: Text(AppLocalizations.of(context)!.signIn),
        onPressed: userNamePasswordSignIn,
      ),
    );

    var googleSignInButton = isGoogleSignInEnabled
        ? SizedBox(
            width: 200,
            child: ElevatedButton.icon(
                onPressed: signInToGoogle,
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  color: Colors.white,
                ),
                label: Text(AppLocalizations.of(context)!.signUpWithGoogle)),
          )
        : SizedBox.shrink();

    var backToSignInButton = SizedBox(
      width: isForgetPasswordScreen ? 200 : null,
      child: ElevatedButton.icon(
        label: Text(AppLocalizations.of(context)!.signIn),
        icon: Icon(Icons.arrow_back),
        onPressed: setAsSignInScreen,
      ),
    );

    var forgetPasswordButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.lock_reset),
        label: Text(AppLocalizations.of(context)!.resetPassword),
        onPressed: forgetPassword,
      ),
    );

    var registerUserButton = ElevatedButton.icon(
      label: Text(AppLocalizations.of(context)!.signUp),
      icon: Icon(Icons.person_add),
      onPressed: registerUser,
    );
    List<Widget> buttons = [
      signInButton,
      signUpButton,
      googleSignInButton,
    ];

    if (isForgetPasswordScreen) {
      textFields = [
        emailTextField,
      ];
      buttons = [forgetPasswordButton, backToSignInButton];
    }
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
      buttons = [registerUserButton, backToSignInButton];
    }

    if (this.isPendingSigning) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(AppLocalizations.of(context)!.signingIn),
        Spacer(),
      ];
    }
    if (this.isPendingRegistration) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(
            AppLocalizations.of(context)!.registeringUser),
        Spacer(),
      ];
    }
    if (this.isPendingResetPassword) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(AppLocalizations.of(context)!.reset),
        Spacer(),
      ];
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
            padding: EdgeInsets.symmetric(
                vertical: isRegistrationScreen ? 10.0 : 0.0, horizontal: 10),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      height: credentialButtonHeight,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 20),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: textFields,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buttons,
                      ),
                    ),
                  ],
                ))));
  }
}
