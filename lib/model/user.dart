import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:myapp/system/info.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class User {
  static SharedPreferences? _sharedPrefs;
  Future<void> init() async {
    _sharedPrefs ??= await SharedPreferences.getInstance();
  }

  bool get isLogin => _sharedPrefs?.getBool('isLogin') ?? false;
  set isLogin(bool value) {
    _sharedPrefs?.setBool('isLogin', value);
  }

  String get fullname => _sharedPrefs?.getString('fullname') ?? "";
  set fullname(String value) {
    _sharedPrefs?.setString('fullname', value);
  }

  String get employee_code => _sharedPrefs?.getString('employee_code') ?? "";
  set employee_code(String value) {
    _sharedPrefs?.setString('employee_code', value);
  }

  String get brance_code => _sharedPrefs?.getString('brance_code') ?? "";
  set brance_code(String value) {
    _sharedPrefs?.setString('brance_code', value);
  }

  String get brance_name => _sharedPrefs?.getString('brance_name') ?? "";
  set brance_name(String value) {
    _sharedPrefs?.setString('brance_name', value);
  }

  String get uid => _sharedPrefs?.getString('uid') ?? "";
  set uid(String value) {
    _sharedPrefs?.setString('uid', value);
  }

  String get email => _sharedPrefs?.getString('email') ?? "";
  set email(String value) {
    _sharedPrefs?.setString('email', value);
  }

  String get authenToken => _sharedPrefs?.getString('authen_token') ?? "";
  set authenToken(String value) {
    _sharedPrefs?.setString('authen_token', value);
  }

  String get avatar =>
      _sharedPrefs?.getString('avatar') ??
      "${Info().baseUrl}images/nopic-personal.jpg";
  set avatar(String value) {
    _sharedPrefs?.setString('avatar', value);
  }

  Future<void> logout() async {
    await _sharedPrefs?.clear();
  }
}
