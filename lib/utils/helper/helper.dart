import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toast/toast.dart';

void showToast(BuildContext context,
    {@required String message,
    int gravity = 0,
    Color backgroundColor = const Color(2852126720),
    Color textColor = Colors.white,
    int duration = 4}) {
  Toast.show(message, context,
      backgroundRadius: 10,
      duration: duration,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor);
}

double getWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

// void showSnackBar(GlobalKey<ScaffoldState> _scaffoldKey, String msg,
//     {double height = 30, Color color = AppColor.blue}) {
//   if (_scaffoldKey == null || _scaffoldKey.currentState == null) {
//     return;
//   }
//   _scaffoldKey.currentState.;
//   final snackBar = SnackBar(
//       backgroundColor: color,
//       content: Text(
//         msg,
//         style: TextStyle(
//           color: Colors.white,
//         ),
//       ));
//   _scaffoldKey.currentState.showSnackBar(snackBar);
// }

/// @ validate email
bool validateEmail(String email) {
  String p =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  RegExp regExp = new RegExp(p);

  var status = regExp.hasMatch(email);
  return status;
}

bool isPasswordCompliant(String password, [int minLength = 8]) {
  if (password == null || password.isEmpty) {
    return false;
  }

  bool _hasDigits = password.contains(new RegExp(r'[0-9]'));
  bool _hasLowercase = password.contains(new RegExp(r'[a-z]'));
  bool _hasMinLength = password.length >= minLength;
  return _hasDigits & _hasLowercase & _hasMinLength;
}

String getStringPathName(String name) {
  final List<String> _link = name.split('/');
  return _link.last;
}

String getStringPathNameFromWeb(String name) {
  return name.contains('vocals.mp3') ? 'vocals.mp3' : 'other.mp3';
}

//* finds available space for storage on users device
Future<String> findLocalPath() async {
  final directory = Platform.isAndroid
      ? await getExternalStorageDirectory()
      : await getApplicationDocumentsDirectory();
  return directory.path;
}
