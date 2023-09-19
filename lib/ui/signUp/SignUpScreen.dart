import 'dart:io';

import 'package:easy_localization/easy_localization.dart' as easyLocal;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:custom_food/constants.dart';
import 'package:custom_food/main.dart';
import 'package:custom_food/model/User.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/ui/container/ContainerScreen.dart';
import 'package:custom_food/ui/phoneAuth/PhoneNumberInputScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:permission_handler/permission_handler.dart';

import '../home/SelectRestaurant.dart';

File? _image;
class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey();
  String? firstName, lastName, email, mobile, password, confirmPassword;
  AutovalidateMode _validate = AutovalidateMode.disabled;
  PhoneNumber code = PhoneNumber(isoCode: "VE");
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) if (Platform.isAndroid) {
      retrieveLostData();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: Form(
            key: _key,
            autovalidateMode: _validate,
            child: formUI(),
          ),
        ),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse? response = await _imagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image = File(response.file!.path);
      });
    }
  }

  _onCameraClick() async {
    if (kIsWeb) {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null)
        setState(() {
          _image = File(image.path);
        });
    } else {
      final action = CupertinoActionSheet(
        message: Text(
          'addProfilePicture',
          style: TextStyle(fontFamily: "Oswald", fontSize: 15.0),
        ).tr(),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text('chooseFromGallery').tr(),
            isDefaultAction: false,
            onPressed: () async {
              Navigator.pop(context);
              XFile? image =
                  await _imagePicker.pickImage(source: ImageSource.gallery);
              if (image != null)
                setState(() {
                  _image = File(image.path);
                });
            },
          ),
          CupertinoActionSheetAction(
            child: Text('takeAPicture').tr(),
            isDestructiveAction: false,
            onPressed: () async {
              Navigator.pop(context);
              XFile? image =
                  await _imagePicker.pickImage(source: ImageSource.camera);
              if (image != null)
                setState(() {
                  _image = File(image.path);
                });
            },
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('cancel').tr(),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      showCupertinoModalPopup(context: context, builder: (context) => action);
    }
  }

  Widget formUI() {
    return Column(
      children: <Widget>[
        Align(
            alignment: Directionality.of(context) == TextDirection.ltr
                ? Alignment.topLeft
                : Alignment.topRight,
            child: Text(
              'createNewAccount',
              style: TextStyle(
                  fontFamily: "Oswald",
                  color: Color(COLOR_PRIMARY),
                  fontWeight: FontWeight.bold,
                  fontSize: 25.0),
            ).tr()),
        Padding(
          padding:
              const EdgeInsets.only(left: 8.0, top: 32, right: 8, bottom: 8),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey.shade400,
                child: ClipOval(
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: _image == null
                        ? Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          )
                        : kIsWeb
                            ? Image.network(
                                _image!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                right: 0,
                child: FloatingActionButton(
                    backgroundColor: Color(COLOR_ACCENT),
                    child: Icon(
                      CupertinoIcons.camera,
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                    mini: true,
                    onPressed: _onCameraClick),
              )
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
              cursorColor: Color(COLOR_PRIMARY),
              textAlignVertical: TextAlignVertical.center,
              validator: validateName,
              onSaved: (String? val) {
                firstName = val;
              },
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                fillColor: Colors.white,
                hintText: easyLocal.tr('firstName'),
                hintStyle: TextStyle(
                  fontFamily: "Oswald",
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
              validator: validateName,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: Color(COLOR_PRIMARY),
              onSaved: (String? val) {
                lastName = val;
              },
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                fillColor: Colors.white,
                hintText: 'lastName'.tr(),
                hintStyle: TextStyle(
                  fontFamily: "Oswald",
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
              keyboardType: TextInputType.emailAddress,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.next,
              cursorColor: Color(COLOR_PRIMARY),
              validator: validateEmail,
              onSaved: (String? val) {
                email = val;
              },
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                fillColor: Colors.white,
                hintText: 'emailAddress'.tr(),
                hintStyle: TextStyle(
                  fontFamily: "Oswald",
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
        ),

        /// user mobile text field, this is hidden in case of sign up with
        /// phone number
        Padding(
          padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                shape: BoxShape.rectangle,
                border: Border.all(color: Colors.grey.shade200)),
            child: InternationalPhoneNumberInput(
              locale: context.locale.languageCode,
              searchBoxDecoration: InputDecoration(labelText: 'Search by country name or dial code'.tr()),
              errorMessage: "validNumber".tr(),
              onInputChanged: (PhoneNumber number) =>
                  mobile = number.phoneNumber,
              ignoreBlank: true,
              countries: ["VE", "US", "CO", "PA"],
              autoValidateMode: AutovalidateMode.always,
              inputDecoration: InputDecoration(
                hintText: 'phoneNumber'.tr(),
                hintStyle: TextStyle(
                  fontFamily: "Oswald",
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              inputBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              initialValue: code,
              selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DIALOG),
              selectorTextStyle: TextStyle(fontFamily: "Oswald"),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
              obscureText: !visible,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.next,
              controller: _passwordController,
              validator: validatePassword,
              onSaved: (String? val) {
                password = val;
              },
              style: TextStyle(fontFamily: "Oswald", fontSize: 18.0),
              cursorColor: Color(COLOR_PRIMARY),
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                fillColor: Colors.white,
                hintText: 'password'.tr(),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
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
                  child: Icon(visible ? Icons.visibility : Icons.visibility_off,
                      color: Color(COLOR_PRIMARY)),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUp(),
              obscureText: !visible,
              validator: (val) =>
                  validateConfirmPassword(_passwordController.text, val),
              onSaved: (String? val) {
                confirmPassword = val;
              },
              style: TextStyle(fontFamily: "Oswald", fontSize: 18.0),
              cursorColor: Color(COLOR_PRIMARY),
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                fillColor: Colors.white,
                hintText: 'confirmPassword'.tr(),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).errorColor),
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
                  child: Icon(visible ? Icons.visibility : Icons.visibility_off,
                      color: Color(COLOR_PRIMARY)),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                backgroundColor: Color(COLOR_PRIMARY),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  side: BorderSide(
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
              ),
              child: Text(
                'signUp'.tr(),
                style: TextStyle(
                  fontFamily: "Oswald",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                ),
              ),
              onPressed: () => _signUp(),
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
                  color: isDarkMode(context) ? Colors.white : Colors.black),
            ).tr(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: ElevatedButton(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
        // InkWell(
        //   onTap: () {
        //     push(context, PhoneNumberInputScreen(login: false));
        //   },
        //   child: Padding(
        //     padding: EdgeInsets.only(top: 10, right: 40, left: 40),
        //     child: Container(
        //         alignment: Alignment.bottomCenter,
        //         padding: EdgeInsets.all(10),
        //         decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(25),
        //             border: Border.all(color: Color(COLOR_PRIMARY), width: 1)),
        //         child: Row(
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: [
        //               Icon(
        //                 Icons.phone,
        //                 color: Color(COLOR_PRIMARY),
        //               ),
        //               Text(
        //                 'signUpWithPhoneNumber'.tr(),
        //                 style: TextStyle(
        //                     fontFamily: "Oswald",
        //                     color: Color(COLOR_PRIMARY),
        //                     fontWeight: FontWeight.bold,
        //                     letterSpacing: 1),
        //               ),
        //             ])),
        //   ),
        // )
      ],
    );
  }

  /// dispose text controllers to avoid memory leaks
  @override
  void dispose() {
    _passwordController.dispose();
    _image = null;
    super.dispose();
  }

  /// if the fields are validated and location is enabled we create a new user
  /// and navigate to [ContainerScreen] else we show error
  _signUp() async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState!.save();
      await _signUpWithEmailAndPassword();
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  loginWithGoogle() async {
    try {
      await showProgress(context, "loggingInPleaseWait".tr(), false);
      dynamic result = await FireStoreUtils.loginWithGoogle();
      await hideProgress();
      if (result != null && result is User) {
        MyAppState.currentUser = result;

        if (MyAppState.currentUser!.active == true) {
          pushAndRemoveUntil(context, ContainerScreen(user: result), false);
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

  _signUpWithEmailAndPassword() async {
    await showProgress(context, "creatingNewAccountPleaseWait".tr(), false);
    dynamic result = await FireStoreUtils.firebaseSignUpWithEmailAndPassword(
        email!.trim(),
        password!.trim(),
        _image,
        firstName!.replaceFirst(firstName![0], firstName![0].toUpperCase()),
        lastName!.replaceFirst(lastName![0], lastName![0].toUpperCase()),
        mobile!,
        context);
    await hideProgress();
    if (result != null && result is User) {
      MyAppState.currentUser = result;
      if(kIsWeb || (!kIsWeb && (MyAppState().activatedLocation == null ||
                        !MyAppState().activatedLocation! || MyAppState().locationActive == null ||
                        !MyAppState().locationActive!)) ){
        pushAndRemoveUntil(context, SelectRestaurant(), false);
      }else{
      pushAndRemoveUntil(context, ContainerScreen(user: result), false);}
    } else if (result != null && result is String) {
      showAlertDialog(context, 'failed'.tr(), result, true);
    } else {
      showAlertDialog(context, 'failed'.tr(), "couldNotSignUp".tr(), true);
    }
  }
}