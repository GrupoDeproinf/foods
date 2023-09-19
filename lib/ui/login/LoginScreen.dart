import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;
import 'package:custom_food/constants.dart';
import 'package:custom_food/main.dart';
import 'package:custom_food/model/User.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/ui/container/ContainerScreen.dart';
import 'package:custom_food/ui/phoneAuth/PhoneNumberInputScreen.dart';
import 'package:custom_food/ui/resetPasswordScreen/ResetPasswordScreen.dart';

import '../home/SelectRestaurant.dart';

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  GlobalKey<FormState> _key = GlobalKey();
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
        elevation: 0.0,
      ),
      body: AutofillGroup(
        child: Form(
          key: _key,
          autovalidateMode: _validate,
          child: ListView(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(top: 32.0, right: 16.0, left: 24.0),
                child: Text(
                  'signIn',
                  style: TextStyle(
                      fontFamily: "Oswald",
                      color: Color(COLOR_PRIMARY),
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold),
                ).tr(),
              ),

              /// email address text field, visible when logging with email
              /// and password
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: double.infinity),
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                  child: TextFormField(
                      autofillHints: [AutofillHints.username],
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: validateEmail,
                      controller: _emailController,
                      style: TextStyle(fontFamily: "Oswald", fontSize: 18.0),
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Color(COLOR_PRIMARY),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 16, right: 16),
                        hintText: 'emailAddress'.tr(),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY), width: 2.0)),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      )),
                ),
              ),

              /// password text field, visible when logging with email and
              /// password
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: double.infinity),
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                  child: TextFormField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: _passwordController,
                      autofillHints: [AutofillHints.password],
                      obscureText: !visible,
                      validator: validatePassword,
                      onFieldSubmitted: (password) => _login(),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(fontFamily: "Oswald", fontSize: 18.0),
                      cursorColor: Color(COLOR_PRIMARY),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 16, right: 16),
                        hintText: 'password'.tr(),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY), width: 2.0)),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              visible = !visible;
                            });
                          },
                          child: Icon(
                              visible ? Icons.visibility : Icons.visibility_off,
                              color: Color(COLOR_PRIMARY)),
                        ),
                      )),
                ),
              ),

              /// forgot password text, navigates user to ResetPasswordScreen
              /// and this is only visible when logging with email and password
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => push(context, ResetPasswordScreen()),
                    child: Text(
                      'Forgot password?'.tr(),
                      style: TextStyle(
                          fontFamily: "Oswald",
                          color: Color(COLOR_PRIMARY),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ),

              /// the main action button of the screen, this is hidden if we
              /// received the code from firebase
              /// the action and the title is base on the state,
              /// * logging with email and password: send email and password to
              /// firebase
              /// * logging with phone number: submits the phone number to
              /// firebase and await for code verification
              Padding(
                padding:
                    const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(COLOR_PRIMARY),
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(
                          color: Color(COLOR_PRIMARY),
                        ),
                      ),
                    ),
                    child: Text(
                      'logIn'.tr(),
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                    ),
                    onPressed: () => _login(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'or',
                    style: TextStyle(
                        fontFamily: "Oswald",
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black),
                  ).tr(),
                ),
              ),

              /// Google login button
              Padding(
                padding:
                    const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.asset(
                                'assets/images/google_logo.png',
                                // color: Colors.grey.shade200,
                                height: 25,
                                width: 25,
                              ),
                            ),
                            Text(
                              'Continuar con Google'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: "Oswald",
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54),
                            ).tr(),
                          ]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(googleButtonColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: const BorderSide(
                            color: Color(googleButtonColor),
                          ),
                        ),
                      ),
                      onPressed: () async => loginWithGoogle()),
                ),
              ),
              if (!kIsWeb)
                FutureBuilder<bool>(
                  future: apple.TheAppleSignIn.isAvailable(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator.adaptive(
                        valueColor:
                            AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                      );
                    }
                    if (!snapshot.hasData || (snapshot.data != true)) {
                      return Container();
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(
                            right: 40.0, left: 40.0, bottom: 20),
                        child: apple.AppleSignInButton(
                          cornerRadius: 25.0,
                          type: apple.ButtonType.signIn,
                          style: isDarkMode(context)
                              ? apple.ButtonStyle.white
                              : apple.ButtonStyle.black,
                          onPressed: () => loginWithApple(),
                        ),
                      );
                    }
                  },
                ),

              // /// switch between login with phone number and email login states
              // Padding(
              //   padding: EdgeInsets.only(top: 10, right: 40, left: 40),
              //   child: InkWell(
              //     borderRadius: BorderRadius.circular(25),
              //     hoverColor: Color(COLOR_PRIMARY).withOpacity(0.1),
              //     onTap: () {
              //       push(context, PhoneNumberInputScreen(login: true));
              //     },
              //     child: Container(
              //         alignment: Alignment.bottomCenter,
              //         padding: EdgeInsets.all(10),
              //         decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(25),
              //             border:
              //                 Border.all(color: Color(COLOR_PRIMARY), width: 1)),
              //         child: Row(
              //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //             children: [
              //               Icon(
              //                 Icons.phone,
              //                 color: Color(COLOR_PRIMARY),
              //               ),
              //               Text(
              //                 'loginWithPhoneNumber'.tr(),
              //                 style: TextStyle(
              //                     fontFamily: "Oswald",
              //                     color: Color(COLOR_PRIMARY),
              //                     fontWeight: FontWeight.bold,
              //                     fontSize: 16,
              //                     letterSpacing: 1),
              //               ),
              //             ])),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  _login() async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState!.save();
      await _loginWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text.trim());
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  /// login with email and password with firebase
  /// @param email user email
  /// @param password user password
  _loginWithEmailAndPassword(String email, String password) async {
    await showProgress(context, "loggingInPleaseWait".tr(), false);
    dynamic result = await FireStoreUtils.loginWithEmailAndPassword(
        email.trim(), password.trim());
    await hideProgress();
    if (result != null && result is User && result.role == USER_ROLE_CUSTOMER) {
      result.fcmToken =
          kIsWeb ? "" : await FireStoreUtils.firebaseMessaging.getToken() ?? '';
      await FireStoreUtils.updateCurrentUser(result).then((value) async {
        MyAppState.currentUser = result;
        print(MyAppState.currentUser!.active.toString() + "===S");
        if (MyAppState.currentUser!.active == true) {
          if ((kIsWeb &&
                  (MyAppState.currentUser!.defaultRestaurant == null ||
                      MyAppState.currentUser!.defaultRestaurant!.isEmpty)) ||
              (!kIsWeb && (MyAppState().activatedLocation == null ||
                        !MyAppState().activatedLocation! || MyAppState().locationActive == null ||
                        !MyAppState().locationActive!))) {
            pushReplacement(context, SelectRestaurant());
          } else {
            pushReplacement(context, ContainerScreen(user: result));
          }
        } else {
          showAlertDialog(
              context, "accountDisabledContactAdmin".tr(), "", true);
        }
      });
    } else if (result != null && result is String) {
      showAlertDialog(context, "NotAuthenticate".tr(), result, true);
    } else {
      showAlertDialog(context, "NotAuthenticate".tr(),
          'Login failed, Please try again.'.tr(), true);
    }
  }

  ///dispose text editing controllers to avoid memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  loginWithGoogle() async {
    try {
      await showProgress(context, "loggingInPleaseWait".tr(), false);
      dynamic result = await FireStoreUtils.loginWithGoogle();
      await hideProgress();
      if (result != null && result is User) {
        MyAppState.currentUser = result;
        print("AQUI");
        if (MyAppState.currentUser!.active == true) {
          if ((kIsWeb &&
                  (MyAppState.currentUser!.defaultRestaurant == null ||
                      MyAppState.currentUser!.defaultRestaurant!.isEmpty)) ||
              (!kIsWeb && (MyAppState().activatedLocation == null ||
                        !MyAppState().activatedLocation! || MyAppState().locationActive == null ||
                        !MyAppState().locationActive!))) {
            pushReplacement(context, SelectRestaurant());
          } else {
            pushReplacement(context, ContainerScreen(user: result));
          }
        } else {
          showAlertDialog(
              context, "accountDisabledContactAdmin".tr(), "", true);
        }
      } /*else if (result != null && result is String) {
        showAlertDialog(context, 'Error'.tr(), result.tr(), true);
      } else {
        showAlertDialog(
            context, 'Error', "notLoginFacebook".tr(), true);
      }*/
    } catch (e, s) {
      await hideProgress();
      print('_LoginScreen.loginWithGoogle $e $s');
      showAlertDialog(context, 'error'.tr(), "notLoginFacebook".tr(), true);
    }
  }

  loginWithApple() async {
    try {
      await showProgress(context, "loggingInPleaseWait".tr(), false);
      dynamic result = await FireStoreUtils.loginWithApple();
      await hideProgress();
      if (result != null && result is User) {
        MyAppState.currentUser = result;
        // pushAndRemoveUntil(context, ContainerScreen(user: result), false);
        if (MyAppState.currentUser!.active == true) {
          pushAndRemoveUntil(context, ContainerScreen(user: result), false);
        } else {
          showAlertDialog(
              context, "accountDisabledContactAdmin".tr(), "", true);
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'error'.tr(), result.tr(), true);
      } else {
        showAlertDialog(context, 'error', "notLoginApple".tr(), true);
      }
    } catch (e, s) {
      await hideProgress();
      print('_LoginScreen.loginWithApple $e $s');
      showAlertDialog(context, 'error'.tr(), "notLoginApple".tr(), true);
    }
  }
}
