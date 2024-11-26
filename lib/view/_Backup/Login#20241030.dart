import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/system/info.dart';
import 'package:myapp/view/HomeView.dart';
import 'package:http/http.dart' as http;

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
  String errorText = "";
  User user = User();

  Future<void> login() async {
    Map map = {
      "employee_code": username.text,
      "pass_user": password.text,
    };

    var body = json.encode(map);
    return postLogin(http.Client(), body);
  }

  Future<void> postLogin(http.Client client, String jsonMap) async {
    try {
      final response = await client.post(
        Uri.parse(Info().userLoginAuth),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonMap,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> employee = json.decode(response.body);
        print('employee: $employee');

        if (employee["status"] == "success") {
          user.isLogin = true;
          user.fullname = employee["name_user"].toString();
          user.uid = employee["employee_code"].toString();
          user.employee_code = employee["employee_code"].toString();
          user.brance_code = employee["branch_code_odoo"].toString();
          user.brance_name = employee["brance_name"].toString();
          user.select_branch_code = employee["branch_code_odoo"].toString();
          user.select_branch_name = employee["brance_name"].toString();
          user.email = employee["email"].toString();
          user.password = password.text;
          user.area_ma_code = employee["area_ma_code"].toString();

          // ตรวจสอบการสร้าง defaultBranch และ branch name
          String? defaultBranchCode = employee["branch_code_odoo"] != null
              ? employee["branch_code_odoo"].toString()
              : null;
          String? defaultBranchName = employee["brance_name"] != null
              ? employee["brance_name"].toString()
              : null;

          List<Map<String, String>> updatedBranchCodesArea =
              (employee["branch_codes_area"] as List)
                  .map((branch) => {
                        "branch_code": branch["branch_code"] as String,
                        "branch_name": branch["branch_name"] as String
                      })
                  .toList();

          if (defaultBranchCode != null && defaultBranchName != null) {
            updatedBranchCodesArea.insert(0, {
              "branch_code": defaultBranchCode,
              "branch_name": defaultBranchName
            });
          }
          user.branch_codes_area = updatedBranchCodesArea;

 
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeView()),
            ModalRoute.withName("/"),
          );
        } else {
          setState(() {
            errorText = "${employee['message']}";
          });
        }
      } else {
        setState(() {
          errorText = "Request failed with status: ${response.statusCode}.";
        });
      }
    } catch (e) {
      print('Error during login: $e');
      setState(() {
        errorText = "Login failed. Please try again later.";
      });
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  void initState() {
    super.initState();
    EasyLoading.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFA726),
                Color(0xFFFF5722),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
              const SizedBox(height: 20),
              Container(
                child: ElevatedButton(
                  onPressed: () {
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
