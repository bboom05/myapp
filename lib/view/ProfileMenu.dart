import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/ChooseLogin.dart';
import 'package:myapp/view/Login.dart';
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
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  ModalRoute.withName("/"),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Color(0xfff8f8f8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16, // ใช้ตัวอักษรแบบบาง
            color: Colors.grey,
            fontFamily: 'Kanit',
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, {required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Color(0xffFF8C00)),
          title: Text(
            title,
            style: TextStyle(fontFamily: 'Kanit', fontSize: 16),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        Divider(
          thickness: 1,
          indent: 16,
          endIndent: MediaQuery.of(context).size.width * 0.05,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Initialize Toast context

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'บัญชี',
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.black,
            fontWeight: FontWeight.w300, // ใช้ตัวอักษรแบบบาง
          ),
        ),
        backgroundColor: Colors.white,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.orange),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: Container(
        color: Colors.white,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('บัญชีของฉัน'),
                  _buildListTile(
                    'ข้อมูลเกี่ยวกับบัญชี',
                    Icons.person,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()), // ไปหน้า ProfilePage
                      );
                    },
                  ),
                  // _buildSectionTitle('ตั้งค่า'),
                ],
              ),
            ),
            // SliverList(
            //   delegate: SliverChildListDelegate(
            //     [
            //       // _buildListTile(
            //       //   'ตั้งค่าการแชท',
            //       //   Icons.chat,
            //       //   onTap: () {},
            //       // ),
            //       // _buildListTile(
            //       //   'ตั้งค่าการแจ้งเตือน',
            //       //   Icons.notifications,
            //       //   onTap: () {},
            //       // ),
            //       // _buildListTile(
            //       //   'การตั้งค่าความเป็นส่วนตัว',
            //       //   Icons.lock,
            //       //   onTap: () {},
            //       // ),
            //       // _buildListTile(
            //       //   'ผู้ใช้ที่ถูกระงับ',
            //       //   Icons.block,
            //       //   onTap: () {},
            //       // ),
            //       // _buildListTile(
            //       //   'ภาษา / Language',
            //       //   Icons.language,
            //       //   onTap: () {},
            //       // ),
            //     ],
            //   ),
            // ),
            SliverToBoxAdapter(
              child: Column(
                
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              //     _buildSectionTitle('ช่วยเหลือ'),
              //     _buildListTile(
              //       'ศูนย์ช่วยเหลือ',
              //       Icons.help,
              //       onTap: () {},
              //     ),
              //     _buildListTile(
              //       'กฎระเบียบในการใช้',
              //       Icons.rule,
              //       onTap: () {},
              //     ),
              //     _buildListTile(
              //       'นโยบายของ Shopee',
              //       Icons.policy,
              //       onTap: () {},
              //     ),
              //     _buildListTile(
              //       'ชอบใช้งาน Shopee? ให้คะแนนแอปเลย!',
              //       Icons.star,
              //       onTap: () {},
              //     ),
              //     _buildListTile(
              //       'เกี่ยวกับ',
              //       Icons.info,
              //       onTap: () {},
              //     ),
              //     _buildListTile(
              //       'คำขอลบบัญชีผู้ใช้',
              //       Icons.delete,
              //       onTap: () {},
              //     ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        logout(); // logout function
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "ออกจากระบบ",
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Kanit',
                                fontWeight: FontWeight.w300, // ใช้ตัวอักษรแบบบาง
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
