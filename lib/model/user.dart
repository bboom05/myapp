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

  String get password => _sharedPrefs?.getString('password') ?? "";
  set password(String value) {
    _sharedPrefs?.setString('password', value);
  }

  String get brance_code => _sharedPrefs?.getString('brance_code') ?? "";
  set brance_code(String value) {
    _sharedPrefs?.setString('brance_code', value);
  }

  String get brance_name => _sharedPrefs?.getString('brance_name') ?? "";
  set brance_name(String value) {
    _sharedPrefs?.setString('brance_name', value);
  }

  String get select_branch_code =>
      _sharedPrefs?.getString('select_branch_code') ?? "";
  set select_branch_code(String value) {
    _sharedPrefs?.setString('select_branch_code', value);
  }

  String get select_branch_name =>
      _sharedPrefs?.getString('select_branch_name') ?? "";
  set select_branch_name(String value) {
    _sharedPrefs?.setString('select_branch_name', value);
  }

  String get area_ma_code => _sharedPrefs?.getString('area_ma_code') ?? "";
  set area_ma_code(String value) {
    _sharedPrefs?.setString('area_ma_code', value);
  }
  // การจัดการ branch_codes_area แบบ List<Map<String, String>>
  List<Map<String, String>> get branch_codes_area {
    // ดึงข้อมูลที่เก็บในรูปแบบ List<String>
    List<String>? savedBranches = _sharedPrefs?.getStringList('branch_codes_area');
    if (savedBranches == null) return [];

    // แปลง List<String> กลับมาเป็น List<Map<String, String>>
    return savedBranches.map((encodedBranch) {
      List<String> parts = encodedBranch.split('|'); // แยกข้อมูล branch_code และ branch_name
      return {
        'branch_code': parts[0],
        'branch_name': parts[1],
      };
    }).toList();
  }

  set branch_codes_area(List<Map<String, String>> value) {
    // แปลง List<Map<String, String>> เป็น List<String> ก่อนที่จะเก็บลง SharedPreferences
    List<String> encodedBranches = value.map((branch) {
      return '${branch['branch_code']}|${branch['branch_name']}'; // รวม branch_code และ branch_name เป็น String
    }).toList();
    
    _sharedPrefs?.setStringList('branch_codes_area', encodedBranches);
  }

  
  // List<String> get branch_codes_area =>
  //     List<String>.from(_sharedPrefs?.getStringList('branch_codes_area') ?? []);
  // set branch_codes_area(List<String> value) {
  //   _sharedPrefs?.setStringList('branch_codes_area', value);
  // }

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
