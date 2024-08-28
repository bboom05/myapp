import 'package:flutter/material.dart';
import 'package:myapp/view/QRScannerPage.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFA726), // สีเริ่มต้น
                Color(0xFFFF7043), // สีไล่ลง
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt, color: Colors.white), // ไอคอนกล้อง
            label: const Text('สแกน', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontFamily: 'Kanit')), // ข้อความปุ่ม
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0, // ไม่มีเงาเพราะมีการใช้ gradient
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Colors.transparent, // ตั้งเป็น transparent เพื่อให้เห็น Gradient
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // รูปทรงโค้งมนของปุ่ม
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
