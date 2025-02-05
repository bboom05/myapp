import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:myapp/view/Login.dart';
import '../system/info.dart';
import 'package:http/http.dart' as http;

class ResetPasswordView extends StatefulWidget {
  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final employeeCodeController = TextEditingController();
  final newPasswordController = TextEditingController();
  bool hidePassword = true;
  String errorMessage = ""; // ตัวแปรสำหรับเก็บข้อความแจ้งเตือน

  Future<void> _resetPassword() async {
    // ตรวจสอบว่ามีข้อมูลครบถ้วนก่อนทำการรีเซ็ตรหัสผ่าน
    if (employeeCodeController.text.isEmpty ||
        newPasswordController.text.isEmpty) {
      setState(() {
        errorMessage =
            'กรุณากรอกข้อมูลให้ครบถ้วน'; // แสดงข้อความเมื่อข้อมูลไม่ครบ
      });
      return;
    }

    // แสดง loading indicator
    EasyLoading.show(status: 'กำลังรีเซ็ตรหัสผ่าน...');

    Map<String, String> map = {
      "employee_code": employeeCodeController.text,
      "pass_user": newPasswordController.text,
    };

    var body = json.encode(map);
    await postResetPassword(http.Client(), body);
  }

  Future<void> postResetPassword(http.Client client, String jsonMap) async {
    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;

    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    try {
      final response = await client.post(
        Uri.parse(Info().userSignup),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/json'
        },
        body: jsonMap,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          // รีเซ็ตรหัสผ่านสำเร็จ แสดง Popup
          _showSuccessDialog();
        } else {
          setState(() {
            // แสดงข้อความ error จาก server
            errorMessage = data["message"] == "Employee code not found"
                ? "ไม่พบรหัสพนักงานในระบบ"
                : "เกิดข้อผิดพลาด: ${data["message"]}";
          });
        }
      } else {
        setState(() {
          // แสดง error เมื่อ request ล้มเหลว
          errorMessage =
              'ไม่สามารถรีเซ็ตรหัสผ่านได้ สถานะ: ${response.statusCode}';
        });
      }
    } catch (e) {
      // จัดการ error ที่เกิดขึ้นระหว่าง request
      print('Error during reset password: $e');
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาด โปรดลองใหม่อีกครั้ง';
      });
    } finally {
      EasyLoading.dismiss(); // ปิด loading indicator
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ปิด popup ด้วยการกดภายนอกไม่ได้
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // ขอบโค้งมนเล็กน้อย
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white, // พื้นหลังสีขาวเรียบง่าย
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // จำกัดขนาดตามเนื้อหาข้างใน
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CAF50), // สีเขียวแสดงถึงความสำเร็จ
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'รีเซ็ตรหัสผ่านสำเร็จ!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600, // ความหนาของข้อความที่พอดี
                    color: Colors.black87, // สีข้อความเป็นสีเทาเข้ม
                    fontFamily: 'Kanit',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'รหัสผ่านของคุณถูกเปลี่ยนเรียบร้อยแล้ว',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey, // สีเทาเพื่อความเรียบง่าย
                    fontFamily: 'Kanit',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด popup
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginView()),
                      (Route<dynamic> route) =>
                          false, // นำทางไปยังหน้า LoginView
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    backgroundColor: const Color(0xFFFFA726), // สีเขียว minimal
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // ปุ่มโค้งมนเล็กน้อย
                    ),
                    elevation: 0, // ไม่มีเงาเพื่อความเรียบง่าย
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      color: Colors.white, // ข้อความสีขาวที่ดูสะอาดตา
                      fontFamily: 'Kanit',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งรหัสผ่านใหม่',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _buildTextField(
              employeeCodeController,
              hintText: 'รหัสพนักงาน',
            ),
            _buildTextField(
              newPasswordController,
              hintText: 'รหัสผ่านใหม่',
              obscureText: hidePassword,
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty) // แสดงข้อความแจ้งเตือนถ้ามี
              Container(
                alignment: Alignment.centerLeft, // จัดให้อยู่ทางซ้าย
                margin: const EdgeInsets.only(bottom: 10),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'Kanit',
                  ),
                  textAlign: TextAlign.left, // จัดข้อความให้อยู่ทางซ้าย
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text('รีเซ็ตรหัสผ่าน',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'Kanit', fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFFFF8C00),
                shadowColor: const Color(0xFFF26522),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
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
      ),
    );
  }
}
