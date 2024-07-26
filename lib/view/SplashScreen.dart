import 'package:flutter/material.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:myapp/view/HomeView.dart';
import 'package:myapp/model/user.dart';

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
      duration: const Duration(seconds: 5),
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
      initialRoute = const HomeView();
    } else {
      // initialRoute = const ChooseLogin();
      initialRoute = const LoginView();
    }
    setState(() {});
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
                  '1APPservices',
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
