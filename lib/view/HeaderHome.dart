import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';

class HeaderHome extends StatefulWidget {
  const HeaderHome({super.key});

  @override
  State<HeaderHome> createState() => _HeaderHomeState();
}

class _HeaderHomeState extends State<HeaderHome> {
  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      color: Color(0xFFFF8C00),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 80),
            Text(
              'Hi! ${fullname}',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 3),
            Text(
              '${brance_name} ' + '(' + brance_code + ')',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
