import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart'; // Assuming this is where your User class is
import 'package:myapp/view/ChooseLogin.dart';
import 'package:myapp/view/HomeView.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget initialRoute = const HomeView();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      home: initialRoute,
    );
  }
}
