import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/system/info.dart';
import 'package:myapp/view/HomeView.dart';
import 'package:http/http.dart' as http;
import 'ResetPasswordView.dart';

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
    print('jsonMap: $jsonMap');
    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;

    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    try {
      final response = await client.post(
        Uri.parse(Info().userLoginAuth),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
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
          user.brance_name = employee["branch_code_odoo_name"].toString();
          user.select_branch_code = employee["branch_code_odoo"].toString();
          user.select_branch_name =
              employee["branch_code_odoo_name"].toString();
          user.email = employee["email"].toString();
          user.password = password.text;
          user.area_ma_code = employee["area_ma_code"].toString();

          // List<Map<String, String>> updatedBranchCodesArea =
          //     (employee["branch_codes_area"] as List)
          //         .map((branch) => {
          //               "branch_code": branch["branch_code"] as String,
          //               "branch_name": branch["branch_name"] as String
          //             })
          //         .toList();

          // if (employee["branch_code_odoo"] != null &&
          //     employee["branch_code_odoo_name"] != null) {
          //   updatedBranchCodesArea.insert(0, {
          //     "branch_code": employee["branch_code_odoo"].toString(),
          //     "branch_name": employee["branch_code_odoo_name"].toString(),
          //   });
          // }
          // user.branch_codes_area = updatedBranchCodesArea;

          List<Map<String, String>> updatedBranchCodesArea = [];

          if (employee["branch_codes_area"] != null &&
              (employee["branch_codes_area"] as List).isNotEmpty &&
              (employee["branch_codes_area"] as List)
                  .any((branch) => branch["branch_code"] != null)) {
            updatedBranchCodesArea = (employee["branch_codes_area"] as List)
                .where((branch) => branch["branch_code"] != null)
                .map((branch) => {
                      "branch_code": branch["branch_code"]?.toString() ?? "",
                      "branch_name":
                          branch["branch_name"]?.toString() ?? "Unknown"
                    })
                .toList();

            // เพิ่มข้อมูล branch_code_odoo เฉพาะกรณีที่มี branch_codes_area อยู่แล้ว
            if (employee["branch_code_odoo"] != null &&
                employee["branch_code_odoo_name"] != null) {
              updatedBranchCodesArea.insert(0, {
                "branch_code": employee["branch_code_odoo"].toString(),
                "branch_name": employee["branch_code_odoo_name"].toString(),
              });
            }
          }

          // ถ้าไม่มีข้อมูลใน branch_codes_area ให้กำหนดเป็นค่าเริ่มต้นตามต้องการ
          if (updatedBranchCodesArea.isEmpty) {
            updatedBranchCodesArea = [
              {
                "branch_code": employee["branch_code_odoo"]?.toString() ?? "",
                "branch_name":
                    employee["branch_code_odoo_name"]?.toString() ?? "Unknown",
              }
            ];
          }

          user.branch_codes_area = updatedBranchCodesArea;
          print('user.branch_codes_area: ${user.branch_codes_area}');

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
              _buildTextField(
                username,
                hintText: 'รหัสพนักงาน',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                password,
                hintText: 'รหัสผ่าน',
                obscureText: hidePassword,
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
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ResetPasswordView()),
                    );
                  },
                  child: Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'Kanit',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
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

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          hintText: hintText,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }
}
