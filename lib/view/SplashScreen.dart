import 'package:flutter/material.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:myapp/view/HomeView.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/system/info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Widget initialRoute = const HomeView();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    checkLoginStatus().then((_) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => initialRoute,
            ),
          );
        }
      });
    });
  }

  Future<void> checkLoginStatus() async {
    var user = User();
    await user.init();
    if (user.isLogin) {
      await fetchBranchData(user.employee_code);
      initialRoute = const HomeView();
    } else {
      initialRoute = const LoginView();
    }
    setState(() {});
  }

  Future<void> fetchBranchData(String employeeId) async {
    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));
    final response = await http.post(
      Uri.parse(Info()
          .getBranchData), // Update this with your actual API URL for fetching branch data
      headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'employee_code': employeeId}),
    );

    if (response.statusCode == 200) {
      List<dynamic> employees = json.decode(response.body);
      var employee = findEmployeeByCode(employees, employeeId);
      // print("employee ${employee}");
      if (employee != null) {
        var user = User();
        await user.init();
        user.brance_code = employee['brance_code'];
        user.brance_name = employee['brance_name'];
      }
    } else {
      print('Failed to fetch branch data with status: ${response.statusCode}');
    }
  }

  Map<String, dynamic>? findEmployeeByCode(
      List<dynamic> employees, String employeeCode) {
    try {
      return employees
          .firstWhere((emp) => emp['employee_code'] == employeeCode);
    } catch (e) {
      print('Error finding employee: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[200]!, // เพิ่มสีเทาอ่อนเพื่อสร้างความลึก
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_splash.png', // เพิ่ม path ของโลโก้ของคุณ
                  width: 200,
                  // height: 200,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Super App',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF8C00), // สีข้อความเป็นสีดำ
                    fontFamily: 'Kanit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
