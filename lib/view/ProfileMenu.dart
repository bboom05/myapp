import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:toast/toast.dart';
import 'package:myapp/view/ProfilePage.dart'; // เพิ่มการนำเข้า ProfilePage

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
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
      body: ListView(
        children: [
          // const Padding(
          //   padding: EdgeInsets.all(8.0),
          //   child: Center(
          //     child: CircleAvatar(
          //       radius: 50,
          //       backgroundColor: Colors.orange,
          //       child: Icon(Icons.person, size: 70, color: Colors.white),
          //     ),
          //   ),
          // ),
          SizedBox(height:30),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xffFF8C00)),
            title: Text('ข้อมูลเกี่ยวกับบัญชี'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProfilePage()), // ไปหน้า ProfilePage
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.attach_money, color: Color(0xffFF8C00)),
            title: Text('ยอดขาย'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // การทำงานเมื่อกดเมนู ยอดขาย
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.trending_up, color: Color(0xffFF8C00)),
            title: Text('Forecast'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // การทำงานเมื่อกดเมนู Forecast
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () {
                logout(); // logout function
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.exit_to_app, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "ออกจากระบบ",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
