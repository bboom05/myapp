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

    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    var user = User();
    await user.init();
    // print('user: ${user.isLogin}');
    // print('user: ${user.employee_code}');
    // print('user: ${user.brance_code}');
    // print('user: ${user.brance_name}');
    // print('user: ${user.email}');
    // print('user: ${user.fullname}');
    // print('user: ${user.uid}');
    // print('user: ${user.password}');

    if (user.isLogin) {
      await fetchBranchData(user.employee_code, user.password);
      navigateToPage(HomeView()); // Navigate to HomeView if logged in
    } else {
      navigateToPage(
          const LoginView()); // Navigate to LoginView if not logged in
    }
  }

  Future<void> fetchBranchData(String employeeId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Info().userLoginAuth), // API URL
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'employee_code': employeeId,
          'get_branch': '1',
          'pass_user': password
        }),
      );
      // print('response: ${response.body}');
      // print('response: ${response.statusCode}');
      // print('response: ${response.headers}');

      if (response.statusCode == 200) {
        Map<String, dynamic> employee = json.decode(response.body);
        if (employee["status"] == "success") {
          var user = User();
          await user.init();
          user.brance_code = employee['branch_code_odoo'];
          user.brance_name = employee['branch_code_odoo_name'];
          user.select_branch_code = employee['branch_code_odoo'];
          user.select_branch_name = employee['branch_code_odoo_name'];
        }
      } else {
        print(
            'Failed to fetch branch data with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during branch data fetch: $e');
    }
  }

  void navigateToPage(Widget page) {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      }
    });
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
                  'assets/images/logo_splash.png', // โลโก้ของแอป
                  width: 200,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Super App',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF8C00),
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
