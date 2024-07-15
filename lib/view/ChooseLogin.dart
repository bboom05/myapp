import 'package:flutter/material.dart';
import 'package:myapp/view/CameraScreen.dart';
import 'package:myapp/view/Login.dart';

class ChooseLogin extends StatefulWidget {
  const ChooseLogin({super.key});

  @override
  State<ChooseLogin> createState() => _ChooseLoginState();
}

class _ChooseLoginState extends State<ChooseLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('เลือกประเภทผู้ใช้',
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(
          color: Colors.white, // ตั้งค่าสีของไอคอนย้อนกลับ
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginView()),
                  );
                },
                child: const Text(
                  'พนักงาน',
                  style: TextStyle(fontSize: 24, fontFamily: 'Kanit'),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFFF8C00),
                  shadowColor: const Color(0xFFF26522),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                // onPressed: () {
                //   print('กดปุ่มลูกค้า');
                // },
                onPressed: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CameraScreen()))
                },
                child: const Text(
                  'ลูกค้า',
                  style: TextStyle(fontSize: 24, fontFamily: 'Kanit'),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFFF8C00),
                  shadowColor: const Color(0xFFF26522),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
