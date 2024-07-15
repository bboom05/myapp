import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/system/info.dart';
import 'package:myapp/view/HomeView.dart';
// import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;
// import 'package:myapp/view/QRScannerPage.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;
  bool showLoginSocial = true;

  String icon = "";
  String errorText = "";
  User user = User();

  // Future<void> login() async {
  //   Map map = {};
  //   map.addAll({
  //     "username": username.text,
  //     "password": password.text,
  //   });

  //   var body = json.encode(map);
  //   return postLogin(http.Client(), body, map);
  // }

  Future<void> login() async {
    Map map = {
      "username": username.text,
      "password": password.text,
    };

    var body = json.encode(map);
    return postLogin(http.Client(), body, map);
  }

  Future<void> postLogin(http.Client client, String jsonMap, Map map) async {
    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    try {
      final response = await client.post(
          Uri.parse(Info().userLogin), // Update this with your actual API URL
          headers: {
            'Authorization': 'Basic $encodedCredentials',
            'Content-Type': 'application/json',
          },
          body: jsonMap);
      // var msg = '';
      if (response.statusCode == 200) {
        List<dynamic> employees = json.decode(response.body);
        var employee =
            findEmployeeByCode(employees, map['username'], map['password']);
        await user.init();
        EasyLoading.dismiss();
        if (employee != null) {
          user.isLogin = true;
          user.fullname = employee["name_user"].toString();
          user.uid = employee["employee_code"].toString();
          user.employee_code = employee["employee_code"].toString();
          user.brance_code = employee["brance_code"].toString();
          user.brance_name = employee["brance_name"].toString();
          user.email = employee["email"].toString();
       
          // user.authenToken = rs["authenToken"].toString();
          // Toast.show("ยินดีต้อนรับ",
          //     // ignore: use_build_context_synchronously
          //     duration: Toast.lengthLong, gravity: Toast.bottom,context:context);
          // Toast.show("ยินดีต้อนรับ", duration: Toast.lengthLong, gravity: Toast.bottom, context: context); // Make sure context is passed here correctly
          Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => HomeView()),
            ModalRoute.withName("/"),
          );
        } else {
          setState(() {
            errorText = "รหัสพนักงานหรือรหัสผ่านไม่ถูกต้อง กรุณาลลองใหม่อีกครั้ง";
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error during login: $e');
    }
  }

  Map<String, dynamic>? findEmployeeByCode(
      List<dynamic> employees, String code, String password) {
    try {
      return employees.firstWhere((emp) =>
          emp['employee_code'] == code && emp['pass_user'] == password);
    } catch (e) {
      print('Error finding employee: $e');
      return null;
    }
  }

  // Future<void> postLogin(http.Client client, jsonMap, Map map) async {
  //   const usernameKey = 'tgdatauser';
  //   const passwordKey = 'tgf0n3';
  //   const credentials = '$usernameKey:$passwordKey';
  //   final encodedCredentials = base64Encode(utf8.encode(credentials));
  //   final response = await client.post(Uri.parse(Info().userLogin),
  //       headers: {
  //         'Authorization': 'Basic $encodedCredentials',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonMap);
  //   var rs = json.decode(response.body);
  //   var status = "success";
  //   // var status = rs["status"].toString();
  //   var msg = rs["msg"].toString();
  //   await user.init();
  //   EasyLoading.dismiss();
  //   if (status == "success") {
  //     user.isLogin = true;
  //     user.uid = rs["employee_code"].toString();
  //     user.fullname = rs["fullname"].toString();
  //     user.employee_code = rs["employee_code"].toString();
  //     user.brance_code = rs["brance_code"].toString();
  //     user.brance_name = rs["brance_name"].toString();
  //     // user.authenToken = rs["authenToken"].toString();
  //     Toast.show("ยินดีต้อนรับ",
  //         duration: Toast.lengthLong, gravity: Toast.bottom);
  //     // ignore: use_build_context_synchronously
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (context) => const HomeView()),
  //       ModalRoute.withName("/"),
  //     );
  //   } else {
  //     setState(() {
  //       errorText = msg;
  //     });
  //   }
  //   if (FocusScope.of(context).isFirstFocus) {
  //     FocusScope.of(context).requestFocus(new FocusNode());
  //   }
  // }

  @override
  void initState() {
    super.initState();
    EasyLoading.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Login',
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(
          color: Colors.white, // ตั้งค่าสีของไอคอนย้อนกลับ
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                child: Image.asset('assets/images/tg_logo.png'),
                height: 200,
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: username,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'รหัสพนักงาน',
                    isDense: true,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสพนักงาน';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: password,
                  obscureText: hidePassword,
                  onChanged: (value) {
                    formKey.currentState?.validate();
                    if (errorText.isNotEmpty) setState(() => errorText = '');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    return null;
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    isDense: true,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          // color: Theme.of(context).primaryColorDark,
                          color: Colors.black),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              if (errorText.isNotEmpty)
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 4),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // TextButton(
              //   onPressed: () {
              //     // Logic to handle forgotten password
              //     print('Forgot Password Button Pressed');
              //   },
              //   child: const Text('ลืมรหัสผ่าน?',
              //       style: TextStyle(
              //           color: Color.fromARGB(255, 137, 137, 137),
              //           fontSize: 16,
              //           fontFamily: 'Kanit')),
              // ),
              const SizedBox(height: 20),
              Container(
                child: ElevatedButton(
                  // onPressed: _login,
                  onPressed: () {
                    // Navigator.pushAndRemoveUntil(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const HomeView()),
                    //   (Route<dynamic> route) => false,
                    // );

                    setState(() {
                      final valid = formKey.currentState?.validate();
                      if (valid == true) {
                        EasyLoading.show(status: 'loading...');
                        login();
                      }
                    });
                  },
                  child: const Text('เข้าสู่ระบบ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Kanit')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFFFF8C00),
                    shadowColor: const Color(0xFFF26522),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
