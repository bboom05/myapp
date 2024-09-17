import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // พื้นหลังสีอ่อน
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              fullname,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileItem('Employee ID', employee_code),
                      const Divider(thickness: 0.5), // เส้นบาง
                      _buildProfileItem('Branch Code', brance_code),
                      const Divider(thickness: 0.5), // เส้นบาง
                      _buildProfileItem('Branch Name', brance_name),
                      const Divider(thickness: 0.5), // เส้นบาง
                      _buildProfileItem('Email', email),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
