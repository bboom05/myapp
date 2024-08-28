import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:toast/toast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var user = User();
  bool isLogin = false;
  var fullname = "";
  var employee_code = "";
  var brance_code = "";
  var brance_name = "";
  var email = "";

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
      employee_code = user.employee_code;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
      email = user.email;
    });
  }

  Future<void> logout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('ยืนยันการออกจากระบบ?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ยืนยัน'),
              onPressed: () {
                user.logout();
                Toast.show("ออกจากระบบแล้ว",
                    duration: Toast.lengthLong, gravity: Toast.bottom);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ChooseLogin()),
                  ModalRoute.withName("/"),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Initialize Toast context

    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        // backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(
            color: Colors.white), // ตั้งค่าสีของไอคอนย้อนกลับ
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFA726), // สีส้มอ่อน
                Color(0xFFFF5722), // สีส้มเข้ม
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              title: Text(fullname),
              leading: Icon(Icons.person, color: Colors.orange),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              title: const Text('Employee ID'),
              subtitle: Text(employee_code),
              leading: Icon(Icons.badge, color: Colors.orange),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              title: const Text('Branch ID'),
              subtitle: Text(brance_code),
              leading: Icon(Icons.business, color: Colors.orange),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              title: const Text('Branch'),
              subtitle: Text(brance_name),
              leading: Icon(Icons.location_city, color: Colors.orange),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              title: const Text('Email'),
              subtitle: Text(email),
              leading: Icon(Icons.alternate_email, color: Colors.orange),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(20.0),
          //   child: GestureDetector(
          //     onTap: () {
          //       logout(); // logout function
          //     },
          //     child: Container(
          //       padding:
          //           const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          //       decoration: BoxDecoration(
          //         color: Colors.red,
          //         borderRadius: BorderRadius.circular(5),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: const [
          //           Icon(Icons.exit_to_app, color: Colors.white),
          //           SizedBox(width: 8),
          //           Text(
          //             "ออกจากระบบ",
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontFamily: 'Kanit',
          //               fontSize: 16,
          //             ),
          //           ),
          //           SizedBox(width: 8),
          //           Icon(
          //             Icons.arrow_forward_ios,
          //             color: Colors.white,
          //             size: 16,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
