import 'package:flutter/material.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:myapp/view/HomeView.dart';
import 'package:myapp/model/user.dart';

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
      duration: const Duration(seconds: 3),
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
      initialRoute = const ChooseLogin();
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
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)], // Gradient colors
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
                  'assets/images/tgreloading.png', // เพิ่ม path ของโลโก้ของคุณ
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 10),
                const Text(
                  'TG Fone',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Change text color to white for better contrast
                    fontFamily: 'Kanit',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '1APPservices',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Change text color to white for better contrast
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
